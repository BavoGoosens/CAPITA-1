:- include(kplanner).

% 2 planning params: number of layers of sand/ice
%% The goal is to get the sand and ice layers removed and store the mineral.
%% No bound is known on the number of layers of sand or the number of layers of ice

prim_action(break_sand,[ok]).		% break a layer of sand
prim_action(break_ice, [ok]).   % break a layer of ice
prim_action(look_sand,[no_sand,sand]).	% look if there is still sand left
prim_action(look_ice,[no_ice, ice]).    % look if there is still ice left
prim_action(store,[ok]).	      % store the mineral

prim_fluent(mineral).           % out or stored
prim_fluent(sand_layer).        % sand or no_sand
prim_fluent(ice_layer).         % ice or no_ice
prim_fluent(layers_of_sand).    % unknown bound on the number of sand layers
prim_fluent(layers_of_ice).     % unknown bound on the number of ice layers

% To break a layer of sand the mineral needs to be out and sand needs to be present
poss(break_sand,and(mineral=out,sand_layer=sand)).
% To break a layer of ice the mineral needs to be out, all the layers of sand
% need to be removed and there needs to be ice present
poss(break_ice, and(mineral=out, and(sand_layer=no_sand, ice_layer=ice))).
% To look for ice the mineral still needs to be out and all the sand needs to have
% been removed
poss(look_ice, and(mineral=out,sand_layer=no_sand)).
% To look for sand the mineral has to be out.
poss(look_sand,mineral=out).
% In order to store the mineral it has to still be out and all the ice and sand
% needs to be gone.
poss(store,and(mineral=out, and(ice_layer=no_ice, sand_layer=no_sand))).

% Storing a mineral causes the prim fluent mineral to take the value stored
causes(store,mineral,stored,true).
% Breaking a layer of sand removes one layer of sand
causes(break_sand,layers_of_sand,X,X is layers_of_sand-1).
% Breaking a layer of sand can remove all the sand from the mineral
causes(break_sand,sand_layer,no_sand,true).
% Breaking a layer of sand can uncover another layer of sand
causes(break_sand,sand_layer,sand,true).
% Breaking a layer of ice removes one layer of ice
causes(break_ice, layers_of_ice,X,X is layers_of_ice-1).
% Breaking a layer of ice can remove all the ice from the mineral
causes(break_ice, ice_layer, no_ice, true).
% Breaking a layer of ice can uncover another layer of ice
causes(break_ice, ice_layer, ice, true).

% looking determines whether there is still sand present
settles(look_sand,X,sand_layer,X,true).
% if the mineral is seen to be covered with sand, layers_of_sand cannot be 0
settles(look_sand,no_sand,layers_of_sand,0,true).
rejects(look_sand,sand,layers_of_sand,0,true).

% looking determines whether there is still ice present
settles(look_ice,X,ice_layer,X,true).
% if the mineral is seen to be covered with ice, layers_of_ice cannot be 0
settles(look_ice,no_ice,layers_of_ice,0,true).
rejects(look_ice,ice,layers_of_ice,0,true).

init(mineral,out).      % the mineral is out and available
init(ice_layer, ice).   % There might initially be a layer of ice
init(ice_layer, no_ice).  % There might initially be no ice present
init(sand_layer,sand).    % The mineral is initially covered with sand

parm_fluent(layers_of_ice).             % layers_of_ice is a planning parameter
init_parm(generate, layers_of_ice, 1).  % small bound for generating is 1
init_parm(test, layers_of_ice, 100).    % large bound for testing is 100

parm_fluent(layers_of_sand).            % layers_of_sand is a planning parameter
init_parm(generate,layers_of_sand,1).   % small bound for generating is 1
init_parm(test,layers_of_sand,100).     % large bound for testing is 100

% The goal is to store the mineral. For this to happen all the ice and sand
% needs to be removed
top :- kplan(and(mineral=stored, and(ice_layer=no_ice, sand_layer=no_sand))).
