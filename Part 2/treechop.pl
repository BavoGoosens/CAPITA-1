%% The goal is to get the tree down and store the axe.
%% In this version, no bound is known on how many chops will be needed

:-include(kplanner).

prim_action(chop,[ok]).		% hit the tree with the axe
prim_action(look,[down,up]).	% look if the tree is up or down
prim_action(store,[ok]).	% put away the axe

prim_fluent(axe).               % stored or out
prim_fluent(tree).	        % up or down
prim_fluent(chops_max).	        % unknown bound on the number of chops

poss(chop,and(axe=out,tree=up)).
poss(look,true).
poss(store,axe=out).

% causes(A,R,F,V,W), is used to state that action A changes the value of F.
%    Specifically, if A returns result R, then the possible values for F are
%    any value V for which W is true.
%          e.g. causes(walk_to(X),_,mylocation,X,true).
%               causes(apply_heat,_,temperature,X,X is temperature+1).
causes(store,axe,stored,true).
causes(chop,chops_max,X,X is chops_max-1).
causes(chop,tree,down,true).
causes(chop,tree,up,true).

% looking determines whether the tree is up or down
settles(look,X,tree,X,true).
% if the tree is seen to be up, chops_max cannot be 0
settles(look,down,chops_max,0,true).
rejects(look,up,chops_max,0,true).

init(axe,out).      % the axe is out and available
init(tree,up).      % the tree may be up initially
init(tree,down).    % the tree may be down  initially

parm_fluent(chops_max).           % chops_max is the unique parameter
init_parm(generate,chops_max,1).  % small bound for generating is 1
init_parm(test,chops_max,100).    % large bound for testing is 100

top :- kplan(and(tree=down,axe=stored)).
