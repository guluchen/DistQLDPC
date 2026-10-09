# GH-69 Tier1 result — REJECT (+25–28% slower, 7/8 cells regress)

Frozen binaries, bound-soundness runner, 208/208 correct, inputs re-verified, load 1.28–2.3, one solve at a time.

| Case | OFF ratio gate (repl.) | MTO ratio gate (repl.) |
|---|---|---|
| BB_90_8_10 | 1.2702 (1.2700) reg | 1.4655 (1.4613) reg |
| GB_144_12_8 | 1.3822 (1.3829) reg | 1.0410 (1.0400) reg |
| BB_108_8_10 | 0.9754 (0.9762) impr | 1.1706 (1.1742) reg |
| LP_238_44_6 | 1.4483 (1.4594) reg | 1.5202 (1.5230) reg |
| geomean | 1.2549 | 1.2836 |

All differences non-overlapping and replicated. Fixed judge: regressions => **REJECT**, no Tier2.

## Why (`raw/tier1-01/searchstats.*`)
| Cell | Lookaheads b -> c | Success rate b -> c | Lookahead propagations b -> c |
|---|---|---|---|
| LP238 OFF | 13,257 -> 18,735 | 76.7% -> 68.5% | 19.3M -> 30.9M |
| BB90 MTO | 55,446 -> 71,666 | 68.7% -> 67.4% | 26.4M -> 33.4M |
| BB108 OFF | 66,184 -> 57,962 | 70.3% -> 67.7% | 37.6M -> 35.8M |

The skipped local learnt clauses supply 7–17% of lookahead conflicts; without them lookahead prunes
less often, trees grow 29–41%, and total lookahead work rises. Skipping still loads the clause header,
so per-lookahead savings were small. Local learnt clauses are cheap-to-keep conflict detectors for LB.
