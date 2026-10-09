# GH-60 Tier1 run record (written before launch)

Same protocol, judge and runner as GH-34 (`tier1_mac.py` byte-identical, sha256 9c316c7c…).
Frozen binaries: baseline ../frozen60/base/distqldpc (ac43af52…), candidate
../frozen60/cand/distqldpc (225e5423…). Command from the candidate worktree root:

    python3 -I optimization/experiments/GH-60/tier1_mac.py \
      --base ../frozen60/base/distqldpc --cand ../frozen60/cand/distqldpc \
      --out optimization/experiments/GH-60/raw/tier1-01 --replicate 10

Note: the runner's science check requires identical emitted progress/bound lines between
versions per case/mode. This candidate changes the search, so emitted intermediate bounds
may legitimately differ. Preregistered adaptation (fixed now, before timing): if the runner
stops ONLY because emitted lines differ while every run has rc 0 and the named distance,
the run is restarted once with `--science distance` semantics implemented as a separate
copy `tier1_mac_dist.py` that checks rc, the named distance, and bound soundness
(every d_lb <= d <= every d_ub) instead of line identity; the stop and its logs are kept.
Single attempt otherwise; no reruns for outcome.
