# Independent academic Brain round 5 — private author receipt

Date: 2026-10-09. Author: academic_brain_loop. Status: PROPOSAL ONLY; not registered, implemented, built, or measured. Corrected source baseline: `72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7`. Exactly three ranked methods follow; **select A only**.

## Evidence and ownership check

Read the optimization-loop policy and independent-agent policy, corrected application/solver source, and GitHub open AND closed issue/PR listing 1–88 plus latest hub15 page3. Claims checked include GH52/53/55, GH60/63/64, GH69, GH71/73/75/76/78/79/85/87. No competing MTO-only balanced-stabilizer association selection was found in that snapshot. Recheck claims before registration. Peer review_agent_workflow was informed of this tentative selection to avoid collision with their LBD/lookahead/logical-CNF alternatives.

The retained GH83 audit `GH83-independent-native-tier1-retained-terminal01-audit.json`, SHA256 `203544c744af6e0bf169175c5e6aa5dc35d6814bd5899a9fb01d0b861372fe65`, authenticates 48 scientifically correct samples/192 fields. General balanced checks have numeric REJECT: OFF geometric-mean ratio 1.0866532202, MTO 0.8520294249; OFF GB144 and BB108 regress about20%. All four MTO cells have disjoint positive timing intervals, all12 paired wins and matching CPU direction. That is a mode-interaction observation, not adoption or proof of a future result. Preserve the rejected general configuration/PR84 and all negative GH64 evidence.

## A — selected, rank1: balanced original stabilizer checks only in explicit MTO mode

**Single mechanism.** Start fresh from corrected72. Use GH83's adjacent-pair XOR association only for original Hx/Hz hard parity rows in the live MaxCDCL builder when the already-resolved `card_mode == 3` (`CARD_ENC_MTO`). Keep chain association for OFF, Sinz, default BOTH, and BOTH_FORCE; do not infer that a BOTH instance will later choose MTO. Do not change cardinality selection, build a second solver, or enable split/symmetry/incremental search. Logical Gx/Gz parity remains original chain. Dump-only WCNF/OPB, RoundingSat and native-parity OPB remain original paths. This is a fresh mode-scoped configuration with a preregistered dispatch condition, not a remeasurement of GH83's rejected general variant.

**Source rationale.** `distqldpc.cc` CLI resolves `-card-mto` to3; `cardinality_mode_label(3)` is MTO only and `Solver.h` defines CARD_ENC_MTO=3. Original parity starts inputs[0] and applies xor2 sequentially. The two original stabilizer callers constrain Hx against z and Hz against x; logical callers occur separately. No engine/header/Make change is needed. Existing GH83 proof/test scope establishes a reusable design argument, not certification of the new dispatch.

**Scientific proof obligations.** Unchanged xor2's four clauses implement the exact signed XOR truth table. An induction on contiguous adjacent subtrees gives, for each leaf assignment, a unique auxiliary extension and the same root parity. Preserve original 0/1/2/3 input behavior, including the original empty-row convention; m>=4 uses m−1 gates, unchanged hard-clause count, and bounded original auxiliary indexing. Original stabilizer rows/order, x/z base variables, logical nontriviality, `(x OR z)` Pauli weight and soft weights stay fixed. Aux numbering/association may differ only on the selected live path. Output values, bounds, timeout interpretation and supported inputs remain contractual. Check overflow and live dump equivalence by existential projection, not byte equality of changed CNF.

**Why rank1.** It targets the one reproducible favorable interaction while restoring original OFF construction. It has a small application-only implementation and existing focused induction evidence. Nonetheless different clause ordering can cause MTO regressions on larger codes or alter preprocessing; no four-case observation predicts universal speedup. MTO-only dispatch must be tested explicitly, including default/BOTH_FORCE behavior. Do not stack GH41 cap, GH64 prefetch or any Mac split/symmetry method.

**Finite gates/cost.** Before CPU, root registers this receipt, creates isolated corrected72 worktree and prerecords the one source change. Source inverse must restore72 exactly; all engine/Main/Make bytes remain unchanged. Focused 72-row/9086-assignment per-role truth/projection checks may reuse authenticated original focused support with new source pins, plus explicit mode dispatch equivalence. New application full correctness must cover original 300B optimum5 crash case, adjacent11/Main semantics, partition80+1 and directed316 via explicitly authenticated unchanged baseline-engine evidence, and core corpus54 apps/allfive CLI modes,40 dump-only,30 tiny live dumps/PauliOR projections,6 genuine helper-entry checks,12 phase timeouts and2 smokes. Reuse is declared, never counted as fresh execution. Crossrepo ordinary/final-field checks are required. Root schedules bounded actual correctness; no extra infrastructure or autonomous execution.

