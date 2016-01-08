%% The goal is to get the floor empty by moving all the blocks to the table
%% No bound is known on how many blocks are on the floor

:-include(kplanner).

prim_action(pickupBlock,[ok]).		% pick up a block from the floor to the table
prim_action(ignore, [ok]).        % ignore the current block
prim_action(look,[empty,notEmpty]).	% look if the floor is notEmpty or empty
prim_action(checkBlock,[clear,notClear]). % check if a block is clear or notClear

prim_fluent(floor).	        % can be empty or still contain blocks
prim_fluent(blocksOnFloor).	% unknown bound on the number of blocks on the floor
                            % = #ofpickups necesarry to clear floor
prim_fluent(block).         % current block under conisderation can be clear or notClear

% To pick up a block there need to be block on the floor and the block under consideration
% needs to be clear
poss(pickupBlock,and(floor=notEmpty, block=clear)).
% It is always possible to check the floor
poss(look,true).
% The current block under consideration can be ignored if it is notClear and
% if there is a notClear block left then the floor should also be
poss(ignore, and(block=notClear, floor=notEmpty)).
% The block under consideration can be checked
poss(checkBlock,floor=notEmpty).

% Picking up a block decrements the nb of blocks on the floor
causes(pickupBlock,blocksOnFloor,X,X is blocksOnFloor-1).
% Picking up a block can empty the floor
causes(pickupBlock,floor,empty,true).
% Picking up a block can result in the floor not being empty (more blocks left)
causes(pickupBlock,floor,notEmpty,true).
% Ignoring a block does not change the number of blocks on the floor
causes(ignore, blocksOnFloor, X, X is blocksOnFloor).
% Ignoring a block might cause the next under consideration to be a clear one
causes(ignore, block, clear, true).

% looking determines the value of the block
settles(checkBlock,X,block,X,true).

% if a block is seen to be not clear, blocksOnFloor cannot be 0
rejects(checkBlock,notClear, blocksOnFloor, 0, true).
% if a block is seen to be not clear, the floor cannnot be empty
rejects(checkBlock,notClear, floor, empty, true).
% looking determines whether the floor is notEmpty or empty
settles(look,X,floor,X,true).
% if the floor is seen to be notEmpty, blocksOnFloor cannot be 0
settles(look,empty,blocksOnFloor,0,true).
rejects(look,notEmpty,blocksOnFloor,0,true).

init(floor,notEmpty).  % the floor may be notEmpty initially
init(floor,empty).     % the floor may be empty  initially
init(block,clear).     % The block under consideration may be clear initially
init(block,notClear).  % The block under consideration may be notClear initially

parm_fluent(blocksOnFloor).           % blocksOnFloor is the unique parameter
init_parm(generate,blocksOnFloor,1).  % small bound for generating is 1
init_parm(test,blocksOnFloor,100).    % large bound for testing is 100

% The goal is to empty the floor
top :- kplan(floor=empty).
