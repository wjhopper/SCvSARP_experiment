function []= giveInstructions(phase_name, inputHandler, window, constants)

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
                                array2table(nan(6, 1), 'VariableNames', {'onset'})];
        study_practice_pairs = study_practice_pairs(randperm(size(study_practice_pairs, 1)),:);           
        test_practice_pairs = [cell2table([{'raisin','vine','fruit','ant','bug','cricket'}',...
                                           {'grape','grape','grape','insect','insect','insect'}', ...
                                           {'T', 'T', 'T', 'T', 'T', 'T'}'], ...
                                          'VariableNames', {'cue','target', 'practice'}),...
                               response_schema(6)];
        test_practice_pairs = test_practice_pairs(randperm(size(test_practice_pairs, 1)),:);
        final_test_pairs = [study_pairs(randperm(size(study_pairs, 1)), 1:3), ...
                            response_schema(6)];

        %% Screen        
        KbQueueCreate;        
        text = ['Welcome to the experiment!' ...
                '\n\nIn this experiment, you will be shown pairs of words.' ...
                '\nYour task is to learn these pairs, so that you will be able to remember them later on a test.'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(inputHandler, constants, '');

        %% Screen
        text = ['Each word pair will have the first word on the left side of the screen, and the second word on the right side.', ...
                '\n\nThe pairs you study will be grouped into "lists" of ', ...
                num2str(constants.list_length), ...
                ' pairs, and you will study each pair one at a time.'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(inputHandler, constants, '');

        %% Screen
        text = ['The best way to remember the words in the pair is to think of an association between them.' ...
                '\n\nFor instance, if you studied the list:', ...
                '\n\nlibrary - oval', ...
                '\nfoam - camera', ...
                '\n\nyou could imagine an oval shaped library and a picture of some bread.'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(inputHandler, constants, '');

        %% Screen
        text = ['After you study each list of pairs, there will be a brief delay, followed by another round of practice to help your memory.',...
                '\n\nTo help you remember the words on the list, you will see words related to the ones you need to remember.',...
                '\n\nYou will practice remembering the words in two ways: by restudying, and by taking practice tests'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(inputHandler, constants, '');

        %% Screen
        text = ['When you restudy a word from the list, you will be shown that word together with a related word.' ...
                '\n\nEach word you restudy will be shown as a pair 3 times, with a different related word each time'....
                '\n\nFor example, if you were restudying to help you remember the word "oval", you might see the pairs "circle - oval", "round - oval", and "shape - oval".'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(inputHandler, constants, '');

        %% Screen
        text = ['When you are tested, you will be shown a word on the left, but the word on the right will be missing.' ...
                '\n\nYour job is to remember the missing word from the pair, and type it in using the keyboard.'...
                '\n\nWhen you finish typing, press Enter to continue to the next pair.', ...
                '\n\nIf you do not type anything after 10 seconds, the test will automatically continue to the next pair.'];
        drawInstructions(text, 'any key', constants.readtime*2, window, constants);
        listen(inputHandler, constants, '');

         %% Screen
        text = ['On the practice test, the word on the left will be related to a word on the list you need to remember and type in.',...
                '\n\nFor example, if you were taking a practice test to help you remember the word "camera", you might ',...
                'be prompted to recall "camera" with "film - ?", "flash - ?" and "video - ?".'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(inputHandler, constants, '');       

        %% Screen
        text = ['After the practice phase, there will be another brief delay, followed by a final memory test.',...
                '\n\nOn this test, you will be prompted to recall words from the list by presenting words from left-hand', ...
                ' side of each pair you initially studied.', ...
                '\n\n For example you might be prompted with "library - ?" and \n"foam - ?" to recall "oval" and "camera".'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(inputHandler, constants, '');     

        %% Screen
        text = ['Let''s do one quick practice run before the real experiment begins.',...
                '\n\nWhen you continue to the next screen, you''ll prepare for the real experiment by studying a list, practicing the words, and taking a final test',...
                '\n\nDuring the real experiment, the lists will be longer, and there will be delays in between each phase'];
        drawInstructions(text, 'any key', constants.readtime, window, constants);
        listen(inputHandler, constants, '');  

        %% Practice block: Study 
        countdown('It''s time to study a new list of pairs', constants.studyNewListCountdown, ...
                  constants.countdownSpeed,  window, constants);
        study(study_pairs, window, constants);

        %% Practice block: Practice
        practice(study_practice_pairs, test_practice_pairs, 'S', inputHandler, window, constants);

        %% Practice block: Test
        giveInstructions('final', inputHandler, window, constants);
        setupTestKBQueue;
        [On, resp, FP, LP, advance] = testing(final_test_pairs, inputHandler, window, constants, '');
        final_test_pairs(:,{'onset','FP','LP','response','advance'}) = table(On,FP,LP,resp,advance);
        KbQueueRelease;
        
        assert(all(final_test_pairs.FP - final_test_pairs.onset) > 0, ...
               'First Press times less than onset times - this should be impossible!')        
        assert(all(final_test_pairs.LP - final_test_pairs.FP) > 0, ...
               'Last Press times less than First Press times - this should be impossible!')
        assert(all(diff(final_test_pairs.LP) > 0), ...
               'Last Press times show a decrease - this should be impossible!');
        assert(all(diff(final_test_pairs.FP) > 0), ...
               'Fist Press times show a decrease - this should be impossible!');
       assert(all(diff(final_test_pairs.advance) > 0), ...
               'Advance times show a decrease - this should be impossible!');
        %% Screen
        koi=zeros(1,256);
        koi(KbName('RETURN'))=1;
        KbQueueCreate([], koi);
        text = ['That is everything you need to know to start the experiment. If you have any questions, please ask the experimenter now.' ...
                '\n\nIf not, press the Enter key to begin studying the first list of pairs!'];
        DrawFormattedText(window, text, constants.leftMargin, 'center',[],constants.wrapat,[],[],1.5);
        Screen('Flip',window,[],1);
        listen(inputHandler, constants, '');
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

        listen(inputHandler, constants, '');
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