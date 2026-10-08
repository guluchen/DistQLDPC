# GH41 isolated native Tier 1 result

**INCONCLUSIVE; no Tier 1 promotion or adoption.** All 48 fixed solves passed scientific validation. The independent audit passed; the unchanged original numeric filter was inconclusive and the preregistered engineering corroboration predicate was false.

Baseline `24572d6d09cce9a4a5faa58300a89e0feba9da6a`; candidate `66cf8be5a4881643f2063471325e33cecaa0caf1`; execution support `0235cb3b30fc226e237e41c724f9bb52e3e1eb99`. [Assignment](https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6069447421). Four fixed cases, OFF and MTO, three baseline/candidate pairs in AB/BA/AB order; unchanged 180/195-second limits and frozen native binaries.

| Case | Mode | Baseline median (s) | Candidate median (s) | Candidate/baseline |
|---|---|---:|---:|---:|
| BB_90_8_10 | OFF | 3.738307307940 | 3.749379129848 | 1.002961720639 |
| BB_90_8_10 | MTO | 4.738240879960 | 3.956327264896 | 0.834978078389 |
| GB_144_12_8 | OFF | 1.464394470211 | 1.510901966132 | 1.031758857922 |
| GB_144_12_8 | MTO | 1.863564613042 | 1.010040991940 | 0.541994082132 |
| BB_108_8_10 | OFF | 4.839542190079 | 4.831144078868 | 0.998264688915 |
| BB_108_8_10 | MTO | 6.057082410902 | 5.306181547930 | 0.876029280761 |
| LP_238_44_6 | OFF | 3.148849488003 | 3.150065732887 | 1.000386250562 |
| LP_238_44_6 | MTO | 3.698327896884 | 2.934100355022 | 0.793358630395 |

OFF median geometric ratio: 1.0082517787448626; range-envelope geometric ratio: 1.0135266371131497. MTO: 0.7488838204352065 and 0.7568117606198492 respectively. The original filter requires both modes to meet its criteria; OFF did not. All OFF elapsed ranges overlapped, with no disjoint serious regression.

All four MTO cases had disjoint positive CPU and conservative exit-interval ranges, and all three paired CPU/exit inequalities held. All four OFF combined corroboration predicates were false. CPU time and exit intervals do not bound cache, turbo, thermal, IRQ, or memory interference.

The installed helper reserved CPU pair 102/230, with actual capacity, affinity, NoNewPrivs, cpuset and ownership checks retained. This was not exclusive control of the whole host. Owned cleanup, inner restoration to CPU 102, helper release, root restoration to 0–255, group absence and independent post-exit process absence passed. Forced root-supervisor-death recovery was not runtime-tested; full adoption remains blocked.

Complete original archive, extracted byte-identical evidence, original SHA index, SSH lease streams, postprobe source/raw streams/proof, and independent audit source/report/actual arguments are retained under [raw/linux-isolated-tier1-01](raw/linux-isolated-tier1-01). The public catalog is `PUBLIC-SHA256.json`; it supplements and does not replace the original SHA index.

Original archive: 4,300,800 bytes, SHA256 `eacd6703473ef448f259292f89b71e3c4a25d906a5a4608839821215be501cbf`. Original raw index SHA256 `18d5231e72684b5ca06b34f7a2784f760fc34cbbbc29a9908eb1461314cb7481`. Independent audit report SHA256 `256bdce7887d0f85b78ea075d7ede9e27a1f082edc53567bb1309203e0a347b4`.

Historical prerequisites remain separate: Tier 0 original archive SHA256 `71f7058fbaa7a350835e88faac48cfb2581da10e65c6437008947eca596451d9`; isolated execution package SHA256 `827e6969e45caf1f1b055201842faa94f270088ab1eb4162bb958b12d7827c21`; hosted artifact SHA256 `bc9bf45541d332dff2def2042c160c91cb9bce0bc9626d85ce79af2fa95bd33f`. No runs, rows, exclusions, thresholds, source, or scientific semantics changed during retention. Exploratory Tier 2 requires its separate standing-permission prerecord and named assignment; this result is not Tier 1 PASS.
