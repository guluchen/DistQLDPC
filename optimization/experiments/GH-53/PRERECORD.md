# Independent Brain round7: existing basic conflict minimization default
Owner independent-brain-20261009-round7; fresh24572d6d09cce9a4a5faa58300a89e0feba9da6a. DistQLDPC's downstream instrumented/optimized MaxCDCL-derived engine and QDistSAT benchmark platform remain distinct from upstreamMaxCDCL. Preserve scientific/CSS/QECC/PauliOR/logical/weighted-objective/model/bound/timeout/result assumptions and upstream attribution. No prior patches stacked, no CPU slot.

Exactly THREE ranked methods; only A selected:

## A rank1 SELECTED: existing ccmin-mode default2(deep)→1(basic)
Change ONLY the default literal of opt_ccmin_mode in Solver.cc131 from2 to1. Keep option range0..2, Solver constructor/caller/helper code, triggers, clause learning, LBD/binResMinimize, bounds/restarts/activities/cardinality/compiler unchanged. Original standalone Main's existing explicit option override remains supported; DistQLDPC application's CLI does not parse that solver option, so do not invent a new application flag.

Mechanism: two actual downstream call paths simplifyConflictClause2422 and simplifyQuasiConflictClause4427 select existing basic local reason-clause tests rather than deep recursive litRedundant stack traversal. Basic may save conflict analysis work while keeping longer learned clauses, changing subsequent search. This is NOT an identical-search storage/codegen experiment: compare scientific correctness, learned-clause implication and rollback invariants, not require identical activities/search trajectory or clause length. No new minimization algorithm, no mode0 disabling, no sweep, no retry selected cases/mode-specific auto-selection or other patch.

Expected cases with substantial recursive redundancy analysis, OFF/MTO uncertain; existing counters/timing do not establish that bottleneck. Longer clauses/more propagation/conflicts may outweigh saved analysis, including serious medium-case regressions (GH30 lesson). Cost1–3days proof/test preparation plus assigned bounded tiers; semantic risk actual learned reasons/core/aux-variable context, performance risk search divergence. Require actual constructor default1/default2 proof, both simplification helper paths and literal removal/retention cases, exact tiny hard+bound formula entailment checks for derived clauses, weighted-cost/model/allbound/timeout/PMS/CSS oracles, legal reasons/backtrack/seen cleanup. Existing compiled basic path is starting evidence, NOT correctness certification. Explicit rerank GH46-C previously UNSELECTED, no selected ccmin claim found.

Why A now: GH50 actual originalGCC alreadyCSE and GH27/GH40 operation reductions do not predict speed; try a measurable existing algorithmic work/learned-clause tradeoff instead of another source rewrite likely compiled away. Higher search risk is deliberate and requires stronger science gates. Ordinary existing-source configuration, NOT a transplant from a paper.

## B rank2 UNSELECTED: demand dirty watch cleanup only propagateForLK
Explicit rerank GH17-B/GH20-C/GH27-B/GH44-B/GH46-B/GH50-B. Use existing lookup(p) on reached watcher lists instead of entry globalcleanAll. Needs actual dirty/reached/avoided work counts and full direct-consumer/deletion/append/GC/reset proof; binResMinimize uses watches_bin directly, pending bound-specific deleted clauses cannot be assumed safe. Globalcleanup usuallyempty or latercleanup mayerase total savings. Withdraw if broad redesign/additional changes required. Higher cross-lifetime correctness risk/cost2–3days, no hotness/cache/speed claim, engineering/BibNA. Unselected; not implemented.

## C rank3 UNSELECTED: exact size2 computeLBD loop specialization
Rerank GH50-C: two explicit original loop bodies only for exactly2literals, retain one counter increment and both seen2 comparisons/writes/zero-level conditions, including prior stamps/unsignedwrap; genericloop unchanged otherwise. No approximate LBD or heuristic threshold. Actual GCC may already unroll/CSE; mandatory installedcodegen and observed size2caller opportunity first. Extra branch/inlining can harm allotherclauses. Return/counter/allstamp array and laterconsumer comparisons required across zero/equal/different levels/wrap. Cost1–2days; engineering/BibNA. Unselected.

