# CSS/qLDPC construction coverage

Continuous library goal, started 2026-10-29. This is a working acceptance
ledger, not a claim that all CSS codes or all papers have been covered.
The goal remains open until each applicable missing construction below has
representative reproducible inputs and completed validation. A documented
scientific/availability limitation requiring a PI decision remains an open item. Discovering another
major omission adds a row; it does not silently shrink the goal.

## Acceptance criteria

For each construction, record published parameters and distinguish exact
distances, lower bounds and heuristic upper estimates. Generate all four
matrices from published mathematics with original scripts; record provenance
and redistribution terms. Check GF(2) commutation, dimensions, both logical
quotient bases and full pairing, all same-(n,k) row spaces including X/Z swap,
and suspected column-permutation equivalence. Reproduce files byte for byte.
Run serial 60-second Linux smoke with retained source/binary/input identities
and raw logs; partial or missing numeric bounds remain incomplete gates.
A published small exact-distance anchor should be reproduced. New scientific
results remain PLAUSIBLE until independently checked with GF(2) witnesses.

Target a small anchor and several sizes spanning roughly 100-3000 qubits
where the construction supplies practical examples. Preserve known published
size ranges rather than inventing scaled distance claims. A connected-case
ladder is useful; repeated equivalent inputs or disconnected copies are not
additional coverage. Prefixes identify provenance, not disjoint mathematics.

All additions remain in `data/matrices/untiered`. No automatic tier assignment,
stem rename, QDistSAT mirror, solver change or main integration. Completed work
branches can accumulate while PI integration is pending. Heavy validation
becomes an exact reproducible server job package; no Mac solver experiments.

## Current evidence snapshot

Base main `6083e662c621f3b66defd434cfae31a028d483c4`: 51 tiered codes and
24 untiered codes. The separate GH-160 branch contains six more BP inputs;
those are not part of this branch or main. GH-164 contains six BB inputs on its separate reviewed work branch.
GH-165 adds four hyperbolic inputs on its separate work branch.
GH-166 adds six nonabelian ZSZ-LP inputs on its reviewed work branch.
GH-167 has six pair-partition CPM inputs on its separate work branch. GH-168 has six periodic toric inputs on its separate work branch. GH-169 has six finite-group Tanner inputs on its separate work branch. GH-170 adds four quaternary group-valued PP inputs on its separate work branch. GH-171 adds four divisor-driven cyclic GB inputs on its separate work branch. GH-172 adds six triangular4.8.8 inputs on its separate work branch. GH-173 retains six Gallager-LDPC-factor HGP controls on its separate work branch. GH-174 adds four first-distinct-column HGP inputs on its separate work branch. GH-175 adds six periodic4D toric inputs on its separate work branch. GH-176 adds six explicit covering-graph BB inputs here, taking this branch's untiered inventory to30. Counts measure files, not families.

