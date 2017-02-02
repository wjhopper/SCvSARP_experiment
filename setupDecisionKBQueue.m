function setupDecisionKBQueue(device)
    % Creates a KB Queue that listens for letter keys, backspace, and
    % return on the specified input device

    if ~nargin
        device = [];
    end

    keysOfInterest = zeros(1,256);
    keysOfInterest(KbName({'m','z'})) = 1;
    KbQueueCreate(device, keysOfInterest);
end