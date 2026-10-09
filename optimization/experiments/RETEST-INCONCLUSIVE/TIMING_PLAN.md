# Re-test timing plan for the INCONCLUSIVE experiments (written before any timing)
PI request 2026-10-09: re-test the INCONCLUSIVE experiments. Candidates (ports on corrected baseline 72d1fe1, all
trace-identical, frozen on yfclab2 under ~/mac-agent-20261009/frozen/retest/): gh34-litvals, gh21-o2, gh16-pgo,
h007-lto, gh48-isa-v2, gh64-prefetch, gh20-watch-tail. Baseline: ~/mac-agent-20261009/frozen/tier3/base (b943c2c9…).
Layout-noise controls: relink1 (7e3b4793…), relink2 (dc9c0268…) = identical baseline objects linked in a different
order (trace-identical), timed exactly like candidates.
Host yfclab2 after the GH-85 Tier3 run has finished; one worker per binary, each pinned to its own logical CPU on
NUMA node 1 (64,65,67,68,70,71,73,74,77; siblings unused); other agents restricted to node 0.
Per binary: BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6 x {no-card, card-mto}: gate 3+3 AB/BA/AB, then 10
alternating AB/BA pairs (replication); 180/195 s; every run must reproduce the baseline's o/progress lines.
Judge: unchanged GH16 rule on the gate (all medians non-worse and envelope geomean < 1 => numerically positive;
non-overlapping regression flags), replication reported. A candidate cell counts as beyond layout noise only if
|ratio - 1| exceeds the largest |ratio - 1| of relink1/relink2 in that cell (GH-67 method). Tier2 (LP340) only for
candidates that are positive and beyond noise. Single attempt.
