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
GH-165 adds four hyperbolic inputs here, taking this branch's untiered inventory to 28. Counts measure files, not families.

| Construction class / specialization | Coverage and remaining work | Evidence |
|---|---|---|
| Bivariate bicycle (BB), ordinary weight-6 | Existing tiered family | `NOTICE` section 5, tier0..tier5 |
| Generalized bicycle (GB), cyclic two-block | Existing tiered family; additional published coprime/divisor examples still missing | `NOTICE` section 5; Lu et al. [2608.09115](https://arxiv.org/abs/2608.09115) is a research target |
| Lifted products (LP), existing cyclic lifts | Existing tiered family; not a substitute for nonabelian group examples | `NOTICE` section 5 |
| Quantum Tanner codes | Existing TN family; must not describe it as absent | `NOTICE` section 5 |
| HGP, repetition factors / planar surface specialization | Six inputs n=13..1105 on main; largest default smoke lacks numeric bounds, supplemental [9,26] | GH-153, `untiered/README.md` |
| HGP, cubic-graph cycle factors | Six inputs n=45..2866 on main; n=2866 default smoke lacks bounds, supplemental [5,8] | GH-154, `CYCLE_HGP.md` |
| HGP / quantum expander codes with growing-distance LDPC factors | Missing. Cycle-factor ladder does not establish this coverage | [1504.00822](https://arxiv.org/abs/1504.00822) |
| Color codes, triangular 6.6.6 | Six inputs n=7..2791 on main; n=2791 numeric upper-bound smoke gate incomplete | GH-156, `COLOR666.md` |
| Color codes, 4.8.8 / closed higher-genus variants | Missing structural variants; do not count as new independent family | Published explicit incidence/parameter source to resolve |
| BB on twisted quotient tori | Six published inputs n=30..340 on main, all numeric smoke gates passed | GH-159, `TWISTED_TORUS.md`, [2503.03827v3](https://arxiv.org/abs/2503.03827v3) |
| Tanner-cycle balanced product, cyclic action | Six inputs n=78..962 on `codex/balanced-tanner-library`; five distances cross-checked, largest CC-only exact pending independent completion | GH-160, [2012.09271v3](https://arxiv.org/abs/2012.09271v3) |
| Weight-8-check BB | GH-164: six published examples at n=72,144,200; all exact claims reproduced by both engines, GF(2) witness audit passes; work branch only | `WEIGHT8_BB.md`, [2609.06572v1](https://arxiv.org/abs/2609.06572v1) |
| Periodic toric codes | Missing explicit closed-boundary ladder. Planar repetition-HGP does not provide k=2 toric topology | Kitaev [quant-ph/9707021](https://arxiv.org/abs/quant-ph/9707021) |
| Closed hyperbolic surface codes | GH-165: four {5,4} inputs at n=60,160,360,1800; independent quotient/manifold and both-half graph distances pass. Both engines solve first three; n=1800 numeric smoke incomplete after bounded diagnostics, server package prepared. Published n=1920 normal-closure ambiguity awaits PI decision | Breuckmann-Terhal [1506.04029v2](https://arxiv.org/abs/1506.04029v2) |
| Nonabelian balanced / lifted products and ZSZ-LP | Missing nonabelian structure; cyclic GH-160 does not complete it | Hong [2607.27644v1](https://arxiv.org/abs/2607.27644v1) |
| Moderate-blocklength Quantum Tanner from new finite groups | Missing explicit new-group examples; retain heuristic d as upper estimates | Mian et al. [2608.12509](https://arxiv.org/abs/2608.12509); resolve group/local-code provenance |
| Pair-partition / group-valued constructions | Missing; check overlap with LP/BB before adding | Okada-Kasai [2607.14091](https://arxiv.org/abs/2607.14091); Lee group-valued paper/source to resolve |
| BB from covering graphs | Missing provenance/cover structure specialization | Symons-Rajput-Browne [2511.13560](https://arxiv.org/abs/2511.13560): cover parameters to resolve |
| LLM/evolution-discovered BB | Missing discovery-provenance targets, not new mathematical families | Cruz-Benito et al. [2610.06623](https://arxiv.org/abs/2610.06623); further evolution source to resolve |
| Homological products / higher-dimensional homological CSS | Missing explicit practical instances; investigate before claiming mainstream coverage complete | [1311.0885](https://arxiv.org/abs/1311.0885), source/size ladder to verify |
| Fiber-bundle and asymptotically good qLDPC constructions | Research gap: resolve explicit reproducible practical finite instances; do not replace with a cyclic toy and mark complete | Fiber bundles [2009.03921](https://arxiv.org/abs/2009.03921); good-code finite parameter availability still to investigate |

Research-target links do not imply parameter extraction or license review has
passed. The broad literature backlog intentionally remains visible, including
families for which practical finite inputs may require PI judgment. Non-CSS,
subsystem-only, gauge-fixed and circuit-distance objects cannot be silently
converted into inputs for this CSS stabilizer-distance solver.

## Execution order and durable state

1. GH-164 package complete on its work branch: independent witness audits and raw Linux logs retained. Main integration remains pending PI approval.
2. GH-165 first three cases validated; n=1800 numeric smoke remains open for the prepared server package, and n=1920 remains a PI interpretation decision. Independent work continues with nonabelian ZSZ-LP; periodic toric references remain missing.
3. Nonabelian ZSZ-LP and finite-group Tanner cases, then pair-partition/group
   examples; prioritize structurally new inputs over more BB variants.
4. Cover the remaining handoff targets and genuine family gaps; repair the
   incomplete numeric smoke gates listed above using short checks or a server
   package, without reinterpreting UNKNOWN as a certified interval.
5. Audit every row and every acceptance criterion against current files and
   durable evidence before claiming the continuous goal complete.

One construction per branch/report. The next agent should inspect current
main, work branches, issues and this ledger before selecting work. Relevant
active solver topics at this snapshot: GH-148, GH-152, GH-157, GH-162; library
work does not alter their solver files or occupy their server cores.
