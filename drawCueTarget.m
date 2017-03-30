function drawCueTarget(cue, target, window, constants, color)

if nargin == 5 && all(size(color) == [1,3]) && isnumeric(color)
    reset = true;
    old_color = Screen('TextColor', window, floor(color));
else
    reset = false;
end

DrawFormattedText(window, cue ,'right', constants.yCenter,[],[],[],[],[],[],constants.left_half-[0 0 constants.spacing 0]);
if reset
    Screen('TextColor', window, old_color);
end
DrawFormattedText(window,' - ', 'center',constants.yCenter);
DrawFormattedText(window, upper(target) , constants.right_half(1)+constants.spacing, constants.yCenter);

end

