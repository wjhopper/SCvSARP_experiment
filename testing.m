function [onset, recalled, latency, response, firstPress, lastPress, advance] = testing(data, decisionHandler, responseHandler, window, constants, message, first_letter)
% The onset vector holds the timestamp each trial began (as measured by the
% sync to the vertical backtrace

% The response cell array holds the input on each trial. If no input was
% given, the cell for the trial will hold an empty string ''

% the firstPress vector holds the timestamp of the first valid keypress
% (valid keys are a-z) belonging to the final response. Importantly, this
% is *NOT* neccesarily the ABSOLUTE first valid keypress participants made: a
% participants may use the backspace key to remove characters from their
% response e.g. in the event of a typo, and when this character is removed
% from the response string, the timestamp of its press is also removed from
% the RT vector. Thus, a participant may enter many characters, and remove
% all of them, and then complete their response for the trial. In
% that case, the firstPress timestamp would hold the time when the
% participant pressed the key for the first character in their FINAL
% response, not their initial (and subsequently removed) entry.

% the finalPress vector holds the timestamp of the last valid keypress
% belonging to the final response. Importantly, this is the *NOT* the time
% time the subject pressed the Enter or Return key to finalize their
% response, but is the final key in the range a-z they pressed

% Some important corner cases should be noted: If no response was given
% (i.e. an empty string is returned from the trial), then firstPress and
% lastPress should be NaN. If only a single valid keypress was recorded,
% then firstPress == lastPress. If multiple keypresses are recorded,
% firstPress and lastPress should be different, and the difference can be
% used to infer the amount of time spent typing.
% first
% Switch to high priority mode and increase the fontsize

if nargin <= 5
    message = '';
end

correct_code = KbName('m');

oldPriority = Priority(1);
oldsize = Screen('TextSize', window, 40);

% Preallocate the output structures
onset = nan(size(data,1),1);
recalled = zeros(size(data,1),1);
latency = nan(size(data,1),1);
firstPress = nan(size(data,1),1);
lastPress = nan(size(data,1),1);
advance = zeros(size(data,1),1); % Enter key sets this to the time it was pressesed, which breaks the while loop
response = cell(size(data,1),1);

if any(strcmp('cue_type',data.Properties.VariableNames));
    colors = nan(size(data,1),3);
    episodic_rows = strcmp('episodic', data.cue_type);
    colors(episodic_rows,:) = repmat([204, 0, 0], sum(episodic_rows), 1); % red
    semantic_rows = strcmp('semantic', data.cue_type);
    colors(semantic_rows,:) = repmat([0, 102, 0], sum(semantic_rows), 1); % green
else
    colors = nan(size(data,1),1);
end
for j = 1:size(data,1)
    postpone = 0; % Don't postpone response deadline until the subject interacts
    string = ''; % Start with an empty response string for each target
    rt = []; % Start with an empty RT vector for each target
    setupDecisionKBQueue;
    if ~isempty(message)
        DrawFormattedText(window, message, constants.leftMargin, constants.winRect(4)*.15, [], 40, [],[],1.5);
    end
    if first_letter
        prompt = [data.target{j}(1) '______ ?'];
    else
        prompt = '?';
    end
    drawCueTarget(data.cue{j}, prompt, window, constants, colors(j,:)); % Draw cue and prompt
    DrawFormattedText(window, 'Z = Don''t Remember', constants.winRect(3)*.1, constants.winRect(4)*.9);
    DrawFormattedText(window, 'M = Remember', 'right', constants.winRect(4)*.9, ...
                      [],[],[],[],[],[],[0 0 constants.winRect(3)*.9, constants.winRect(4)]); 
    vbl = Screen('Flip', window); % Display cue and prompt
    onset(j) = vbl; % record trial onset
    deadline = vbl + constants.testDur;
    KbQueueStart;
    while GetSecs < deadline && isnan(latency(j))
        [keys_pressed, press_times] = decisionHandler(constants.device, 'm', .5);
        if ~isempty(keys_pressed)
            KbQueueStop;
            recalled(j) = keys_pressed(1) == correct_code;
            latency(j) = press_times(keys_pressed(1));            
        end
    end
    
    if recalled(j)
        keys_pressed = []; %#ok<NASGU>
        drawCueTarget(data.cue{j}, prompt, window, constants, colors(j,:)); % Draw cue and prompt
        vbl = Screen('Flip', window, vbl + (latency(j)-vbl) + constants.ifi/2); % Display cue and prompt
        setupTestKBQueue;        
        KbQueueStart;
    end
    
    % Until Enter is hit or deadline is reached, wait for input
    % In the advance variable, we take advantage of the fact that MATLAB
    % coerces numbers > 0 to logical trues. This allows us to use advance
    % to store key press times, as well as control the persistance of the
    % while loop
    while ~advance(j) && recalled(j)
        % string is the entirity of the subjects response thus far
        [keys_pressed, press_times] = responseHandler(constants.device, data.target{j});
        if ~isempty(keys_pressed)
            % Loop over each recorded keycode. There should ideally be only one,
            % but crazy things can happen
            for i = keys_pressed
                switch i
                    case 13 %13 is return
                        if ~isempty(string) % set the advance flag is input has been given
                            advance(j) = press_times(i);
                        end
                    case 8 %8 is BACKSPACE
                        % remove the last entered character and its
                        % keypress timestamp but only if some user input
                        % has been given previously (meaning the input
                        % string will not be ''.
                        if ~strcmp('',string) 
                            string = string(1:end-1);       
                            rt = rt(1:end-1);
                        end
                    otherwise
                        % Add the character just pressed to the input
                        % string, and record the timestamp of its keypress.
                        % Set the redraw flag to 1.
                        string = [string, KbName(i)]; %#ok<AGROW>
                        rt = [rt press_times(i)]; %#ok<AGROW>
                end
            end
            
            if ~isempty(message)
                DrawFormattedText(window, message, constants.leftMargin, constants.winRect(4)*.15, [], 40, [],[],1.5);
            end
            if first_letter
                prompt = [data.target{j}(1) string];
            else
                prompt = string;
            end
            drawCueTarget(data.cue{j}, prompt, window, constants,  colors(j,:));
            vbl = Screen('Flip', window, vbl + (press_times(i) - vbl) + constants.ifi);
            postpone = postpone + 1;
        end
    end

    KbQueueStop;    
    [response{j}, firstPress(j), lastPress(j)] = cleanResponses(string, rt);
end
KbQueueRelease;
Screen('TextSize', window, oldsize); % reset text size
Priority(oldPriority);  % reset priority level
end

function [response, firstPress, lastPress] = cleanResponses(string, RT)

% Make sure response is a blank string, instead of some empty matrix or a
% char(0), as both of those are technically empty, but behave differently
% when trying to assign into a matrix or table
    if isempty(string)
        response = '';
    else
        response = string;
    end

% Check the rt vector. 
% if it is empty, mark both presses as missing
    if isempty(RT)
        firstPress = NaN;
        lastPress = NaN;
% if only a single key was pressed, make first and last press the same    
    elseif numel(RT) == 1
        firstPress = RT;
        lastPress = RT;
% if multiple keys were pressed, then first press is the first one, and last press is the last one.        
    else
        firstPress = RT(1);
        lastPress = RT(end);
    end
end