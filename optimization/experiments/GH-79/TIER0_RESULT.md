# GH-79 Tier0 result — PASS (correctness only; no timing claims)

Candidate `bf8110f2a8e10ca4f331abe7acd4c7be83e06905` (one concept on corrected baseline
`72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7`). Frozen binaries: `frozen-binaries.sha256`.
Hosts: Apple Mac (clang 21, shared; guarded by coordinator TIMING_LOCK and load < 6) and
yfclab2 (Linux 6.8, GCC 13.3; correctness only, per coordinator SERVER.md).

1. Build: clean build on both hosts; no new warnings in `src/core/distqldpc.cc` (GCC's one
   `write` unused-result warning is pre-existing baseline code).
2. Mandatory regressions, PASS on both hosts: `scripts/smoke_test.sh`,
   `scripts/test_partition_soft_literals.py`, tests/test_partition_soft_literals.cc oracle
   (CI compile line; `GH58_PARTITION_ORACLE_PASS cases=80`). `raw/mac-tier0/`,
   `raw/server-tier0-science/gh79-regressions.txt`.
3. Clause soundness: in-binary verification failures 0 on all 50 bundled codes
   (`conj_stats_all_codes.txt`). Independent Python re-check of the clauses the binary
   actually emitted (solve-path WCNF dumps, candidate vs frozen baseline, all 50 codes):
   every candidate-only clause of the form (-a_j v OR v_i) verified implied (u + G_j in the
   stabilizer row space by exact GF(2) reduction), 0 bad; counts equal the `-v` totals
   (`raw/mac-tier0/verify_all.txt`, `offline/verify_dump.py`). The solver's preprocessing
   reshapes some Tseitin aux clauses differently once the extra clauses exist (equal counts
   +k/-k); that is the solver's own sound preprocessing, not new semantics.
4. `-no-conj` identity: solve-path `-dump-wcnf` with `-no-conj` and `-dump-only` dumps are
   byte-identical to the frozen baseline on LP_34, TN_36_8_4, BB_72, BB_90, GB_144_12_8,
   LP_238.
5. Science sweep (GH-60 harness, identical copy `~/mac-agent-20261009/tier0_science.py`,
   md5 b2515b9d…; 50 codes x {default,no-card,card-mto,card-sinz}, 60 s, `--jobs 4` on
   yfclab2 = 8 solver processes, started 16:50 finished 18:06 +0800):
   **200/200 OK, ALL_OK**. 52 runs completed by both with identical, correctly named
   distances; 4 completed only by the candidate (LP_340_56_8 no-card d=8; TN_108_2_12
   default d=12; TN_200_10_10 default/card-mto d=10); 1 only by the baseline
   (TN_200_10_10 no-card, d=10); no emitted d_lb above / d_ub below the distance anywhere;
   no abnormal exits. Completion near the 60 s limit on a loaded 8-process host is not
   timing evidence. `raw/server-tier0-science/gh79-tier0/science.json` + 400 logs.
6. Timeout semantics: covered by the 143 sweep jobs where neither binary completed (plus 5 one-sided timeouts) (TIMEOUT, `s UNKNOWN`, sound
   bounds); output format unchanged.
7. QDistSAT cross-repo: one-commit branch `ci/xrepo-gh79` = `981e847` (tree 019e71ce = candidate
   tree, parent 72d1fe1), run 37907655988: SUCCESS, **scientific results match YES**
   (LP_136_32_4, BB_108_8_10 x no-card/card-mto). `raw/xrepo-run37907655988/`.

Decision: **Tier0 PASS**. Tier1/Tier2 timing is the coordinator's (Mac frozen binary).

## Ground-truth anomaly found by the offline analysis (pre-existing, not caused by GH-79)

`offline/check_named_vs_rows.py`: bundled `TN_648_10_71` has logical rows of weight 52
(Gz rows 0 and 2) that are verified nontrivial logicals: Hz.x = 0, not in rowspan(Hx), and
x = Gz_0, z = 0 satisfies every hard constraint of the baseline encoding with a_8 = 1 (cost 52).
Hence the true distance of the bundled matrices is <= 52 < 71 = named distance. All other 49
codes are consistent. The sweep did not trip on it (no solver reached a UB < 71 in 60 s), but
any faster or longer run that finds a weight <= 70 solution will be flagged as `d_ub < named`
by the harness although it is correct. Escalated to the coordinator/PI; no data changed.
