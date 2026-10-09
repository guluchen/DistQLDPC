# GH-92 Tier0 result — PASS (correctness only; no timing performed by this agent)

Preregistered interaction experiment GH-85 x GH-87 (issue #92; PROPOSAL.md committed `335dddb` before
any code change). Candidate source `e226951` = GH-85 `cc7e5ea` (72d1fe1 + GH-73 `cad2c70` + GH-85)
+ `15dee7d` (cherry-pick of GH-87 `4766d31`, conflicts resolved) + `e226951` (cherry-pick of the
`src/core/distqldpc.cc` part of GH-87 A1 `783527a`). Later commits are records only.

## Merge

* Conflicts in `MODIFICATIONS.md`, `NOTICE`, `src/core/distqldpc.cc` resolved by keeping both features
  (both table rows / notice paragraphs; both flag sets `-no-symbreak`, `-symbreak-report`,
  `-no-dualskip`, `-dualskip-report`, `-joint`; both help blocks; both report modes — if both report
  flags are given, the symbreak report is printed first, then the dualskip report).
* Deduplication: GH-87's copies of `Gf2Basis`, `RowSupports`, `append_supports`, `basis_of`,
  `permuted_rows_in`, `SymCandidate` were byte-identical to GH-85's (checked by script before deletion)
  and were removed. `add_candidate` now only drops duplicates; one family generator
  `candidate_family(n, with_identity)` seeds the identity first and, for GH-85
  (`with_identity=false`), erases it at the end — same list and order as GH-85's
  `symmetry_candidates` (identity and duplicates rejected); GH-87 (`with_identity=true`) gets
  identity + family exactly as its `dual_candidates`. The family bodies of GH-85 and GH-87 were
  textually identical (diff). Behavioural identity is confirmed by the reports below.
* Driver: dual-map detection first; if a map is verified the Z half is eliminated; then per-half
  symmetry detection on every half still present (X only under elimination, both otherwise). A1
  (phase 2b cap U-1) only when the Z half was eliminated. Soundness comment in
  `min_distance_css_interleaved`: dX = dZ from the verified permutation, so solving only X is exact;
  per-half orbit clauses (plain half automorphisms only, never the XZ-dual map) preserve every capped
  existence answer of the X half; hence the stack is exact.
* Line endings: all three files are LF (`file`), unchanged.

## Checks (Mac, Apple clang; one solver process; `raw/mac/run1.log`, `mac.sh`)

