# Binary prime quadratic-residue CSS inputs (GH208)

Proposed prefix `QR`. These are dense CSS codes encoding one qubit, not qLDPC,
a nonzero-rate ladder or a claim to cover every quantum QR construction.
Five cases were frozen in issue208 before generation or native search:

|Case|n|k|Source/construction reference|
|---|---:|---:|---|
|golay23|23|1|exact7 Golay correctness control|
|prime431|431|1|lower23; exact unconfirmed in reviewed primary sources|
|prime719|719|1|lower31; exact unconfirmed in reviewed primary sources|
|prime1031|1031|1|lower35; exact unconfirmed in reviewed primary sources|
|prime2039|2039|1|lower47; exact unconfirmed in reviewed primary sources|

The four targets are finite specializations of the general published family.
They are not asserted globally open or new codes. Preserve easy/poor outcomes
after selection. No distance, prime, coordinate, generator or row-order sweep.
Primitive prime length and p=7 modulo8 are checked independently. The recent
paper's p=5 modulo8 qubit codes are not CSS and are outside this batch.

Sources: Ketkar, Klappenecker, Kumar and Sarvepalli,
[quant-ph/0508070v2](https://arxiv.org/abs/quant-ph/0508070v2), Sec9/Theorem40;
Grassl, *New quantum codes from CSS codes*, QIP22:86(2023),
[DOI10.1007/s11128-023-03835-3](https://doi.org/10.1007/s11128-023-03835-3),
Proposition2/7; Zurel, Jana and de Silva,
[2603.18560v2](https://arxiv.org/abs/2603.18560v2), Sec3/Theorem3/Corollary4
and Table1. Grassl's paper is CC BY4.0; arXiv perpetual licenses for the other
papers are not software/data redistribution licenses. Original GPL3+ scripts
reconstruct mathematics only. No author code, matrix, paper or images copied.

## Physical construction and source correspondence

Let Q be the nonzero squares modulo p and use
`e=1+sum(a in Q) X^a` in GF(2)[X]/(X^p+1). Physical qubit i is coefficient
X^i. Select the first independent cyclic shifts of e, scanning shifts0..p-1;
store the original physical rows, not the eliminated rows. Both Hx and Hz
are this basis. Gx/Gz come from the repository's complete logical builder:

```sh
python3 scripts/codegen/qr.py --all --out /tmp/qr-rebuilt
python3 scripts/compute_logicals.py --method bitset --dir /tmp/qr-rebuilt QR_431_1_unknown
python3 scripts/codegen/validate_qr.py --dir /tmp/qr-rebuilt --out /tmp/qr-check.json
```

To identify the source QR ideal without constructing an enormous splitting
field, let zeta have order p. The Gauss sums etaQ=sum(zeta^a,a in Q) and etaN
are fixed by Frobenius since2Q=Q, hence each is0 or1, and etaQ+etaN=1.
Thus e vanishes on0 and exactly one of Q,N; either choice is the source
expurgated QR ideal. Multiplication by a nonresidue exchanges the two
choices as an explicit physical permutation. This is source equivalence,
not a second stored code or an unspecified local-label choice.

Independent validation enumerates Q by Euler's criterion, reconstructs every
physical row using least-pivot selection (constructor uses greatest pivot),
and computes gcd(e,X^p+1) by set polynomial Euclid. Its polynomial-shift basis
must span exactly the actual H rows. Actual ranks are11/215/359/515/1019 in
each half; k=1. Full GF2, both logical quotient bases and pairing are checked.

## Independent finite-matrix lower certificate

Let D be the actual cyclic stabilizer space and J the all-ones vector.
The validator checks literal integer cyclic correlations of e, all even;
therefore e(X)e(X^-1)=0 over GF2. All cyclic translates then have zero
polynomial product with the reversal of every other translate. It checks
rank(D)=(p-1)/2 and D self-orthogonal, so ker(H)=D direct-sum <J>.
The even stabilizers span the full even part of the kernel. Consequently
every nontrivial half-logical is v=J+s with s in D and is odd.

For every such v, v(X)v(X^-1)=J: the D reversal product is zero, the mixed
J products vanish since stabilizers are even, and J*J=J since p is odd.
Each nonzero cyclic coefficient thus has an odd, positive integer number
of support differences. Counting all ordered unequal support pairs gives
`wt(v)*(wt(v)-1)>=p-1`.

Every selected cyclic row has weight(p+1)/2 divisible4, and all pairwise
overlaps are even. By wt(a+b)=wt(a)+wt(b)-2|a intersect b|, every stabilizer
has weight0 modulo4. Then wt(J+s)=p-wt(s)=3 modulo4. The least compatible
weight satisfying the difference bound is7/23/31/35/47.

This certificate applies to all logicals in both physical halves; it is not
an empirical test of sampled words. The independent tiny23 coset enumerates
2048 words and verifies exact7, and actual minimum words are GF2 checked.
Large cases undergo no local distance search. Initial actual logical-basis
uppers are7/107/195/283/507, separate from the theorem floors and native logs.

Prime cyclic transitivity, full support and nonzero proper rank prove the
stabilizer code indecomposable: equal-size component blocks divide prime p;
singleton components would force the full coordinate space. No same(n,k)
peer across42 pinned main/library refs. This does not prove arbitrary
inequivalence to every unknown code or a global novelty claim.

All inputs stay `_unknown` in untiered. Source claims, finite certificates,
native bounds and actual words are recorded separately. A source lower-only
target never requires a word at its lower endpoint. Large missing gates use
guarded unexecuted server packages; no main/tier/default/QDistSAT changes.


## Terminal native results and retained-only completion

Scientific source00f51d54c1a07a6ce20e75ff6b9b4326fa54055c,
tree1006dbee8b29a17a79aca118820807c76946d82b. Run
[40993376260](https://github.com/guluchen/DistQLDPC/actions/runs/40993376260)/
job123860784465 SUCCESS:49Linux units, full physical/certificate/logical
construction/inventory and20byte reproduction, exactly5defaultMaxSAT+5CC
short attempts. Original60engine evidence files, complete1017948-character
job, source/binary/all4input hashes and original audit retained in raw/.
One identical compiled binary68f4157e2fb10371d6d35321cb53bd86151fac185172d98936d093a41203aa3a
for all10 attempts. Source general CI40993376202/job123860784291 SUCCESS;
data CI40993302471 SUCCESS. No scientific retry or parameter change.

|n,k|Raw MaxSAT|Raw CC|Actual GF2 upper|Finite-certificate interval|
|---|---|---|---:|---|
|23,1|7..7 SOLVED|7..7 SOLVED|7|7..7|
|431,1|3..71 BOUNDED|6..71 BOUNDED|71|23..71|
|719,1|3..135 BOUNDED|6..135 BOUNDED|135|31..135|
|1031,1|3..191 BOUNDED|5..199 BOUNDED|191|35..191|
|2039,1|null/null TIMEOUT_NO_BOUNDS|5..427 BOUNDED|427|47..427|

Every reported upper has an actual word, and every actual word passes GF2
syndrome/quotient/detector checks. Golay exact7 independently confirmed by
both complete engines and tiny2048coset. Four large exact distances remain
unresolved by these searches; reviewed sources supply construction floors,
not exact/upper claims. No assertion of global openness/novelty. Source floors
and independently checked finite matrix proof are never substituted into raw
engine fields. CC1031 reported199 stays199 even though MaxSAT materializes191.
MaxSAT2039 null/null remains null/null; numeric gate INCOMPLETE. Other four
numeric gates PASS. Four lower-only source-upper-word gates NOT_APPLICABLE.
Original raw audit and all20frozen matrices remain byte-identical.
