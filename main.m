function exit_stat = main(varargin)

exit_stat = 1; % assume that we exited badly if ever exit before this gets reassigned

if Screen('NominalFrameRate', max(Screen('Screens'))) ~= 60
    errordlg('Monitor refresh rate must be set to 60hz');
    return;
end

% use the inputParser class to deal with arguments
ip = inputParser;
%#ok<*NVREPL> dont warn about addParamValue
addParamValue(ip,'email', 'will@fake.com', @validate_email);
addParamValue(ip,'sessions_completed', 0, @(x) x <= 3);% # sessions must be kept in sync with constants.n_sessions
addParamValue(ip,'debugLevel',0, @(x) isnumeric(x) && x >= 0);
addParamValue(ip,'robotType', 'Good', @(x) sum(strcmp(x, {'Good','Bad','Chaotic'}))==1)
parse(ip,varargin{:}); 
input = ip.Results;
defaults = ip.UsingDefaults;

% Get full path to the directory the function lives in, and add it to the path
constants.root_dir = fileparts(mfilename('fullpath'));
path(path,constants.root_dir);
constants.lib_dir = fullfile(constants.root_dir, 'lib');
path(path, genpath(constants.lib_dir));

% Make the data directory if it doesn't exist (but it should!)
if ~exist(fullfile(constants.root_dir, 'data'), 'dir')
    mkdir(fullfile(constants.root_dir, 'data'));
end

% Define the location of some directories we might want to use
constants.stimDir=fullfile(constants.root_dir,'db');
constants.savePath=fullfile(constants.root_dir,'data');

%% Set up the experimental design %%
constants.list_length = 18;
constants.conditions = {'S', 'T', 'N'};
constants.n_sessions = 3;
constants.practiceCountdown = 3;
constants.finalTestCountdown = 5;
constants.finalTestBreakCountdown = 10;
constants.studyNewListCountdown = 5;
constants.gamebreakCountdown = 5;

assert(mod(constants.list_length, length(constants.conditions)) == 0, ...
       strcat('List length (', num2str(constants.list_length), ') is not a multiple of 3'));

%% Set the font size for dialog boxes
old_font_size = get(0, 'DefaultUIControlFontSize');
set(0, 'DefaultUIControlFontSize', 14);
old_image_visiblity = get(0,'DefaultImageVisible');
set(0,'DefaultImageVisible','off')

%% Debug Levels
% Level 0: normal experiment
if input.debugLevel >= 0
    constants.screenSize = 'full';
    constants.cueDur = 3; % Length of time to study each cue-target pair
    constants.testDur = 10;
    constants.readtime=10;
    constants.countdownSpeed = 1;
    constants.ISI = .5;
    inputHandler = makeInputHandlerFcn('KbQueue');
    constants.device = [];
end

% Level 1: Fast Stim durations, readtimes & breaks
if input.debugLevel >= 1
    constants.cueDur = 1; % pairs on screen for the length of 60 flip intervals
    constants.testDur = 5;
    constants.readtime = constants.cueDur;
end

% Level 2: Fast countdowns
if input.debugLevel >= 2
    constants.countdownSpeed = constants.cueDur;
end

% Level 3: Small Screen, Human Input
if input.debugLevel >= 3
    constants.screenSize = 'small';
end

% Level 4: Robot input, Large Screen
if input.debugLevel >= 4
    constants.screenSize = 'full';    
    inputHandler = makeInputHandlerFcn([input.robotType,'Robot']);
    constants.Robot = java.awt.Robot;
end

% Level 5: Extreme debugging, useful for knowing if flips are timed ok.
if input.debugLevel >= 5
    hertz = Screen('NominalFrameRate', max(Screen('Screens'))); % hertz = 1/ifi    
    constants.cueDur = (1/hertz); % pairs on screen for only 1 flip
    constants.countdownSpeed = constants.cueDur;
    constants.readtime = constants.cueDur;
    constants.ISI = constants.cueDur;
end

if input.debugLevel >= 6
    constants.screenSize = 'small';
end

%% Connect to the database

setdbprefs('DataReturnFormat', 'table'); % Retrieved data should be a dataset object
setdbprefs('ErrorHandling', 'report'); % Throw runtime errors when a db error occurs

try
    % instance must be a predefined datasource at the OS level
    db_conn = database.ODBCConnection('fam_sarp', 'will', ''); % Connect to the db
catch db_error
    database_error(db_error)
end
% When cleanupObj is destroyed, it will execute the close(db_conn) statement
% This ensures we don't leave open db connections lying around somehow
cleanupObj = onCleanup(@() on_exit_function(db_conn,old_font_size,old_image_visiblity));

