#!/usr/bin/env python3
"""GH-128 job lists. usage: mkjobs.py server CAND MAIN > jobs.jsonl | mkjobs.py mac CAND MAIN > jobs.jsonl"""
import json, os, sys
host, cand, main = sys.argv[1:4]
LIM = {0: 600, 1: 1800, 2: 1800, 3: 1800, 4: 5000}
# rough expected seconds (server main medians, slower mode) to order longest first
EXP = {'TN_250_10_15': 3100, 'BB_288_12_18': 920, 'LP_544_80_12': 520, 'TN_144_2_13': 360, 'GB_144_12_12': 131,
       'TN_200_10_10': 130, 'BB_144_14_14': 73, 'LP_442_68_10': 46, 'TN_108_2_12': 30}
def stems(t):
    d = f'data/matrices/tier{t}'
    return sorted(f[:-7] for f in os.listdir(d) if f.endswith('_Hx.txt'))
jobs = []
def add(arm, t, s, m, seed):
    b, fl = (main, []) if arm == 'main' else (cand, ['-p1skip=on'] if arm == 'on' else [])
    jobs.append(dict(id=f'{s}.{m}.s{seed}.{arm}', arm=arm, bin=b, flags=fl, tier=t, stem=s, mode=m, seed=seed,
                     limit=LIM[t] if host == 'server' else 600))
tiers = range(5) if host == 'server' else range(3)
for t in tiers:
    for s in stems(t):
        for m in ('no-card', 'card-mto'):
            for arm in ('off', 'on'): add(arm, t, s, m, 0)
            if host == 'mac' or t <= 1: add('main', t, s, m, 0)
            if host == 'server' and t in (1, 2):
                for seed in (1, 2, 3, 4):
                    for arm in ('off', 'on'): add(arm, t, s, m, seed)
jobs.sort(key=lambda j: -EXP.get(j['stem'], 1))
for j in jobs: print(json.dumps(j))
