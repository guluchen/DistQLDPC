# GH55 static scope/proof obligations; NOT compiled or tested

Preregister e74047c BEFORE source edit. One production function capacity(int)
changes geometric storage growth only; initial2, original min-required rounding,
original INT_MAX guard/realloc/exception expression and all logical/lifetime APIs
are byte-unchanged. Unused nextCap not edited. Original source license remains.

Invariant inherited from valid Vec use: cap>=0, sz>=0, sz<=cap, cap even and
cap<INT_MAX. Constructors set0; original/candidate increments are even. At cap0
new growth equals original2. At even cap>=2, use add=cap only if
cap<=INT_MAX-cap. Hence doubling is representable and remains even<INT_MAX.
Otherwise retain original growth (including original guard). Required-size
rounded increment can exceed geometric increment; the unchanged max and guard
still determine allocation/exception. No multiplication or rounding policy is
changed; existing valid-request assumptions are not expanded or silently repaired.
Near-int calculations require an independent widened-integer model before real
tests; do not allocate gigabytes or excuse original undefined inputs as tested.

Successful capacity(n) does not modify sz or elements. The allocation may move,
as in the original realloc contract; relocation-safe T and existing alias rules
must hold. New memory addresses/retained bytes can differ and are observable.
No claim of identical allocation timing/bytes/OOM incidence is made: larger
capacity may regress memory/OOM/cache behavior, and that risk must be measured.
Exception API/path and caller handling remain unchanged; any failure is retained
and never counted as correct scientific completion. No allocator/lifetime change.

Source call audit (baseline): only explicit .capacity(n) calls in src are
trail.capacity(v+1) at Solver.cc1293 and6085; no external .capacity() read was
found. This is not a complete correctness proof: audit implicit push/growTo/
constructor operations, push_ room assumptions, relocation and pointer aliases
and recheck all call syntax/types independently. Larger capacity satisfies minimum
room, but an illegal alias in preexisting code must not become an assumed invariant.

Required tests NOT_RUN: separately compiled baseline/candidate identical fixtures
for int/Lit or other explicitly relocation-safe types, bothpush overloads, growTo,
pad/default initialization, push_, shrink/shrink_, pop, clear retained/deallocated,
copy/move, explicit reserve, contents/order/size; capacity-policy assertions
separate from science equivalence. Avoid custom nontrivial test types whose
assignment into raw vector storage could itself be undefined. Widened arithmetic
models exercise guard/fallback boundaries without huge actual allocations.

Baseline-only allocation observer must isolate authenticated test objects and
report actual event counts/old-newcap/type-size/requestbytes. Realloc-in-place is
possible, so requested bytes are not copied bytes or CPU time. Do not infer exact
alternative allocation savings from realloc-only traces; baseline capacity may
cover later logical demand that a different policy does not. No time-share claim.

Known GH46 valid fixture is mandatory fullTier0 gate: original baseline crash on
10variables/15hard/13unitsoft family1variant1, optimum5/witness472. It remains
unresolved; selected change is not an explanation/fix and cannot waive it.
No production scientific PASS/Tier1 until correctness established. Engineering
container/census results cannot substitute for this gate. Every semantic mismatch,
wrong bound/distance/status or crash stops performance; durable raw/root notification.

Current: source-only candidate/attribution docs prepared; no compiler/container/
observer/solver/host assignment/scientific validation/performance. Peer source
review then separately preregistered bounded resource support required before run.
