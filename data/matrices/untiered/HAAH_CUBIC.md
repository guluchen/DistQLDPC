# Periodic Haah Code1 CSS representatives (GH-182)

## Primary sources and limits

Jeongwan Haah, *Local stabilizer codes in three dimensions without string
logical operators*, Phys.Rev.A83,042330(2011), DOI10.1103/PhysRevA.83.042330,
[arXiv1101.1962v2](https://arxiv.org/abs/1101.1962v2), Fig1/TableI/Eq8.
CSS Code1 only, excluding non-CSS Code0. Paper license is arXiv perpetual/
nonexclusive distribution, not software or matrix redistribution permission.
Only published mathematics is reconstructed; original scripts/matrices GPL3+.
No author implementation, original matrix files, paper prose/images or
external distance solver is copied, redistributed or run.

P. Panteleev and G. Kalachev, *Degenerate Quantum LDPC Codes With Good
Finite Length Performance*, Quantum5,585(2021), DOI10.22331/q-2021-11-22-585,
[arXiv1904.02703v3](https://arxiv.org/abs/1904.02703v3), AppendixB itemD and
Table1: the8x8x8 Code1 has published interval13<=d<=32. Published CC BY4.0,
https://creativecommons.org/licenses/by/4.0/; source mathematics attributed,
not source text/software. That interval is distinct from our checked words
and search proofs. Source long-decoder observations alone prove no lower
bound. Do not confuse this citation with the different2012.04068 LP paper.

Source Theorem1 supplies d>=L for specified periodic codes, not exact finite
d. Source TableII k formula is explicitly empirical for2<=L<=200; actual
GF2 ranks and complete logicals are computed independently here. No thermal-
memory/self-correction theorem is asserted from absence of string logicals.

## Fixed cases and physical coordinates

| L | n=2L^3 | actual k | rank Hx=rank Hz | initially materialized basis upper |
|---:|---:|---:|---:|---:|
|2|16|6|5|2|
|4|128|14|57|14|
|6|432|6|213|30|
|8|1024|30|497|42|
|10|2000|6|997|50|
|11|2662|2|1330|121|

These sizes are fixed before any solver run; no distance/weight-based
resampling. Proposed HCC prefix records provenance, not disjointness from
algebraic GB/LP formulations. Unknown stems pending PI naming/tiering.
The initial supplied-basis upper42 at L8 did not reproduce source upper32.
The retained Linux MaxSAT run now emits an actual GF2-verified weight32
word, reproducing that endpoint without promoting source metadata to proof.

Qubit(x,y,z,s) has index2*((x*L+y)*L+z)+s, s=0,1, coordinates moduloL.
Use Fig1's B' origin, +x forward,+y right,+z up. Source corner coordinates:
A101,B111,C100,D110,A'010,B'000,C'011,D'001. Code1 Z corner labels, in that
order, are ZI,ZZ,IZ,ZI,IZ,II,ZI,IZ. The X generator is the body-opposite
Z generator with its two species exchanged (Eq8). Translate each local
pattern over every lattice site. Periodic collisions add by XOR, not union.
For L>=2 all check weights are8 and each column weight in either half is4.

## Soundness and independent construction check

The source corner list, after body inversion, has component polynomials
f=1+x+y+z and g=1+xy+xz+yz. Thus source X supports(g,f), and source Z
supports xyz*(bar f,bar g), where bar reverses all spatial exponents.
In the binary periodic group algebra the cross pairing reduces, up to a
translation, to g*f+f*g=0. This proves all translated X/Z checks commute,
including finite collision cancellation. It is not a distance formula.

The constructor uses local corner translations. The independent verifier
imports none of it and reconstructs every physical matrix COLUMN by solving
for the check anchor from the two explicit polynomials, independently
handling cyclic multiplicities. It compares every matrix entry, checks
actual dimensions/ranks/full logical quotient bases and pairing, check/
column weights and connected incidence. Its supplied-basis physical upper
words are independently checked for syndrome, stabilizer nonmembership and
logical detection; taking an existing basis row involves no support search.

The physical map(x,y,z,s)->(-x,-y,-z,1-s) is an involutory qubit permutation.
Independent checks show it exchanges the actual Hx/Hz row sets (up to check
anchor order) and maps both COMPLETE logical quotient bases. Unlike a
nonphysical GL transformation, it preserves Pauli/Hamming weight; therefore
it proves X/Z distance equality for these exact finite inputs. It supplies
no absolute distance bound by itself. No CLI dual-map assumption is changed.

## Duplicate and remaining validation gates

Compare all same(n,k) stabilizer row spaces, also X/Z-swapped, on main and
pending library branches. The pending covering-graph BB_128_14_unknown has
same dimensions and independently confirmed d12 on its own branch. Its
literal/direct-swapped spaces differ from HCC_128_14_unknown. Raw peer
matrices, input hashes and BOTH engine exact proofs/actual words are retained
under GH-182/raw/peer128. The retained Linux run now
provides a GF2-verified actual Haah word8 against that peer's exact12. Since
overall distance is invariant under physical column permutations and XZ
swap, the strict invariant proves inequivalence. Both Haah engines also
confirm exact8. The peer review gate passes; labels alone were not evidence.

Reproduce:

```
python3 scripts/codegen/haah_cubic.py --all --out /tmp/haah-rebuilt
python3 scripts/codegen/validate_haah_cubic.py --out /tmp/haah-construction.json
python3 scripts/codegen/validate_css.py --output /tmp/haah-inventory.json
python3 tests/test_codegen_haah_cubic.py
```

Compare all24 generated matrix files byte for byte. Mac generation/algebra/
tiny unit/mutant checks only, no solver or source-distance support search.
Selected Linux calls are60sCPU/90swall/4GiB,serial,one pinned allocated core,
default seed; every printed word is independently GF2-checked and compared
with published intervals and the other engine. Missing CLI fields stay
INCOMPLETE. One-engine exact/raised lower results stay PLAUSIBLE until
independent completion. Heavy jobs require an unexecuted yfclab2 package and
explicit PI core allocation. No solver/default/tiered/QDistSAT/final-name/
main/PR change. See GH-182/REPORT.md for actual current status.

## Retained Linux outcome

Both engines confirm d2/8 at n16/128. CC-only d18 at n432 is PLAUSIBLE;
open combined intervals[19,32]/[19,50]/[19,121] have provisional lower19
and actual independently checked upper words. Source upper32 and the n128
peer inequality are verified. Default MaxSAT n2000/n2662 has no numeric
fields (INCOMPLETE); seven proof/numeric jobs are packaged unexecuted.
Raw source/engine identities and current evidence are in GH-182/REPORT.md.
