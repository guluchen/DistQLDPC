## Cells (new vs old; median over reps, then over seeds; wall in s)

| Tier | Mode | Code | seeds | old wall | new wall | wall ratio | cpu ratio |
|---|---|---|---:|---:|---:|---:|---:|
| tier2 | cc | BB_144_14_14 | 3 | 0.6231 | 0.6204 | 0.996 | 1.006 |
| tier2 | cc | LP_544_80_12 | 3 | 0.0438 | 0.0333 | 0.759 | 0.934 |
| tier2 | cc | TN_108_2_12 | 3 | 1.8107 | 1.8118 | 1.001 | 1.001 |
| tier2 | mto | BB_144_14_14 | 3 | 13.3797 | 13.1300 | 0.981 | 0.977 |
| tier2 | mto | LP_544_80_12 | 3 | 14.5664 | 14.1177 | 0.969 | 0.968 |
| tier2 | mto | TN_108_2_12 | 3 | 19.8998 | 19.4537 | 0.978 | 0.979 |
| tier2 | nocard | BB_144_14_14 | 3 | 13.1625 | 12.6378 | 0.960 | 0.961 |
| tier2 | nocard | LP_544_80_12 | 3 | 13.9501 | 13.4979 | 0.968 | 0.968 |
| tier2 | nocard | TN_108_2_12 | 3 | 19.9104 | 19.4988 | 0.979 | 0.979 |
| tier3 | cc | HGP_481_1_16 | 3 | 0.1725 | 0.1561 | 0.905 | 0.946 |
| tier3 | cc | LP_1020_136_16 | 3 | 0.2804 | 0.2725 | 0.972 | 0.975 |
| tier3 | cc | TN_250_10_15 | 3 | 50.5596 | 50.6515 | 1.002 | 1.002 |

## Verdict per tier and mode

| Tier | Mode | cells | geomean | worst cell | cells > 1.25 | verdict |
|---|---|---:|---:|---|---:|---|
| tier2 | cc | 3 | 0.911 | 1.001 (TN_108_2_12) | 0 | PASS |
| tier2 | mto | 3 | 0.976 | 0.981 (BB_144_14_14) | 0 | PASS |
| tier2 | nocard | 3 | 0.969 | 0.979 (TN_108_2_12) | 0 | PASS |
| tier3 | cc | 3 | 0.959 | 1.002 (TN_250_10_15) | 0 | PASS |
| tier2 | all | 9 | 0.952 | 1.001 | 0 | PASS |
| tier3 | all | 3 | 0.959 | 1.002 | 0 | PASS |

## Logs

units with byte-identical stdout in every run of both arms: 34; other units: 2 (of which old itself varies across reps: 1; identical up to line order in every run: 1)
- ('tier3', 'cc', 'LP_1020_136_16', 2): distinct stdouts old 2, new 2, same set: False
- ('tier3', 'cc', 'TN_250_10_15', 0): distinct stdouts old 1, new 2, same set: False

## Answers

runs: 216; rc != 0 or answer != stem: 0 []

## Wait slack (wall - user - sys) of runs with wall < 0.2 s, in ms

| Arm | runs | median | p90 | max |
|---|---:|---:|---:|---:|
| old | 20 | 12.27 | 14.79 | 15.59 |
| new | 21 | 3.37 | 4.25 | 4.99 |
