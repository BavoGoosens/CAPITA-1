% Primitive control actions

primitive_action(hmove(Z)).
primitive_action(vmove(Z)).
primitive_action(turnoff(position(X, Y))).

% Preconditions for primitive actions

poss(hmove(Z), S) :- currentPosition(position(X, Y), S), K is X + Z, K =< 4, 0 =< K. % hardcode eruit halen
poss(vmove(Z), S) :- currentPosition(position(X, Y), S), K is Y + Z, K =< 4, 0 =< K. % hardcode eruit halen
poss(turnoff(position(X, Y)), S) :- currentPosition(position(X, Y), S), destination(position(X, Y), S).

% Successor state axioms for primitive fluents

currentPosition(position(X+Z, Y), do(A, S)) :- A = hmove(Z), currentPosition(position(X, Y), S), print("Horizonal move"), print(Z), print(S).
currentPosition(position(X, Y+Z), do(A, S)) :- A = vmove(Z), currentPosition(position(X, Y), S), print("Vertical move"), print(Z), print(S).
currentPosition(position(X, Y), do(A, S)) :- A \= vmove(_), A \= hmove(_), currentPosition(position(X, Y), S), print("No move"), print(S).
destination(position(X, Y), do(A,S)) :- destination(position(X, Y), S), A \= turnoff(position(X, Y)).

% Initial situation

currentPosition(position(0, 0), s0).
destination(position(4, 4), s0).

nextDestination(position(X, Y), S) :- destination(position(X, Y), S).

% Procedures

proc(goTo(N), while(\+ currentPosition(N), vmove(1) # hmove(1) # vmove(-1) # hmove(-1))).
proc(serve(N), goTo(N)).
proc(serveADestination, pi(n, ?(nextDestination(n)) : serve(n))).
proc(control, while(some(n, destination(n)), serveADestination : stop)).
proc(stop).

proc(test, pi(n,?(destination(n)) : goTo(n))).

% Restore suppressed situation arguments.

restoreSitArg(destination(position(X, Y)), S, destination(position(X, Y), S)).
restoreSitArg(nextDestination(position(X, Y)), S, nextDestination(position(X, Y), S)).
restoreSitArg(currentPosition(position(X, Y)), S, currentPosition(position(X, Y), S)).
