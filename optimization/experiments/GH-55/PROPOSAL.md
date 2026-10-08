# GH55 prerecord (before implementation)

Issue https://github.com/guluchen/DistQLDPC/issues/55; hubclaim6070380729.

# Independent review Brain after finite GH48: measured memory work

Owner review_agent_workflow, hub15. Fresh baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a;
no prior ISA/compiler/solver change composed. DistQLDPC is the downstream
MaxCDCL-derived application with its own instrumentation; QDistSAT is its separate
benchmark platform. Neither is interchangeable with upstream MaxCDCL/WMaxCDCL.
This prerecord precedes any implementation. Source/research only, no CPU slot.

Exactly three ranked methods:

## A rank1 SELECTED: fixed doubling for common Vec capacity growth

One conceptual change in src/solver/mtl/Vec.h::capacity(int): use an even doubling
growth increment when doubling fits signed int; retain original initial2 and
original3/2 growth fallback when doubling cannot fit. Keep original min-required
rounding, existing INT_MAX guard, realloc/exception handling, logical size,
construction/destruction/copy/move/clear/pop/push and all other solver code.
No scratch reuse, lifetime retention, pooling, allocator replacement or preallocation.
The unused nextCap helper is not a refactoring target. Update MODIFICATIONS/NOTICE
as appropriate for this embedded downstream patch, preserving all upstream licenses.

Mechanism: fewer geometric realloc calls for vectors repeatedly growing beyond
small initial capacities, at the cost of larger retained capacity. Actual default
capacity sequence for pushes begins2,4,8,14,22,34; doubling would start2,4,8,16,32.
This targets real allocations across many solver vectors rather than one assumed
duplicate instruction. Realloc may grow in place, so requested bytes do not prove
copied bytes or time share. No current measured allocation opportunity/speed claim.
Source audit finds only two explicit capacity(v+1) calls, both trail reservation;
no external capacity() read in src. Audit every push_/alias/relocation assumption.

Prerequisite bounded BASELINE-ONLY engineering allocation census on four fixed
LP34/LP136 OFF/MTO cases, with authenticated observer source/objects isolated from
production. Count actual realloc events, old/new capacities, requested byte totals
and type-size bins; report observer science against known distances but do not call
that production correctness PASS or performance. Allocation events beyond oldcap8
are the first normal push opportunity; if absent, shelf before candidate timing.
Do not replay only realloc events and claim exact hypothetical savings: missing
logical demands and differing capacities can invalidate such a reconstruction.
No predicted saved-copy time/CPU threshold invented from event counts. Only use a
full demand trace or paired deterministic container tests for exact replay claims.

Correctness proof/tests: even cap<INT_MAX preserves push sz+1 invariant; doubling
only cap<=INT_MAX-cap avoids arithmetic overflow, otherwise original fallback;
capacity>=min_required, identical size/order/elements/destructor/copy/move behavior;
both push overloads, push_, growTo padded/default, shrink/shrink_, clear(true/false),
explicit reserve, relocation-safe types, near-int arithmetic without huge allocations,
and faithful OOM behavior. Larger memory may cause OOM/cache regressions; no failure
is hidden or relabeled as a valid scientific result. If any caller depends on
capacity-derived behavior or invalid aliases, repair within this concept or withdraw,
not weaken correctness assumptions. No extra nextCap/header refactor.

Rerank disclosure: previously UNSELECTED GH48-B, not novel. New choice motivated
by GH48 finite nearzero results and GH50 proving actual generated ForLK bytes and
relocations identical for a duplicate-value source optimization. GH17 caller
scratch saved only9/328 predicted allocations and GH46 scratch-lifetime proposal
is distinct. Search all open/closed issues for growth/doubling before claim; no
selected doubling owner found. Expected effect is broader repeated-allocation
work on medium/large cases, not a demonstrated hot function. Cost1–2days preparation,
one bounded engineering/correctness slot, then standard48 only if all gates pass.
Ordinary program optimization; paper-derived mechanism/Bib NOT_APPLICABLE.

## B rank2 UNSELECTED: original restart-first100→200 only

Explicit rerank GH48-C, not new. Change only the default rfirst literal; Luby,
increment, phases, learning, bounds/cardinality unchanged. Intended fewer restarts
and repeated search setup, but actual starts/search counters must justify opportunity;
no measured bottleneck or win claimed. It is distinct from active GH53 ccmin2→1.
Audit nested budgets/termination/progress and all scientific weighted cost/rollback/
model/bounds/timeout semantics. GH30/GH44 search divergence warns of substantial
case/mode regressions. No parameter sweep. Cost2–3days/high search risk, BibNA.

## C rank3 UNSELECTED: memoized BDD cardinality encoding research

Potential one concept: a reduced ordered BDD encoding of the exact existing
active-soft cardinality bound, preserving literal list and k; no stronger bound,
lookahead/restart/logical/Pauli change. Use existing Pauli-weight indicators, never
assume X and Z are mutually exclusive (Y is allowed). Unit-weight cardinality
may permit polynomial state reuse, but construction/clauses/search can regress.
Mode/logging/CLI compatibility must be resolved explicitly before implementation;
do not silently mislabel an encoder or change legacy result semantics. Exact tiny
assignment equivalence, preprocessing/frozen-objective/auxiliary lifetime and
every bound/parenttimeout proof required. No implementation/API transplant selected.

