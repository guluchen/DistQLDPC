#!/usr/bin/env python3
"""GH-144 S0: U0 per seed and median pre-pass seconds under the four stop-rule settings (tier 1-5). usage: compare_plateaus.py > plateau_table.md"""
import json, collections, statistics
def load(f):
    d = collections.defaultdict(list)
    for l in open(f):
        r = json.loads(l)
        if 'u0' in r: d[(r['tier'], r['stem'])].append(r)
    return d
cfg = [('P64/S600', 'server/finder600.jsonl'), ('P256/S60', 'server/plat256_s60.jsonl'), ('P1000/S60', 'server/plat1000_s60.jsonl'), ('P4000/S60', 'server/plat4000_s60.jsonl')]
D = [(n, load(f)) for n, f in cfg]
keys = sorted(D[2][1].keys(), key=lambda k: (k[0], int(k[1].split('_')[1]), k[1]))
print('| Tier | Code | d | ' + ' | '.join(f'{n} U0 | {n} s' for n, _ in D) + ' |')
print('|---:|---|---|' + '---|---:|' * len(D))
for k in keys:
    if k[0] < 1: continue
    row = []
    for n, d in D:
        L = sorted(d[k], key=lambda r: r['seed'])
        row += ['/'.join(str(r['u0']) for r in L), '%.2f' % statistics.median(r['pre_seconds'] for r in L)]
    print(f"| {k[0]} | {k[1]} | {k[1].split('_')[3]} | " + ' | '.join(row) + ' |')
print()
for n, d in D:
    h = t = 0; s14 = []
    for k, L in d.items():
        f = k[1].split('_')[3]
        if f.isdigit(): h += sum(r['u0'] == int(f) for r in L); t += len(L)
        if 1 <= k[0] <= 4: s14.append(max(r['pre_seconds'] for r in L))
    print(f'- {n}: U0 = d in {h}/{t} runs on codes with a numeric stem; max pre-pass seconds on tiers 1-4: {max(s14):.2f}')
