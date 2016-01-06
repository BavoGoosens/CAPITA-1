%
% FILE: kplanner.pl
% The file ktrue.pl is loaded to do formula evaluation
%
% Prolog code for an iterative planner.
% See "Planning with Loops" by Hector Levesque for background
%
:- write('*** Loading kplanner by Hector Levesque (c) 2004, version 1.0'), nl.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%                     December 15, 2004
%
% This software was developed by Hector Levesque from Sept-Dec 04.
% 
%        Do not distribute without permission.
%        Include this notice in any copy made.
% 
%        Copyright (c) 2004 by The University of Toronto,
%                              Toronto, Ontario, Canada.
% 
%                     All Rights Reserved
% 
% Permission to use, copy, and modify, this software and its
% documentation for non-commercial research purpose is hereby granted
% without fee, provided that the above copyright notice appears in all
% copies and that both the copyright notice and this permission notice
% appear in supporting documentation, and that the name of The University
% of Toronto not be used in advertising or publicity pertaining to
% distribution of the software without specific, written prior
% permission.  The University of Toronto makes no representations about
% the suitability of this software for any purpose.  It is provided "as
% is" without express or implied warranty.
% 
% THE UNIVERSITY OF TORONTO DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
% SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS, IN NO EVENT SHALL THE UNIVERSITY OF TORONTO BE LIABLE FOR ANY
% SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
% RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
% CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
% CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  The following predicates need to be defined in a separate file:
%
%  For formula evaluation, we need a basic action theory
%    -prim_fluent(F), declares F as a primitive fluent
%    -prim_action(A,RL), declares A as a primitive action with RL as 
%        a list of possible sensing results
%    -poss(A,C) declares C is the precondition for action A
%    -causes(A,R,F,V,C), when A occurs with sensing result R,
%        then F is caused to have the possible values of each V 
%        for which C is possibly true
%    -settles(A,R,F,V,C), when A occurs with sensing result R,
%        and C is known, then F is known to have value V
%    -rejects(A,R,F,V,C), when A occurs with sensing result R,
%        and C is known, then F is known not to have value V
%    -init(F,V), V is a possible initial value for F.
%
%  For problems requiring a planning parameter, we also need:
%    -parm_fluent(F), F is the planning parameter
%    -init_parm(W,F,V), where W is 'generate' or 'test', V is a
%        possible initial value for the fluent F
%
%  There are some directives that can be used to prune the search:
%    -good_action(A,C), A is acceptable when C is possibly true
%    -good_state(N,C), current state is acceptable, 
%         if N actions remain and C is possibly true
%    -filter_useless, do not consider actions that are no-ops in plans
%    -filter_beyond_goal, no actions after goal has been achieved
%    -gen_max(N), in generating plans only search for plans to depth N
%    -test_max(N), with parameters, only test plans to depth N
%
%  The top level predicate exported is kplan(C)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- include(ktrue).

:- dynamic parm_fluent/1, init_parm/3, searchBeyondGoal/0,
     goodAct/2, goodState/2, testMax/1, genMax/1, trivAct/2.

