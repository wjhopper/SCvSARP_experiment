function data = practice(data, first, inputHandler, window, constants)

    studyRows = strcmp(data.practice,'S');
    testRows = strcmp(data.practice,'T');
    if strcmp('S', first)
        countdown('It''s time to restudy words from the last list', constants.practiceCountdown,...
                  constants.countdownSpeed,  window, constants);
        data.onset(studyRows) = study(data(studyRows, {'cue','target'}), window, constants);
        countdown('Time for a practice test on words from the last list', constants.practiceCountdown,...
                  constants.countdownSpeed,  window, constants);    
        [onset, response, firstPress, lastPress] = testing(data(testRows,:), inputHandler, window, constants);
    else
        countdown('Time for a practice test on words from the last list', constants.practiceCountdown,...
                  constants.countdownSpeed,  window, constants);
        [onset, response, firstPress, lastPress] = testing(data(testRows,:), inputHandler, window, constants);
        countdown('It''s time to restudy words from the last list', constants.practiceCountdown,...
                  constants.countdownSpeed,  window, constants);
        data.onset(studyRows) = study(data(studyRows, {'cue','target'}), window, constants);
    end

    data.onset(testRows) = onset;
    data.response(testRows) = response;
    data.FP(testRows) = firstPress;
    data.LP(testRows) = lastPress;
end