%% -------- GUI input option ----------------------------------------------------
% list of input parameters while may be exposed to the gui
% any input parameters not listed here will ONLY be able to be set via the
% command line
expose = {'email'};
valid_input = false;
while ~valid_input
    if any(ismember(defaults, expose))
    % call gui for input
        guiInput = getSubjectInfo('email', struct('title', 'E-Mail', ...
                                                   'type', 'textinput', ...
                                                   'validationFcn', @validate_email));
        if isempty(guiInput)
            exit(exit_stat);
        else   
            input = filterStructs(guiInput,input);
        end
    end

    session = get(fetch(exec(db_conn, ...
                             sprintf('select * from participants where email like ''%s''', ...
                                     input.email))), ...
                  'Data');

    if strcmp(session, 'No Data')
        valid_input = confirmation_dialog(input.email, 0);
        if valid_input
            new_subject = true;
            rng('shuffle');
            rng_state = rng;
            try
                insert(db_conn, 'participants', ...
                       {'email', 'sessions_completed', 'rng_seed'}, ...
                       {input.email, 0, double(rng_state.Seed)});
               % Retrieve the info the database assigns
                session = get(fetch(exec(db_conn, ...
                                         sprintf('select * from participants where email like ''%s''', ...
                                                 input.email))), ...
                              'Data');
            catch db_error
               database_error(db_error)
            end
        end

    else
        valid_input = confirmation_dialog(input.email, session.sessions_completed);
        new_subject = false;
    end
    
    if ~valid_input && ~ismember('email', defaults)
        defaults = [defaults, {'email'}]; %#ok<AGROW>
    end
end

%% Add the fields from input and session to the constants struct
constants.subject = session.subject;
constants.email = session.email;
constants.sessions_completed = session.sessions_completed;
constants.current_session = session.sessions_completed + 1;
constants.debugLevel = input.debugLevel;
clear input session

%% Get or create the lists for the subject

if new_subject
    try
        stimuli = get(fetch(exec(db_conn, 'select * from stimuli')), 'Data');
    catch db_error
        rollback_subject(db_conn, constants.subject)
        database_error(db_error)
    end

    try
        lists = create_lists(stimuli, constants);
        lists.subject = repmat(constants.subject, size(lists,1), 1);
    catch
        rollback_subject(db_conn, constants.subject)
    end

    try
        insert(db_conn, 'lists', ...
               lists.Properties.VariableNames, ...
               lists);
    catch db_error
        rollback_subject(db_conn, constants.subject)
        database_error(db_error)
    end

else
    lists = get(fetch(exec(db_conn, ...
                           sprintf('select * from lists where subject = %d', ...
                                   constants.subject))), ...
                'Data');
end

%% Construct the datasets that will govern stimulus presentation 
% and have responses stored in them
episodic_lists = lists(lists.session == constants.current_session, ...
                       {'list', 'id', 'episodic_cue', 'target'});
episodic_lists.Properties.VariableNames{'episodic_cue'} = 'cue';

semantic_lists = lists(lists.session == constants.current_session, ...
                       {'list','id','semantic_cue_1', 'semantic_cue_2', ...
                        'semantic_cue_3', 'target', 'practice'});
semantic_lists = stack(semantic_lists, {'semantic_cue_1', 'semantic_cue_2', 'semantic_cue_3'}, ...
                       'NewDataVariableName','cue', 'IndexVariableName', 'cue_number');
semantic_lists.cue_number = cellfun(@(x) str2double(x(end)), cellstr(semantic_lists.cue_number));
semantic_lists = semantic_lists(:, {'list','id','cue_number','cue','target','practice'});

study_lists = [episodic_lists, table(nan(size(episodic_lists, 1), 1), 'VariableNames', {'onset'})];

restudy_pairs = strcmp(semantic_lists.practice, 'S');
study_practice_lists = [semantic_lists(restudy_pairs,:), ...
                        table(nan(sum(restudy_pairs), 1),'VariableNames', {'onset'})];

test_pairs = strcmp(semantic_lists.practice, 'T');
test_practice_lists = [semantic_lists(test_pairs,:), response_schema(sum(test_pairs))];

final_test_lists = [episodic_lists,  response_schema(size(episodic_lists, 1))];

% Shuffle items within lists, so that pairs aren't given in the same order
% in all phases
for i = unique(study_lists.list)'

    [new_rows, old_rows] = shuffle_list(study_practice_lists.list, i);
    study_practice_lists(old_rows,:) = sortrows(study_practice_lists(new_rows,:), 'cue_number');

    [new_rows, old_rows] = shuffle_list(test_practice_lists.list, i);
    test_practice_lists(old_rows,:) = sortrows(test_practice_lists(new_rows,:), 'cue_number');

    [new_rows, old_rows] = shuffle_list(final_test_lists.list, i);
    final_test_lists(old_rows,:) = final_test_lists(new_rows,:);
end

try
    [window, constants] = windowSetup(constants);
    giveInstructions('intro', inputHandler, window, constants);
    setupTestKBQueue;
%% Main Loop
    for i = unique(study_lists.list)'
% Study Phase
        countdown('It''s time to study a new list of pairs', constants.studyNewListCountdown, ...
                  constants.countdownSpeed,  window, constants);
        studyIndex = study_lists.list == i;
        study_lists.onset(studyIndex) = study(study_lists(studyIndex, :), window, constants);
