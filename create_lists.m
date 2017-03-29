function [ stimuli ] = create_lists(raw_stimuli, c)
    
    % Number of targets we start with from the raw stimuli
    n_stimuli = size(raw_stimuli,1);
    % Number of targets we can divide evenly between the conditions
    n_stimuli = n_stimuli - mod(n_stimuli, length(c.n_conditions));
    % Number of targets we can divide into lists of x items
    n_stimuli = n_stimuli - mod(n_stimuli, c.list_length);
    n_lists = n_stimuli/c.list_length;
    
    % Select the targets to be used
    % Do the selection and random shuffling in 3 steps
    % 1. Choose the stimuli to be used (should be same for all participants
    % 2. Randomize the order of the chosen stimuli so that assignment to
    % condition is random
    % 3. randomize the episodic cue/target word pairing
    stimuli = raw_stimuli(1:n_stimuli, :);
    stimuli = stimuli(randperm(n_stimuli),:);
    stimuli.episodic_cue = stimuli.episodic_cue(randperm(n_stimuli));

    % Assign each set of cue-target pairs to a session
    stimuli.session = repelem(1:c.n_sessions, n_stimuli/c.n_sessions)';

    % Assign each set of cue-target pairs to a list
    stimuli.list = repelem(1:n_lists, c.list_length)';

    % Within a list, assign each item to a condition
    condition = [repelem(c.practice_types', c.list_length*[.4, .4, .2]), ...
                 repmat(c.cue_types', c.list_length*.5, 1)];
    stimuli(:, {'practice','cue_type'}) = cell(n_stimuli, 2);
    for i=1:n_lists
        rows = (stimuli.list == i);
        stimuli(rows, {'practice','cue_type'}) = condition(randperm(length(condition)),:);
    end

end

