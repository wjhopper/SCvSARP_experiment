function drawCueTarget(cue, target, window, constants )

DrawFormattedText(window, cue ,'right', constants.yCenter,[],[],[],[],[],[],constants.left_half-[0 0 constants.spacing 0]);
DrawFormattedText(window,' - ', 'center',constants.yCenter);
DrawFormattedText(window, upper(target) , constants.right_half(1)+constants.spacing, constants.yCenter);

end

