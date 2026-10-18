Mac, -no-card, default seed, 4 concurrent, `-v -frontier=on|off -frontier-stats`; per probe MaxCDCL's own lookahead counters (nbLK = lookahead calls, nbLKup = lookahead unit propagations, hardConflicts), grouped by probe outcome (tools/lkstats.py). The FOUND row of TN_108 has almost no conflicts (6 / 0) and is not meaningful.

| code | probe class | arm | conflicts | lookahead calls / conflict | lookahead propagations / conflict | hard-conflict share | wall s (run) |
|---|---|---|---:|---:|---:|---:|---:|
| BB_144_14_14 | NONE (refutation) + final optimize proof | off | 393666 | 1.36 | 486 | 0.013 | 34.0 |
| BB_144_14_14 | FOUND | off | 264416 | 1.35 | 487 | 0.011 | 34.0 |
| BB_144_14_14 | NONE (refutation) + final optimize proof | on | 113378 | 1.81 | 736 | 0.015 | 7.9 |
| BB_144_14_14 | FOUND | on | 32350 | 1.81 | 738 | 0.018 | 7.9 |
| LP_442_68_10 | NONE (refutation) + final optimize proof | off | 267982 | 1.20 | 1656 | 0.014 | 37.1 |
| LP_442_68_10 | FOUND | off | 23627 | 1.14 | 1584 | 0.021 | 37.1 |
| LP_442_68_10 | NONE (refutation) + final optimize proof | on | 40836 | 1.58 | 3110 | 0.058 | 12.7 |
| LP_442_68_10 | FOUND | on | 16622 | 1.69 | 2855 | 0.049 | 12.7 |
| GB_144_12_12 | NONE (refutation) + final optimize proof | off | 586139 | 1.37 | 475 | 0.012 | 63.8 |
| GB_144_12_12 | FOUND | off | 624748 | 1.36 | 473 | 0.012 | 63.8 |
| GB_144_12_12 | NONE (refutation) + final optimize proof | on | 239434 | 1.79 | 712 | 0.015 | 27.5 |
| GB_144_12_12 | FOUND | on | 200797 | 1.80 | 716 | 0.015 | 27.5 |
| TN_108_2_12 | NONE (refutation) + final optimize proof | off | 206999 | 1.37 | 391 | 0.055 | 10.9 |
| TN_108_2_12 | FOUND | off | 6 | 0.33 | 124 | 1.000 | 10.9 |
| TN_108_2_12 | NONE (refutation) + final optimize proof | on | 158211 | 1.67 | 532 | 0.066 | 9.2 |
| TN_108_2_12 | FOUND | on | 0 | 2.00 | 742 | 0.000 | 9.2 |
| TN_200_10_10 | NONE (refutation) + final optimize proof | off | 122957 | 1.24 | 722 | 0.043 | 15.5 |
| TN_200_10_10 | FOUND | off | 119143 | 1.29 | 750 | 0.026 | 15.5 |
| TN_200_10_10 | NONE (refutation) + final optimize proof | on | 122608 | 1.58 | 1046 | 0.073 | 21.4 |
| TN_200_10_10 | FOUND | on | 83690 | 1.73 | 1117 | 0.043 | 21.4 |
