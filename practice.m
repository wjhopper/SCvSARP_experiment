function [test_practice, study_practice] = practice(study_practice, test_practice, first, decisionHandler, inputHandler, window, constants)

    if strcmp('S', first)
        % Study
        countdown('It''s time to restudy words from the last list', constants.practiceCountdown,...
                  constants.countdownSpeed,  window, constants);
        study_practice.onset = study(study_practice(:, {'cue','target'}), window, constants);
        % Then retest
        countdown('Time for a practice test on words from the last list', constants.practiceCountdown,...
                  constants.countdownSpeed,  window, constants);    
        [onset, recalled, latency, response, firstPress, lastPress, adv] = testing(test_practice, decisionHandler, inputHandler, window, constants);
    else
        % Test
        countdown('It''s time for a practice test on words from the last list', constants.practiceCountdown,...
                  constants.countdownSpeed,  window, constants);
        [onset, recalled, latency, response, firstPress, lastPress, adv] = testing(test_practice, decisionHandler, inputHandler, window, constants);
        % Then Restudy
        countdown('It''s time to restudy some words from the last list', constants.practiceCountdown,...
                  constants.countdownSpeed,  window, constants);
        study_practice.onset = study(study_practice(:, {'cue','target'}), window, constants);
    end

    test_practice.onset = onset;
    test_practice.recalled = recalled;
    test_practice.latency = latency;
    test_practice.response = response;
    test_practice.FP = firstPress;
    test_practice.LP = lastPress;
    test_practice.advance = adv;    
end
