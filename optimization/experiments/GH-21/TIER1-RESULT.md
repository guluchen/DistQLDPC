# GH21 O2-only Tier1 result

**INCONCLUSIVE / NOT ADOPTED.** Hosted/local Tier0 PASS and all48 Tier1 solves scientifically correct. Overall medians favor O2 slightly, with overlapping per-case ranges; no serious or nonoverlapping regression. This Windows diagnostic does not establish controlled promotion. No Tier2/3 executed. Preserve the one-token O3→O2 candidate in its isolated draft branch; do not merge or call the mechanism ineffective.

Production baseline24572d6, candidatee1aa917; actual executed supportfa7531a1dd3624ad4cd3b5269f071550bafe52c5. Exact Tier0-verified original O3/O2 production binary hashes retained in raw environment.json. No rebuilding, training, profiling, additional optimization flags, test-only Main/shim, or solver source patch in timed work. QDistSAT remains the separate benchmark framework; DistQLDPC's MaxCDCL-derived downstream instrumented engine is the tested executable.

Assignment https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6064121965 authorized only fixed48 Tier1. Three serial pairs AB/BA/AB per case/mode,180s CPU limit195s external watchdog, fixed order/mode/compiler/inputs. All samples complete, no timeout or crash, each expected distance/objective/finalLB/UB correct and every emitted bound scientifically valid. Independent audit recomputed96 bound updates,48 raw outputs, exact serial order/commands, raw hashes, medians/envelopes/GM,16 immutable matrix hashes, runtime/helper/parser/binary identities, capacity/affinity/priority and cleanup: PASS.

| Case | Mode | O3 median s | O2 median s | O2/O3 | maxO2/minO3 |
|---|---|---:|---:|---:|---:|
| BB_90_8_10 | no-card | 2.731289 | 2.708652 | 0.991712 | 0.997979 |
| BB_90_8_10 | card-mto | 3.280243 | 3.267554 | 0.996132 | 0.996557 |
| GB_144_12_8 | no-card | 1.145459 | 1.134539 | 0.990467 | 1.011473 |
| GB_144_12_8 | card-mto | 1.444456 | 1.434112 | 0.992839 | 1.000084 |
| BB_108_8_10 | no-card | 3.335406 | 3.328833 | 0.998029 | 1.000890 |
| BB_108_8_10 | card-mto | 4.258488 | 4.232986 | 0.994011 | 0.999924 |
| LP_238_44_6 | no-card | 2.299417 | 2.272472 | 0.988282 | 1.003516 |
| LP_238_44_6 | card-mto | 2.713822 | 2.686284 | 0.989853 | 0.994593 |

Per-mode geometric median ratios: no-card0.9921157821 (~0.788% faster), card-mto0.9932061210 (~0.679% faster). Range-envelope geometric means1.0034518916 and0.9977869735. All8 medians improve, but four per-case ranges overlap; no disjoint regression. The smaller O2 text section does not prove cache-miss causality or larger-case speedup. No pooling of modes, censored samples, favorable retries or statistical significance claim.

85 resource observations all satisfy aggregate spare>50%/one CPU<=half spare, minimum aggregate idle72.9873909%;5 contention alerts, all preflight (0 active), minimum sampled sibling idle92.2480620%. One logical CPU mask16384, AboveNormal32768 inherited by owned processes. Samples alone cannot prove zero unsampled interference, power/frequency equality or controlled isolation. Retain raw variation and alerts even though improvement direction is positive.

Supervisor exit0/valid_run=true; owned child list empty, Job limits/affinity/sleep/priority all restored, final mask65535/Normal32. Windows released immediately at https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6064213166. Only metadata audit and publication followed. The before/after identity guards passed. Raw execution files, executed-driver.py, independent-audit.json and original execution SHA256.json are preserved under raw/windows-tier1-01; PUBLIC-SHA256.json covers all public raw bytes. Run `python optimization/experiments/GH-21/audit_tier1.py optimization/experiments/GH-21/raw/windows-tier1-01` for independent verification.

Learning: current diagnostic cannot directly deny a small O2 benefit, but gives no formal Tier1 PASS. Under the user's earlier explicit one-tier exploratory exception, preregister exactly LP_340_56_8 (12 solves, same O3/O2 binaries) while leaving Tier1 INCONCLUSIVE; await a fresh assigned slot. Also retain exact controlled server replication commands. No new optimization concept or Tier3 before this bounded followup.
