% Initial setup

board_x_max(4).
board_y_max(4).

currentPosition(position(0, 0), s0).
destination(position(4, 4), s0).

nextDestination(position(X, Y), S) :- destination(position(X, Y), S).


% Primitive control actions

% Move horizontally
primitive_action(hmove(Z)).
% Move vertically
primitive_action(vmove(Z)).
% turn the rover off at a certain position
primitive_action(turnoff(position(X, Y))).

% Preconditions for primitive actions

poss(hmove(Z), S) :-
  currentPosition(position(X, Y), S),
  board_x_max(XX),
  K is X + Z, K =< XX, 0 =< K.

poss(vmove(Z), S) :-
  currentPosition(position(X, Y), S),
  board_y_max(YY),
  K is Y + Z, K =< YY, 0 =< K.

poss(turnoff(position(X, Y)), S) :-
  currentPosition(position(X, Y), S),
  destination(position(X, Y), S).

% Successor state axioms for primitive fluents

currentPosition(position(K, Y), do(A, S)) :-
  A = hmove(Z), currentPosition(position(X, Y), S), K is X + Z.

currentPosition(position(X, K), do(A, S)) :-
  A = vmove(Z), currentPosition(position(X, Y), S), K is Y + Z.

currentPosition(position(X, Y), do(A, S)) :-
  A \= vmove(_), A \= hmove(_), currentPosition(position(X, Y), S).

destination(position(X, Y), do(A,S)) :-
  destination(position(X, Y), S), A \= turnoff(position(X, Y)).

notCurrentPosition(N, S) :- \+ currentPosition(N, S).

% Procedures

proc(randomMove, vmove(1) # hmove(1) # vmove(-1) # hmove(-1)).
proc(goTo(N), while(notCurrentPosition(N), randomMove)).
proc(serve(N), goTo(N)).
proc(serveADestination, pi(n, ?(nextDestination(n)) : serve(n))).
proc(control, while(some(n, destination(n)), serveADestination)).
proc(stop).

proc(test, pi(n,?(destination(n)) : goTo(n))).

% Restore suppressed situation arguments.

restoreSitArg(destination(P), S, destination(P, S)).
restoreSitArg(nextDestination(P), S, nextDestination(P, S)).
restoreSitArg(currentPosition(P), S, currentPosition(P, S)).
restoreSitArg(notCurrentPosition(P), S, notCurrentPosition(P, S)).
