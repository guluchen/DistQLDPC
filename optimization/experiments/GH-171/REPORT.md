# GH-171: divisor-driven cyclic GB references

Date2026-10-29. Issue [171](https://github.com/guluchen/DistQLDPC/issues/171).
Base main6083e662c621f3b66defd434cfae31a028d483c4.
Branch `codex/divisor-gb-library`. Status: local and Linux validation PASS; all four published exact distances
reproduced by both internal engines with verified logical words. This is a library addition, not solver adoption.

## Proposal and provenance

Three proposals: selected fixed divisor-driven GB references; deferred4.8.8
color geometry; deferred HGP with growing-distance classical LDPC factors.
See issue171 for hypothesis, effect and risks. Prior library evidence
GH159/164/166/169/170 and the coverage ledger informed the choice. Open issues
and remote branches were checked before claim; hub15 links this round.

Four published cases n46/66/90/170,k2/20/4/10, exact claims8/7/10/8,
from Lu–Guo–Liu–Yang arXiv2608.09115v3 TablesII/IV/V, Example11.
Latest paper parameters agree with v1 notes. Source CC BY4.0 attribution is
in NOTICE and DIVISOR_GB.md. Original mathematics-only generator; no external
implementation, matrix file, Magma or third-party distance tool used.

`divisor_gb.py` builds two cyclic blocks with explicit transpose convention;
`validate_divisor_gb.py` independently reconstructs physical columns and
set-polynomial gcd, checks actual ranks, CSS/full logical quotients/pairing,
connectivity/degrees and translation/duality. Written dimension/commutation
proof in DIVISOR_GB.md. Existing logical builder unchanged. All four matrices
per input are reproducible and have unknown stems under untiered.

## Validation and retained evidence

Raw generation, construction and same-parameter cross-branch scan in raw/.
All10 new and34 prior unit tests pass;16 matrix files regenerate byte for
byte, all28 untiered codes pass the full GF(2) inventory check (79 total).
Prior24 parsed manifest rows and96 matrix files are unchanged.
Binary rank pairs(22,22),(23,23),(43,43),(80,80) yield the published k.
Basis upper witnesses15/9/18/17 are verified GF(2), not lower proofs or
substitutes for source d. No same-(n,k) peer in tiers, untiered or pending
library branches. No arbitrary permutation search is needed across differing
n,k, which are invariants.

Initial unit assumption d=2 for all <=12-qubit toy cases was incorrect;
complete increasing-support enumeration shows2,2,3,3. Corrected the fixture
and tested random physical relabeling. Initial failure retained; it is not
a scientific disagreement with any of the four published references.

No Mac solver experiment or timing. Linux plan: unchanged solver, four
default MaxSAT and four CC serial60s smokes, one pinned allocated runner CPU,
4GiB address cap and90s wall backstop, null stdin. Retain every raw log,
source/binary/input digest and verify actual printed words independently.
Any contradiction with a published exact distance is a scientific escalation;
an incomplete lower proof remains PLAUSIBLE and is packaged for the server.

No performance tier gate or seed-median claim; no solver/Makefile/tiered data
change. Prior24 manifest rows and96 matrices must stay unchanged. No PR or
main push. Main integration/server-core allocation need PI decisions.

Scientific semantics changed: no.
PI action required: yes for main integration;
none needed to continue independent authorized library construction.

## Linux results and reproducibility

Source checkpoint22e27d49d9382185168a8eaefc97a5a7acef6bd4;
parent data commitcbb4823d3c0d3ab3be9823d6401f5b6c62ae1aaf;
source tree2097238679e10f5b8ab2d2bbca92a06cafee97e9.
[Library workflow40862753015](https://github.com/guluchen/DistQLDPC/actions/runs/40862753015),
job123409827109: SUCCESS, every step passed. Ordinary CI40862752823,
job123409826603: SUCCESS. This includes unchanged-solver build, all44 units,
all28 untiered GF(2) inventory cases,16 fresh matrix comparisons and8 serial
short engine checks. Runtime measurements are smoke diagnostics only.

| Stem | Published exact d | MaxSAT lb/ub | CC lb/ub | Actual GF(2) words |
|---|---:|---|---|---|
| GB_46_2_unknown | 8 | 8/8 SOLVED | 8/8 SOLVED | both engines weight8 |
| GB_66_20_unknown | 7 | 7/7 SOLVED | 7/7 SOLVED | both engines weight7 |
| GB_90_4_unknown | 10 | 10/10 SOLVED | 10/10 SOLVED | both engines weight10 |
| GB_170_10_unknown | 8 | 8/8 SOLVED | 8/8 SOLVED | both engines weight8 |

All numeric gates PASS. Every printed logical word passes independent
syndrome, non-stabilizer quotient and logical-detector checks. The two
implementations confirm each source exact claim; none remains a one-engine
PLAUSIBLE result. No new stronger distance claim, scientific mismatch,
unfinished numeric gate or long proof job remains for this batch. No server
run was needed or launched. All stems remain unknown pending PI handling.

Binary SHA25668f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a,
matching the unchanged main build used by recent library rounds. Per-engine
argv, Linux environment, return codes, raw logs, source/input/binary hashes,
CSV results and DONE receipts are versioned in raw/actions/default/. The
full412249-character job log and audit.json are retained there. Local audit
replay from those raw inputs is byte-identical to the CI audit. No mathematical
or source bound substitutes for a CLI field. Solver/scripts/matrices have
not changed since the validated source checkpoint. Subsequent commits only
retain evidence and report outcomes.

A metadata-only update initially used the nonexistent CSV field
supplemental_60s_status instead of supplemental_status. The writer exception
truncated only the pending branch manifest after its24 existing rows; raw
results and all matrices remained intact. Restored the exact validated28-row
manifest and applied the results with the established schema, serializing
in memory before replacing the file. Revalidated full inventory and prior24
rows after repair. This routine evidence-format failure did not rerun or
alter scientific calculations. The intermediate commit remains in history.

Replay commands (no solver execution):

```sh
python3 scripts/codegen/audit_divisor_gb_smoke.py --maxsat optimization/experiments/GH-171/raw/actions/default/gb-maxsat --cc optimization/experiments/GH-171/raw/actions/default/gb-cc --out /tmp/gb-audit.json
python3 scripts/codegen/validate_css.py --output /tmp/gb-inventory.json
python3 scripts/codegen/validate_divisor_gb.py --output /tmp/gb-construction.json
```

To rerun short smokes on Linux Actions, use smoke_untiered.py --ci --family GB
--verbose, once with the default engine and once with --engine cc, with fresh
--out directories. Server mode instead requires --cpu CORE on an explicitly
PI-allocated free core. Never run these solver commands on the Mac.
No PR opened. The continuous goal stays active;4.8.8 color geometry,
growing-distance LDPC-factor HGP and other missing rows remain visible.
