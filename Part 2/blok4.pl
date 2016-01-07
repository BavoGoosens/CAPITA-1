%% The goal is to get the floor empty and store the axe.
%% In this version, no bound is known on how many chops will be needed

:-include(kplanner).
:- filter_beyond_goal.

prim_action(pickupBlock,[ok]).		% pick up a block from the floor to the table
prim_action(ignore, [ok]).        % ignore the current block since it is not clear
prim_action(look,[empty,notEmpty]).	% look if the floor is notEmpty or empty
prim_action(checkBlock,[clear,notClear]). % check if a block is clear or not

prim_fluent(floor).	        % can be empty or still contain block
prim_fluent(blocksOnFloor).	% unknown bound on the number of blocks on the floor = #ofpickups necesarry to clear floor
prim_fluent(block).         % clear or notClear

poss(pickupBlock,and(floor=notEmpty, block=clear)).
poss(look,true).
poss(ignore, and(block=notClear, floor=notEmpty)).
poss(checkBlock,floor=notEmpty).

causes(pickupBlock,blocksOnFloor,X,X is blocksOnFloor-1).
causes(pickupBlock,floor,empty,true).
causes(pickupBlock,floor,notEmpty,true).
causes(ignore, blocksOnFloor, X, X is blocksOnFloor).
% causes(ignore, block, notClear, true).
causes(ignore, block, clear, true).

% looking determines the value of the block
settles(checkBlock,X,block,X,true).
% looking determines whether the floor is notEmpty or empty
settles(look,X,floor,X,true).
% if the floor is seen to be notEmpty, blocksOnFloor cannot be 0
settles(look,empty,blocksOnFloor,0,true).
rejects(look,notEmpty,blocksOnFloor,0,true).

init(floor,notEmpty).      % the floor may be notEmpty initially
init(floor,empty).    % the floor may be empty  initially
init(block,clear).
init(block,notClear).

parm_fluent(blocksOnFloor).           % blocksOnFloor is the unique parameter
init_parm(generate,blocksOnFloor,1).  % small bound for generating is 1
init_parm(test,blocksOnFloor,100).    % large bound for testing is 100

top :- kplan(floor=empty).