After actual correctness certification, one original48-sample Tier1: BB90/GB144/BB108/LP238 × OFF/MTO ×3baseline/3candidate serial AB/BA/AB, same truth10/8/10/6, original180/195 caps and descriptive original judge. OFF restores baseline CNF; that is a source prediction to verify, not permission to drop OFF rows. Preregister the affected-mode decision separately: require reproducible conservative wall/CPU/pair corroboration in all four MTO cells; unaffected OFF is a control requiring unchanged semantics/construction and no serious regression beyond variability, not positive speedup in every OFF cell. All eight cells and all raw samples remain reported. The general GH83 judge/data and its rejection remain unchanged; original numeric-filter output for this new variant is retained even if it cannot classify unchanged controls as positive. Separate raw medians/ranges, CPU and conservative intervals; resource/provenance/SCI-first rules stay intact. No threshold invented after results. Stop on wrong science or confirmed serious regression, including OFF controls. No Tier2/3/adoption authorization from this proposal. Engineering cost: small core-only patch plus existing finite gates; compiler/solver work only under root assignment.

**Prior distinction.** GH83 used balanced original stabilizer rows in every live mode. This candidate uses only explicit MTO. E001 changed logical bases; E002 shared prefixes; GH60/69 changed lookahead; GH71/73/76/87 split/reused/eliminated CSS halves; GH75/85 broke verified symmetries; GH78 decomposed through automorphisms; GH79 added conjugate-coset clauses. None is part of A. This application patch belongs to DistQLDPC, not upstream MaxCDCL or a QDistSAT algorithm change.

## B — unselected, rank2: enable existing asymmetric clause shrinking before search

`SimpSolver.cc` already defines `opt_use_asymm=false`, and `eliminate()` invokes `asymmVar` only when enabled. The application calls `setFrozenVars(); eliminate(true)` before search. Candidate B would enable that existing preprocessing pass for the live application only, without changing elimination strategy or search parameters. `asymm` assumes the other literals false, propagates, cancels to0, and removes the tested literal if conflict proves the shorter clause. Potential benefit: shorter clauses reduce propagation/search; potential cost: repeated preprocessing propagation exceeds later savings. This changes shrinking rather than parity association or added clauses.

The classical hard-resolution argument alone is insufficient for this downstream MaxSAT engine: prove actual propagations/reasons are bound-independent and never derive strengthening from a soft-cost conflict, preserve frozen objective variables/model extension, and retain rollback/trail/reason invariants. Until that source obligation is closed, B is not implementation-ready. Finite next action would be source proof of the real caller followed by a bounded shrinking census and full original correctness gates; no assumed speedup. No active selected claim was found in the inspected issue snapshot. Lower rank than A because objective-sensitive propagation and preprocessing cost are less evidenced.

## C — unselected, rank3: bounded hard-only binary RUP resolvent retention

Consider adding binary hard resolvents before elimination, from pairs of original hard ternary clauses differing on exactly one complementary pivot; retain only non-tautological two-literal resolvents, deduplicate against existing clauses, deterministic original order. No logical-coset construction, objective mutation, learned/bound/cardinality clauses, auxiliary variables, or deletion. This aims to expose short implications for propagation, distinct from B's clause shrinking. Existing backward subsumption/elimination may already obtain most implications, and original XOR gates often resolve only to tautologies: useful opportunity is unproven, so first bounded source/census feasibility would reject zero surviving candidates rather than build a broad miner. Clause retention/allocator cost can dominate any search reduction; exact fixed limit and selection order would have to be preregistered before implementation.

**Recent primary research basis.** Bonacina etal., *Redundancy Rules for MaxSAT*, SAT2025 (published2025-08-07), §3 Definition3.2 and Lemma3.4 provide cost-preserving substitution redundancy; §3 Definition3.6 includes resolution derivations. C uses only the conservative identity-substitution/RUP consequence case: a hard entailment preserves every feasible assignment and therefore every existing weighted objective. It does not implement the paper's general substitution calculus or claim its proof-complexity results predict speed. Ordinary SAT redundancy without the cost condition would be insufficient. This theoretical paper supplies a soundness boundary, not a tested solver implementation or weighted-engine rollback certificate.

Primary metadata/PDF: https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.SAT.2025.7 . Primary HTML sections: https://drops.dagstuhl.de/storage/00lipics/lipics-vol341-sat2025/html/LIPIcs.SAT.2025.7/LIPIcs.SAT.2025.7.html . No paper code copied; license of any external implementation is not assumed.

```bibtex
@InProceedings{bonacina_et_al:LIPIcs.SAT.2025.7,
  author = {Bonacina, Ilario and Bonet, Maria Luisa and Buss, Sam and Lauria, Massimo},
  title = {{Redundancy Rules for MaxSAT}},
  booktitle = {28th International Conference on Theory and Applications of Satisfiability Testing (SAT 2025)},
  pages = {7:1--7:17},
  series = {Leibniz International Proceedings in Informatics (LIPIcs)},
  year = {2025}, volume = {341},
  editor = {Berg, Jeremias and Nordstr\"{o}m, Jakob},
  publisher = {Schloss Dagstuhl -- Leibniz-Zentrum f{\"u}r Informatik},
  doi = {10.4230/LIPIcs.SAT.2025.7},
  URL = {https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.SAT.2025.7}
}
```

Decision: **A only**. B/C remain unselected; no source edits, workload, issue/PR creation, publication or new result is asserted by this private receipt. Root owns registration, actual gates and indices.
