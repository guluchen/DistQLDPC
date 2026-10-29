# Published lower-only GB reference and exact anchor (GH-196)

Mostad, Rosnes and Lin, [DOI10.1109/JSAIT.2025.3594310](https://doi.org/10.1109/JSAIT.2025.3594310),
IEEE JSAIT6,367-382(2025), TableII supplies two frozen cases:

| stem | cyclic l | published distance | actual both-half rank | initial actual GF2 upper |
|---|---:|---|---:|---:|
|GB_180_26_unknown|90|exact7 anchor|77|10|
|GB_688_30_unknown|344|lower19 only; exact unconfirmed|329|104|

Source exponents are frozen in lower_reference_gb_cases.json before generation.
No extra480 exact-known case or post-result replacement for quantity. Existing
GB family, not a new mathematical family. Primary-source review found no later
exact result; this is not a claim of global openness. Source19 is not yet an
independently reproduced lower proof. Initial basis upper104 is verified,
not exact distance or a published upper. No inherited growth guarantee.

```
python3 scripts/codegen/lower_reference_gb.py --all --out /tmp/gb-rebuilt
python3 scripts/codegen/validate_lower_reference_gb.py --out /tmp/gb-construction.json
python3 tests/test_codegen_lower_reference_gb.py
python3 optimization/experiments/GH-196/raw/review_pinned_inventory.py
```

All8matrices reproduce byte for byte; unchanged compute_logicals.py --method
bitset supplies both full quotient bases. Independent reverse physical
columns, set-polynomial gcd dimension proof, actual commutation/ranks/kernel/
quotient/pairing/cyclic and XZ physical maps/typed stabilizer connectivity and
actual words pass. Fifty tiny random column/commutation cases plus50tiny gcd/
rank comparisons and mutants/claim-parser fixtures cover source errors.
52local units(18new+34prior),26untiered/77total inventory PASS. Neither(n,k)
has a peer across34pinned main/library refs; no existing input was replaced.

Original mathematics-only GPL3+ reconstruction. No author software, matrix
files, paper text/images or external distance solver used/distributed; no
open license inferred for author assets. Full attribution NOTICE, finite
soundness MODIFICATIONS, visually reviewed PDFpages14-15/SHA256 receipt in
GH-196/raw/source-review.json. The earlier arXiv2405.07980v2 is shorter and
must not replace the later journal's finite table. Decoder/circuit distances
are not substituted for this static CSS distance.

One-time Linux plan:2MaxSAT+2CC, serial60CPU/90wall/4GiB/defaultseed/pinned
allocated CPU,15min workflow cap. Preserve source/input/binary/raw identities
and every actual word. Exact anchor mismatch or actual word below19 is a
scientific escalation; weaker search lower is allowed. Missing fields stay
INCOMPLETE; new strongest lower/exact PLAUSIBLE until independently verified.
No source-upper-word target is invented for GB688. Heavy missing gates become
unexecuted guarded yfclab2 jobs; no allocated core. All untiered on work branch,
no solver/default/tier/name/QDistSAT/main/PR change. Terminal results pending.
