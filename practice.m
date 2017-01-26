function data = practice(test_practice, study_practice, first, inputHandler, window, constants)

    if strcmp('S', first)
        % Study
        countdown('It''s time to restudy words from the last list', constants.practiceCountdown,...
                  constants.countdownSpeed,  window, constants);
        data.onset = study(study_practice(:, {'cue','target'}), window, constants);
        % Then retest
        countdown('Time for a practice test on words from the last list', constants.practiceCountdown,...
                  constants.countdownSpeed,  window, constants);    
        [onset, response, firstPress, lastPress] = testing(test_practice, inputHandler, window, constants);
    else
        % Test
        countdown('It''s time for a practice test on words from the last list', constants.practiceCountdown,...
                  constants.countdownSpeed,  window, constants);
        [onset, response, firstPress, lastPress] = testing(test_practice, inputHandler, window, constants);
        % Then Restudy
        countdown('It''s time to restudy some words from the last list', constants.practiceCountdown,...
                  constants.countdownSpeed,  window, constants);
        data.onset = study(study_practice(:, {'cue','target'}), window, constants);
    end

    data.onset = onset;
    data.response = response;
    data.FP = firstPress;
    data.LP = lastPress;
end
