# GH-17 / caller-local core-merge scratch

**Disposition: SHELVED / LOW PRIORITY / NOT ADOPTED. Performance INCONCLUSIVE.**
Local and required hosted Tier0 PASS. Allocation diagnostic reveals a small
nonzero opportunity, not measured runtime benefit or a performance rejection.
No Tier1/2/3; do not generalize these two small diagnostic cases to hard cases.
Root integrator accepted this disposition after the assigned diagnostic.

## Identity and exact implementation

Baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a; tested production candidate
191de6849357574c830e14992a7afe9615dad320. Sole conceptual change is caller-local
oldset capacity reuse in each of two lookahead callers, three call arguments,
original clear/merge/lock/order retained. PR18 remains isolated, draft, unmerged.
Exact production diff: implementation.patch. Preregistration precedes source
implementation; diagnostics never enter production source or timed binaries.

Test-only follow-up changes Fixture::emit to non-const to use the existing vec2
non-const accessor legally; test source SHA256
4310702ed999779fcfe6db552987082434ebf95400f723de68561ad1dab084eb.
The Windows wrapper is separately hashed in identity.json. This report does
not claim that dirty test/runner follow-up was present in tested commit191de68.
Later record/support commits preserve the exact production source identity.

## Tier0

Candidate builds with preserved original GCC14.4 -O3 flags; baseline executable
and objects reused only after complete immutable package manifest validation.
Both compiled production-method probes PASS:4096 three-core sequences plus
manual overlap/dedup/unlock/empty/disjoint/restart assertions.12290 exact state
trace lines per binary match bytewise; trace covers variable owners, seen flags,
unlocked list and active core membership/representatives/weights.
Independent CSS fixtures certify distances1,2,1 in OFF/MTO, matching final
distance/objective/LB/UB; all12 initial exported WCNFs pairwise identical, with
explicit mode flags. LP34 smoke distance2, help and four LP340 forced wall
timeouts preserve unknown/result/bound semantics and leave no owned descendants.

Attempt01 retained: candidate build passed; baseline probe compilation failed
on an invalid const_cast introduced in the test subclass adaptation. No solver
semantic result or benchmark was produced; resource cleanup passed. Routine
test fix led to fresh attempt02, not repeated favorable performance sampling.

Hosted current CI37795560318 and cross-repo37795560187 PASS. Eight pilot solves
LP136/BB108 OFF/MTO match d/objective/LB/UB4/10, no timeout. QDistSAT actual
revision7c4774fffc49856f48a22ae5f9063d00b2661aaa. Hosted built synthetic merge
81968c22c3614d0903b88ddde650b000c9cf36b9; fetched Git verification confirms
its tree and191de68 tree both25dfe88fb464dc600a9b4651916ee4b5c5398dd1.
Raw artifact zip/report/job log retained with SHA256
d859383ee5958781cb5334c08c422157060128644f5a16cf35454c28857788f2.
All shared-runner elapsed values are informational, never performance evidence.

## Bounded allocation diagnostic

Separate original-baseline snapshot, normalized source hash checked before
adding counter-only RAII support. Four serial LP34/LP136 OFF/MTO calls,120s
parent/135s external limits; all exact scientific results, no aborted sample.
Observed original reallocations are capacity crossings around actual pushes.
Reuse allocations are a deterministic replay of original Vec growth per caller,
explicitly predictions, not observed candidate counts or a time share.

| Case/mode | Caller invocations | setConflict calls | Populated calls | Original allocations | Predicted reused allocations | Predicted saved |
|---|---:|---:|---:|---:|---:|---:|
| LP34 OFF | 1 | 1 | 0 | 0 | 0 | 0 |
| LP34 MTO | 1 | 1 | 0 | 0 | 0 | 0 |
| LP136 OFF | 2174 | 4490 | 164 | 164 | 158 | 6 |
| LP136 MTO | 2424 | 5234 | 164 | 164 | 161 | 3 |

Total328 original allocations,319 predicted reused:9 saved (2.74% of this
buffer's allocation events). Maximum capacity2 integer elements,8 bytes on
this compiler. Most populated uses occur in different caller invocations,
limiting the chosen safe reuse lifetime. No allocator time share measured.
Zero-opportunity rejection prerequisite is NOT met:9 is nonzero. Engineering
triage shelves this low-yield scope while preserving formal performance
INCONCLUSIVE. This is not a measured slowdown, a proven no-benefit statement,
or a rejection of longer-lived scratch reuse/all allocator optimizations.

## Resources and cleanup

Assignment hub15/comment6062543626. Windows single-CPU temporary unnamed Job,
AboveNormal for the owned process tree, allow-contention correctness/diagnostic
mode, global spare>50% and one worker<=half spare actively checked every2s.
Attempt02 recorded61 capacity checks, minimum global idle69.83%,12 contention
alerts retained. No timing conclusion. Sampled descendants all enforced mask/
priority; QueryInformationJobObject verifies no owned descendants after each
command and only runner PID before release. Bounded file-backed supervision
avoids communicate pipe-drain hangs; manager watchdog abort path was not needed.
Forced solver timeouts exercised internal child killing and Job cleanup.
Job limits, original affinity65535, Normal priority32 and sleep restored PASS.
Windows slot released in hub15/comment6062760241; no remaining GH17 workload.

## Learning and next action

Concrete repeated-call sites are not enough to establish an allocation hotspot.
Caller-local safe lifetime captures little populated reuse on these cases; do
not expand this same experiment into persistent storage or general pooling.
No Tier1 promotion/adoption or controlled-server claim. Preserve all evidence,
then fresh Brain proposes3 independent methods and selects1 with a new rationale.
Any revisit uses a separately registered scope and supporting diagnostic.

Raw commands, outputs, manifests, identities/capacity/Job records under
raw/windows-assigned-01, raw/windows-assigned-02 and raw/hosted-191de68.
Compiled probes and recreated diagnostic snapshot stay local; their hashes
and exact source reconstruction commands are retained. No paper-derived method;
source provenance is ordinary engineering plus actual downstream code lifecycle.
