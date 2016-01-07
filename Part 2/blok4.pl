%% The goal is to get the floor empty and store the axe.
%% In this version, no bound is known on how many chops will be needed

:-include(kplanner).

prim_action(pickupBlock,[ok]).		% hit the floor with the axe
prim_action(look,[empty,notEmpty]).	% look if the floor is notEmpty or empty
prim_action(jezza,[jos,jef]).
prim_action(disregard, [ok]).

prim_fluent(floor).	        % notEmpty or empty
prim_fluent(blocksOnFloor).	        % unknown bound on the number of chops
prim_fluent(block).              % jos or jef

poss(pickupBlock,and(floor=notEmpty, block=jos)).
poss(disregard, block=jef).
poss(look,true).
poss(jezza,true).

causes(pickupBlock,blocksOnFloor,X,X is blocksOnFloor-1).
causes(pickupBlock,floor,empty,true).
causes(pickupBlock,floor,notEmpty,true).

causes(disregard, block, jos, true).
causes(disregard, block, jef, true).

settles(jezza,X,block,X,true).
% looking determines whether the floor is notEmpty or empty
settles(look,X,floor,X,true).
% if the floor is seen to be notEmpty, blocksOnFloor cannot be 0
settles(look,empty,blocksOnFloor,0,true).
rejects(look,notEmpty,blocksOnFloor,0,true).

init(floor,notEmpty).      % the floor may be notEmpty initially
init(floor,empty).    % the floor may be empty  initially
init(block,jos).
init(block,jef).

parm_fluent(blocksOnFloor).           % blocksOnFloor is the unique parameter
init_parm(generate,blocksOnFloor,1).  % small bound for generating is 1
init_parm(test,blocksOnFloor,100).    % large bound for testing is 100

top :- kplan(floor=empty).
