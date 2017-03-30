function giveInstructions(phase_name, decisionHandler, responseHandler, window, constants)

switch phase_name
    case 'intro'
        study_pairs = [cell2table([{'pine', 'puddle', 'napkin','zebra', 'root', 'bite'}', ...
                                   {'top', 'grape', 'insect', 'tape', 'mug', 'cloth'}', ...
                                   {'S', 'T', 'T', 'N', 'S', 'N'}'], ...
                                  'VariableNames', {'cue','target', 'practice'}), ...
                       table(nan(6,1), 'VariableNames', {'onset'})];
        study_practice_pairs = [cell2table([{'bottom','counter','mountain','cup','coffee','jug'}',...
                                            {'top','top','top','mug','mug','mug'}', ...
                                            {'S', 'S', 'S', 'S', 'S', 'S'}'], ...
                                           'VariableNames', {'cue','target', 'practice'}),...
                                table(nan(6, 1), 'VariableNames', {'onset'})];
        study_practice_pairs = study_practice_pairs(randperm(size(study_practice_pairs, 1)),:);
        study_practice_pairs.trial = (1:size(study_practice_pairs, 1))';

        test_practice_pairs = [cell2table([{'raisin','vine','fruit','ant','bug','cricket'}',...
                                           {'grape','grape','grape','insect','insect','insect'}', ...
                                           {'T', 'T', 'T', 'T', 'T', 'T'}'], ...
                                          'VariableNames', {'cue','target', 'practice'}),...
                               response_schema(6)];
        test_practice_pairs = test_practice_pairs(randperm(size(test_practice_pairs, 1)),:);
        test_practice_pairs.trial = (1:size(test_practice_pairs, 1))';
        
        final_test_pairs = [study_pairs(randperm(size(study_pairs, 1)), 1:3), ...
                            response_schema(6)];

        %% Screen        
        KbQueueCreate;        
        text = ['Welcome to the experiment!' ...
                '\n\nIn this experiment, you will be shown pairs of words.' ...
                '\nYour task is to learn these pairs, so that you will be able to remember them later on a test.'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(responseHandler, constants, '');

        %% Screen
        text = ['The pairs you study will be grouped into "lists" of ', num2str(constants.list_length), ' pairs, and you will study the pairs one at a time.', ...
                '\n\nEach pair will have one word on the left, and the other word on the right.', ...
                '\n\nThe word on the right is the one you need to remember for the tests.'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(responseHandler, constants, '');

        %% Screen
        text = ['Use the word on the left to help you remember the word on the right. For example, if you studied the list:', ...
                '\n\n                  library - OVAL', ...
                '\n\n                  foam - CAMERA', ...
                '\n\nyou could imagine an oval shaped library and a picture of some bread to help your memory.'];
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
        text = ['After you study each list of pairs, there will be a brief delay, followed by more practice to help your memory.',...
                '\n\nDuring the practice, the words on the left will be ones related to the words on the right you need to remember.',...
                '\n\nYou will practice remembering the words in two ways: by restudying, and by taking practice tests'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(responseHandler, constants, '');

        %% Screen
        text = ['When you restudy, you will be shown a word you need to remember together with a related word. You will restudy each word 3 times, with a different related word each time'....
                '\n\nFor example, if you were restudying to help you remember the word "oval", you might see the pairs "circle - OVAL", "round - OVAL", and "shape - OVAL".'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(responseHandler, constants, '');

        %% Screen
        text = ['On the practice test, you will only be shown the first letter of word you need to remember. Use the related word on the left to help you remember it.',...
                '\n\nFor example, if you were taking a practice test to help you remember the word "camera", you might ',...
                'be prompted to recall "camera" with "film - C____ ?", "flash - C____ ?" and "video - C____ ?".'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(responseHandler, constants, '');

        %% Screen
        text = ['During the test, press the ''z'' key if you don''t remember the missing word, and press the ''m'' key if you do '...
                '\n\nIf you press ''m'', you must then type it the answer. When you finish typing, press Enter to continue to the next pair.', ...
                '\n\nIf you do not press ''z'' or ''m'', the test will automatically continue after 10 seconds.'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(responseHandler, constants, '');

        %% Screen
        text = ['Here''s a short example of what the practice will be like.' ...
                '\n\nThe words you''re practicing are from the short list you saw earlier'];
        drawInstructions(text, 'any key', 0, window, constants);
        listen(responseHandler, constants, '');

        %% Practice block: Practice
        practice(study_practice_pairs, test_practice_pairs, decisionHandler, responseHandler, window, constants);        

        %% Screen
        KbQueueCreate;
        text = ['After the practice phase, there will be another brief delay, followed by a final memory test.',...
                '\n\nOn this test, you will be prompted using the left-hand side words from the original study list (not the related words from the practice phase).', ...
                '\n\nFor example, you would be prompted with "library - ?" and "foam - ?" to recall "oval" and "camera".'];
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
        text = ['It''s time for the final test on this list of pairs.',...
                '\n\nThe final test will begin in'];
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