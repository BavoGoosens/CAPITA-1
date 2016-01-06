%% The goal is to get the tree down and store the axe.
%% In this version, no bound is known on how many chops will be needed

:-include(kplanner).

prim_action(putClearBlockOnTable,[ok]).		% hit the tree with the axe
prim_action(look,[clearBlocksOnFloor, allBlocksOnTable]).	% look if the tree is up or down

prim_fluent(table).	        % up or down
prim_fluent(blocksCount).	        % unknown bound on the number of chops

poss(putClearBlockOnTable,table=clearBlocksOnFloor).
poss(look,true).

causes(putClearBlockOnTable,blocksCount,X,X is blocksCount-1).
causes(putClearBlockOnTable,table,allBlocksOnTable,true).
causes(putClearBlockOnTable,table,clearBlocksOnFloor,true).


% looking determines whether the tree is up or down
settles(look,X,table,X,true).
% if the tree is seen to be up, chops_max cannot be 0
settles(look,allBlocksOnTable,blocksCount,0,true).
rejects(look,clearBlocksOnFloor,blocksCount,0,true).

init(table,clearBlocksOnFloor).      % the tree may be up initially
init(table,allBlocksOnTable).    % the tree may be down  initially

parm_fluent(blocksCount).           % chops_max is the unique parameter
init_parm(generate,blocksCount,1).  % small bound for generating is 1
init_parm(test,blocksCount,100).    % large bound for testing is 100

top :- kplan(table=clearBlocksOnFloor).
