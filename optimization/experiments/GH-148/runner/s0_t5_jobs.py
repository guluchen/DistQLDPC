#!/usr/bin/env python3
"""GH-148 S0 Tier 5 probe (informational, not a gate): candidate binary, -stab-overlap off vs on, -no-card, default
seed, 3600 s, on Tier 5 codes whose first refutations finish within an hour on main (time to lb 18 / lb 17 / solve).
usage: s0_t5_jobs.py CAND OUT.jsonl"""
import json, sys
CAND, OUT = sys.argv[1:3]
codes = ['BB_360_12_24', 'BB_756_16_ge30', 'BB_864_4_ge30', 'LP_1020_136_16', 'LP_1122_148_20', 'TN_180_2_17', 'TN_216_4_18',
         'TN_396_4_ge17', 'TN_360_4_ge17', 'TN_612_2_ge17', 'TN_504_2_ge17', 'TN_288_2_ge9', 'LP_2610_744_16', 'TN_684_2_ge9']
with open(OUT, 'w') as fh:
    for stem in codes:
        for vn, ex in (('off', []), ('on', ['-stab-overlap=on'])):
            fh.write(json.dumps(dict(id=f's0t5.{stem}.{vn}', bin=CAND, args=['-no-card', '-frontier-stats'] + ex, code=f'data/matrices/tier5/{stem}',
                                     stem=stem, tier=5, arm=vn, seed=0, mode='no-card', limit=3600)) + '\n')
