# Profile of main 7eadd54 (coordinator, 2026-10-10) — evidence for GH-98
Mac, frozen-main7e (6bdcaa25…), `sample` on the solving child for 60-80 s per case (*.sample.top.txt), solver -v logs (*.v.log).
| Case | propagateForLK | lookbackResetTrail | pickAuxiVar | uncheckedEnqueueForLK | propagate |
|---|---:|---:|---:|---:|---:|
| GB_144_12_12 no-card | 67.7% | 7.2% | 5.3% | 2.2% | 4.5% |
| LP_442_68_10 no-card | 65.0% | 8.6% | 9.0% | 2.8% | 2.1% |
| LP_544_80_12 card-mto | 62.6% | 9.9% | 9.1% | 3.2% | 1.8% |
| TN_144_2_13 no-card | 70.7% | 7.0% | 4.8% | 1.9% | 4.3% |
| TN_250_10_15 no-card | 74.2% | 6.4% | 5.4% | 2.1% | 2.6% |
Instrumented build (counters only in propagateForLK; source instrumented_Solver.cc.txt), 30 s runs, last cumulative line (out3.*.log):
| Case | long-watcher visits | blocker true | learnt share of blocker-true | blocker true at lookahead base (level <= decisionLevel) of ALL visits |
|---|---:|---:|---:|---:|
| GB_144_12_12 no-card | 6.64e9 | 95.4% | 95.5% | 92.4% |
| LP_544_80_12 card-mto | 2.91e9 | 84.2% | 77.9% | 70.2% |
| TN_144_2_13 no-card | 0.15e9 | 74.4% | 75.2% | 55.7% |
| LP_340_56_8 no-card | 0.13e9 | 63.1% | 39.6% | 27.8% |
Reading: most lookahead propagation work re-checks watchers whose blocker was already true before the lookahead round
(lookahead only extends the trail, at level decisionLevel()+1). Such watchers cannot change during the round. Original
size-4 clauses (3-input XORs from SatELite elimination of xor2 auxiliaries) and size-3 clauses (xor2) are a minority of these visits.
Priority therefore: (1) skip base-satisfied watchers in lookahead (issue #99); (2) native XOR constraints (this issue) second.
