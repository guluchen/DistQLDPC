# GH-75 Tier0 result — PASS (correctness only; no timing performed by this agent)

Candidate source bbe5055 (= 9bb402a for `src/`), one conceptual delta on corrected
baseline 72d1fe1 (`src/core/distqldpc.cc` only, +347/-6). Frozen binaries:
`frozen-binaries.sha256` (Mac, for the coordinator's timing) and
`raw/tier0-science-02/binaries.sha256` (yfclab2 Linux GCC 13.3, correctness).

1. **Build/smoke**: Mac Apple clang 21 (shim) and Linux GCC 13.3 build; warning count
   34 = baseline 34, none from `distqldpc.cc`. `scripts/smoke_test.sh` PASS on both.
2. **Mandatory GH58 fixture**: `scripts/test_partition_soft_literals.py` (optimum 5, 11
   adjacent oracles) and `tests/test_partition_soft_literals.cc`
   (`GH58_PARTITION_ORACLE_PASS cases=80`) PASS on Mac and Linux (engine unchanged).
3. **Baseline encoding preserved under `-no-symbreak`**: `-v` traces byte-identical to the
   72d1fe1 binary for LP_34_20_2, BB_72_12_6, TN_36_8_4 (default and `-no-card` on Mac;
   default on Linux).
4. **Automorphism evidence** (`raw/automorphisms/`, all 50 codes, `-symbreak-report` +
   independent Python GF(2) re-verification of every reported generator and of orbit
   count/representatives): ALL_PASS on Mac and identical on Linux
   (`raw/automorphisms-linux/`). Detection costs <= 0.012 s CPU (LP_1768).
   * Transitive group -> unit clause `w_0`: all 10 BB codes, GB_144_12_8, GB_144_12_12
     (2D/1D translations within each half + XZ-dual "half swap with group inverse"),
     TN_36_8_4 (XZ-dual block maps).
   * 34 orbits (orbit-chain): LP_136/238/340/442/544/714/1768, PK_31, xu_30, xu_42
     (block-cyclic shift with circulant size l = 4/7/10/13/16/21/52/31/30/42).
   * 36 orbits: TN_108/144/180/216/252/360/396/468/504/612/684, TN_72_8_8; 16 orbits:
     TN_496_2_32 (strided shift L=31).
   * None found (encoding unchanged): LP_34_20_2, TN_36_8_3, TN_54_11_4, TN_72_14_4,
     TN_200, TN_250, TN_288, TN_324, TN_432, TN_540, TN_576 x2, TN_648 x2.
5. **Science sweep** (`raw/tier0-science-02`, yfclab2, unmodified GH-60 harness, 50 codes x
   {default,no-card,card-mto,card-sinz}, 60 s, `--jobs 4`): **200/200 OK, ALL_OK**, 0
   problems. 52 runs completed by both with identical, correctly named distances; 7
   completed only by the candidate (LP_340_56_8 all 4 modes d=8, BB_144_12_12 sinz d=12,
   TN_108_2_12 default/mto d=12); 1 only by the baseline (TN_108_2_12 no-card, baseline
   56.6 s, i.e. near the limit). No emitted d_lb above / d_ub below the reference anywhere.
   Server walls are not timing evidence.
6. **Timeout semantics**: 141 candidate timeouts, all `TIMEOUT`/`s UNKNOWN` with a sound
   d_lb emitted (baseline 147/147). Of 140 runs timing out in both, the candidate's final
   d_lb is higher in 56 and never lower (diagnostic observation only).
7. **Hosted**: CI and QDistSAT cross-repo on `ci/xrepo-gh75` (e63832a, parent 72d1fe1,
   candidate tree): SUCCESS, **scientific match YES** (LP_136_32_4 d=4, BB_108_8_10 d=10,
   no-card and card-mto; `raw/hosted/`).
8. Aborted partial Mac sweep `raw/tier0-science-01` (39/39 OK) retained, see ATTEMPTS.md.

Decision: **Tier0 PASS**. Search behaviour intentionally differs; correctness rests on the
optimum-preservation argument in PROPOSAL.md (verified automorphisms only) plus the
checks above. Tier1/Tier2 are for the coordinating agent.
