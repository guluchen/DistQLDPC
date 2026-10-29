# HGP from degree-three Gallager classical LDPC factors

Original mathematics-based construction, GPL-3.0-or-later. Sources:
Robert G. Gallager, *Low-Density Parity-Check Codes* (MIT Press1963),
[author's copy](https://web.mit.edu/gallager/www/pages/ldpc.pdf), Sec2.2,
pp13–14/Fig2.1 for the ensemble, Theorem2.4/pp17–18 for typical growth;
Jean-Pierre Tillich and Gilles Zémor,
[arXiv0903.0566v2](https://arxiv.org/abs/0903.0566v2), Theorems1/15.
No external code, constructor, matrix or source file is redistributed. Source
copyrights/licenses are not imputed to our original scripts or matrices.

These are original finite seed realizations of the published ensemble, not
individually named paper codes with published distances. They retain HGP
prefixes and unknown stems. They differ from degree-two cycle factors: the
raw classical matrices have exactly three ones per column and four per row,
independently of length. Gallager's typical-distance result is probabilistic;
it does not prove that every finite sample, or this deterministic infinite
seed sequence, is asymptotically good. Finite exact distances need separate
proofs. No monotone-distance or per-seed growth assertion is made.

| Classical n | Raw rows | Actual rank r | Quantum N | Quantum k |
|---:|---:|---:|---:|---:|
| 8 | 6 | 4 | 80 | 16 |
| 12 | 9 | 7 | 193 | 25 |
| 20 | 15 | 13 | 569 | 49 |
| 28 | 21 | 19 | 1145 | 81 |
| 36 | 27 | 25 | 1921 | 121 |
| 44 | 33 | 31 | 2897 | 169 |

## Complete deterministic generation

The classical factor is three partitions of n positions into successive
groups of four. The first partition is identity. For each block b=1,2,
start p=[0,..,n-1] and for i=n-1,..,1 compute a SHA256 integer from ASCII
`distqldpc-gallager-v1|n=N|seed=0|block=B|i=I|attempt=A`.
Use the full256-bit unsigned big-endian digest. Reject values at or above
2^256-(2^256 mod(i+1)), increment A from0, then swap p[i] with
p[value mod(i+1)]. Each check is the indicator of a consecutive four-entry
slice of the resulting permutation. This completely fixes the original
pseudorandom sampler across Python versions. Seed0 and the six lengths were
preregistered before generation; exactly one realization each, no rejection,
resampling, distance screening, seed competition or parameter sweep.

Select the first linearly independent ORIGINAL rows in source order. Keep
their original weight-four vectors, not their dense echelon reductions.
Rank and kernel equality are checked independently. This removes redundant
checks while preserving the classical code and bounded degrees. A nominal
row count is never used as rank. Fixed permutations and selected indices in
gallager_hgp_cases.json are also checked against the sampler, not trusted alone.

For the selected full-row-rank r×n matrix H, columns are (v1,v2) followed by
(c1,c2), with the second coordinate fastest. Hx rows(c1,v2) implement
[H⊗I_n | I_r⊗H^T]; Hz rows(v1,c2) implement
[I_n⊗H | H^T⊗I_r]. N=n²+r² and k=(n-r)². The independent validator
assembles physical columns, reverses the shuffle, uses set-based elimination,
checks actual quantum ranks/full logical quotients/pairing and connectedness,
and verifies the explicit tensor-coordinate swap exchanging X and Z spaces.
There is no same-(N,k) peer across current or inspected pending libraries.

## Soundness and distance semantics

Hx Hz^T=(H⊗H^T)+(H⊗H^T)=0. Each quantum check has weight4 plus a column
degree of H, at most7; selecting original rows preserves LDPC sparsity.
Both quantum check ranks are rn, verified in GF(2), yielding the stated k.
Since r<=3n/4, the product rate is bounded below by1/25; actual finite rates
use measured ranks. Both raw and selected classical graphs and both quantum
Tanner graphs must be connected; a disconnected first sample would be
reported instead of silently replaced.

Theorem1 applies because H has full row rank and nontrivial kernel: quantum
d equals the classical minimum distance. The independent Linux certificate
constructs a classical kernel using dense binary elimination, enumerates ALL
2^(n-r) words via Gray transitions, retains the full weight enumerator and a
minimum support, and applies the product theorem. Dimensions here4,5,7,9,11,13
give at most8192 words, with a single60s CPU/90s wall/four-GiB/one-core cap
on the entire six-case classical check. It does not import the quantum
constructor or logical builder. Small <=8-bit unit cases are permitted on
Mac; source-code distance checks otherwise refuse execution off Linux.

For a nonzero classical word w and unit e_j outside rowspace(H), w⊗e_j
in the first qubit block is a nontrivial Z word, with the transposed support
an X word. Actual syndrome/quotient/logical-detector checks establish this
directly. The all-ones classical word is available algebraically because
each check is even, giving initial upper n without claiming a distance.
`claimed_d` explicitly says this is an unpublished finite case with an
upper-only witness. Computed classical-product and quantum search results
are recorded separately. Missing engine fields are never filled from theory.

```sh
python3 scripts/codegen/gallager_hgp.py --all
python3 scripts/codegen/validate_gallager_hgp.py --output /tmp/gallager-construction.json
python3 scripts/codegen/validate_css.py --output /tmp/css-validation.json
python3 tests/test_codegen_gallager_hgp.py
python3 scripts/codegen/gallager_hgp.py --all --out /tmp/gallager-fresh
```

Generation refuses overwrite and uses the unchanged bitset logical builder.
Linux proof/smoke evidence, provisional results and any server jobs are in
GH-173. No tier assignment, renaming or QDistSAT mirroring is implied.

## Observed finite results and quality verdict

Independent classical enumeration/product theorem, MaxSAT and CC agree on
d=2,2,2,4,2,2. Every numeric smoke gate and actual-word GF(2) check passes.
Five factors contain identical nonzero parity-check columns, exactly explaining
their weight-two codewords; complete duplicate groups/counts are retained in
GH-173/raw/structural-review.json. The unexpurgated controls are valid and
reproducible, but do NOT supply a growing-distance finite ladder. Do not mark
that coverage gap complete or use these samples to assert poor asymptotic
ensemble behavior. No seed was replaced after observing distances.

Verdict: VALID_UNEXPURGATED_CONTROLS / NEUTRAL_FOR_GROWING_DISTANCE_COVERAGE.
These work-branch inputs await PI integration/utility review. The next design
may explicitly condition the source ensemble on distinct columns, with a new
preregistered construction and its conditioning proof, rather than retroactively
selecting more favorable seeds for this batch. No unresolved distance proof
or heavy server job is needed for these six controls.
