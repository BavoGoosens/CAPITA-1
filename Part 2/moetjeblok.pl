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
prim_action(senseClear, [clear, notClear]).
prim_action(senseLocation, [onFloor, onTable]).

% put block on the table
prim_action(putOnTable, [ok]).


prim_fluent(block) %clear, notClear, onFloor, onTable