Research origin: Vandesande, Coll and Bogaerts, AAAI2026, sections4.1–4.3, describes
reduced BDD construction, memoization of equivalent suffix bounds and CNF encoding
as part of certifying BnB MaxSAT. Their study primarily concerns proof logging,
not a promised DistQLDPC speedup. BDD encoding itself predates this paper; this is
not a novelty claim, and upstream WMaxCDCL is not our downstream solver. Original
PDF sections read; only unselected adaptation, no proof-logging bundle. MDD grouping
needs additional at-most-one facts absent for raw X/Z, so do not assume it applies.
Cost3–5days/higher encoding and compatibility risk, hence unselected.
https://ojs.aaai.org/index.php/AAAI/article/view/38449/42411
https://doi.org/10.1609/aaai.v40i17.38449

```bibtex
@inproceedings{vandesande2026certified,
  author = {Dieter Vandesande and Jordi Coll and Bart Bogaerts},
  title = {Certified Branch-and-Bound MaxSAT Solving},
  booktitle = {Proceedings of the AAAI Conference on Artificial Intelligence},
  year = {2026}, volume = {40}, number = {17}, pages = {14342--14351},
  doi = {10.1609/aaai.v40i17.38449},
  url = {https://ojs.aaai.org/index.php/AAAI/article/view/38449}
}
```

Other recent primary reading: IJCAI2025 CASHWMaxSAT (Pan/Wang/Cai) extended weight
stratification and disjoint-core integration, abstract only, not adapted. Original
application soft objective is unit-weight; high-weight priorities do not directly
justify a speedup here. DeepDist ECAI2025/arXiv2512.05619 abstract revisits SLS
weighting and hybrid warm starts, not selected; preserve earlier selected SLS
hypothesis ownership and do not present generic warm start as novel. These are
research context, not extra proposed optimization methods in this three-method round.
https://www.ijcai.org/proceedings/2025/295
https://arxiv.org/abs/2512.05619

## History, scientific gate and resource protocol

Read AGENTS/README/MODIFICATIONS/NOTICE/crossrepoCI/loop policy, sharedSTATE/HYPOTHESES
78f3081 and latest hub issue truth (snapshot may be stale). GH48 all1014raw aa2c21e
finiteT2 all12sciencePASS/OFF+0.707%/MTO-0.434%overlap/formalINCON/practicalSHELVE;
no useful material gain established/noT3. GH50 exact1168ForLKbytes/3relocs identical:
SHELVE before timing, originalGCC already eliminates the assumed duplicate. GH41
completed LinuxLP340 reported SPECIALIZED_DIAGNOSTIC pending independent whole-raw
audit, no adoption/T1promotion/T3. Earlier PGO/O2/inline/Mac gains controlled-unproven;
globalmtune/Clang/v3/ternary/activity patches rejected or shelved, never stacked.
ActiveGH53 owns basic ccmin; GH26 weightedFLA proof unresolved; no exact duplicate claim.

IMPORTANT GH46 anomaly remains visible/unresolved: valid10variable15hard13unitsoft
WCNF family1-variant1, independent optimum5/witness472, crashed original baseline
and observer baseline, candidate not executed on that failure. It is not upstream
MaxCDCL evidence or candidate-caused result. Never omit/waive that valid fixture,
silently narrow accepted domain, or promote through the unresolved correctness gate.
SelectedA does not fix it or claim it explained. Any full Tier0 must include it;
if correctness cannot be established, retain gateREJECT/INCON and stop performance.
Engineering allocation/code/container observations cannot substitute for science.

Register own new issue/hub claim before production edit; fresh own worktree/branch
from245, exclusive experiment ownership, issue truth instead of sharedSTATE edits.
No build/observer/container test/solver/performance until named host assignment;
source/research only now. Team aggregate spare>50%, <=halfspare, one serial worker
perhost, boundedJob/ownedcleanup or reviewed installed Linuxlease; no CPU from
another owner's window. Peer review source and frozen provenance before launch.

Full correctness includes original CSS/Pauli/logical/groundtruth/weights/cardinality/
model/lower-upper/timeout/status/return behavior, independent PMS/CSS oracles,
original smoke and true pre/postmodel timeout coverage, plus knownGH46 validfixture.
No semantic mismatch/crash/bound regression proceeds to performance; failures
durably retained, attribution preserved. Hosted source-pinned ordinary+QDistSAT
required selected short science; CIelapsed never speed evidence. No paidcloud substitute.

Only after actual Tier0 PASS: standard48 OFF/MTO3+3ABBAAB180195, exact four cases,
original numeric criteria/rawallgroups. Material gain beyond variability/no serious
regression for normal promotion; observedquietness not controlled acceptance.
Tier2LP34012 only normalgate or separatelypreregistered userone-tier exception,
never call INCON asPASS. NoTier3 now/adoption without supporting controlled evidence.
Durable actual rawGitblob hashes/manifests/allargv/input/source/bin/runtime/resource/
cleanup/medians/learning, including failed/engineering attempts. Priorrecord preserved.
