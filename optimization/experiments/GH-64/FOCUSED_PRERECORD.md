# Focused production propagation gate (source only)

Preregistered before fixture code. Compile the SAME fixture separately against
fresh baseline72d1 and candidate7bde632 engine objects with original compiler/
flags; no fallback mock of propagateForLK and no timed production observer.
Driver preparation and all compilation/execution require root assignment.

Enumerate lengths0/1/2/3, current and next independent clause actions:
satisfied (blocker true), move (false blocker/undefined tail), move (undefined
blocker/undefined tail), unit (undefined blocker/false tail), hard conflict
(false blocker/false tail), soft unit failure (undefined blocker/false tail
and opposite mapped soft literal). For lengths2/3 enumerate all36 pairs;
length1 all6 actions; length0 once. Each with/without lazy-deleted prefix and
with/without explicit GC before propagation:316 cases per engine. Length3
adds a satisfied suffix to exercise last-next and compaction. No truth supplied
to production binaries. One fresh Solver per case,16 variables.

Require expected conflict/soft variable/assignments based independently on
the original clause formulas; satisfy/move retain original implied state,
unit forces its first literal, hard conflict stops before subsequent action,
soft failure leaves its implication queued and reports that variable. Track
exact moved/retained watcher destinations, trail/qhead/reason/counter values.
Emit all assigned/reason/level/seen/soft mapping/lock identity fields, all watch
and binary-watch lists, live clauses/circular scan points, qhead/trail/conflict/
flags/unlocked lists/allocator used+wasted. Compare baseline/candidate stdout
bytes exactly, independent expected assertions must also pass. GC cases prove
deleted-prefix actual CRef relocation, cleaning removes dead watch in both
lists before candidate prefetch evaluation. Fixture-only transcripts synthetic
public state, no host metadata, never a performance measurement or fullTier0.

Budget requested: compile120s each engine/fixture worker sequential(-j1);
fixture60s each, aggregate360s plus bounded owned cleanup. Disabled until named
slot/source review. Fail scientific expectation immediately STOP/REJECT;
compile/provenance/resource/coverage gap engineeringINCON. Full scientific,
crash/adjacent and crossrepo gates still required; no fixturePASS claimed now.
