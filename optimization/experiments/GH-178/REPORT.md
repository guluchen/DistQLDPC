# GH-178: finite twisted circle-bundle open-distance representatives

Status: CONSTRUCTION_AND_VERIFIED_UPPER_PASS; Linux short checks pending.
Issue https://github.com/guluchen/DistQLDPC/issues/178, hub15 claim6497953233.
Fresh main6083e662c621f3b66defd434cfae31a028d483c4;
branch codex/fiber-bundle-library, source recorded after push.
No PR requested; FBC prefix/naming/tiering/main integration need PI review.

## Three proposals, choice and literature boundary

1. CHOSEN: finite circle bundles from2009.03921v2 Definition2.11 with sparse
   full-row-rank bases and nonremovable twists. Expected: genuine missing
   finite bundle structure and unknown distances at n252..2800. Risks:
   boundary/transposes, removable gauge, hidden factors/rank and false claims
   that these modest finite bases meet an asymptotic theorem.
2. Larger nonabelian two-block open targets: useful practical gaps, source/
   equivalence review needed.
3. General Bravyi-Hastings products: a distinct remaining family gap requiring
   finite parameter extraction.

Prior GH164..177 reports, literature survey and coverage ledger reviewed.
PI priority remains unknown exact distances. Fresh issues/remote branches
show no competing fiber-bundle topic. Published math: Hastings-Haah-O'Donnell,
2009.03921v2 Sec2.3 Eq5/Definition2.11/Lemma2.5/Proposition2.10. Only original
mathematical reconstruction; no source text/images/software/matrices copied
or external distance solver. arXiv perpetual/nonexclusive paper license is
not imputed to software/data. Original scripts/matrices GPL3-or-later.

These finite instances use the permissive bundle definition, NOT the paper's
polylog-check random-base, weight-reduction or distance-balancing theorem.
They are not a surrogate for asymptotically-good qLDPC or all general
homological-product codes. FBC is a proposed provenance prefix and overlaps
lifted-product mathematics. Full coverage ledger remains open.

## Frozen input selection and local checks

Bases(16,12),(24,18),(32,24),(40,30),(48,36),(64,48), circleL9/9/25/25/25/25,
N252/378/1400/1750/2100/2800, k4/6/8/10/12/16. Fixed stable PRNG seeds,
unbiased configuration shuffle, first simple/distinct-column/full-rank/
connected base accepted. Sample indices7/43/45/17/21/7, with only parallel-
edge rejects except one rank reject at base24. Twist sample0 in every case;
cycle-voltage gcdell=3/3/5/5/5/5. Complete base rows, twists, seeds and replay
receipts frozen. NO distance/support enumeration, seed resampling or tuning.

Commands:
```
python3 scripts/codegen/fiber_bundle.py --all --out data/matrices/untiered
python3 scripts/codegen/validate_fiber_bundle.py --out optimization/experiments/GH-178/raw/construction.json
python3 scripts/codegen/validate_css.py --output data/matrices/untiered/validation.json
python3 tests/test_codegen_fiber_bundle.py
python3 scripts/codegen/fiber_bundle.py --all --out /tmp/gh178-fresh
```

Mac generation/algebra/tiny units only. Independent physical chain columns,
squarezero, actual ranks, complete logical quotients/full pairing, degree/
weight, base chain projection, fiber translation, raw and canonical-rowspace
connectedness PASS. BFS versus weighted-disjoint-set gauge implementations
agree on nonremovable subgroup.11 new units include random tiny chains,
actual gauge-induced physical permutations, frozen first-admissible replay,
wrong-boundary/trivial-gauge/base-rank/upper-stabilizer mutants and stable
PRNG output. Prior34 units pass, total45;24 matrix files byte-reproduced.
All prior24 manifest rows/96 matrix bytes preserved;30untiered+51tiered
inventory. No same(n,k) peer across current main/pending library branches.
Written structural/upper soundness proof in FIBER_BUNDLE.md. No pruning,
solver bound, default, build or tiered matrix change.

Actual verified X logicals give overall upper9/9/25/25/25/25. These upper
words have zero actual syndrome, are outside actual stabilizer row space and
have a logical detector. No exact distance or lower bound inferred from the
source asymptotics or a claimed equal-half symmetry.

## Linux plan and resource limits

Unchanged solver build,45units, full construction/inventory comparisons,
24-file regeneration. Six selected default MaxSAT and six CC calls, serial
60sCPU each,90swall,4GiB,one allocated pinned runner-affinity CPU, default
seed,20min overall job cap. No sweeps/repeated diagnostics, Mac/third-party
solver, paid cloud or server execution. No performance/Tier1..5 adoption
claim; seed medians/ranges do not apply to single diagnostic smokes.
Retain every raw output, argv, source/binary/input identity, failure/timeout.
Audit every physical word and search interval against other engine and the
independent upper word. Missing raw numeric fields stay INCOMPLETE; an upper
certificate never fills absent CLI output. New one-engine exact/lower results
PLAUSIBLE until independent completion. Heavy jobs become an unexecuted
frozen yfclab2 package requiring an explicitly PI-allocated free core.

## Completion fields

What changed: six reproducible finite fiber-bundle representatives with
nonremovable twists and verified upper witnesses, proposed FBC prefix.
Validation: local45units/construction/regeneration pass; Linux pending.
Results: independent overall uppers9/9/25/25/25/25, exact distances unknown.
Unresolved: Linux numeric/scientific proof gates and other coverage gaps.
Scientific semantics changed: no.
PI action required: yes for prefix/main integration/final names/tiers and any
server allocation; independent library construction can continue meanwhile.
