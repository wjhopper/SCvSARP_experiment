function setupTestKBQueue(device)
    % Creates a KB Queue that listens for letter keys, backspace, and
    % return on the specified input device

    if ~nargin
        device = [];
    end

    keysOfInterest = zeros(1,256);
    keysOfInterest(KbName({'a','b','c','d','e','f','g','h','i','j','k','l','m', ...
                           'n','o','p','q','r','s','t','u','v','w','x','y','z', ...
                           'BACKSPACE', 'RETURN'})) = 1;
    KbQueueCreate(device, keysOfInterest);
end