:- set_event_handler(64,retract_dynamic/0).  % avoid errors on recompilation
retract_dynamic :- 
     retract_all(prim_fluent(_)), retract_all(prim_action(_,_)), 
     retract_all(init(_,_)), retract_all(causes(_,_,_,_)), 
     retract_all(causes(_,_,_,_,_)), retract_all(settles(_,_,_,_,_)), 
     retract_all(rejects(_,_,_,_,_)), retract_all(parm_fluent(_)),
     retract_all(init_parm(_,_,_)), retract_all(searchBeyondGoal),
     retract_all(goodAct(_,_)), retract_all(goodState(_,_)), 
     retract_all(testMax(_)), retract_all(genMax(_)), 
     retract_all(trivAct(_,_)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  The top level predicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

kplan(Goal) :- 
   write('The goal:  '), write(Goal), nl, nl, Go is cputime, kp(Goal,Plan),  
   Diff is cputime-Go, nl, nl, write('A plan is found after '),
   write(Diff), write(' seconds.'), nl, pp(Plan), nl.
kplan(Goal,Plan) :- kp(Goal,Plan).

kp(Goal,Plan) :- parm_fluent(_) -> gtplan(Goal,Plan) ; gplan(Goal,Plan).

gtplan(Goal,Plan) :- genSmall(Goal,Plan), tstLarge(Goal,Plan), iniReset.
gtplan(_,_) :- iniReset, fail.

genSmall(Goal,Plan) :- iniSet(generate), gplan(Goal,Plan), nonTrivLoops(Plan).
genSmall(_,_) :- nl, write('No more plans to generate'), nl, fail.

tstLarge(Goal,Plan) :- iniSet(test), tplan(Goal,Plan). 
tstLarge(_,_) :- iniSet(generate), ttyecho('x'), fail.

iniSet(W) :- iniReset, parm_fluent(F), 
   ((init_parm(W,F,V), assert(init(F,V)), fail) ; true).

iniReset :- parm_fluent(F), retract_all(init(F,_)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  The plan tester
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tplan(Goal,Plan) :- testMax(Max), tp(Goal,Max,[],Plan,[]), !.

% tp(G,N,H,P,S) execute P starting in H with S as a stack of loops
% and terminate in a state of depth N at most and where G is known to hold

tp(G,N,H,P,S) :- var(P), !, (P=nil;P=exit;P=next), tp(G,N,H,P,S).
tp(G,_,H,nil,[]) :- kTrue(G,H).
tp(G,N,H,next,[loop(P1,P2)|S]) :- tp(G,N,H,P1,[loop(P1,P2)|S]).
tp(G,N,H,exit,[loop(_,P2)|S]) :- tp(G,N,H,P2,S).
tp(G,N,H,seq(A,P),S) :- 
   N > 0, N1 is N-1, legalAct(A,[R],H), !, tp(G,N1,[o(A,R)|H],P,S).
tp(G,N,H,case(A,IL),S) :- 
   N > 0, N1 is N-1, legalAct(A,RL,H), !, tpAll(G,N1,H,A,RL,IL,S).
tp(G,N,H,loop(P1,P2),S) :- tp(G,N,H,P1,[loop(P1,P2)|S]).

tpAll(_,_,_,_,[],[],_).
tpAll(G,N,H,A,[R|RL],[if(R,_)|IL],S) :- 
        impSense(A,R,H), !, tpAll(G,N,H,A,RL,IL,S).
tpAll(G,N,H,A,[R|RL],[if(R,P)|IL],S) :- 
        tp(G,N,[o(A,R)|H],P,S), !, tpAll(G,N,H,A,RL,IL,S).

% A is primitive action whose precondition is known to be true
legalAct(A,RL,H) :- prim_action(A,RL), poss(A,C), kTrue(C,H).

% the sensing value R for action A is impossible in history H
impSense(A,R,H) :- causes(A,R,_,_,C), kTrue(neg(C),H).
impSense(A,R,H) :- settles(A,R,F,V,C), kTrue(C,H), not mval(F,V,H). 
impSense(A,R,H) :- rejects(A,R,F,_,_), not mval(F,_,[o(A,R)|H]). 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  The plan generator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gplan(Goal,Plan) :- genMax(Max), idplan(Goal,0,Max,Plan).

% idplan(G,N,M,P) find a plan P for goal G by iterative deeping from N to M
idplan(G,N,_,P) :- ttyecho(' '), ttyecho(N), dfplan(G,N,[],P).
idplan(G,N,M,P) :- N < M, N1 is N+1, idplan(G,N1,M,P).

% find a plan no deeper than N for achieving the goal starting in history H
dfplan(Goal,_,H,Plan) :- 
    kTrue(Goal,H), Plan=nil, (searchBeyondGoal -> true ; !).
dfplan(Goal,N,H,Plan) :- N > 0, N1 is N-1, 
    okState(N,H), okAct(A,RL,H), tryAct(A,RL,Goal,N1,H,Plan).

% find a plan whose first action is A with sensing results RL
tryAct(A,[R],Goal,N,H,Plan) :- !, dfplan(Goal,N,[o(A,R)|H],P), 
       (Plan=seq(A,P) ; unwind(Plan,seq(A,P))).
tryAct(A,RL,Goal,N,H,Plan) :- makeIfs(RL,A,Goal,N,H,IL), 
       (Plan=case(A,IL) ; unwind(Plan,case(A,IL))).

% find subplans if(R,P) for each of the possible sensing results R in RL
makeIfs([],_,_,_,_,[]).
makeIfs([R|RL],A,Goal,N,H,[if(R,_)|IL]) :- 
    impSense(A,R,H), !, makeIfs(RL,A,Goal,N,H,IL).
makeIfs([R|RL],A,Goal,N,H,[if(R,P)|IL]) :- 
    dfplan(Goal,N,[o(A,R)|H],P), makeIfs(RL,A,Goal,N,H,IL).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Unwinding loops
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%  unwind(P,Q) iff P is a loop that unwinds to Q.
unwind(P, Q) :- P=loop(P1,P2), replNoExit(P1,P,P2,Q).

%  repl(P,X,Y,Q): P is body part of loop X and Q is the result of replacing 
%  in P 'exit' by Y and 'next' by the unwinding of X. Used to generate P!
%
%  This does the following optimization: 'exit' is only generated just
%  after a 'case'.  No loss of generality for binary sensing.

repl(_,_,_,Q) :- var(Q), !.
repl(exit,X,Y,Q) :- not X=loop(exit,_), Q=Y.
repl(P,X,Y,Q) :- replNoExit(P,X,Y,Q).

replNoExit(_,_,_,Q) :- var(Q), !.
replNoExit(next,X,_,Q) :- not X=loop(next,_), (X=Q ; unwind(X,Q)).
replNoExit(loop(P1,P),X,Y,loop(P1,Q)) :- replNoExit(P,X,Y,Q).
replNoExit(seq(A,P),X,Y,seq(A,Q)) :- replNoExit(P,X,Y,Q).
replNoExit(case(A,ILP),X,Y,case(A,ILQ)) :- replAll(ILP,X,Y,ILQ).

replAll([],_,_,[]).
replAll([if(R,P)|ILP],X,Y,[if(R,Q)|ILQ]) :- 
    repl(P,X,Y,Q), replAll(ILP,X,Y,ILQ).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Filtering of trivial states, actions, plans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% H is an acceptable state given that N actions are left
okState(N,H) :- goodState(N,C) -> mTrue(C,H) ; true.

% A is a acceptable action in H: legal, not filtered, not trivial
okAct(A,RL,H) :- legalAct(A,RL,H),
  (goodAct(A,C1) -> mTrue(C1,H) ; true), not trivAct(A,H).

% A is trivial if it is a sensing action that was just performed.
trivAct(A,[o(A,_)|_]) :- prim_action(A,[_,_|_]).

% A is useless if it has no effect and anything it senses is known
uselessAct(A,H) :- not causes(A,_,_,_,_), 
  not (settles(A,_,F,_,_), not kTrue(F=_,H)), 
  not (rejects(A,_,F,_,_), not kTrue(F=_,H)).

% P is a non-trivial plan if all its loops have a 'next' operator
nonTrivLoops(P) :- var(P), !.
nonTrivLoops(nil).
nonTrivLoops(seq(_,P)) :- nonTrivLoops(P).
nonTrivLoops(case(_,IL)) :- nonTrivAll(IL).
nonTrivLoops(loop(P1,P2)) :- hasNext(P1), !, nonTrivLoops(P2).

nonTrivAll([]).
nonTrivAll([if(_,P)|IL]) :- nonTrivLoops(P), nonTrivAll(IL).

% hasNext(P) succeeds if loop body P has a 'next' operator
hasNext(P) :- var(P), !, fail.
hasNext(next).
hasNext(seq(_,P)) :- hasNext(P).
hasNext(loop(_,P)) :- hasNext(P).
hasNext(case(_,IL)) :- hasSomeNext(IL).

hasSomeNext([if(_,P)|IL]) :- hasNext(P) ; hasSomeNext(IL).

testMax(400).  /* default max depth of program when testing large */
genMax(20).    /* default max depth of program when generating small */
searchBeyondGoal.  /* consider non-empty plans when goal is achieved */

% user directives for setting up the above filters

good_action(A,C) :- assert(goodAct(A,C)).
good_state(N,C) :- assert(goodState(N,C)).
filter_useless :- assert(trivAct(A,H) :- uselessAct(A,H)).
filter_beyond_goal :- retract_all(searchBeyondGoal).
test_max(N) :- retract_all(testMax(_)), assert(testMax(N)).
gen_max(N) :- retract_all(genMax(_)), assert(genMax(N)).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  The plan pretty printer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ttyecho(C) :- write(C), flush(output).

tab(0).
tab(N) :- N>0, N1 is N-1, write(' '), tab(N1).

pp(P) :- write('-------------------------------------------'), nl, pp(0,P), !.

pp(N,X) :- var(X), !, tab(N), write(----), nl. 
pp(_,nil).
pp(N,exit) :- tab(N), write('EXIT'), nl.
pp(N,next) :- tab(N), write('NEXT'), nl.
pp(N,seq(A,P)) :- tab(N), write(A), (P=nil;write(' ;')), nl, pp(N,P).
pp(N,case(A,IL)) :- tab(N), write('CASE '), write(A), write(' OF'), nl, 
    N2 is N+2, pp2(N2,IL), tab(N), write('ENDC'), nl.
pp(N,loop(P1,P2)) :- tab(N), write('LOOP'), nl, N2 is N+2, pp(N2,P1),
    tab(N), write('ENDL'), (P2=nil;write(' ;')), nl, pp(N,P2).
 
pp2(_,[]).
pp2(N,[if(R,P)|IL]) :- tab(N), write(' -'), write(R), write(': '), pp3(N,P,IL).

pp3(N,X,IL) :- var(X), !, write('---'), nl, pp2(N,IL).
pp3(N,nil,IL) :- !, write('nil'), nl, pp2(N,IL).
pp3(N,next,IL) :- !, write('NEXT'), nl, pp2(N,IL).
pp3(N,exit,IL) :- !, write('EXIT'), nl, pp2(N,IL).
pp3(N,P,IL) :- 	nl, N2 is N+5, pp(N2,P), pp2(N,IL).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  The plan tester as above but with printing (for debugging only)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

trplan(Goal,Plan) :- testMax(Max), trp(0,Goal,Max,[],Plan,[]), !.

trp(M,G,N,H,P,S) :- var(P), !, (P=nil;P=exit;P=next), trp(M,G,N,H,P,S).
trp(_,G,_,H,nil,[]) :- kTrue(G,H), write(' DONE').
trp(M,G,N,H,next,[loop(P1,P2)|S]) :- trp(M,G,N,H,P1,[loop(P1,P2)|S]).
trp(M,G,N,H,exit,[loop(_,P2)|S]) :- trp(M,G,N,H,P2,S).
trp(M,G,N,H,seq(A,P),S) :- nl, tab(M), write(A), N > 0, N1 is N-1, 
   legalAct(A,[R],H), !, write(' -- OK'), trp(M,G,N1,[o(A,R)|H],P,S).
trp(M,G,N,H,case(A,IL),S) :- nl, tab(M), write(A), M1 is M+2, N > 0, 
   N1 is N-1, legalAct(A,RL,H), !, write(' -- OK'), 
   trpAll(M1,G,N1,H,A,RL,IL,S).
trp(M,G,N,H,loop(P1,P2),S) :- trp(M,G,N,H,P1,[loop(P1,P2)|S]).

trpAll(_,_,_,_,_,[],[],_).
trpAll(M,G,N,H,A,[R|RL],[if(R,_)|IL],S) :- 
  impSense(A,R,H), !,  nl, tab(M), write(R), write(': CANT HAPPEN'),
  trpAll(M,G,N,H,A,RL,IL,S).
trpAll(M,G,N,H,A,[R|RL],[if(R,P)|IL],S) :- nl, tab(M), write(R), write(':'),
  M1 is M+2, trp(M1,G,N,[o(A,R)|H],P,S), !, trpAll(M,G,N,H,A,RL,IL,S).
