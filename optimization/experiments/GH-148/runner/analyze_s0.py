#!/usr/bin/env python3
"""GH-148 S0 summary: per (code, mode, variant) median wall and median total conflicts over seeds; ratios vs off.
usage: analyze_s0.py RESULTS.jsonl > table.md"""
import json, sys, statistics, collections, math
rs = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
rs = [r for r in rs if 'error' not in r]
cell = collections.defaultdict(list)
for r in rs:
    conf = sum(p[4] for p in r.get('probes', []))
    last = r['probes'][-1][4] if r.get('probes') else 0
    cell[(r['tier'], r['stem'], r['mode'], r['arm'])].append((r['wall'] if r['solved'] else float(r['limit']), conf, last, r['solved'], r['result']))
def gm(x): return math.exp(sum(map(math.log, x)) / len(x)) if x else float('nan')
print('| Tier | Code | Mode | off wall s (conflicts) | bin wall s (conflicts) | seq wall s (conflicts) | bin/off wall | bin/off confl | seq/off wall | seq/off confl | answers |')
print('|---:|---|---|---|---|---|---:|---:|---:|---:|---|')
rat = collections.defaultdict(list)
for key in sorted({k[:3] for k in cell}, key=lambda k: (k[0], k[1], k[2])):
    med = {}
    for v in ('off', 'bin', 'seq'):
        L = cell.get(key + (v,), [])
        med[v] = (statistics.median(x[0] for x in L), statistics.median(x[1] for x in L)) if L else (float('nan'), float('nan'))
    ans = sorted({x[4][1] for v in ('off', 'bin', 'seq') for x in cell.get(key + (v,), []) if x[4]})
    o = med['off']
    r = lambda v, i: med[v][i] / o[i] if o[i] else float('nan')
    for v in ('bin', 'seq'):
        rat[(key[2], v, 'wall')].append(r(v, 0)); rat[(key[2], v, 'confl')].append(r(v, 1))
    print(f'| {key[0]} | {key[1]} | {key[2]} | {o[0]:.2f} ({o[1]:.0f}) | {med["bin"][0]:.2f} ({med["bin"][1]:.0f}) | {med["seq"][0]:.2f} ({med["seq"][1]:.0f}) | '
          f'{r("bin",0):.3f} | {r("bin",1):.3f} | {r("seq",0):.3f} | {r("seq",1):.3f} | {ans} |')
print()
for k in sorted(rat): print(f'- geomean {k[0]} {k[1]}/off {k[2]}: {gm(rat[k]):.3f}')
