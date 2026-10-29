# GH-165: closed hyperbolic-surface library

Issue: https://github.com/guluchen/DistQLDPC/issues/165
Branch: codex/hyperbolic-surface-library
Base main: 6083e662c621f3b66defd434cfae31a028d483c4.
Status: four unambiguous cases locally validated; Linux evidence pending;
Table I n=1920 construction interpretation awaits PI decision.

## Selection and scope

Proposals: (1) SELECTED: explicit closed {5,4} hyperbolic surfaces from
Breuckmann-Terhal arXiv:1506.04029v2 Table I, (2) periodic toric scaling
anchors, (3) nonabelian ZSZ-LP. The selected construction adds geometric
structure absent from the BB/GB/LP/TN/HGP/color inventory. Prior GH-153/154,
GH-156, GH-159/160, GH-164 evidence informed independent verification and
short-smoke retention. Active solver rounds remain untouched. This is not a
performance optimization/adoption experiment; no Tier 1-5 timing claim.

Original intended ladder: n=60,160,360,1800,1920. The first four reconstruct
with the expected group orders and dimensions. The fifth is explicitly held,
not silently omitted from the goal: see the scientific-definition escalation.

## Scientific-definition escalation

Table I row 5's translation word is represented in `hyperbolic_cases.json`.
Oriented normal closure gives order 3840; imposing its reflected word too gives
order 120. The original and reflected words are checked at every state, all
inverses hold, and reverse relation scan yields identical canonical tables.
`raw/orientation-diagnostic.json` records both outcomes, allocated state counts
and the fact that no n=1920 matrices were generated. The original PDF page 10
and HTML agree, excluding an HTML transcription discrepancy. The paper gives
G+ presentations but also describes conjugation by the full reflection group;
the two interpretations disagree for this row. No claim about a wrong distance.

Per AGENTS.md scientific-specification ambiguity rule, PI was asked whether
to authorize the explicit oriented construction if independent topology and
distance verification pass, or hold this case. The decision is pending; the
case status prevents generation. The four unaffected cases satisfy both
interpretations and proceed independently. No outside communication occurred.

## Construction and validation

`hyperbolic_surface.py`: bounded original relator/coset enumerator, standard
library only. Merges are consequences of relator loops or inverse edges;
completed right-generator table is verified at every state. Canonical BFS
labeling. Certificates include full action and all cell incidences. Rotation
cosets give Hx vertex-edge, Hz face-edge, with full CSS homology. Logicals via
existing bitset compute_logicals.py. See HYPERBOLIC.md for group definitions,
proof of commutation and original all-root BFS homological distance proof.
No external implementations, matrix files, paper text or distance tools copied.
No solver/default/Makefile/tiered matrix changes.

Independent `validate_hyperbolic.py` does not import the generator/enumerator.
Rebuilds cells from permutation cycles, checks group relations, connectedness,
all edge incidences, polygon boundary simplicity, consistent orientation,
circular vertex links, negative Euler characteristic and k=2g. Shared
independent bitset validator checks GF(2) ranks, kernels, logical quotient bases,
pairing and same-(n,k) row-space duplicates including X/Z swap. No such peers.

| n | k | quotient order | genus | published primal/dual d |
|---|---|---|---|---|
| 60 | 8 | 120 | 4 | 6 / 4 |
| 160 | 18 | 320 | 9 | 8 / 6 |
| 360 | 38 | 720 | 19 | 8 / 8 |
| 1800 | 182 | 3600 | 91 | 10 / 10 |

Local Mac commands (no DistQLDPC run):
- `python3 scripts/codegen/hyperbolic_surface.py --all --out /tmp/gh165-first`
- `python3 scripts/codegen/hyperbolic_surface.py --all --certificates optimization/experiments/GH-165/raw/quotients`
- `python3 scripts/codegen/validate_hyperbolic.py --output optimization/experiments/GH-165/raw/topology.json`
- `python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json`
- `python3 scripts/codegen/diagnose_hyperbolic_orientation.py --output optimization/experiments/GH-165/raw/orientation-diagnostic.json`
- Five test scripts: test_codegen_hyperbolic (12), twisted_torus (9),
  color666 (10), hgp (8), cycle (7): 46 tests pass.
- All 16 matrix files byte-identical between generation invocations;
  independent algebra inventory: 28 untiered, 79 total in this branch.

Tests catch extra relation collapsing the quotient, wrong/inconsistent inverse,
disconnected actions, incidence bit flip, singular logical quotient, treating
stabilizer as a logical, forbidden pending-case generation and resource cap.
BFS oracle checks both n=60 halves and relabeling, and agrees with literal
support enumeration on a tiny graph. Full n=1800 distance verification does
not run on the Mac. Evidence in raw/ retains pilot and final tests separately.

## Linux package

Workflow hyperbolic-library-smoke.yml: build unchanged solver, 46 units,
full algebra/topology/diagnostic, all matrices and quotient regeneration;
independent all-root BFS distances on both graphs (30s each, 150s aggregate
backstop), then four MaxSAT and four CC 60s smoke checks. One allocated CPU,
4 GiB cap and stdin /dev/null for solver jobs; no server cores allocated.
Audit every actual witness and independent primal/dual witnesses in GF(2),
source/binary/all input hashes, raw answer agreement, exact claims and both
engine lower bounds. Shared audit is derived from our GH-164 audit, with
explicit stem prefix and optional independently verified surface witnesses.
MaxSAT argv remains unchanged unless explicit `--engine cc` selected.

Actual Actions IDs, source/binary identity and observations follow after runs.
No existing timeout is relabeled as a completed bound; unknown/partial gates
stay open. Any real distance disagreement stops and escalates. Heavy workloads
must become server packages, never increased local/CI limits.

## Completion fields

What changed: four hyperbolic inputs, reproducible generator, quotient and
independent manifold/oracle checks, source/manifest, units and Linux package.
Validation performed: local algebra/manifold/duplicate checks, 46 units and
byte-identical regeneration; Linux distance and smoke pending.
Results: four correct parameter/topology reconstructions; n=1920 held explicitly.
Unresolved issues: n=1920 PI interpretation decision; Linux gates pending;
main integration requires explicit approval. Continuous goal remains active.
Scientific semantics changed: no.
PI action required: yes for n=1920 interpretation and later main integration;
no for continued validation of the other four cases.
