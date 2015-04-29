function griz_action = itu2griz_action(itu_action)
%ITU2GRIZ_ACTION

ituconstants.ACTION_UP = 1;
ituconstants.ACTION_DOWN = 2;
ituconstants.ACTION_LEFT = 3;
ituconstants.ACTION_RIGHT = 4;
ituconstants.ACTION_END_EFFECTOR = 5;

if (itu_action == ituconstants.ACTION_LEFT)
    griz_action = 1;
elseif (itu_action == ituconstants.ACTION_RIGHT)    
    griz_action = 2;
elseif (itu_action == ituconstants.ACTION_UP)    
    griz_action = 3;
elseif (itu_action == ituconstants.ACTION_DOWN)
    griz_action = 4;
elseif ( itu_action == ituconstants.ACTION_END_EFFECTOR )    
    griz_action = 5;       
end
