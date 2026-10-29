# GH-169: finite-group Quantum Tanner specialization

Issue https://github.com/guluchen/DistQLDPC/issues/169.
Branch codex/finite-group-tanner-library, main base6083e662c621f3b66defd434cfae31a028d483c4.
Status: six fixed original reconstructions pass source-instance/algebra checks;
all46 local tests pass,24 matrices regenerate byte-identically; Linux smoke evidence pending.

Three proposals: SELECTED moderate finite-group Tanner inputs; noncyclic
quaternary PP;4.8.8 color patches. Hypothesis: published fixed nonabelian
group/local-code inputs add open-distance specializations. Risk: source
same(n,k) variants, right-action inverse/local column order, heuristic distance
misinterpretation. Expected library effect only, no solver/default/performance
adoption, tiered benchmark or QDistSAT change. Read prior GH-160/164/165/166/
167/168 records and coverage ledger. No topic collision/server allocation.

Source Mian et al2608.12509v1 Eq34 Tables I/IX/XII. Six inputs n288k8,360k6,
480k8,588k14,756k10,864k8; published overall upper estimates15,18,18,18,9,27.
Not exact labels. TableIII variants are not substituted. Author files sometimes
retain older estimates; complete parameter agreement and proved source matrix
equivalence identify the selected instances. Source full numeric HDF5 records
pinned by commit/blob/SHA256 and projection digests; no constructor/search or
distance-verifier implementation read/copied/run. Source records not redistributed.

MIT numeric-source attribution/full notice in NOTICE, Copyright2026 Quantum
Savory. Paper perpetual/nonexclusive, no copied text; secondary mathematical
regular-action definition2512.20532v1 CC BY4 credited. Original scripts/matrices
GPL3+. Full source/license/construction/soundness proof in FINITE_TANNER.md.

Mac local checks (no DistQLDPC solver execution):
- Fixed HDF5 numeric inputs read using temporary h5py, Git blobs/SHA256 verified.
- `python3 scripts/codegen/finite_tanner.py --all`
- `python3 scripts/codegen/validate_finite_tanner.py --out optimization/experiments/GH-169/raw/construction.json`
- `python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json`
- `python3 tests/test_codegen_finite_tanner.py`:12 pass.
- Optional `verify_finite_tanner_source.py --cache /tmp/gh169-source --out optimization/experiments/GH-169/raw/source-equivalence.json`, all six pass: actual source numeric regular actions give an explicit fiber enumeration, then both stabilizer spaces match.
- Fresh generation in /tmp/gh169-regenerated, all24 files byte-identical.
- Pending branches GH-160/164/165/166/167/168 have no same(n,k) peers;
  exact reviewed commit identities retained in raw/pending-branch-peers.json.

Independent inverse-permutation group/column pullback validator uses no
generator/logical-builder imports. Checks local full duality and source
projection, nonabelian group order, both connected halves, GF(2), actual ranks,
logical quotient bases/full pairing. Random tiny local-code lifts compare
independent reconstruction, tiny8-qubit supports exhaustive, source/action/
permutation/connectivity/logical mutants caught. Wrong right-action convention
can remain CSS, so commutation alone is explicitly insufficient.

Planned Linux: unchanged build,46 unit checks, independent algebra/source
projection/incidence/connectivity,24-file regeneration, six default MaxSAT and
six CC60s checks serial allocated pinned core,4GiB cap,90s wall/stdin null.
Collector retains actual CLI values and supports explicit <= claims; it does
not fill from reference estimates. Every printed logical independently GF(2)
checked. Source/binary/input identities and raw logs durably committed after
execution. Missing numeric gates remain incomplete. New stronger one-engine
lower bounds/exact distances remain PLAUSIBLE. No increased CI limits or
parameter sweep; heavy completion becomes an unexecuted server package.

Completion fields: what changed: six TN untiered inputs, original generator,
source identity/pullback/GF(2)/tests/provenance. Validation: local source and
construction checks, remaining local regressions/Linux pending. Results:
source dimensions and both source stabilizer spaces reproduced. Unresolved:
Linux numeric/witness gates and PI integration/server allocation. Scientific
semantics changed:no. PI action required:no to continue,yes for integration
or server allocation. Prior hyperbolic n1920 interpretation remains pending.
