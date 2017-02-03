function setupNumericKBQueue(device)
    % Creates a KB Queue that listens for letter keys, backspace, and
    % return on the specified input device

    if ~nargin
        device = [];
    end

    keysOfInterest = zeros(1,256);
    keysOfInterest(KbName({'1!','2@','3#','4$','5%','6^','7&','8*','9(','0)', ...
                           '1','2','3','4','5','6','7','8','9','0', ...
                           'BACKSPACE','RETURN'})) = 1;
    KbQueueCreate(device, keysOfInterest);
end