| Check | Result |
|---|---|
| `make clean; make CXX="c++ -Wno-reserved-user-defined-literal"` | rc 0; 32 warnings, none in `distqldpc.cc` (= GH-87's 32 full build) |
| `scripts/smoke_test.sh` | PASS (`raw/mac/smoke.txt`) |
| `python3 -B scripts/test_partition_soft_literals.py` | PASS, 11 adjacent oracles (`raw/mac/partition_py.txt`) |
| `tests/test_partition_soft_literals.cc` (ci.yml compile line + Apple shim) | `GH58_PARTITION_ORACLE_PASS cases=80 no_conflict=1` |
| GH-85 `verify_half_autos.py` (per-half automorphisms, 50 codes x 2 halves) | ALL_PASS (`raw/mac/automorphisms.log`) |
| GH-87 `check_dual_maps.py` (dual maps, 50 codes) | ALL_PASS (`raw/mac/dualmaps.log`) |
| `-symbreak-report` vs GH-85 Mac reports, 50 codes | 50/50 identical modulo `detect_cpu` |
| `-dualskip-report` vs GH-87 Mac reports, 50 codes | 50/50 identical modulo `detect_cpu` |

### Flag equivalence (`traces.sh`, `-v -cpu-lim=120` on both sides; `raw/mac/traces/`)

| Code | modes | `-no-dualskip` vs GH-85 | `-no-symbreak` vs GH-87 | default vs GH-85 | d |
|---|---|---|---|---|---|
| BB_90_8_10 | no-card, card-mto, default | 3/3 IDENTICAL | 3/3 IDENTICAL | differs (dual map: X only) | 10 |
| GB_144_12_8 | same | 3/3 IDENTICAL | 3/3 IDENTICAL | differs (dual map) | 8 |
| BB_108_8_10 | same | 3/3 IDENTICAL | 3/3 IDENTICAL | differs (dual map) | 10 |
| LP_238_44_6 | same | 3/3 IDENTICAL | 3/3 IDENTICAL | 3/3 identical modulo the one `c dualskip:` line | 6 |
| LP_340_56_8 | same | 3/3 IDENTICAL | — | 3/3 identical modulo the one `c dualskip:` line | 8 |
| LP_34_20_2, BB_72_12_6, TN_36_8_4 | same | 9/9 IDENTICAL | 9/9 IDENTICAL | LP_34 identical mod dualskip line; BB_72/TN_36 differ (dual map) | 2/6/4 |
| `-joint` vs baseline 72d1fe1 (LP_34_20_2, BB_72_12_6, TN_36_8_4 x default/no-card) | | 6/6 IDENTICAL | | | |

All traces finished well inside the cpu limit. "Byte-identical default on LP" is necessarily modulo the
single `c dualskip: no dual map ...` line that `-v` prints (as in GH-87's Tier0); everything else,
including `c symbreak` lines and every oracle call, is identical. On every dual-map code the default
trace prints the X-half `c symbreak X` lines identical to GH-85's and contains no Z-half line or Z-half
oracle call (symmetry breaking is applied to the solved half).

## Science sweep (`raw/tier0-science-01/`, `raw/tier0-science-01.log`, `science.sh`)

Mac, under the timing lock (waited until absent, took it with "GH-92 Tier0 science sweep ...",
released at end), 2026-10-09 21:13:47-22:24:31 +0800. Unmodified GH-60 harness copy
`tier0_science.py` (sha256 41ee9dfc...), 50 codes x {default, no-card, card-mto, card-sinz}, 60 s,
`--jobs 4`; baseline frozen 72d1fe1 (3f2fbc42...), candidate frozen92 (49e37dee...). Walls are not
timing evidence.

* **200/200 OK, ALL_OK, 0 problems.** 58 completed by both with identical named distances; 19 only by
  the candidate, all equal to the named distances (BB_144_14_14 x4 d=14, GB_144_12_12 default/mto/sinz
  d=12, LP_340_56_8 x4 d=8, LP_442_68_10 x4 d=10, LP_544_80_12 default/mto d=12, TN_200_10_10 no-card/
  sinz d=10); 0 only by the baseline. Every emitted d_lb <= d <= every emitted d_ub; zero unsound results.
* Post-hoc (`posthoc_science.py`): **123/123 candidate timeouts emitted a d_lb** (POSTHOC_PASS); of 123
  runs timing out in both, candidate final d_lb higher in 123, lower in 0 (diagnostic only).
* New vs both parents' sweeps: BB_144_14_14 now completes (d=14, all modes; neither GH-85 nor GH-87 did in their
  yfclab2 sweeps within 60 s) and GB_144_12_12 card-sinz completes (d=12). TN_648_10_71 (named 71 known wrong, PI
  escalation): no d_ub emitted by either version (cand d_lb 9, base 4-8); nothing to report.

## Hosted

`ci/xrepo-gh92` = one commit `4122860` (parent 72d1fe1, tree `fa7723c` = tree of `e226951`).
CI https://github.com/guluchen/DistQLDPC/actions/runs/37934275255 success; QDistSAT cross-repo
https://github.com/guluchen/DistQLDPC/actions/runs/37934275681 success, **scientific match YES**
(LP_136_32_4 d=4, BB_108_8_10 d=10, no-card and card-mto; `raw/hosted/`). Shared-runner times informational.

## Frozen binary for the coordinator

`frozen-binaries.sha256`: `scratch-2026-10-08-ce0ddb/frozen92/cand/distqldpc`, sha256
`49e37dee170eb6685344aefd25b37bdb1dccc129d640d6802ded25562b51d28f` (read-only). Primary comparison vs
GH-85 `frozen85/cand` (1c6f028a...), secondary vs 72d1fe1 `frozen73n/base` (3f2fbc42...).

## Deviations from the plan

* Only the `src/core/distqldpc.cc` part of `783527a` was cherry-picked; its GH-87 experiment records
  (ATTEMPTS, superseded raw evidence, GH-87 PROPOSAL amendment) stay on the GH-87 branch (the GH-87
  PROPOSAL does not exist on this branch, so including them would only have added a modify/delete conflict).
* The science sweep ran on the Mac (yfclab2 not used), `--jobs 4`, under the timing lock.
* No Linux build this round (server not opened, as instructed).

Decision: **Tier0 PASS**. State TIER0_PASS / WAITING_FOR_HOST (Tier1/Tier2 by the coordinator).
