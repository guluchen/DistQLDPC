# GH-67 Tier1 run record (written before launch)

Sequential, one solve at a time, same host session, frozen binaries (`frozen-binaries.sha256`):
1. Candidate vs baseline: `tier1_mac.py --base ../frozen67/base/distqldpc --cand ../frozen67/cand/distqldpc --out raw/tier1-cand --replicate 10`
2. R1, R2, R3 vs baseline: `tier1_mac.py --base ../frozen67/base/distqldpc --cand ../frozen67/R{k}/distqldpc --out raw/tier1-R{k} --replicate 0`
Unchanged GH16 judge for the candidate. Noise floor per cell = max over R1–R3 of |median ratio - 1|;
a candidate cell is "beyond layout noise" only if its |median ratio - 1| exceeds that floor.
Single attempt; no reruns for outcome.
