# GH-73 Tier1 run record (written before launch; corrected baseline 72d1fe1)
Mac host, frozen ../frozen73n/base (72d1fe1, 3f2fbc42…) vs ../frozen73n/cand (72d1fe1+GH-73, adc3e31f…),
GH-60 bound-soundness runner `tier1_mac_dist.py` unchanged, 4 cases x OFF/MTO, gate 3+3 AB/BA/AB + 10
replication pairs, 180/195 s. TIMING_LOCK file held for the whole run (other agents' solver work paused;
their correctness sweeps run on yfclab2). Unchanged GH16 judge; Tier2 LP340 only if the gate is positive
with no regression flag. Single attempt. Note: design iterations used informal runs of these cases (ATTEMPTS.md).
