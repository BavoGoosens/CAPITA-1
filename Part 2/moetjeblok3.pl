

prim_action(checkFloor, [empty, nonempty]).
prim_action(checkTable, [empty, nonempty]).
prim_action(senseLocation, [floor, table]).
prim_action(senseClear, [clear, nonclear]).
prim_action(moveBlockToTable, [ok]).

prim_fluent(floor).                  % number of blocks on the floor (unknown)
prim_fluent(table).                  % number of blocks on the table (unknown)
prim_fluent(block).                  % clear, nonclear, floor, table
