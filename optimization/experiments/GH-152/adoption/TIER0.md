# GH-152 adoption: Tier 0 of `-cc-aut=on` as the CC default

Branch `adopt/gh152-cc-aut-default`, binary 8b27780 (sha256 0fbd957d...), built on yfclab2 with `make clean && make -j8`.
All runs used cores 64-71, one process per pinned core, with `prlimit --as=4294967296`.
References: frozen main e52d15b (`92bc16bc...`) and the GH-152 binary dfd0717 (`802729d7...`).

| Check | Result |
|---|---|
| Build | OK (only the existing warnings) |
| `make test-cc` (`test_cc.txt`) | CC_ENGINE_TESTS PASS. Parts A-H report 0 bad; mutants 1-14 detected. Parts A-F now run with the new default (`-cc-aut` on). |
| `make test-cc-flags` (`test_cc_flags.txt`) | 348 checks, 0 failed (346 before plus 2 new default-on checks) |
| `scripts/smoke_test.sh` (`smoke.txt`) | passed |
| Default MaxSAT path vs e52d15b, tier0+1 `-v`, `-no-card` and `-card-mto`, with `-ub-pre=off` (`ident_maxsat.txt`) | 30/30 identical |
| Same, default `-ub-pre=on` | 26/30 identical. The other 4 first differ at an `ub-pre X/Z: converged` line (the pre-pass alternates its halves by time). Recheck (`recheck_timing.txt`) ran 5 runs per binary on these 4 cells. Both binaries give the same set of masked logs; on TN_36_8_3 the base binary itself gives 2 different logs. Timing only. |
| Old CC path: e52d15b `-engine=cc` vs adoption `-engine=cc -cc-aut=off`, `-ub-search=off`, with and without `-cc-stats` (`ident_cc.txt`) | 30/30 identical |
| New default: dfd0717 `-engine=cc -cc-aut=on` vs adoption `-engine=cc`, same flags | 30/30 identical |
| CC answers on tiers 0-3, `-engine=cc` (default) and `-cc-aut=off`, 600 s (`answers.jsonl`) | 46/46 equal the stem |

Scripts: `ident_adopt.py`, `answers_adopt.py` and `recheck_timing.py` (run from a worktree root).
