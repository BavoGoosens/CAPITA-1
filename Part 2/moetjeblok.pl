
:-include(kplanner).

prim_action(putOnTable(_),[ok]).		% put the block on the table
prim_action(look,[empty,nonEmpty]).	% look if the table is empty or non-empty
prim_action(checkBlock(_),[clear, notClear, onTable]).	% check if the block is clear

prim_fluent(block(X)).       % clear of not clear
prim_fluent(floor).	        % empty or non-empty
prim_fluent(floorMax).	    % unknown bound on the number of blocks on the floor

poss(putOnTable(B),block(B)=clear).
poss(look,true).
poss(checkBlock(_),true).

% causes(A,R,F,V,W), is used to state that action A changes the value of F.
%    Specifically, if A returns result R, then the possible values for F are
%    any value V for which W is true.
%          e.g. causes(walk_to(X),_,mylocation,X,true).
%               causes(apply_heat,_,temperature,X,X is temperature+1).
causes(putOnTable(_), floorMax,X,X is floorMax-1).
causes(putOnTable(B), block(B), onTable, true).
% causes(putOnTable,tree,down,true).
% causes(putOnTable,tree,up,true).

% looking determines whether the floor is empty or not
settles(look,X,floor,X,true).
% if the tree is seen to be nonEmpty, floormax cannot be 0
settles(look,empty,floorMax,0,true).
rejects(look,nonEmpty,floorMax,0,true).

% checkBlock determines whether a block is clear, notClear or onTable.
settles(checkBlock(B),X, block(B), X, true).

init(block(_),clear).      % the axe is out and available
init(floor,nonEmpty).      % the tree may be up initially
init(floor,empty).    % the tree may be down  initially

parm_fluent(floorMax).           % chops_max is the unique parameter
init_parm(generate,chops_max,1).  % small bound for generating is 1
init_parm(test,chops_max,100).    % large bound for testing is 100

top :- kplan(and(floor=empty, all(x, block(x), checkBlock(x) = onTable))).
