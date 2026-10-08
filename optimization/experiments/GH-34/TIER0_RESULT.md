# GH-34 Tier0 result — PASS (local macOS host)

Issue https://github.com/guluchen/DistQLDPC/issues/34 . Baseline 24572d6; production
source commit a1b90ad (src tree `de939e35b12ea420e22988a2d580d6988f825046`
unchanged by later documentation/harness commits). Both binaries built with
`make CXX="c++ -Wno-reserved-user-defined-literal"` (Apple clang 21.0.0,
arm64-apple-darwin27.0.0), original Makefile flags `-O3 -g -DNDEBUG ...`.

| Binary | SHA256 |
|---|---|
| baseline `bin/distqldpc` | `ac43af52144330f72d838667c82851511bc208f1cb35966359126c2d6a69eb26` |
| candidate `bin/distqldpc` | `0549c4ecc9cdf65fa807a1a7556667787bedcebdff674ed2296032168fc61b8b` |

## Attempt history
Candidate 9735547 failed the bit-exact check (see ATTEMPTS.md); fixed as a1b90ad,
Tier0 restarted from the beginning. All failed/aborted evidence retained.

## Checks on a1b90ad
1. Build: both binaries build; identical warning count (34). `scripts/smoke_test.sh` PASS for both.
2. Test-only `-DLITVALS_CHECK` (asserts the mirror equals `assigns[var]^sign` and is
   in range on every `value(Lit)` read), built with NDEBUG and with upstream asserts
   enabled: LP_34_20_2, LP_136_32_4, BB_90_8_10, GB_144_12_8, BB_108_8_10,
   LP_238_44_6 x {no-card, card-mto} = 24 runs, 0 mismatches, 0 assertion
   failures, distances 2/4/10/8/10/6 as named. `raw/tier0-check-02/`.
3. Verbose trace identity, all 50 bundled codes x {default, no-card, card-mto,
   card-sinz}, 20 s limit (**deviation**: PROPOSAL.md preregistered byte-identity for
   every case finishing within 60 s; this sweep used 20 s, so runs finishing in
   20-60 s only received the prefix check. Disclosed after independent review; the
   preregistered 60 s check is run separately, see TIER0_60S_RESULT.md), 4 comparisons in parallel (`raw/tier0-02/`):
   - 52 completed comparisons (14 codes): stdout+stderr byte-identical, exit status
     identical, every `o N` equals the distance in the code name.
   - 148 timed-out comparisons. The original harness rule reported 143 consistent
     and 5 `TIMEOUT-PREFIX-MISMATCH` (BB_756 sinz, LP_442 default/mto, TN_684 sinz,
     xu_42 sinz). Cause: harness defect. In `-v` mode the parent appends a
     multi-line trailer after killing the child; the rule stripped only one
     line, so any pair killed at different search points failed. The original
     verdict file is kept unchanged (`trace_identity.json`, `console.log`).
   - **Post-hoc rule change**: the preregistered rule said any difference = STOP;
     the harness did stop (exit 2). The timeout comparator was corrected AFTER
     seeing that result. `rejudge_trace_identity.py` re-judged the SAME saved logs
     (no re-run):
     child search output prefix-consistent in all 148; both trailers TIMEOUT /
     `s UNKNOWN`; every reported d_lb <= named distance <= d_ub. Result
     `rejudged.json`: 200/200 OK. In the 5 flagged pairs one version simply
     progressed further before the 20 s kill (candidate 4, baseline 1); 143
     pairs stopped at the same output point. This is not timing evidence.
     The independent review re-checked all 148 pairs without dropping any line:
     the shorter child output is a full byte-prefix of the longer in every pair;
     all walls >= 20.005 s with rc 1, and the parent prints TIMEOUT only when it
     killed the child at the deadline (a crashed child prints `c status: UNKNOWN`).
     Limits: most timed-out prefixes cover only 2-5 KB of early search; the
     'named distance' bound check is not meaningful for xu_30/xu_42/PK_31, whose
     last name field may not be a distance.
4. Timeout semantics: LP_340_56_8 `-cpu-lim=1` and `=5`, OFF/MTO: outputs
   (progress, bounds, `c status: TIMEOUT`, `s UNKNOWN`, rc 1) identical between
   versions. `raw/tier0-02-timeout/`.
5. Machine code: in `propagateForLK` the candidate's value checks compile to
   `ldrb` + compare (the per-check `and`/`eor` of sign handling disappear);
   function length 489 -> 474 instructions (otool, informational).
6. QDistSAT cross-repo PR check: pending on the draft PR (hosted).

Decision: local Tier0 **PASS**; search semantics unchanged by construction and by
observed trace identity. Hosted cross-repo check result recorded separately.
