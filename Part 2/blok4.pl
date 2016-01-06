%% The goal is to get the floor empty and store the axe.
%% In this version, no bound is known on how many chops will be needed

:-include(kplanner).

prim_action(pickupBlock,[ok]).		% hit the floor with the axe
prim_action(look,[empty,notEmpty]).	% look if the floor is notEmpty or empty
%prim_action(store,[ok]).	% put away the axe

%prim_fluent(axe).               % stored or out
prim_fluent(floor).	        % notEmpty or empty
prim_fluent(blocksOnFloor).	        % unknown bound on the number of chops

poss(pickupBlock,floor=notEmpty).
poss(look,true).
%poss(store,axe=out).

% causes(A,R,F,V,W), is used to state that action A changes the value of F.
%    Specifically, if A returns result R, then the possible values for F are
%    any value V for which W is true.
%          e.g. causes(walk_to(X),_,mylocation,X,true).
%               causes(apply_heat,_,temperature,X,X is temperature+1).
%causes(store,axe,stored,true).
causes(pickupBlock,blocksOnFloor,X,X is blocksOnFloor-1).
causes(pickupBlock,floor,empty,true).
causes(pickupBlock,floor,notEmpty,true).

% looking determines whether the floor is notEmpty or empty
settles(look,X,floor,X,true).
% if the floor is seen to be notEmpty, blocksOnFloor cannot be 0
settles(look,empty,blocksOnFloor,0,true).
rejects(look,notEmpty,blocksOnFloor,0,true).

%init(axe,out).      % the axe is out and available
init(floor,notEmpty).      % the floor may be notEmpty initially
init(floor,empty).    % the floor may be empty  initially

parm_fluent(blocksOnFloor).           % blocksOnFloor is the unique parameter
init_parm(generate,blocksOnFloor,1).  % small bound for generating is 1
init_parm(test,blocksOnFloor,100).    % large bound for testing is 100

top :- kplan(floor=empty).
