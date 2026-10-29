# Distinct-column Gallager-HGP representatives

Original GPL-3.0-or-later mathematical construction. Sources: Gallager,
*Low-Density Parity-Check Codes* (MIT Press, 1963), Sec.2.2/Theorem2.4,
[author's PDF](https://web.mit.edu/gallager/www/pages/ldpc.pdf); Tillich–Zémor,
[arXiv:0903.0566v2](https://arxiv.org/abs/0903.0566v2), Theorems1/15.
No third-party constructor, program, matrix or source file is redistributed.
The cited files' copyrights/licenses are not imputed to our original work.

This is an original explicit conditioning of the published Gallager(3,4)
ensemble, not the book's exact half-ensemble expurgation recipe. GH-173's
unexpurgated controls and neutral quality verdict remain unchanged on their
separate work branch. These four new classical lengths are the multiples
of four below44 not already used there; they fill size gaps and avoid
same-(N,k) duplication. No distances were used to select sizes or samples.

| Classical n | First unique sample | Sparse rank r | Quantum N | Quantum k |
|---:|---:|---:|---:|---:|
| 16 | 0 | 10 | 356 | 36 |
| 24 | 0 | 16 | 832 | 64 |
| 32 | 1 | 22 | 1508 | 100 |
| 40 | 0 | 28 | 2384 | 144 |

Only sample0 at n32 was rejected, for one repeated column pair. All four
accepted factor and quantum graphs are connected. A disconnected accepted
sample would be reported, not replaced. Finite distances are not individually
published. The manifest's initial <=n claim has an actual algebraic word;
computed exact results and any missing CLI fields are recorded separately.

## Complete generation and first-admissible verification

Make three partitions of n positions into groups of four. Partition0 is
identity. For each other partition, start p=[0,..,n-1] and run Fisher–Yates
with i descending from n-1 to1. Draw an unsigned256-bit big-endian SHA256
integer from ASCII
`distqldpc-gallager-v1|n=N|seed=0|block=B|i=I|attempt=A`.
Reject values >=2^256-(2^256 mod(i+1)), incrementing A from0; then swap
p[i] and p[value mod(i+1)]. For sample0, this is exactly GH-173's stream.
For sample s>0 append `|sample=S` after the attempt field in every label.

Each four-entry slice gives a parity row. Reject a sample ONLY if two raw
columns are identical. Choose the first accepted index, at most10000 samples;
failure at the cap stops with no fallback. Record every index, collision-pair
count and acceptance bit. No distance, threshold, witness weight or timing
is evaluated in this structural generation. All frozen permutations/history
are regenerated and verified, not accepted as trusted constructor inputs.

The independent implementation reverses swap order, inverts the resulting
mapping and reconstructs every candidate up to acceptance. It uses tuple
column signatures and pairwise comparisons, independently of the generator's
integer columns/Counter. It rejects skipped admissible samples or tampered
history. Set-based elimination selects the same first independent ORIGINAL
sparse rows as the constructor's integer elimination. Keeping original
weight-four rows preserves the kernel and bounded degree.

For the selected r×n full-row-rank H, use
Hx=[H⊗I_n | I_r⊗H^T], Hz=[I_n⊗H | H^T⊗I_r].
Coordinates are (v1,v2) followed by (c1,c2), second index fastest; row orders
are (c1,v2) for Hx and (v1,c2) for Hz. Physical-column reconstruction verifies
every entry. Hx Hz^T=0 by cancellation of the two H⊗H^T terms. Actual ranks
rn each give N=n²+r², k=(n-r)². Checks have weight at most7. Full logical
quotient bases/pairing, both connected graphs and tensor-swap X/Z duality
are checked independently. No same-(N,k) peer exists across current and
inspected pending library branches.

## Structural lower bound and conditioning proof

Every raw column is nonzero, of weight3. Distinct columns prohibit weight2
kernel words, and nonzero columns prohibit weight1. Summing the first
partition rows gives the all-ones vector, so every kernel word has even
weight. Thus classical d>=4. Selecting a spanning subset of original rows
preserves this kernel. The full-row-rank same-factor HGP theorem transfers
the bound to the quantum code. This is not a finite exact-distance proof
and is never inserted into an absent CLI bound.

In the ideal uniform Gallager ensemble, the first partition has 3n/2 pairs
within checks. For a fixed such pair, each other independent partition puts
it in one check with probability 3/(n-1). Hence the expected duplicate-pair
count is 27n/[2(n-1)²], tending to zero. Markov's inequality implies that
the distinct-column event E has probability tending to one. For a distance
event B whose probability tends to zero under Gallager's theorem,
P(B|E)<=P(B)/P(E) also tends to zero. This conditioning therefore preserves
the typical-ensemble statement. The deterministic SHA256 samples themselves
have no automatic asymptotic or monotone-distance guarantee. A bounded draw
cap reports failure rather than changing the rule.

## Reproduction and finite-distance validation

```sh
python3 scripts/codegen/expurgated_hgp.py --all
python3 scripts/codegen/validate_expurgated_hgp.py --output /tmp/expurgated-construction.json
python3 scripts/codegen/validate_css.py --output /tmp/css-validation.json
python3 tests/test_codegen_expurgated_hgp.py
python3 scripts/codegen/expurgated_hgp.py --all --out /tmp/expurgated-fresh
```

Generation refuses any overwrite and uses the unchanged bitset logical
builder. Gx is ker(Hx)/row(Hz), representing Z words in this repository.
The independent Linux classical oracle constructs a kernel, enumerates all
2^(n-r) words, retains the weight enumerator/minimum support and applies HGP
Theorem1. The maximum dimension here12 gives4096 words. Its whole four-case
check is capped at one allocated CPU,4GiB,60s CPU/90s wall. Source-distance
enumeration refuses Mac execution, apart from <=8-bit tiny units. Both quantum
engines get separate serial60s checks and actual words are verified in GF(2).
All16 new files must reproduce byte for byte. Results, limits, failures and
any unfinished proof jobs belong in GH-174, not source-distance claims.
