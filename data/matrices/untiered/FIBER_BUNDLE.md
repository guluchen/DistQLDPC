# Finite twisted circle-bundle CSS inputs (GH-178)

## Source and scope

Original mathematical reconstruction of M. B. Hastings, J. Haah and
R. O'Donnell, *Fiber Bundle Codes: Breaking the N^(1/2) polylog(N) Barrier
for Quantum LDPC Codes*, [arXiv:2009.03921v2](https://arxiv.org/html/2009.03921v2),
Sec2.3 Eq5, Definition2.11, Lemma2.5 and Proposition2.10.
The finite circle-bundle definition permits arbitrary classical base complexes
and rotation twists. No paper prose/images, external code or matrix files
are redistributed. The arXiv perpetual/nonexclusive paper license is not
imputed to software or data. Our original scripts/matrices are GPL3-or-later.

These are new finite sparse-base instances, not individually published
parameters. They do not assert the paper's asymptotic theorem, its random
polylog-weight base hypotheses, weight reduction or distance balancing.
They supply finite bundle representatives; practical asymptotically-good
qLDPC and general Bravyi-Hastings product coverage remain separate open items.
Propose FBC as a short provenance prefix, acknowledging overlap with cyclic
lifted-product mathematics. Every stem remains `_unknown` for PI review.

| Base bits,checks | Circle length L | n | k | Independently verified overall upper |
|---|---:|---:|---:|---:|
|16,12|9|252|4|9|
|24,18|9|378|6|9|
|32,24|25|1400|8|25|
|40,30|25|1750|10|25|
|48,36|25|2100|12|25|
|64,48|25|2800|16|25|

All individual exact distances were unknown at construction. No estimate or
asymptotic formula is used as an exact finite distance. Selection is fixed
before any solver call, consistent with the PI's unknown-distance priority.

## Reproducible bases and nonremovable twists

Each base is a simple(3,4)-biregular binary matrix H with n_B bits and
m_B=3n_B/4 checks. An explicitly specified64-bit PRNG and unbiased
Fisher-Yates shuffle match the configuration stubs. Retain the FIRST sample
having no repeated edge/column, full row rank and connected incidence graph.
No minimum-distance enumeration, distance filtering or seed resampling occurs.
Accepted zero-based samples7/43/45/17/21/7 and all rejection counts are frozen
along with every base row, edge shift, seed and replay receipt in
scripts/codegen/fiber_bundle_cases.json. Reproduction checks the full replay.

Let L=ell^2 with ell3 or5. Assign every base incidence a rotation t_rc in
ell*Z/L. Retain the first assignment whose cycle-voltage subgroup has gcdell
with L; all six accept twist sample0. This tests structural nontriviality,
not distance. The constructor computes BFS potentials. An independent verifier
uses weighted disjoint-set equations, not the constructor's traversal.

Gauge soundness: a fiber-coordinate change transforms t_rc to
 t_rc+g_r-g_c modulo L. Along a spanning tree, potentials remove all tree
labels; remaining residuals are cycle voltages. All labels can be removed
iff every residual vanishes. Their generated subgroup is invariant under
vertex-coordinate changes and has gcd(L,residuals). Here gcdell<L proves
nonremovable twisting and exactly the intended rotation subgroup. This is
not a proof of inequivalence to every HGP under arbitrary column permutations.
Tiny tests verify actual qubit/row permutations induced by gauge changes,
and detect a zero-twist mutant. Circle boundary links adjacent fiber sites,
so subgroup twists do not split the full bundle into disconnected copies.

## Actual chain boundary and soundness

Horizontal qubits h(c,j) are base-bit c times fiber vertex j. Vertical qubits
v(r,j) are base-check r times fiber edge j->j+1. Checks in E0 are(r,j),
and cells in E2 are(c,edge j), all fiber coordinates modulo L.

```
d1 h(c,j) = sum_{r:H_rc=1} (r,j+t_rc)
d1 v(r,j) = (r,j)+(r,j+1)
d2(c,edge j) = h(c,j)+h(c,j+1)
                 + sum_{r:H_rc=1} v(r,j+t_rc)
Hx=d1, Hz=d2^T
```

For each base incidence, d1d2 has the same two fiber endpoints twice;
rotations commute with circle boundary and binary cancellation gives zero.
The generator constructs CHECK ROWS; the independent implementation builds
the inverse incidences from PHYSICAL COLUMNS. Every actual matrix entry is
compared, and full GF2 commutation is checked. Projection maps horizontal
qubits to base bits, vertical qubits to zero and E0 sites to base checks;
the actual d1/d2 projection identities are checked column by column.

Actual ranks are rankHx=m_B L and rankHz=n_B L-(n_B-m_B), giving
k=n_B-m_B. Full logical quotient bases and full Gx Gz^T pairing are verified,
not inferred only from a dimension formula. Hx rows weigh6, Hz rows5;
Hx column degrees are3/2 on horizontal/vertical qubits and Hz degrees2/4.
Both raw Tanner graphs and the canonical reduced-row-space partition are
connected. The latter rules out hidden direct sums under arbitrary check
basis changes. Fiber translation is verified on both actual row sets;
no X/Z duality or equal-half distance assumption is made.

## Independent upper word

Choose a coordinate e_c outside row(H), possible since rankH<n_B, and take
all L horizontal qubits above c. Each Hz row meets it in zero or two places,
so its X syndrome vanishes. Finite base-to-bundle cohomology motivates the
construction; actual Python GF2 checks verify the word is outside row(Hx)
and detected by the supplied complete logical basis. Thus d<=dX<=L for
these ACTUAL matrices. This proves only an upper bound. It neither asserts
dZ=L nor supplies a finite lower bound. The original base rows have even
weight, but logical validity is still checked directly rather than assumed.

## Reproduce and audit

```
python3 scripts/codegen/fiber_bundle.py --all --out /tmp/fiber-bundle-rebuilt
python3 scripts/codegen/validate_fiber_bundle.py --out /tmp/fiber-bundle-construction.json
python3 scripts/codegen/validate_css.py --output /tmp/fiber-bundle-inventory.json
python3 tests/test_codegen_fiber_bundle.py
```

Compare all24 matrix files byte for byte. Same(n,k) row spaces, including
XZ swap, are checked against tier0..5 and untiered. Pending library branch
peers are also inspected; no same(n,k) peer exists for these six cases.
Distinct n also precludes within-batch equivalence. Preserve all prior24
manifest rows/96 matrix bytes and all51 tiered inputs.

Mac work is generation/algebra/tiny random units only. Linux selected serial
60sCPU MaxSAT/CC calls use one allocated pinned CPU,4GiB and90swall. Source,
binary and matrix hashes and raw logs are retained; all actual words are
independently GF2-verified. Missing CLI bounds remain empty/INCOMPLETE even
though the algebraic upper witness is complete. New one-engine exact/lower
results remain PLAUSIBLE until independent completion. Heavy jobs require
an unexecuted server package and PI-allocated free yfclab2 core. No solver,
encoding, bound, default, tier, final-name, QDistSAT or main change occurs.
See GH-178/REPORT.md and retained raw evidence for actual observed results.
