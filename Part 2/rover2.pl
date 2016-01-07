
:- include(kplanner).

% prim_action(break_sand, [ok]).
% prim_action(break_ice, [ok]).
% prim_action(put_away, [ok]).

% 2 planning params: number of layers of sand/ice
%% The goal is to get the tree down and store the axe.
%% In this version, no bound is known on how many chops will be needed

prim_action(break_sand,[ok]).		% hit the tree with the axe
prim_action(look_sand,[no_sand,sand]).	% look_sand if the tree is up or down
prim_action(store,[ok]).	% put away the axe

prim_fluent(mineral).               % stored or out
prim_fluent(sand_layer).	        % up or down
prim_fluent(layers_of_sand).	        % unknown bound on the number of chops

poss(break_sand,and(mineral=out,sand_layer=sand)).
poss(look_sand,true).
poss(store,mineral=out).

% causes(A,R,F,V,W), is used to state that action A changes the value of F.
%    Specifically, if A returns result R, then the possible values for F are
%    any value V for which W is true.
%          e.g. causes(walk_to(X),_,mylocation,X,true).
%               causes(apply_heat,_,temperature,X,X is temperature+1).
causes(store,mineral,stored,true).
causes(break_sand,layers_of_sand,X,X is layers_of_sand-1).
causes(break_sand,sand_layer,no_sand,true).
causes(break_sand,sand_layer,sand,true).

% looking determines whether the tree is up or down
settles(look_sand,X,sand_layer,X,true).
% if the tree is seen to be up, chops_max cannot be 0
settles(look_sand,no_sand,layers_of_sand,0,true).
rejects(look_sand,sand,layers_of_sand,0,true).

init(mineral,out).      % the axe is out and available
init(sand_layer,sand).      % the tree may be up initially
init(sand_layer,no_sand).    % the tree may be down  initially

parm_fluent(layers_of_sand).           % layers_of_sand is the unique parameter
init_parm(generate,layers_of_sand,1).  % small bound for generating is 1
init_parm(test,layers_of_sand,100).    % large bound for testing is 100

top :- kplan(and(sand_layer=no_sand,mineral=stored)).
