# Independent review Brain after GH44: fixed lower ISA without new FMA

Owner review_agent_workflow; hub15. DistQLDPC is downstream instrumented
MaxCDCL-derived distance application, QDistSAT its separate benchmark platform;
neither identical to upstream MaxCDCL. Fresh baseline
24572d6d09cce9a4a5faa58300a89e0feba9da6a, no previous patches stacked. Source and
metadata only: no named host, build/probe/test/performance NOT_RUN. Preserve all
scientific distance/CSS/PauliOR/logical/weighted-cost/model/bound/timeout/result
semantics, ground truth/correctness assumptions and upstream attribution.

Exactly three independently ranked proposals:

## A rank1 SELECTED — original GCC O3 plus fixed x86-64-v2

One concept: append ONLY `-march=x86-64-v2` to baseline Makefile CXXFLAGS. Same
GCC14.4/originalO3/generic tuning/language/ABI/GNU linker/zlib/runtime/source/FP
policy. No native tuning, v3 flag, separate FMA flag, LTO/PGO/Clang/fast-math,
solver heuristic or code optimization. It is a separately registered lower-ISA
target from baseline, not a v3 candidate repair or selected subset of its cases.

Mechanism: enable SSE3/SSSE3/SSE4.1/SSE4.2/POPCNT/CX16/LAHF instruction availability
without enabling AVX/AVX2/FMA. May improve integer/vector code while retaining
original separate double arithmetic contraction availability. GCC level targets
have generic tuning; fresh actual installed default target/tuning/FP/macro proof
required. No demonstrated vectorization or speed estimate. Codegen/layout can
still regress; source-byte identity is not a scientific equivalence proof.

New evidence compared with older native-ISA unselected proposals: GH44 v3 full
Tier0/all48science PASS but global switch rejected with disjoint OFF+14/+15 and
GB144MTO+30% regressions, although MTO benefits on other cases were large. Retained
BB90OFF repeat1 counters differ: baseline nbLK51547/nbLKup25033733/hardConflicts1663
vs v3 nbLK55629/nbLKup27775696/hardConflicts1787. Thus actual search trajectories
changed, not just walltime. Original FP contraction fast and newly available FMA
are plausible explanations; this DOES NOT prove FMA caused any change, nor predict
v2 benefit. Layout/compiler scheduling remain alternatives. Lower ISA supplies
information about a materially different codegen regime with low semantic risk.

Relation to previous attempts: explicitly reranks ISA family previously unselected
GH21-B/GH36-B/GH41-B. Actual v3 selected GH44 is locally rejected, not universally
disproved; no exact v2 claim appears in all-state shared search. Distinct from
GH32 mtune-only and GH38 Clang (both locally rejected). No adaptive per-case/mode
choice and no fallback composition; evaluate all four cases and both modes.

Origin ordinary compiler engineering: GCC official14.3 x86 level target docs and
Optimize options, read2026-10-09. Documentation version is not installed14.4
proof. Academic Bib for selected mechanism NOT_APPLICABLE:
https://gcc.gnu.org/onlinedocs/gcc-14.3.0/gcc/x86-Options.html
https://gcc.gnu.org/onlinedocs/gcc-14.3.0/gcc/Optimize-Options.html

Scope one Make option; every src/solver/core Git byte and MODIFICATIONS/NOTICE
unchanged. Candidate hardware portability remains restricted: portable exact CPUID
v2 feature gate on selected CPU BEFORE candidate execution/ABI probe/builded-app
run. No need to execute XGETBV for v2, but retain CPUID leaf availability checks;
verify actual candidate target macros have no FMA/AVX and original generic/FP
policy. Original allocator/defaultlink/PE/liveDLL/runtime and full source/object
provenance frozen. Full j1 clean builds, bounded <=2700s Tier0, estimate a few hours
preparation plus one local slot. Gate unsupported CPUs as compatibility INCON,
never bypass or label an illegal-instruction crash scientifically acceptable.

## B rank2 UNSELECTED — fixed doubling Vec capacity growth

One concept if later selected: change only common vec<T>::capacity's geometric
growth from approximately3/2 to2 while retaining logical size/elements/destructor/
realloc/error semantics and even capacities. Source Vec.h computes even add from
min_cap and old cap; many independent vectors allocate through this path.
Hypothesis fewer geometric reallocations/copies reduce repeated memory management
at cost of retained capacity. This is distinct from active GH46 lookahead-only
capacity retention and rejected/shelved GH17 caller scratch; no buffer lifetime
changes, pooling, preallocation or other allocator. It is NOT demonstrated hot.

Prerequisite targeted baseline count of actual allocation events/requested bytes/
simulated saved reallocations/retained peak for this single global growth policy,
four bounded LP34/LP136 OFF/MTO diagnostics, never production/timed instrumentation.
Proof must preserve int overflow handling before computing doubled add, cap even
invariant/max-size push assumptions and all call/pointer alias constraints; full
container state/lifetime/OOM tests plus scientific tiers. Changed allocation
lifetime/address schedule might reveal illegal alias assumptions; do not waive
them as ordinary performance changes. Larger memory could regress caches/OOM;
zero/negligible practical opportunity shelves before timing. Estimated2days,
broader lifetime risk than selectedA. Ordinary engineering/BibNA. Unselected only.

