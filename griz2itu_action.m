function [ itu_action ] = griz2itu_action( griz_action )

ituconstants.ACTION_UP = 1;
ituconstants.ACTION_DOWN = 2;
ituconstants.ACTION_LEFT = 3;
ituconstants.ACTION_RIGHT = 4;
ituconstants.ACTION_END_EFFECTOR = 5;

if (griz_action == 1)
    itu_action = ituconstants.ACTION_LEFT;
elseif (griz_action == 2)
    itu_action = ituconstants.ACTION_RIGHT;
elseif (griz_action == 3)
    itu_action = ituconstants.ACTION_UP;
elseif (griz_action == 4)
    itu_action = ituconstants.ACTION_DOWN;
elseif (griz_action == 5)
    itu_action = ituconstants.ACTION_END_EFFECTOR;
end

