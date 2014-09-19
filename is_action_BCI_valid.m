function isValid = is_action_BCI_valid(state, action)
%IS_VISUALY_RANDOM

% Action:
% 1 -> Left
% 2 -> Right
% 3 -> Up
% 4 -> Down
% 5 -> Nothing

isValid = 1;
switch action
    
    case 1
        if ~mod(state - 1, 5)
            isValid = 0;
        end
        
    case 2
        if ~mod(state, 5)
            isValid = 0;
        end
        
    case 3
        if state > 20
            isValid = 0;
        end
        
    case 4
        if state < 6
            isValid = 0;
        end
        
    case 5
        isValid = 1; % do nothing
        
    otherwise
        isValid = 0;
        
end