## C rank3 UNSELECTED — fixed original restart base100→200

One concept if later selected: original opt_restart_first default100 becomes200;
existing Luby factor/inc/phase/learning/core/bound logic otherwise untouched.
Hypothesis fewer repeated restarts retain useful deeper search, balancing clause
learning. Actual existing per-run starts/UP/LK statistics motivate counting but
do not prove a restart bottleneck or predict speed. It changes search policy and
can cause severe case/mode divergence, as GH30 +114% and GH44 demonstrate.
Audit original nested search budget and termination/progress assumptions, full
weighted/unweighted PMS/CSS/bounds/model/timeout/rollback correctness; exact result
semantics unchanged. No simultaneous VSIDS/LRB/ccmin/FLA/cap/encoding change and
no sweep of restart parameters. Estimated2–3days; highest performance/search risk.
All-state rfirst search empty; standard technique, no new academic-method claim.
Ordinary source-path experiment/BibNA. Unselected only.

## Recent academic reading and limits

LoMax (2026, within two years) official publisher abstract/data-availability read:
local function scoring/rewrite and progressive correctness/performance validation
is relevant to this existing loop, but it does not supply selectedA or assert
MaxCDCL-specific improvement. Only abstract/publisher metadata read; linked artifact
repository https://github.com/f-f-g/LoMax returned404, so no full patch or code
adaptation claimed. Record Bib entry; do not invent its optimized function.
https://doi.org/10.1002/cpe.70926

```bibtex
@article{gao2026lomax,
  author = {Gao, Fan and Huang, Yanhong and Li, Jianwen and Shi, Jianqi},
  title = {LoMax: LLM-Driven Local Code Optimization for MaxSAT Solvers},
  journal = {Concurrency and Computation: Practice and Experience},
  volume = {38}, number = {17}, pages = {e70926}, year = {2026},
  doi = {10.1002/cpe.70926},
  url = {https://onlinelibrary.wiley.com/doi/10.1002/cpe.70926}
}
```

AAAI2025 unlocking lower-bound paper was identified during search, but the original
source already has unlockReason/quasi-conflict machinery and activeGH26 proves a
related FLA concept. PDF retrieval failed in this reading; no new unlocking method,
implementation, novelty or transplant is proposed here. A paper title alone is
not enough provenance for a solver change. The three actual proposals above are
ordinary program/source optimizations, not asserted adaptations of these papers.

## Shared history and scientific protocol

GH44 exact e94633d/all958 raw Git blobs retained; full48 scientific results good,
OFF GM+6.076%/MTO−6.777% mixed and serious three regressions, globalLOCALREJECT,
noTier2/3, formalcontrolledINCON. GH40 all8disjoint slower; GH38Clang localreject;
GH32mtune reject; PGO/O2/GH27/Mac mirror controlled gains unresolved. Tiny saved
operation/allocation counts are not a time-share proof. GH36generic cap rejected
OFF serious regressions; separate GH41 MTO cap activeLinuxTier0 retries.
GH46 lookahead-only learnt scratch activeWindows queue; GH26 weightedFLA proof
open; externalMacGH34 independent. No accepted optimization, no stack/duplicate
selected claims. Read hub/current issues/open+closed selections before claim;
issue truth outranks concurrent shared STATE edits. Lower issue owns exact duplicate.

Prerecord in fresh own issue/worktree/branch from245 BEFORE Makefile edit; no
sharedSTATE/HYPOTHESES changes. No CPU/build/probe/test/profile/timing until named
assignment after actual previous owner absence/owned-empty/restoration release.
Team global spare>50%, allocation<=halfspare; one serial worker/host, one bounded
Job CPUAboveNormal/2s samples; production candidate hook-free.

Tier0: fresh CPU/installedflags/FP/macro/ABI/runtime/link/source/object proof first,
then original fullCSS three independent Pauli oracles/fivebuildermodes (30 solves,
15 identicalWCNFpairs),2smokes,8LP34/136production,72standalonePMS/36truths,
12genuineproduction and deterministic isolatedpre/post-modeltimeouts. Every interim
LB/UB/d/objective/status/return malformedoutput checked; wrongscience/crash STOP
REJECT andnotify, ordinarycoverage/build/provenance failure retainedINCONCLUSIVE.
Required source-pinned gated ordinaryCI/QDistSAT checks+rawretention; CIelapsed not
performance. Testsymmetricalshim/hookobjects isolated fromproduction.

Only afterfullTier0 andfreshslot: fixedfourcase OFF/MTObaseline3candidate3=48
AB/BA/AB180/195/10800. Exactraw/medians/ranges/science/identities/resourcescleanup
retained, originalnumericjudge unchanged. Reproducible positive direction/no serious
regression fornormalpromotion; no posthocgroups/repeatuntilwin/no automaticadoption.
Controlled acceptance requires actualcontrolled/robustness evidence, not simply
matchingresults. Tier2 LP34012 600/615 onlynormalgate or separately justified user
one-tierexception if notdirectlydenied; neverlabelINCON asPASS. NoTier3 now.

SelectedA currently UNIMPLEMENTED/UNTESTED. Next isolated prerecord/source-only
portable-v2/actualflags driver then serial bounded Tier0 assignment; rootGH46queue
respected, no Linux/Windows work piggybacked onanotherowner.
