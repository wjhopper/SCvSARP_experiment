function onsets = study(data, window, constants)

onsets = nan(size(data,1),1);

if any(strcmp('cue_type',data.Properties.VariableNames));
    colors = nan(size(data,1),3);
    episodic_rows = strcmp('episodic', data.cue_type);
    colors(episodic_rows,:) = repmat([204, 0, 0], sum(episodic_rows), 1);
    semantic_rows = strcmp('semantic', data.cue_type);
    colors(semantic_rows,:) = repmat([0, 102, 0], sum(semantic_rows), 1);
else
    colors = nan(size(data,1),1);
end

oldsize = Screen('TextSize', window, 40);
oldPriority = Priority(2);
wakeup = Screen('Flip', window); % get starting point to base subsequent flips on
for j = 1:size(data,1);
    drawCueTarget(data.cue{j}, data.target{j}, window, constants, colors(j,:)) % Prepare stimuli
    onsets(j) = Screen('Flip', window, wakeup + (constants.ifi/2)); % Show stimulus onscreen
	wakeup = WaitSecs('UntilTime', onsets(j) + constants.cueDur - constants.ifi); % Wait stimulus duration
    vbl = Screen('Flip', window, wakeup + (constants.ifi/2)); % Clear stimulus
	wakeup = WaitSecs('UntilTime', vbl + constants.ISI - constants.ifi); % Wait ISI
end
Screen('TextSize', window, oldsize); % restore original font size
Priority(oldPriority);
end

