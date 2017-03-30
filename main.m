function exit_stat = main(varargin)

exit_stat = 1; % assume that we exited badly if ever exit before this gets reassigned

if Screen('NominalFrameRate', max(Screen('Screens'))) ~= 60
    h = errordlg('Monitor refresh rate must be set to 60hz');
    uiwait(h)
    return;
end

% Seet the rng with the current time
rng('shuffle');
% retrieve the rng state once it has been seeded
rng_state = rng;

% use the inputParser class to deal with arguments
ip = inputParser;
%#ok<*NVREPL> dont warn about addParamValue
addParamValue(ip,'email', 'will@fake.com', @validate_email);
addParamValue(ip,'sessions_completed', 0, @(x) x <= 1);% # sessions must be kept in sync with constants.n_sessions
groups = {'immediate','delay'};
addParamValue(ip,'group', groups{randsample(length(groups),1)}, @(x) any(strcmpi(x, groups)));
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

% Make the data directory if it doesn't exist
if ~exist(fullfile(constants.root_dir, 'data'), 'dir')
    mkdir(fullfile(constants.root_dir, 'data'));
end

% Define the location of some directories we might want to use
constants.stimDir=fullfile(constants.root_dir,'db');
constants.savePath=fullfile(constants.root_dir,'data');

%% Set up the experimental design %%
constants.list_length = 20;
constants.practice_types = {'S', 'T', 'N'};
constants.cue_types = {'semantic', 'episodic'};
constants.n_sessions = 1;
constants.practiceCountdown = 3;
constants.finalTestCountdown = 3;
constants.finalTestBreakCountdown = 10;
constants.studyNewListCountdown = 3;
constants.n_conditions = 1 + prod([length(constants.cue_types), ...
                                   length(setdiff(constants.practice_types, 'N'))]);
assert(mod(constants.list_length, constants.n_conditions) == 0, ...
       strcat('List length (', num2str(constants.list_length), ') is not a multiple of ', num2str(constants.n_conditions)));

%% Set the font size for dialog boxes
old_font_size = get(0, 'DefaultUIControlFontSize');
set(0, 'DefaultUIControlFontSize', 14);
old_image_visiblity = get(0,'DefaultImageVisible');
set(0,'DefaultImageVisible','off')

%% Debug Levels
% Level 0: normal experiment
if input.debugLevel >= 0
    constants.screenSize = 'full';
    constants.cueDur = 5; % Length of time to study each cue-target pair
    constants.testDur = 10;
    constants.readtime=10;
    constants.countdownSpeed = 1;
    constants.ISI = .5;
    responseHandler = makeInputHandlerFcn('user');
    decisionHandler = responseHandler;
    constants.device = [];
    constants.math_display = 1.5;
    constants.math_wait = 5;
end

% Level 1: Fast Stim durations, readtimes & breaks
if input.debugLevel >= 1
    constants.cueDur = 1; % pairs on screen for the length of 60 flip intervals
    constants.testDur = 5;
    constants.readtime = constants.cueDur;
    constants.math_display =.5;
    constants.math_wait = 2.5;
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
    responseHandler = makeInputHandlerFcn('freeResponseRobot');
    decisionHandler = makeInputHandlerFcn('simpleKeypressRobot');
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
    db_conn = database('SCvSARP', 'will', ''); % Connect to the db
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
            return;
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
            try
                insert(db_conn, 'participants', ...
                       {'email', '"group"', 'sessions_completed', 'rng_seed', 'computer'}, ...
                       {input.email, input.group, 0, double(rng_state.Seed), getenv('COMPUTERNAME')});
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
    end
    
    if ~valid_input && ~ismember('email', defaults)
        defaults = [defaults, {'email'}]; %#ok<AGROW>
    end
end

%% Add the fields from input and session to the constants struct
constants.subject = session.subject;
constants.group = input.group;
constants.email = session.email;
constants.sessions_completed = session.sessions_completed;
constants.current_session = session.sessions_completed + 1;
constants.debugLevel = input.debugLevel;
clear input session

%% Get or create the lists for the subject

if constants.current_session == 1
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

%% Create Study Lists
study_lists = lists(lists.session == constants.current_session, ...
                    {'subject','session','list', 'id', 'episodic_cue', 'target'});
study_lists.Properties.VariableNames{'episodic_cue'} = 'cue';
study_lists.onset = nan(size(study_lists, 1),1);
study_lists.trial = (1:size(study_lists, 1))';

%% Create Practice Lists, for each type of practice
practice_items = ~strcmp(lists.practice, 'N');
n_practice_items = sum(practice_items);
practice_lists = [lists(practice_items, :) ...
                  table(nan(n_practice_items, 1), ...
                        cell(n_practice_items, 1), ...
                        (1:n_practice_items)', ...
                        'VariableNames', {'onset', 'cue', 'trial'})];

for i=1:size(practice_lists, 1)
    if strcmp(practice_lists.cue_type{i}, 'episodic')
        c = practice_lists.episodic_cue{i};
    else
        c = practice_lists.semantic_cue{i};
    end
    practice_lists.cue{i} = c;
end
% Drop the episodic_cue and semantic_cue columns, they've been merged to
% the "cue" column based on trial type.
practice_lists = practice_lists(:, {'subject','session','list','id','cue_type','practice','cue','target','onset','trial'});

%% Final Test Lists
final_test_lists = [study_lists,  response_schema(size(study_lists, 1))];

% Shuffle items within lists, so that pairs aren't given in the same order in all phases
for i = unique(study_lists.list)'    
    rows = practice_lists.list == i;
    practice_lists(rows,:) = practice_lists(randsample(practice_lists.trial(rows), sum(rows)),:);
    rows = final_test_lists.list == i;
    final_test_lists(rows,:) = final_test_lists(randsample(final_test_lists.trial(rows), sum(rows)),:);