% Practice Phase
        % Counterbalance study/test practice order between lists
        if mod(i, 2) == 0
            first = 'S';
        else
            first = 'T';
        end
        SPindex = study_practice_lists.list == i;
        TPindex = test_practice_lists.list == i;
        practice(study_practice_lists(SPindex,:), test_practice_lists(TPindex, :), ...
                 first, inputHandler, window, constants);

% Test Phase
        giveInstructions('final', inputHandler, window, constants);
        finalIndex = final_test_lists.list == i;
        [onset, response, FP, LP] = testing(final_test_lists(finalIndex, :), ...
                                            inputHandler, window, constants, '');
        final_test_lists.onset(finalIndex) = onset;
        final_test_lists.response(finalIndex) = response;
        final_test_lists.FP(finalIndex) = FP;
        final_test_lists.LP(finalIndex) = LP;
    end

catch error
    windowCleanup(constants);
    rethrow(error)
end

%% end of the experiment %%
KbQueueRelease;
giveInstructions('bye', [], window, constants);
windowCleanup(constants)
exit_stat=0;
end % end main()

function windowCleanup(constants)
    sca; % alias for screen('CloseAll')
    rmpath(constants.lib_dir,constants.root_dir);
end

function [window, constants] = windowSetup(constants)
    PsychDefaultSetup(2); % assert OpenGL install, unify keys, fix color range
    constants.screenNumber = max(Screen('Screens')); % Choose a monitor to display on
    constants.res=Screen('Resolution',constants.screenNumber); % get screen resolution
    constants.dims = [constants.res.width constants.res.height];
    if strcmp(constants.screenSize, 'small')
    % Set the size of the PTB window based on screen size and debug level
        constants.screen_scale = reshape(round(constants.dims' * [(1/8),(7/8)]), 1, []);
    else
        constants.screen_scale = [];
    end

    try
        [window, constants.winRect] = Screen('OpenWindow', constants.screenNumber, ...
                                             round(2/3*255), ... % light grey background
                                             constants.screen_scale);
    % define some landmark locations to be used throughout
        [constants.xCenter, constants.yCenter] = RectCenter(constants.winRect);
        constants.center = [constants.xCenter, constants.yCenter];
        constants.left_half=[constants.winRect(1),constants.winRect(2),constants.winRect(3)/2,constants.winRect(4)];
        constants.right_half=[constants.winRect(3)/2,constants.winRect(2),constants.winRect(3),constants.winRect(4)];
        constants.top_half=[constants.winRect(1),constants.winRect(2),constants.winRect(3),constants.winRect(4)/2];
        constants.bottom_half=[constants.winRect(1),constants.winRect(4)/2,constants.winRect(3),constants.winRect(4)];

    % Get some the inter-frame interval, refresh rate, and the size of our window
        constants.ifi = Screen('GetFlipInterval', window);
        constants.hertz = FrameRate(window); % hertz = 1 / ifi
        constants.nominalHertz = Screen('NominalFrameRate', window);
        [constants.width, constants.height] = Screen('DisplaySize', constants.screenNumber); %in mm

    % Font Configuration
        fontsize=28;
        Screen('TextFont',window, 'Arial');  % Set font to Arial
        Screen('TextSize',window, fontsize);       % Set font size to 28
        Screen('TextStyle', window, 1);      % 1 = bold font
        Screen('TextColor', window, [0 0 0]); % Black text

    % Text layout config
        constants.wrapat = 65; % line length
        constants.spacing=35;
        constants.leftMargin = constants.winRect(3)/5;

    catch
        windowCleanup(constants)
        psychrethrow(psychlasterror);
    end
end

function [valid_email, msg] = validate_email(email_address, ~)
    valid_email = ~isempty(regexpi(email_address, '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'));
    if ~valid_email
        msg = 'Invalid E-Mail Address';
    else
        msg = '';
    end

end

function [] = database_error(error)
   errordlg({'Unable to connect to database. Specific error was:', ...
            '', ...
            error.message}, ...
            'Database Connection Error', ...
            'modal')
   rethrow(error)
end

function on_exit_function(db_conn,old_font_size,old_image_visiblity)
    close(db_conn)
    set(0, 'DefaultUIControlFontSize', old_font_size);
    set(0,'DefaultImageVisible', old_image_visiblity)
end

function accept = confirmation_dialog(email, sessions_completed)

    session_msg = {'first','second', 'third'};
    resp = questdlg({['Your e-mail address is: ' email], ...
                     ['This is your ' session_msg{sessions_completed + 1} ' session.'], ...
                     '', ...
                     'Is this correct?'}, ...
                     'Confirm Subject Info', ...
                     'No', 'Yes', 'No');
    accept = strcmp(resp, 'Yes');
end

function [ new_row_ind, old_row_ind ] = shuffle_list(x, list)
    old_row_ind = find(x == list);
    new_row_ind = old_row_ind(randperm(numel(old_row_ind)));
end

function rollback_subject(db_conn, subject)
    exec(db_conn, sprintf('delete * from participants where subject = %d', subject));
end