| Construction class / specialization | Coverage and remaining work | Evidence |
|---|---|---|
| Bivariate bicycle (BB), ordinary weight-6 | Existing tiered family | `NOTICE` section 5, tier0..tier5 |
| Generalized bicycle (GB), cyclic two-block | Existing tiered family; GH-171 adds four fixed divisor-driven cyclic examples n46/66/90/170, independent source/algebra/logical/duplicate checks and all numeric Linux smoke gates pass; both engines reproduce exact8/7/10/8 with GF(2) words; separate work branch only | `NOTICE` section 5; Lu et al. [2608.09115](https://arxiv.org/abs/2608.09115) supplies these fixed cases (v3) |
| Lifted products (LP), existing cyclic lifts | Existing tiered family; not a substitute for nonabelian group examples | `NOTICE` section 5 |
| Quantum Tanner codes | Existing TN family; must not describe it as absent | `NOTICE` section 5 |
| HGP, repetition factors / planar surface specialization | Six inputs n=13..1105 on main; largest default smoke lacks numeric bounds, supplemental [9,26] | GH-153, `untiered/README.md` |
| HGP, cubic-graph cycle factors | Six inputs n=45..2866 on main; n=2866 default smoke lacks bounds, supplemental [5,8] | GH-154, `CYCLE_HGP.md` |
| HGP, genuine degree-three Gallager LDPC factors | GH-173: six fixed first-seed(3,4) ensemble factors, N80..2897; all algebra/44 units/regeneration and Linux classical-product+both-engine exact proofs pass, d2/2/2/4/2/2. Five factors have duplicate columns. VALID_UNEXPURGATED_CONTROLS, neutral for distance growth; those controls alone did not supply a finite distance step. GH-174 adds four explicit conditional-ensemble cases N356..2384; first-admissible replay/algebra/44 units/regeneration and all numeric Linux smokes pass; complete classical-product proof plus CC confirm d4/4/6/6 with GF(2) words, MaxSAT exact first two and[5,6] last two. Two optional MaxSAT-only reproduction jobs packaged; finite distance step only, no deterministic/asymptotic guarantee. Typical ensemble growth is not a finite-seed guarantee | Gallager1963 Sec2.2/Theorem2.4; Tillich–Zemor [0903.0566v2](https://arxiv.org/abs/0903.0566v2) Theorems1/15 |
| HGP / quantum expander codes with an explicit certified growing-distance factor family | Remaining research gap. Finite Gallager samples represent genuine LDPC factors but do not establish a deterministic expander-factor family | [1504.00822](https://arxiv.org/abs/1504.00822) |
| Color codes, triangular 6.6.6 | Six inputs n=7..2791 on main; n=2791 numeric upper-bound smoke gate incomplete | GH-156, `COLOR666.md` |
| Color codes, 4.8.8 / closed higher-genus variants | GH-172 static triangular4.8.8 cases n31..2887 from explicit published coordinates, independent wedge/GF(2)/full-logical/upper-word checks,44 units and24-file regeneration pass; both engines exact7/11 on n31/71, CC-only exact19 on n199 PLAUSIBLE; MaxSAT numeric gates n1567/2887 INCOMPLETE, seven unresolved proof jobs packaged. Closed higher-genus color-code variants still missing; not a new independent family | Shutty [2609.21376v3](https://arxiv.org/abs/2609.21376v3) AppendixD; closed color topology source still to resolve |
| BB on twisted quotient tori | Six published inputs n=30..340 on main, all numeric smoke gates passed | GH-159, `TWISTED_TORUS.md`, [2503.03827v3](https://arxiv.org/abs/2503.03827v3) |
| Tanner-cycle balanced product, cyclic action | Six inputs n=78..962 on `codex/balanced-tanner-library`; five distances cross-checked, largest CC-only exact pending independent completion | GH-160, [2012.09271v3](https://arxiv.org/abs/2012.09271v3) |
| Weight-8-check BB | GH-164: six published examples at n=72,144,200; all exact claims reproduced by both engines, GF(2) witness audit passes; work branch only | `WEIGHT8_BB.md`, [2609.06572v1](https://arxiv.org/abs/2609.06572v1) |
| Periodic toric codes | GH-168: six periodic square toric inputs n18..2888,k2; all six both-half distances independently confirmed by internal signed-cover BFS/GF(2); both CLI engines exact first four, numeric gates n1458/2888 incomplete, three server jobs prepared. Planar repetition-HGP alone did not provide this topology | Kitaev [quant-ph/9707021](https://arxiv.org/abs/quant-ph/9707021) |
| Closed hyperbolic surface codes | GH-165: four {5,4} inputs at n=60,160,360,1800; independent quotient/manifold and both-half graph distances pass. Both engines solve first three; n=1800 numeric smoke incomplete after bounded diagnostics, server package prepared. Published n=1920 normal-closure ambiguity awaits PI decision | Breuckmann-Terhal [1506.04029v2](https://arxiv.org/abs/1506.04029v2) |
| Nonabelian balanced / lifted products and ZSZ-LP | GH-166: six published nonabelian ZSZ-LP cases n=160..775; all numeric smoke gates and upper witnesses pass. Two-engine d=10,12; CC d=14 pending other engine. Stronger open-code CC lower bounds marked PLAUSIBLE; seven exact-proof jobs packaged; cyclic GH-160 alone did not complete this coverage | Hong [2607.27644v1](https://arxiv.org/abs/2607.27644v1) |
| Moderate-blocklength Quantum Tanner from new finite groups | GH-169: six fixed nonabelian group/local-code inputs n288..864, source numeric parameters pinned and both source stabilizer spaces proved equivalent after explicit group enumeration. Independent inverse-permutation/column pullback,46 units, algebra/regeneration and all numeric smoke gates pass. Overall source upper words15,18,18,18,9,27 GF(2)-verified; CC-only exact9/lower improvements PLAUSIBLE,11 unresolved proof jobs packaged. Retain heuristic d as upper estimates | Mian et al. [2608.12509](https://arxiv.org/abs/2608.12509); Eq.(34), Tables1/9/12 give a lifted construction with explicit permutation-group multisets and column permutations; preserve table-specific heuristic upper bounds; GH-169 fixed local matrices and right-action inverse verified against numeric source records; remaining gate status in its report |
| Pair-partition / group-valued constructions | GH-167 pair-partition CPM cases n=104,276,472,584,1112,1784: source/pairing/CSS/girth checks pass; two-engine exact8 at n104, CC-only exact16/18/20 provisional, n1784 default numeric gate incomplete and CC [22,126]; seven unresolved engine proofs packaged. GH-170 adds four quaternary trace-expanded PP inputs n256..1024 including C16 x C2; source/field/group/GF(2)/reflection/source-word checks,46 units and all numeric smoke gates pass; CC exact12 and stronger lower bounds PLAUSIBLE, seven unresolved engine proofs packaged; no disjoint-family count claimed | Okada-Kasai [2607.14091](https://arxiv.org/abs/2607.14091); Lee [2610.06820v1](https://arxiv.org/abs/2610.06820v1), Sec.V and App.D.2, supplies a noncyclic C16 x C2 PP target; numeric C16 x C2 arrays and physical witness now located in the pinned public proof-data bundle; GH-170 rebuilds four mathematical instances including this product group; repository has no LICENSE so no original matrix/proof-program redistribution |
| BB from covering graphs | GH-176 adds six fixed weight8 inputs n64..288,k14; independent physical columns, actual neighborhood bijections, connectedness and chain projection/transfer identities pass, with full logicals and no same(n,k) peers. Linux44units/regeneration/all numeric gates and actual-word audit pass. Both engines exact8/12; CC-only exact16 at n192 PLAUSIBLE; other CC intervals[18,20]/[18,22]/[18,24] retain provisional lower bounds and verified upper words. Seven unresolved engine proofs packaged, unexecuted. Exact8/12 anchors and upper estimates16/20/22/24 remain distinct; this is a BB provenance/structure specialization, not a disjoint family | Symons-Rajput-Browne [2511.13560v3](https://arxiv.org/abs/2511.13560v3), Tables7/8 |
| LLM/evolution-discovered BB | Missing discovery-provenance targets, not new mathematical families | Cruz-Benito et al. [2610.06623](https://arxiv.org/abs/2610.06623); further evolution source to resolve |
| Homological products / higher-dimensional homological CSS | GH-175 adds six periodic4D face-qubit toric inputs n96..3000,k6. Independent column reconstruction and standalone finite-matrix lower/upper certificates confirm both-half d4/6/9/12/16/20; Linux46 units/regeneration/actual-word audit pass; CC reproduces all six exact distances and MaxSAT first five. MaxSAT n3000 default smoke has no numeric fields (INCOMPLETE), one unexecuted server completion job packaged. General Bravyi-Hastings homological products remain a separate research gap; periodic4D specialization does not complete that class | Breuckmann et al. [1609.00510v2](https://arxiv.org/abs/1609.00510v2), Sec.2/Fig.1; general product [1311.0885](https://arxiv.org/abs/1311.0885) |
| Fiber-bundle and asymptotically good qLDPC constructions | Research gap: resolve explicit reproducible practical finite instances; do not replace with a cyclic toy and mark complete | Fiber bundles [2009.03921](https://arxiv.org/abs/2009.03921); good-code finite parameter availability still to investigate |

Research-target links do not imply parameter extraction or license review has
passed. The broad literature backlog intentionally remains visible, including
families for which practical finite inputs may require PI judgment. Non-CSS,
subsystem-only, gauge-fixed and circuit-distance objects cannot be silently
converted into inputs for this CSS stabilizer-distance solver.

## Execution order and durable state

1. GH-164 package complete on its work branch: independent witness audits and raw Linux logs retained. Main integration remains pending PI approval.
2. GH-165 first three cases validated; n=1800 numeric smoke remains open for the prepared server package, and n=1920 remains a PI interpretation decision. Independent ZSZ-LP work is tracked in GH-166; periodic toric references are being added in GH-168.
3. GH-166 six-input library package passes construction/numeric gates; retain its provisional scientific bounds and unexecuted proof jobs. GH-167 CPM construction and five numeric gates pass; n1784 numeric gate and independent lower-bound completions remain open with a server package. GH-168 has six internally verified toric distances; two largest CLI numeric gates remain open with a three-job server package. GH-169 finite-group Tanner numeric/construction package passes; retain provisional lower bounds and its11 unexecuted proof jobs. GH-170 group-valued/quaternary PP construction/numeric package passes; its stronger lower bounds/exact12 remain provisional with seven unexecuted proof jobs. Other remaining cases stay open, prioritizing new structure over more BB variants.
4. Cover the remaining handoff targets and genuine family gaps; repair the
   incomplete numeric smoke gates listed above using short checks or a server
   package, without reinterpreting UNKNOWN as a certified interval.
5. Audit every row and every acceptance criterion against current files and
   durable evidence before claiming the continuous goal complete.

One construction per branch/report. The next agent should inspect current
main, work branches, issues and this ledger before selecting work. Relevant
active solver topics at this snapshot: GH-148, GH-152, GH-157, GH-162; library
work does not alter their solver files or occupy their server cores.


## PI priority update (2026-10-29)

After the current covering-graph BB batch, prioritize cases whose exact
distance is unknown: published intervals, verified upper bounds or explicitly
heuristic estimates, especially substantial unresolved gaps across missing
families and sizes. Keep small known-distance anchors for correctness, but
further selection should emphasize open targets. Never promote a heuristic
claim to a verified bound without an actual checked word or search proof.
This priority supplements the full coverage goal; it does not remove open
families or waive validation, licenses, resource limits or PI decisions.