## Attribution/source and literature limits
Read original245 option/constructor/litRedundant/bothsimplification paths, repository AGENTS/README/MODIFICATIONS/NOTICE/cross-repo/optimization policy and shared open+closed issue selections. Source header attributes Maple_LCM learnt-clause minimization to Luo etal IJCAI2017. Official publisher abstract/bibliography read2026-10-09: paper uses BCP minimization around selected restarts, not proof that basic ccmin implements the paper or preserves downstream weighted-core invariants. Olderthan2years; this is NOT a recentMaxSATpaper adaptation. Recent CP2026FLA owned GH26, newer academic propagation proposalGH52 separate. Record exact attribution Bib instead of inventing academic method:
https://www.ijcai.org/proceedings/2017/98

```bibtex
@inproceedings{Luo2017LearntMinimization,
 author={Mao Luo and Chu-Min Li and Fan Xiao and Felip Many{\`a} and Zhipeng L{\"u}},
 title={An Effective Learnt Clause Minimization Approach for CDCL SAT Solvers},
 booktitle={Proceedings of the Twenty-Sixth International Joint Conference on Artificial Intelligence},
 year={2017}, pages={703--711}, doi={10.24963/ijcai.2017/98},
 url={https://www.ijcai.org/proceedings/2017/98}
}
```

## Learning, duplicates and unresolved baseline anomaly
GH50 engineering-only exactForLK1168bytes+3relocs identical/originalGCCalreadyCSE; SHELVED/no48timing/scienceNOTTESTED. Public70originaltext+original73hashcatalog008aa87/exact71publicGitblob audit6a64fe4; actual3objects local afterbinaryexportapprovalrejection, safepublication limits explicit. GH46 gateREJECT/noallocations: valid unit-weight WCNF family1-variant1 optimum5/witness472 unchanged baseline Main+observer2816/nofinal, candidate notrun. Input/science anomaly retained589raw3de3bea/auditc397b7e, no unsupportedwaiver/drop/groundtruthchange/semanticrepair or upstreamMaxCDCLcause claim. This new optimization does not resolve the baseline anomaly and MUST NOT claim complete certification/promote through unresolved correctness.

GH38/32/40/44 negative fixedconfigs, GH17low saved allocations, PGO/O2/GH27 noisy unsupported gains; none adopted. GH41MTOrowcap Linuxexploratory active, GH48fixedv2 exploratory queue, GH34Macmirror, GH52deferredsoftstop separate, GH26FLAproof priorheld. All-state ccmin/basicminimization/demandcleanup/computeLBD searches checked; only unselected ccmin GH46. Reread afterregistration; lower issue wins sameconcept selected collision. No sharedSTATE/HYPOTHESES/rootcheckout edits.

Preregister own record BEFORE exactlyone default literal sourceedit in fresh245 worktree/branch; update downstreamMODIFICATIONS/NOTICE preserving original headers. Prepare source/entailment/test proof metadata only; no build/solver/instrumentation/timing until named scheduler slot. First actual sciencegate must explicitly account for known valid baseline anomaly, not silently remove it. No normal performance promotion while correctness unresolved.

Tier0 builds/smoke/fullCSS3independentPauli truth×fiveactualCLI/15WCNFpairs/originalMainweighted-PMS/constructor andbothhelpers/complete per-clause implication/lifecycle/seen rollback/status+allinterimfinalbounds/genuineprepostmodeltimeouts and required actual-source CI/QDistSAT. Wrongscience/crash/output regression STOPREJECT; proof/engineering/coverage gapsINCONCLUSIVE. Counter-only work observations isolated from production/timed code.

Only after actual correctness established/new namedslot: originalfixedfourcases OFF/MTO3+3ABBAAB48/internal180external195/allraw/medians/ranges/unchangednumericjudge, no posthocgroups/repeatsuntilwin. Positive reproducible/no serious regression required; controlled conclusion requires controlledcorroboration. Separate ONE exploratoryLP340 userexception only if cannot directly denybenefit/prerecord+newslot; noautoTier2/3. Globalspare>50/team<=halfspare/oneworker perhost/oneCPUJob2stelemetry/all4restore/actualownedabsence/pinnedruntime/source/bin/input. No expensive decisive set/paidcloud/broad parameter sweep.
Current A SELECTED/UNTESTED; no candidate/PR/host/benchmark yet.