end

% Adjust the trial order variable back to sequential
x = reshape(bsxfun(@plus, repmat((1:8)',1,6), 16*(0:5)), [], 1);
restudy_trials = strcmp(practice_lists.practice, 'S');
test_trials = strcmp(practice_lists.practice, 'T');

if mod(constants.subject, 2) == 0
    % if the subject number is ever, restudy trials are first
    practice_lists.trial(restudy_trials) = x;
    practice_lists.trial(test_trials) = x + 8;
else
    practice_lists.trial(test_trials) = x;
    practice_lists.trial(restudy_trials) = x + 8;
end
practice_lists = sortrows(practice_lists, {'list','trial'});
study_practice_lists = practice_lists(strcmp(practice_lists.practice, 'S'),:);
test_practice_lists = [practice_lists(strcmp(practice_lists.practice, 'T'), :), ...
                       response_schema(sum(length(x)))];

final_test_lists.trial = (1:size(final_test_lists, 1))';

try
    [window, constants] = windowSetup(constants);
    giveInstructions('intro', decisionHandler, responseHandler, window, constants);

%% Main Loop
    for i = unique(study_lists.list)'
% Study Phase
        countdown('It''s time to study a new list of pairs', constants.studyNewListCountdown, ...
                  constants.countdownSpeed,  window, constants);
        studyIndex = study_lists.list == i;
        study_lists.onset(studyIndex) = study(study_lists(studyIndex, :), window, constants);

% Practice Phase
        SPindex = study_practice_lists.list == i;
        TPindex = test_practice_lists.list == i;
        [TPdata, SPdata] = practice(study_practice_lists(SPindex,:), test_practice_lists(TPindex, :), ...
                                    decisionHandler, responseHandler, window, constants);
        study_practice_lists(SPindex,:) = SPdata;
        test_practice_lists(TPindex, :) = TPdata;

% If we're in the immediate group, the final test immediately follows
% practice after the math distractor task

        if strcmp(constants.group,'immediate')
            % Math Distractor
            mathDistract(3, window, responseHandler, constants)

            % Test Phase
            giveInstructions('final',[], responseHandler, window, constants);
            finalIndex = final_test_lists.list == i;
            [onset, recalled, latency, resp, FP, LP, adv] = testing(final_test_lists(finalIndex, :), ...
                                                                    decisionHandler, responseHandler, window, constants, '', false);
            final_test_lists.onset(finalIndex) = onset;
            final_test_lists.recalled(finalIndex) = recalled;
            final_test_lists.latency(finalIndex) = latency;
            final_test_lists.response(finalIndex) = resp;
            final_test_lists.FP(finalIndex) = FP;
            final_test_lists.LP(finalIndex) = LP;
            final_test_lists.advance(finalIndex) = adv;
        end
    end

% If we're in the delay group, now we do the final tests
    if strcmp(constants.group,'delay')

        mathDistract(3, window, responseHandler, constants)
        % Test Phase
        for i = unique(final_test_lists.list)'

            giveInstructions('final',[], responseHandler, window, constants);
            finalIndex = final_test_lists.list == i;
            [onset, recalled, latency, resp, FP, LP, adv] = testing(final_test_lists(finalIndex, :), ...
                                                                    decisionHandler, responseHandler, window, constants, '', false);
            final_test_lists.onset(finalIndex) = onset;
            final_test_lists.recalled(finalIndex) = recalled;
            final_test_lists.latency(finalIndex) = latency;
            final_test_lists.response(finalIndex) = resp;
            final_test_lists.FP(finalIndex) = FP;
            final_test_lists.LP(finalIndex) = LP;
            final_test_lists.advance(finalIndex) = adv;

            countdown('Take a break before continuing your memory test',...
                       constants.studyNewListCountdown, constants.countdownSpeed, window, constants);
        end
    end

catch error
    windowCleanup(constants);
    rethrow(error)
end

%% end of the experiment %%
KbQueueRelease;
giveInstructions('bye', [], [], window, constants);
windowCleanup(constants)

try
    insert(db_conn, 'study', ...
           study_lists.Properties.VariableNames, ...
           study_lists);

    study_practice_lists = study_practice_lists(:, {'subject','session','trial','list','id','cue','target','onset'});
    insert(db_conn, 'study_practice', ...
           study_practice_lists.Properties.VariableNames, ...
           study_practice_lists);

    test_practice_lists.response = cellfun(@(x) x(1:min(20,length(x))), test_practice_lists.response, ...
                                           'UniformOutput', false);
    test_practice_lists = test_practice_lists(:, setdiff(test_practice_lists.Properties.VariableNames, ...
                                                         {'practice','cue_type'}));
    insert(db_conn, 'test_practice', ...
           test_practice_lists.Properties.VariableNames, ...
           test_practice_lists);

    final_test_lists.response = cellfun(@(x) x(1:min(20,length(x))), final_test_lists.response, ...
                                           'UniformOutput', false);
    insert(db_conn, 'final_test', ...
           final_test_lists.Properties.VariableNames, ...
           final_test_lists);

    % Update the number of sessions completed
    update(db_conn, ...
           'participants', ...
           {'sessions_completed'}, ...
           constants.current_session, ...
           sprintf('WHERE subject = %d', constants.subject));
catch db_error
    database_error(db_error)
end

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
    HideCursor(constants.screenNumber);
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

function rollback_subject(db_conn, subject)
    exec(db_conn, sprintf('delete from participants where subject = %d', subject));
end