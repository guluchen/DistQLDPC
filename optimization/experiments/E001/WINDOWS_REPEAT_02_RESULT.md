# E001 Windows repeat 02 result

User-authorized repeat of unchanged H-001. Same baseline/candidate/probe binary
hashes; all 914 pinned package files verified. No rebuild, production-code,
compiler-flag, input, scientific or timeout/result-semantics change.
DistQLDPC with its embedded downstream MaxCDCL engine is compiled by Cygwin GCC
14.4.0 with original Makefile application flags; Cygwin provides Unix process
APIs. Native Windows Python with UTF-8 drives the unchanged Tier 0 harness,
adapting only native CLI paths for Unix executables. No solver porting patch.

Fresh Tier 0 PASS: 676 algebra inputs, exhaustive small CSS fixtures, smoke,
QDistSAT OFF/MTO pilot and timeout checks. All 48 new measured solves return
correct certified distance/objective/bounds. Combined local samples: 96.
No timing timeout/crash. Serial AB/BA/AB, three runs/version/case/mode;
180-second internal limit and 195-second watchdog; same full-wall-time metric.

| Case | Mode | Round 2 baseline median (s) | Candidate median (s) | Round 1 ratio | Round 2 ratio |
|---|---|---:|---:|---:|---:|
| BB_90_8_10 | no-card | 2.3487 | 2.2159 | 0.9372 | 0.9434 |
| BB_90_8_10 | card-mto | 2.8158 | 2.3499 | 0.8403 | 0.8346 |
| GB_144_12_8 | no-card | 0.9822 | 1.4492 | 1.4929 | 1.4756 |
| GB_144_12_8 | card-mto | 1.2494 | 1.7652 | 1.4138 | 1.4128 |
| BB_108_8_10 | no-card | 2.8648 | 2.5159 | 0.8681 | 0.8782 |
| BB_108_8_10 | card-mto | 3.6500 | 2.9491 | 0.8057 | 0.8080 |
| LP_238_44_6 | no-card | 1.8805 | 1.7988 | 0.9472 | 0.9566 |
| LP_238_44_6 | card-mto | 2.1994 | 1.6992 | 0.7815 | 0.7726 |

Windows numerical filter: **REJECT again**, because GB regresses in OFF/MTO.
no-card: baseline range 0.9816–1.0155 s versus candidate 1.4491–1.4982 s.
card-mto: baseline range 1.2480–1.2647 s versus candidate 1.7649–1.7666 s.

Equal-weight median-ratio geomeans: OFF 1.03992; MTO 0.92624. Do not mix modes or hide per-case regressions.

GB's observed regression persists in two separately invoked rounds; baseline
and candidate ranges are disjoint in both modes in both rounds. Fewer XOR gates
are insufficient to predict whole-solve speed; causal search mechanism unmeasured.
This desktop has no exclusive reservation, pinned core or fixed power policy.
No hardware-independence claim follows. Original controlled experiment remains
**INCONCLUSIVE**, no acceptance/merge, Tier 2 or Tier 3. Candidate stays isolated.
Another identical desktop repeat is lower priority than controlled reproduction
or analysis of existing GB search logs; no replacement hypothesis selected.

Raw second-round data: raw/windows-repeat-02/, including all outputs, samples,
environment, identity checks, Tier 0, medians/comparison and executed scripts.
Round 1 is untouched. A launcher attempt initially resolved a relative probe
path after changing working directory and failed before any solver test; that
attempt is separately retained under raw/windows-repeat-02-launcher-failure/.
After resolving the path earlier, all tests passed. No scientific mismatch.
