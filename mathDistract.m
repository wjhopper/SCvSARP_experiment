function mathDistract(n_problems, window, responseHandler, constants)

    countdown(['Now try to solve these ' num2str(n_problems) ' addition problems starting in'], constants.practiceCountdown,...
              constants.countdownSpeed,  window, constants);
    oldsize = Screen('TextSize', window, 40);          
    setupNumericKBQueue;
    
    for j = 1:n_problems
        nums = randperm(9);
        for i = nums(1:6)
            DrawFormattedText(window, num2str(i),'center', 'center');
            vbl = Screen('Flip', window);
            WaitSecs('UntilTime', GetSecs + constants.math_display);
        end
        answer = int2str(sum(nums(1:6)));
        string = '';
        advance = false;
        message = 'What is the sum of the numbers you just saw?';
        DrawFormattedText(window, message, constants.leftMargin, constants.winRect(4)*.15, [], 50, [],[],1.5);
        vbl = Screen('Flip', window, vbl + constants.ifi/2, 1);
        KbQueueStart;
        deadline =  vbl + constants.math_wait;
        while GetSecs < deadline + constants.math_wait && ~advance
            [keys_pressed, press_times] = responseHandler(constants.device, answer, .5);
            if ~isempty(keys_pressed)
                % Loop over each recorded keycode. There should ideally be only one,
                % but crazy things can happen
                for i = keys_pressed
                    switch i
                        case 13 %13 is return
                            if ~isempty(string) % set the advance flag is input has been given
                                advance = true;
                            end
                        case 8 %8 is BACKSPACE
                            % remove the last entered character only if some user input
                            % has been given previously (meaning the input string will not be ''.
                            if ~strcmp('',string) 
                                string = string(1:end-1);       
                            end
                        otherwise
                            % Add the character just pressed to the input
                            % string, and record the timestamp of its keypress.
                            % Set the redraw flag to 1.
                            x = KbName(i);
                            string = [string, x(1)]; %#ok<AGROW>
                    end
                end

                if ~isempty(message)
                    DrawFormattedText(window, message, constants.leftMargin, constants.winRect(4)*.15, [], 50, [],[],1.5);
                end
                DrawFormattedText(window, string, constants.winRect(3)*.5,  constants.winRect(4)*.5);
                vbl = Screen('Flip', window, vbl + (press_times(i) - vbl) + constants.ifi);
            end          
        end
        KbQueueStop;
    end
    Screen('TextSize', window, oldsize);
end