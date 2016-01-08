:- include(kplanner).
%:-filter_useless.

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

poss(break_sand,and(mineral=out,sand_layer=sand)).
poss(break_ice, and(mineral=out, and(sand_layer=no_sand, ice_layer=ice))).
% eventueel testen of true => no_sand ?
poss(look_ice, and(mineral=out,sand_layer=no_sand)).
poss(look_sand,mineral=out).
% miss hier straks meer bij zetten
poss(store,and(mineral=out, and(ice_layer=no_ice, sand_layer=no_sand))).


causes(store,mineral,stored,true).
causes(break_sand,layers_of_sand,X,X is layers_of_sand-1).
causes(break_sand,sand_layer,no_sand,true).
causes(break_sand,sand_layer,sand,true).
causes(break_ice, layers_of_ice,X,X is layers_of_ice-1).
causes(break_ice, ice_layer, no_ice, true).
causes(break_ice, ice_layer, ice, true).

% looking determines whether the tree is up or down
settles(look_sand,X,sand_layer,X,true).
% if the tree is seen to be up, chops_max cannot be 0
settles(look_sand,no_sand,layers_of_sand,0,true).
rejects(look_sand,sand,layers_of_sand,0,true).

settles(look_ice,X,ice_layer,X,true).
settles(look_ice,no_ice,layers_of_ice,0,true).
rejects(look_ice,ice,layers_of_ice,0,true).

init(mineral,out).      % the axe is out and available
init(ice_layer, ice).
init(ice_layer, no_ice).
init(sand_layer,sand).      % the tree may be up initially
%init(sand_layer,no_sand).    % the tree may be down  initially

parm_fluent(layers_of_ice).
init_parm(generate, layers_of_ice, 1).
init_parm(test, layers_of_ice, 100).

parm_fluent(layers_of_sand).           % layers_of_sand is the unique parameter
init_parm(generate,layers_of_sand,1).  % small bound for generating is 1
init_parm(test,layers_of_sand,100).    % large bound for testing is 100

top :- kplan(and(mineral=stored, and(ice_layer=no_ice, sand_layer=no_sand))).
