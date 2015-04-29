function grizStates = itu2griz_state(ituStates)

grizStates = (5 - ituStates(1,:)) * 5;
grizStates = grizStates + ituStates(2,:);
grizStates = grizStates';

