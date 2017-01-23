function [ stimuli ] =create_lists(raw_stimuli, c)
    
    % Number of targets we start with from the raw stimuli
    n_stimuli = size(raw_stimuli,1);
    % Number of targets we can divide evenly between the 3 conditions
    n_stimuli = n_stimuli - mod(n_stimuli, length(c.conditions));
    % Number of targets we can divide into lists of x items
    n_stimuli = n_stimuli - mod(n_stimuli, c.list_length);
    n_lists = n_stimuli/c.list_length;
    
    % Select the targets to be used
    % Do the selection and random shuffling in two steps
    % This is because we want to always choose the same stimuli,
    % randomize the order of the chosen stimuli
    stimuli = raw_stimuli(1:n_stimuli, :);
    stimuli = stimuli(randperm(n_stimuli),:);

    % Assign each set of cue-target pairs to a session
    % There are 3 sessions total
    stimuli.session = repelem(1:c.n_sessions, n_stimuli/c.n_sessions)';

    % Assign each set of cue-target pairs to a list
    stimuli.list = repelem(1:n_lists, c.list_length)';

    % Within a list, assign each item to a condition
    condition_indicators = repelem(c.conditions, n_stimuli/n_lists/length(c.conditions))';
    stimuli.practice = cell(n_stimuli, 1);
    for i=1:n_lists
        rows = stimuli.list == i;
        stimuli.practice(rows) = condition_indicators(randperm(length(condition_indicators)));
    end

end

