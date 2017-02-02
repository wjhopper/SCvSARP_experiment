function handlerFcn = makeInputHandlerFcn(handlerName)

valid_types = {'user','freeResponseRobot', 'simpleKeypressRobot'};    
assert(ismember(handlerName, valid_types), ['"handlerType" argument must be one of the following: ' strjoin(valid_types,', ')])

if ~strcmp(handlerName, 'user')

    rob = java.awt.Robot;   
    switch handlerName
        case 'freeResponseRobot'
            n = 1;
            handlerFcn = @GoodFreeResponseRobot;

        case 'simpleKeypressRobot'
            handlerFcn = @GoodSimpleKeypressRobot;

        otherwise
            error(['Unknown handlerName "' handlerName '"']);            
    end
            
else
    handlerFcn = @checkKeys;
end

    function [keys_pressed, press_times] = checkKeys(device, varargin) 
        %
        % The rules of this handler are as follows:
        %
        % 1: If the "Enter" of "Return" key is hit, then length of the response string
        %   is checked. If the response string is not empty, set the advance flag
        %   to 1.
        % 2: If the right arrow key is pressed, then length of the response string
        %   is checked. If the response string is empty, set the advance flag
        %   to 1.
        % 3: If the backspace key is pressed, then length of the response string
        %   is checked. If the response string is not empty, then set remove
        %   the final character from the string, and remove the last recorded
        %   RT. The value of the redraw flag is set to -1.
        % 4: If any other key is pressed, then that keys character value is
        %   concatenated to the existing response string, and the recorded time
        %   for that key presses is concatenated to the existing rt vector
        %   is checked. The value of redraw flag is set to 1.
        %
        % The response string and RT vector are returned (updated with any input
        % given by the participant) as well as the advance and redraw flags.
        %
        % The advance flag can be either 0 (the default) or  1 if the Enter
        % key or left arrow key were pressed, and can be caller to determine
        % if the subject has finalized  their response and thus the experiment
        % should continue to the next trial.
        %
        % The redraw flag can be either 0 (the default) or  1. A value of 1
        % means that valid input was given i.e., a-z was pressed, and 0 
        % means no valid input was given.
        
        % Set flag defaults
        % Check the KbQueue for presses
        [ pressed, press_times]=KbQueueCheck(device);
        if pressed
            % find the keycode for the keys pressed since last check            
            keys_pressed = find(press_times);
            % sort the recorded press time to find their linear position
            [~, ind] = sort(press_times(press_times~=0));
            % Arrange the keycodes according to the order they were pressed
            keys_pressed = keys_pressed(ind);
        else
            keys_pressed = [];            
        end
    end

    function [keys_pressed, press_times] = GoodFreeResponseRobot(device, answer, delay)

    % This function is a wrapper around checkKeys, which provides
    % automatic keyboard input by simulating a keypress of each character in the given response string
    % with Java Robot object instead of waiting for a human.
    %
    % The tricky bit here is that it doesn't loop over each character in
    % the string. We want the chance to poll the keyboard queue in between
    % keypresses, in order to support incremental drawing of the text
    % string, the way the user would expect it to work. If we did loop over
    % the answer to "type in", the word would show up all at once, which is
    % not the way we would want it to work with a human typing responses
    % in real experiment.
    % Instead, this function is a closure and we share a stateful indexing variable n
    % with the parent function, makeInputHandlerFcn. n starts off set to 1 in the
    % parent function. If n is less than or equal to  the length of the answer,
    % we construct the robot press and release calls for that character, hand off
    % to the actual input handler function to record it, and increment the indexing
    % variable n (e.g. n = n + 1 =2). This increment is remembered the next
    % time we enter the function, because this function is a closure.
    %
    % When n grows larger than the length of the answer string, we press
    % and release the Enter key to confirm the previously recorded input
    % and advance. Before returning, n is reset to 1, and this reset is
    % remembered the next time we enter this function (which should be for
    % a new answer to input) and so we begin with inputing the first character of
    % the new answer.
    
        if nargin < 3
            delay=0;
        end
        
        if n == 1
            WaitSecs('UntilTime', GetSecs + delay);
        end
        
        if n <= length(answer)
            WaitSecs('UntilTime', GetSecs + delay/10);
            eval([ 'rob.keyPress(java.awt.event.KeyEvent.VK_', upper(answer(n)), ');' ]);
            eval([ 'rob.keyRelease(java.awt.event.KeyEvent.VK_', upper(answer(n)), ');' ]);
            n = n + 1;

        else
            rob.keyPress(java.awt.event.KeyEvent.VK_ENTER);
            rob.keyRelease(java.awt.event.KeyEvent.VK_ENTER);
            n = 1;
        end

       [keys_pressed, press_times] = checkKeys(device);
    end

    function [keys_pressed, press_times] = GoodSimpleKeypressRobot(device, answer, delay)
   
        if nargin >= 3
            WaitSecs('UntilTime', GetSecs + delay);
        end
        
        eval([ 'rob.keyPress(java.awt.event.KeyEvent.VK_', upper(answer(1)), ');' ]);
        eval([ 'rob.keyRelease(java.awt.event.KeyEvent.VK_', upper(answer(1)), ');' ]);

       [keys_pressed, press_times] = checkKeys(device);
    end

    function [keys_pressed, press_times] = BadRobot(device, varargin)

    % This function is a wrapper around kbQueueHandler, which provides
    % automatic keyboard input by simulating a keypress of each character in the given response string
    % with Java Robot object instead of waiting for a human.
    %
    % The tricky bit here is that it doesn't loop over each character in the string,
    % Instead, this function is a closure and we share a stateful indexing variable n
    % with the parent function, makeInputHandlerFcn. n starts off set to 1 in the
    % parent function. If n is less than or equal to  the length of the answer,
    % we construct the robot press and release calls for that character, hand off
    % to the actual input handler function to record it, and increment the indexing
    % variable n (e.g. n = n + 1 =2). This increment is remembered the next
    % time we enter the function, because this function is a closure.
    %
    % When n grows larger than the length of the answer string, we press
    % and release the Enter key to confirm the previously recorded input
    % and advance. Before returning, n is reset to 1, and this reset is
    % remembered the next time we enter this function (which should be for
    % a new answer to input) and so we begin with inputing the first character of
    % the new answer.

        answer = randsample('abcdefghijklmnopqrstuvwxys', 4);
        WaitSecs('UntilTime', GetSecs + .1);
        if n <= length(answer)
            eval([ 'rob.keyPress(java.awt.event.KeyEvent.VK_', upper(answer(n)), ');' ]);
            eval([ 'rob.keyRelease(java.awt.event.KeyEvent.VK_', upper(answer(n)), ');' ]);        
            n = n + 1;
        else
            rob.keyPress(java.awt.event.KeyEvent.VK_ENTER);
            rob.keyRelease(java.awt.event.KeyEvent.VK_ENTER);           
            n = 1;
        end
            [keys_pressed, press_times] = FreeResponse(device);   
    end
end



