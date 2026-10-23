#!/usr/bin/env python3
"""GH-148 S0 summary: per (code, mode, arm) median wall and median total conflicts over seeds; ratios vs arm 'off'.
usage: analyze_s0.py RESULTS.jsonl > table.md"""
import json, sys, statistics, collections, math
rs = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
rs = [r for r in rs if 'error' not in r]
cell = collections.defaultdict(list)
arms = []
for r in rs:
    if r['arm'] not in arms: arms.append(r['arm'])
    conf = sum(p[4] for p in r.get('probes', []))
    cell[(r['tier'], r['stem'], r['mode'], r['arm'])].append((r['wall'] if r['solved'] else float(r['limit']), conf, r['result']))
others = [a for a in arms if a != 'off']
def gm(x): return math.exp(sum(map(math.log, x)) / len(x)) if x else float('nan')
print('| Tier | Code | Mode | ' + ' | '.join(f'{a} wall s (conflicts)' for a in ['off'] + others) + ' | ' +
      ' | '.join(f'{a}/off wall | {a}/off confl' for a in others) + ' | answers |')
print('|---:|---|---|' + '---|' * (1 + len(others)) + '---:|---:|' * len(others) + '---|')
rat = collections.defaultdict(list)
for key in sorted({k[:3] for k in cell}, key=lambda k: (k[0], k[1], k[2])):
    med = {}
    for v in ['off'] + others:
        L = cell.get(key + (v,), [])
        med[v] = (statistics.median(x[0] for x in L), statistics.median(x[1] for x in L)) if L else (float('nan'), float('nan'))
    ans = sorted({x[2][1] for v in arms for x in cell.get(key + (v,), []) if x[2]})
    o = med['off']
    cols = []
    for v in others:
        a, b = med[v][0] / o[0], med[v][1] / o[1] if o[1] else float('nan')
        rat[(v, 'wall')].append(a); rat[(v, 'confl')].append(b); cols.append(f'{a:.3f} | {b:.3f}')
    print(f'| {key[0]} | {key[1]} | {key[2]} | ' + ' | '.join(f'{med[v][0]:.2f} ({med[v][1]:.0f})' for v in ['off'] + others) + ' | ' + ' | '.join(cols) + f' | {ans} |')
print()
for k in sorted(rat): print(f'- geomean {k[0]}/off {k[1]}: {gm(rat[k]):.3f} over {len(rat[k])} cells')
