# GH-60 Tier0 result — PASS (local macOS host + hosted)

Candidate production source 2a42eca (src tree a0e4cbe6), baseline 24572d6. Frozen binaries
(read-only copies outside any build tree; `frozen-binaries.sha256`, re-verified after runs):
baseline distqldpc ac43af52…6eb26, candidate distqldpc 225e5423…9b0, check build
46e03199…e0f (`-DLKPREFIX_CHECK`, never production). Apple clang 21, same build shim as GH-34.

1. Build/smoke: PASS (same warning count as baseline).
2. Invariant-check build (no `seen` literal kept, every kept reason unit-implying, qhead at
   trail end, unlock list == assigned locked-falsified soft vars): LP34/LP136/BB90/GB144/
   BB108/LP238 x OFF/MTO, 12/12 clean, distances 2/4/10/8/10/6 (`raw/tier0-check-01`, `-02`).
   Via `maxcdcl` on Tier1 WCNF dumps (exit handler prints counters): partial resets
   BB90 105,140 / GB144 56,553 / BB108 135,884 / LP238 13,452, kept literals 3.9M/2.0M/
   4.3M/0.86M, all invariant checks clean, optima 10/8/10/6.
3. Science sweep, 50 codes x 4 modes, 60 s (`raw/tier0-science-02`): 200/200 OK. 58 runs
   completed by both with identical, correctly named distances; 6 completed only by the
   candidate (LP_340_56_8 all 4 modes, d=8; TN_200_10_10 sinz/no-card, d=10); none only by
   the baseline; no emitted d_lb above / d_ub below the distance anywhere. Attempt -01 was
   aborted by my process error (binary replaced mid-run), see ATTEMPTS.md.
4. Exhaustive oracle: preregistered fuzz-01 was harness-invalid (wrong output contract and
   unsupported binary softs; baseline itself "wrong"), retained. Post-hoc corrected
   fuzz-02 (unit softs, GH-22 oracle contract, 3000 seeded instances, n=8..20): baseline,
   candidate and check build each 3000/3000 correct, 0 crashes; 82 hard-UNSAT, optima 0..10;
   349 instances exercise >= 1 partial reset (`raw/fuzz-02`).
5. Hosted CI + QDistSAT cross-repo on 47c61bc (same src): SUCCESS, scientific match YES
   (`raw/hosted/`).
6. Timeout semantics: covered by the 148 timed-out sweep runs (TIMEOUT status, `s UNKNOWN`,
   sound bounds); output format unchanged.

Decision: Tier0 PASS. Search behaviour intentionally differs; correctness rests on the
soundness argument in the issue plus the checks above.
