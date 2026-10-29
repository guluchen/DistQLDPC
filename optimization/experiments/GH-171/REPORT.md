# GH-171: divisor-driven cyclic GB references

Date2026-10-29. Issue [171](https://github.com/guluchen/DistQLDPC/issues/171).
Base main6083e662c621f3b66defd434cfae31a028d483c4.
Branch `codex/divisor-gb-library`. Status: local validation PASS; bounded Linux smoke pending. This is a library addition, not solver adoption.

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
PI action required: yes for main integration and any dedicated-server run;
none needed to continue independent authorized library construction.
