# Published interval-valued generalized bicycle references (GH-191)

Two fixed PK2021 references add useful individual unconfirmed-distance
instances to the existing GB family. They are not a new construction family
or a claim of globally open problems. No parameter screening or scaled copies.

Source: Pavel Panteleev and Gleb Kalachev, *Degenerate Quantum LDPC Codes
With Good Finite Length Performance*, [arXiv1904.02703v3](https://arxiv.org/abs/1904.02703v3),
Quantum5,585(2021), [DOI10.22331/q-2021-11-22-585](https://doi.org/10.22331/q-2021-11-22-585).
Latest version checked2026-10-30. Sec4.2 defines polynomial coefficients
as the first column of the circulant. AppendixB sectionA itemsA1/A5,
PDFp20, and Table1 give the parameters below. CC BY4.0 source credited in
NOTICE; original mathematics-only scripts/matrices GPL3+, no author code,
matrices, prose or images copied. No external distance software executed.

| item | circulant length | n | k | a support | b support | published interval |
|---|---:|---:|---:|---|---|---|
|A1|127|254|28|0,15,20,28,66|0,58,59,100,121|14..20|
|A5|90|180|10|0,28,80,89|0,2,21,25|15..18|

Rabeti–Mahdavifar [2605.14173v1](https://arxiv.org/html/2605.14173v1),
SecV, still uses A1 interval14..20. Targeted later-source searches did not
establish a later exact value; this is not an exhaustive novelty certificate.
The published lower/upper interval remains a source claim, separate from
our numeric solver observations and actual verified upper words.

Hx=[A B], Hz=[B^T A^T], with A[r,h]=a[(r-h) mod l]. Constructor translates
row supports; independent checker reconstructs each physical column from
polynomial coefficients. Independent set-polynomial gcd gives degrees14/5,
matching binary ranks113/85 in both halves and actual k28/10. Full computed
Gx/Gz quotient bases and nonsingular pairing pass. Actual typed physical
stabilizer row spaces have no hidden product partition. Physical cyclic
translation and reflection-plus-block-swap X/Z involution are checked in
both directions, preserving physical weight. No stronger polynomial
involution identity or self-duality is presumed.

No same(n,k) peer across30 pinned main/library refs; main's existing GB144
and GH171 divisor-driven GB cases remain distinct. Generic direct/swapped
rowspace duplicate checks also run. Prior24 manifest rows/300matrix files
are preserved. Branch inventory26untiered/77total.

Reproduce in a fresh output directory (overwrite refused):
```
python3 scripts/codegen/reference_gb.py --all --out /absolute/new/matrices
python3 scripts/codegen/validate_reference_gb.py --out /absolute/new/construction.json
python3 tests/test_codegen_reference_gb.py
python3 scripts/codegen/validate_css.py --output /absolute/new/validation.json
```
13new tests cover independent random physical-column reconstructions,
source/commuting-wrong-matrix/logical/entry/duplicate-support mutants, full
8matrix byte regeneration, overwrite/selection and raw-bound/actual-word
audit guards. No distance/support search on Mac. Linux default MaxSAT and
CC serial60sCPU/90swall/4GiB/defaultseed/pinned allocated core still pending.
Missing raw numbers stay INCOMPLETE. New exact/lower results remain PLAUSIBLE
until independent search/proof plus actual GF2 words. Heavy unresolved work
becomes frozen unexecuted yfclab2 jobs, requiring explicit PI allocation.
No solver/default/tier/stem/main/QDistSAT/PR changes.
