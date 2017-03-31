function giveInstructions(phase_name, decisionHandler, responseHandler, window, constants)

switch phase_name
    case 'intro'
        study_pairs = table({'pine', 'puddle', 'napkin', 'zebra', 'root'}', ...
                            {'top',  'grape',  'insect', 'tape',  'mug'}', ...
                            {'S',    'T',      'T',      'N',     'S'}', ...
                            nan(5, 1), ...
                            'VariableNames', {'cue','target','practice','onset'});

        study_practice_pairs = table({'episodic', 'semantic'}',...
                                     {'pine',     'cup'}', ...
                                     {'top',      'mug'}', ...
                                     {'S',        'S',}', ...
                                     nan(2, 1), ...
                                     'VariableNames', {'cue_type','cue','target','practice','onset'});
        study_practice_pairs = study_practice_pairs(randperm(size(study_practice_pairs, 1)),:);
        study_practice_pairs.trial = (1:size(study_practice_pairs, 1))';

        test_practice_pairs = table({'episodic', 'semantic'}',...
                                    {'puddle',   'bug'}',...
                                    {'grape',    'insect'}', ...
                                    {'T',        'T',}', ...
                                    nan(2, 1), ...
                                    'VariableNames', {'cue_type','cue','target','practice','onset'});

        test_practice_pairs = test_practice_pairs(randperm(size(test_practice_pairs, 1)),:);
        test_practice_pairs.trial = size(test_practice_pairs, 1) + (1:size(test_practice_pairs, 1))';
        test_practice_pairs = [test_practice_pairs, response_schema(size(test_practice_pairs, 1))];
        
        final_test_pairs = [study_pairs(randperm(size(study_pairs, 1)), 1:3), ...
                            response_schema(size(study_pairs, 1))];

        %% Screen        
        KbQueueCreate;        
        text = ['Welcome to the experiment!' ...
                '\n\nIn this experiment, you will be shown pairs of words. Your task is to learn these pairs, so that you will be able to remember them later on a test' ...
                '\n\nEach pair will have one word on the left, and one word on the right. The word on the right is the one you need to remember for the tests.'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(responseHandler, constants, '');

        %% Screen
        text = ['Use the word on the left to help you remember the word on the right. For example, if you studied the pair:', ...
                '\n\n                               library - OVAL', ...
                '\n\nyou could imagine an oval shaped library to help your memory.'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(responseHandler, constants, '');

        %% Screen
        text = ['Here''s a short example of what studying a list of pairs will be like.' ...
                '\n\nDuring the real experiment, the lists will be longer'];
        drawInstructions(text, 'any key', 0, window, constants);
        listen(responseHandler, constants, '');

        %% Practice block: Study 
        countdown('It''s time to study a new list of pairs', constants.studyNewListCountdown, ...
                  constants.countdownSpeed,  window, constants);
        study(study_pairs, window, constants);

        %% Screen
        current_color = Screen('TextColor', window);
        text = ['After you study each list, you will receive additional practice to help your memory. In this practice phase, you will again be shown word pairs.',...
                '\n\nThe words on the right side will be the same words you just studied, but sometimes the word on the left side of the pair will be different than when you first studied each pair.'];
        drawInstructions(text, 'any key', constants.readtime*.5, window, constants);
        listen(responseHandler, constants, '');

        %% Screen                
        text = 'New words will be similar or related to the one on the right that you need to remember. These kinds of words will be\nshown in ';
        [nx, ny] = DrawFormattedText(window, text, constants.leftMargin, constants.winRect(4)*.3, [], constants.wrapat,[],[],1.5);
        [~, ny] = DrawFormattedText(window, 'green text.', nx, ny, [0, 102, 0], constants.wrapat ,[],[],1.5);
        text = 'Other word pairs  will have the same word on the left side as when you first studied them. Words that are the same will be shown in ';
        [nx, ny] = DrawFormattedText(window, text, constants.leftMargin, ny + 3*Screen('TextSize', window),...
                                     current_color, constants.wrapat, [], [], 1.5);
        DrawFormattedText(window, 'red text.', nx, ny, [204, 0, 0], constants.wrapat,[],[],1.5);
        vbl = Screen('Flip',window,[],1);

        DrawFormattedText(window, 'Press any key to continue', 'center', constants.winRect(4)*.9, current_color, constants.wrapat, [],[], 1.5);
        Screen('Flip',window, vbl + constants.readtime - (constants.ifi/2));
        listen(responseHandler, constants, '');

        %% Screen
        text = ['You will practice remembering some words by restudying them.', ...
                '\n\nFor example, if you were restudying the word "OVAL", you might study "'];
        [nx, ny] = DrawFormattedText(window, text, constants.leftMargin, constants.winRect(4)*.3, [], ...
                                    constants.wrapat, [], [], 1.5);
        [nx, ny] = DrawFormattedText(window, 'library', nx, ny, [204, 0, 0], constants.wrapat,[],[],1.5);
        [~, ny] = DrawFormattedText(window, ' - OVAL" (the same pair you previously studied).', nx, ny, current_color,...
                                    constants.wrapat, [], [], 1.5);
        [nx, ny] = DrawFormattedText(window, 'Or, you might study "', constants.leftMargin, ny+3*Screen('TextSize', window), current_color,...
                                    constants.wrapat, [], [], 1.5); 
        [nx, ny] = DrawFormattedText(window, 'circle', nx, ny, [0, 102, 0], constants.wrapat,[],[],1.5);                                
        DrawFormattedText(window, ' - OVAL" ("circle" is a new word related to "OVAL").', nx, ny, current_color,...
                          constants.wrapat, [], [], 1.5);
        DrawFormattedText(window, 'Press any key to continue', 'center', constants.winRect(4)*.9, current_color, constants.wrapat, [],[], 1.5);
        Screen('Flip',window, vbl + constants.readtime - (constants.ifi/2));
        listen(responseHandler, constants, '');

        %% Screen
        text = 'Here''s a short example of what the restudying will be like.';
        drawInstructions(text, 'any key', 0, window, constants);
        listen(responseHandler, constants, '');

        %% Restudy 
        countdown('It''s time to restudy words from the last list', constants.practiceCountdown,...
                  constants.countdownSpeed,  window, constants);
        study(study_practice_pairs, window, constants);

        %% Screen
        text = ['You will practice remembering other words by taking a practice test.',...
                '\n\nOn the practice test, you will be shown a word on the left, and a blank on the right. Use the word on the left to help you remember the correct word.',...
                '\n\nFor example, if you were taking a practice test to help you remember the word "OVAL", you might be tested with "'];
        [~, ny] = DrawFormattedText(window, text, constants.leftMargin, constants.winRect(4)*.2, [], ...
                                    constants.wrapat, [], [], 1.5);
        [nx, ny] = DrawFormattedText(window, 'library', constants.leftMargin, ny+1.5*Screen('TextSize', window), [204, 0, 0],...
                                     constants.wrapat, [], [], 1.5);
        [~, ny] = DrawFormattedText(window, ' - ____?" (the word you studied with "OVAL"), or you might', nx, ny, current_color,...
                                    constants.wrapat, [], [], 1.5);
        [nx, ny] = DrawFormattedText(window, 'be tested with "', constants.leftMargin, ny+1.5*Screen('TextSize', window), current_color,...
                                    constants.wrapat, [], [] ,1.5);
        [nx, ny] = DrawFormattedText(window, 'circle', nx, ny, [0, 102, 0], constants.wrapat,[],[],1.5);                                
        DrawFormattedText(window, ' - ____?" (a word that is related to "OVAL").', nx, ny, current_color,...
                          constants.wrapat, [], [], 1.5);
        DrawFormattedText(window, 'Press any key to continue', 'center', constants.winRect(4)*.9, current_color, constants.wrapat, [],[], 1.5);
        Screen('Flip',window, vbl + constants.readtime - (constants.ifi/2));
        listen(responseHandler, constants, '');

        %% Screen
        text = ['During the test, press the ''z'' key if you don''t remember the missing word, and press the ''m'' key if you do '...
                '\n\nIf you press ''m'', you must then type in the answer. When you finish typing, press Enter to continue to the next pair.', ...
                '\n\nIf you do not press ''z'' or ''m'', the test will automatically continue after 10 seconds.'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(responseHandler, constants, '');
        
        %% Screen
        text = 'Here''s a short example of what the test practice will be like.';
        drawInstructions(text, 'any key', 0, window, constants);
        listen(responseHandler, constants, '');

        %% Test
        countdown('Time for a practice test on words from the last list', constants.practiceCountdown,...
                  constants.countdownSpeed,  window, constants);
        testing(test_practice_pairs, decisionHandler, responseHandler, window, constants, '', false);

        %% Screen
        KbQueueCreate;
        text = ['After the practice phase, there will be a brief delay, followed by a final memory test.',...
                '\n\nOn this test, you will be prompted using the left-hand side words from the from the very first time you studied the word pairs (not the related words from the practice phase).', ...
                '\n\nFor example, you would be prompted with "library - ____?" "oval".', ...
                '\n\nAll the words will have black text during the final test'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(responseHandler, constants, '');

        %% Screen
        text = 'Let''s take a final test on the short list you just practiced.';
        drawInstructions(text, 'any key', 0, window, constants);
        listen(responseHandler, constants, '');
        
        %% Practice block: Test
        giveInstructions('final', decisionHandler, responseHandler, window, constants);
        [On, recall, latency, resp, FP, LP, adv] = testing(final_test_pairs, decisionHandler, responseHandler, window, constants, '',false);
        final_test_pairs(:,{'onset','recalled','latency','FP','LP','response','advance'}) = table(On,recall,latency,FP,LP,resp,adv);

        assert(all(final_test_pairs.FP(~isnan(final_test_pairs.FP)) - final_test_pairs.onset(~isnan(final_test_pairs.FP)) > 0), ...
               'First Press times less than onset times - this should be impossible!')        
        assert(all(final_test_pairs.LP(~isnan(final_test_pairs.LP)) - final_test_pairs.FP(~isnan(final_test_pairs.LP)) > 0), ...
               'Last Press times less than First Press times - this should be impossible!')
        assert(all(diff(final_test_pairs.LP(~isnan(final_test_pairs.LP))) > 0), ...
               'Last Press times show a decrease - this should be impossible!');
        assert(all(diff(final_test_pairs.FP(~isnan(final_test_pairs.FP))) > 0), ...
               'Fist Press times show a decrease - this should be impossible!');
        assert(all(diff(final_test_pairs.advance(final_test_pairs.advance ~= 0)) > 0), ...
               'Advance times show a decrease - this should be impossible!');
        %% Screen
        koi=zeros(1,256);
        koi(KbName('RETURN'))=1;
        KbQueueCreate([], koi);
        text = ['That is everything you need to know to start the experiment. If you have any questions, please ask the experimenter now.' ...
                '\n\nIf not, press the Enter key to begin studying the first list of pairs!'];
        DrawFormattedText(window, text, constants.leftMargin, 'center',[],constants.wrapat,[],[],1.5);
        Screen('Flip',window,[],1);
        listen(responseHandler, constants, '');
        KbQueueRelease;
        Screen('Flip',window,[],1);

    case 'final'
        text = 'It''s time for the final test! The test will begin in:';
        countdown(text, constants.finalTestCountdown, constants.countdownSpeed, window, constants)

    case 'resume'
        KbQueueCreate;
        text = 'Welcome back! Its time to resume the experiment.';
        drawInstructions(text, 'any key', constants.ifi, window, constants);

        listen(responseHandler, constants, '');
        KbQueueRelease;

    case 'bye'
        text = ['The experiment is over, thanks for participating!', ...
                '\n\nPlease let the RA know you have finished on your way out.'];
        DrawFormattedText(window,text, constants.leftMargin,'center',[],constants.wrapat,[],[],1.5);
        Screen('Flip',window);
        WaitSecs(10);

end
% Reset text size
% Screen('TextSize', window, oldTextSize);
end

function drawInstructions(text, advanceKey, when, window, constants, varargin)
    DrawFormattedText(window, text, constants.leftMargin, 'center', [], constants.wrapat ,[],[],1.5);
    vbl = Screen('Flip',window,[],1);
    msg = strjoin({'Press' advanceKey, 'to continue'}, ' ');
    DrawFormattedText(window, msg, 'center', constants.winRect(4)*.9, [], constants.wrapat, [],[], 1.5);
    Screen('Flip',window, vbl + when - (constants.ifi/2));
end

function listen(inputHandler, constants, answer)
    KbQueueStart;
    pressed = false;
    while ~pressed
        pressed = ~isempty(inputHandler(constants.device, answer));
    end
    KbQueueStop;
end