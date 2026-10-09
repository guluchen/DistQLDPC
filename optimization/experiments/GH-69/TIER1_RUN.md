# GH-69 Tier1 run record (written before launch)
`tier1_mac_dist.py` (GH-60 bound-soundness runner, unchanged): frozen ../frozen69/base vs ../frozen69/cand,
4 cases x OFF/MTO, gate 3+3 AB/BA/AB + 10 replication pairs, 180/195 s, one solve at a time.
Starts only after the GH-71 Tier0 sweep has finished (no concurrent load). Unchanged GH16 judge;
confirmed regression => REJECT, no Tier2. Single attempt.
