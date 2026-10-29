# Pair-partition CPM CSS representatives (GH-167)

Proposed prefix PP. Original reconstructions from Koki Okada and Kenta Kasai,
[arXiv:2607.14091v4](https://arxiv.org/abs/2607.14091v4), Sec. II/VI, and the
[authoritative catalogue](https://kasai.ict.eng.isct.ac.jp/pair_partition_cpm_css_codes_20260714.html).
These are fixed instances, not random parameter searches. Noncyclic GPM/APM
variants are separate future coverage. Stems retain unknown.

| n | k | (J,L,P) | source exact-distance claim | source status |
|---|---|---|---|---|
| 104 | 30 | (3,8,13) | 8 | contributor-reported (Jong Yeon Lee) |
| 276 | 98 | (4,12,23) | 14 | pinned repo reconstructed-instance claim |
| 472 | 122 | (3,8,59) | 16 | independent author catalogue certificate |
| 584 | 150 | (3,8,73) | 18 | independent author catalogue certificate |
| 1112 | 282 | (3,8,139) | 20 | independent author catalogue certificate |
| 1784 | 450 | (3,8,223) | 24 | independent author catalogue certificate |

A source's distance label is not our verification. In particular the first
row is not presented as previously independently certified. The selected
472-qubit girth-8 instance differs from the published girth-6 distance-14
instance with the same n,k; no second same-(n,k) variant is added here.
All construction parameters and exact source identities are in the case JSON.

## Mathematical construction and certificate

For exponent s in Z_P, C(s) row a meets column a-s modulo P. For J-by-L
arrays E,D, Hx and Hz are their CPM expansions, of shape JP-by-LP. Pairing
block columns u,v for each X/Z block-row pair i,j requires
`D[j,u]-E[i,u] = D[j,v]-E[i,v] (mod P)`. Each relative circulant appears an
even number of times, so every block of Hx Hz^T cancels in GF(2).

The original generator groups equal mixed differences and pairs their
indices in sorted order. It reconstructs a valid certificate for the fixed
exponents; it does not claim to reproduce the author's original pre-search
matching seed. Dimensions, ranks and k are checked from actual binary rows,
not inferred from the design rate. Every row has weight L and every column
has weight J. Full stabilizer logical spaces are retained, no gauge removal.

Independent validation iterates variable columns and recovers their incident
row lift b+s, rather than borrowing the generator's row loop a-s. It validates
every perfect matching and equation, polynomial cancellation, regularity,
GF(2) ranks, both logical quotient bases and full pairing. It computes Tanner
girth by BFS from J check-orbit representatives: adding a common lift offset
preserves all CPM edges, so every cycle can be translated through lift zero
in one block row. Witness cycles are checked directly; disconnected graphs
are rejected. Girths are 6,6,8,8,8,8 on both sides.

## Provenance, licensing and reproducibility

Original generator and binary matrices are GPL-3.0-or-later. The paper is
CC BY 4.0, with author/title/source/license attribution in NOTICE. For five
web records, only published mathematical exponent facts are used to rebuild
binary matrices from the paper's construction, as prescribed for unlicensed
matrix files by the handoff. The original website files are not redistributed
and no website license is inferred from the software repository.

The n=276 exponent facts come from the repository's MIT-covered associated
data at commit 9c2a6f212025d2dc5decbf264ce2a24ba6924101. Its original parameter
JSON Git blob was verified; full MIT copyright/permission notice is retained.
No external implementation, constructor or distance-verifier code was read,
copied or executed. External distance certificate labels are source claims,
not imported proofs of our own results.

Five exact source-file SHA256 digests were checked against the author's
published manifest. The validator reconstructs the canonical mathematical
parameter text in memory to match those digests without distributing the
original files. The MIT n=276 projection has its own pinned digest, traceable
to the verified Git blob. All six projection digests are checked offline.
This binds the fixed source parameters to the claims and catches accidental
case edits. Source URLs/hashes/statuses are retained in raw/source-identities.json.

```
python3 scripts/codegen/pair_partition.py --all --out /tmp/pp-fresh --certificates /tmp/pp-pairings.json
python3 tests/test_codegen_pair_partition.py
python3 scripts/codegen/validate_pair_partition.py --output /tmp/pp-construction.json
python3 scripts/codegen/validate_css.py --output /tmp/pp-validation.json
```

All 24 matrix files and matching certificates must reproduce byte for byte.
Logicals use the existing compute_logicals.py --method bitset. No same-(n,k)
peers exist in current main/untiered or pending GH-160/164/165/166 branches.
If future peers appear, compare both X/Z stabilizer row-space orientations and
report suspected column-permutation equivalence before adding duplicates.

Tests catch a wrong perfect matching that still covers every column, a
single-half shift-sign error, invalid exponent/dimension/prime, stale source
digests and a singular logical basis. A global sign flip is explicitly tested
as a coordinate relabeling. Tiny paired examples compare orbit-root girth with
literal all-root BFS; the n=104 oracle exhausts supports <=4 in both halves,
including stabilizer exclusion. This lower bound 5 is not an exact-distance
claim. Source anchor d=8 is reserved for actual solver verification.

## Short Linux checks and remaining work

The branch workflow builds unchanged main, rechecks units/algebra/source/
pairings/girth and regeneration, then six serial MaxSAT and six serial CC
60-second runs on one allocated core, 4 GiB cap and 90-second wall backstop,
stdin /dev/null. All printed words are independently checked in GF(2), with
syndrome, stabilizer exclusion and logical-detector pairing. Exact source
claims must remain compatible with bounds/answers. Missing numeric bounds
remain incomplete gates, even if the workflow executes successfully.

Run IDs and actual observations are recorded in GH-167/REPORT.md and the
manifest after execution. New exact results or stronger one-engine bounds
remain PLAUSIBLE until independent completion and GF(2) witness checks.
Heavy work becomes an explicit server package, never longer CI limits or
Mac solver experiments. No main integration, stem rename or tiering occurs.
