%%  Puts some blocks on the table
% The robot has some basic knowledge (e.g. how many blocks) but not much beyond
% that. But it can sense things like whether a block is clear, whether a block
% is on the floor, and whether a block is on the table. The end goal is to get
% all the blocks on the table.
%
% for the full kb prolog program see slides and/or
% http://citeseerx.ist.psu.edu/viewdoc/download;jsessionid=350CC0AE649D0A16A3902B6BA73ADCF9?doi=10.1.1.16.8014&rep=rep1&type=pdf


:- include(kplanner).

% sensing actions
prim_action(senseClear(block(X)), [clear, notClear]).
prim_action(senseLocation(block(X)), [onFloor, onTable]).
prim_action(senseFloor, [empty, notEmpty]).

% put block on the table
prim_action(putOnTable(block(X)), [ok]).


prim_fluent(block(X)). %clear, notClear, onFloor, onTable
prim_fluent(floor). % empty, notEmpty
prim_fluent(blockCount).

poss(putOnTable(block(X)), and(block(X)=clear, block(X)=onFloor)).
poss(senseClear(_), true).
poss(senseLocation(_), true).

causes(putOnTable(block(X)), block(X), block(X) = onTable, true).
causes(putOnTable(block(X)), blockCount, X, X is blockCount-1).
causes(putOnTable(block(X)), floor, allBlocksOnTable, true).
causes(putOnTable(block(X)), floor, someBlocksOnFloor, true).

settles(senseClear(X), Y, block(X), Y, true).
settles(senseLocation(X), Y, block(X), Y, true).
settles(senseFloor, allBlocksOnTable, blockCount, 0, true).
rejects(senseFloor, someBlocksOnFloor, blockCount, 0, true).

init(block(X),onFloor).      % the tree may be up initially
init(floor, someBlocksOnFloor).

parm_fluent(blockCount).           % chops_max is the unique parameter
init_parm(generate,blockCount,1).  % small bound for generating is 1
init_parm(test,blockCount,100).    % large bound for testing is 100

top :- kplan(and(all(X,block(X), onTable),floor=empty)).
