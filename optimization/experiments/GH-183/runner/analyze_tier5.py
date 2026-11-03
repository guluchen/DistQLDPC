#!/usr/bin/env python3
"""GH-183 Tier 5 (from GH-162's): arms main (main 6083e66 / 346d1c6 CC), tb (GH-162 tiebreak), tbmrvbfs, tbmrvbfsa; 6 h,
default seed. Several results files may be given (GH-162's Tier 5 file supplies main and tb for the codes not re-run here;
a later file overrides an earlier one per (code, arm)). Per code: result or final certified lb per arm; time to reach the
main arm's final value; for the largest level every arm completed (EMPTY), the CC nodes and level seconds per arm and
the ratios vs main and vs tb; lb events from 24 up. usage: analyze_tier5.py results1.jsonl [results2.jsonl ...]"""
import json, re, sys, math, collections
T = collections.defaultdict(dict)
for f in sys.argv[1:]:
    for l in open(f):
        r = json.loads(l)
        if r.get('id', '').startswith('t5.') and 'wall' in r: T[r['stem']][r['arm']] = r
ARMS = ['main', 'tb', 'tbmrvbfs', 'tbmrvbfsa']
def levels(r):
    d = collections.defaultdict(dict)
    for L in r['levels']:
        m = re.match(r'(\w) level (\d+) (\w+) nodes (\d+) .* time ([\d.]+)s', L)
        if m: d[int(m.group(2))][m.group(1)] = (m.group(3), int(m.group(4)), float(m.group(5)))
    return d
def res(r): return f"d={r['result'][1]} @ {r['wall']:.0f} s" if r['result'] else f"TIMEOUT lb {r['final_lb']}"
def lbt(r, v):
    if r['result'] and r['result'][1] <= v: return r['result'][0]
    for t, x in r['lb_events']:
        if x >= v: return t
    return None
def ev(r, lo=24): return ' '.join(f'{x}@{t:.0f}' for t, x in r['lb_events'] if x >= lo)
g = lambda v: math.exp(sum(map(math.log, v)) / len(v)) if v else float('nan')
order = sorted(T, key=lambda s: (s[:2], int(s.split('_')[1]), s))
print('| Code | ' + ' | '.join(ARMS) + ' |'); print('|---|' + '---|' * len(ARMS))
for s in order: print(f'| {s} | ' + ' | '.join(res(T[s][a]) if a in T[s] else '-' for a in ARMS) + ' |')
print('\nTime to reach the main arm\'s final value (s; ratio vs main, vs tb):\n')
print('| Code | target | ' + ' | '.join(ARMS) + ' |'); print('|---|---:|' + '---|' * len(ARMS))
for s in order:
    if 'main' not in T[s]: continue
    o = T[s]['main']; target = o['result'][1] if o['result'] else o['final_lb']
    tm = lbt(o, target); tt = lbt(T[s]['tb'], target) if 'tb' in T[s] else None
    cols = []
    for a in ARMS:
        if a not in T[s]: cols.append('-'); continue
        t = lbt(T[s][a], target)
        cols.append('not reached' if t is None else f'{t:.0f}' + (f' ({t/tm:.3f}, {t/tt:.3f})' if tm and tt and a not in ('main', 'tb') and tm > 0 and tt > 0 else ''))
    print(f'| {s} | {target} | ' + ' | '.join(cols) + ' |')
print('\nLargest level completed (EMPTY) by every arm present: nodes (M) and level seconds per arm; ratios vs main / vs tb:\n')
print('| Code | level | ' + ' | '.join(ARMS) + ' |'); print('|---|---:|' + '---|' * len(ARMS))
rat = collections.defaultdict(list)
for s in order:
    arms = [a for a in ARMS if a in T[s]]
    L = {a: levels(T[s][a]) for a in arms}
    both = [w for w in L[arms[0]] if all(w in L[a] and L[a][w] and all(v[0] == 'EMPTY' for v in L[a][w].values()) for a in arms)]
    if not both: print(f'| {s} | - |' + ' - |' * len(ARMS)); continue
    w = max(both)
    val = {a: (sum(v[1] for v in L[a][w].values()), sum(v[2] for v in L[a][w].values())) for a in arms}
    cols = []
    for a in ARMS:
        if a not in val: cols.append('-'); continue
        n, t = val[a]; c = f'{n/1e6:.1f}M, {t:.1f} s'
        for ref in ('main', 'tb'):
            if ref in val and a not in ('main', 'tb') and val[ref][0] > 0 and val[ref][1] > 1:
                c += f'; vs {ref} {n/val[ref][0]:.3f} / {t/val[ref][1]:.3f}'
                rat[(a, ref, 'n')].append(n / val[ref][0]); rat[(a, ref, 't')].append(t / val[ref][1])
        cols.append(c)
    print(f'| {s} | {w} | ' + ' | '.join(cols) + ' |')
print('\nGeomeans over codes (largest common level, levels > 1 s): ' + '; '.join(f'{a} vs {ref} {k} {g(v):.3f} ({len(v)})' for (a, ref, k), v in sorted(rat.items())))
print('\nlb events from 24 (value@s):\n')
print('| Code | ' + ' | '.join(ARMS) + ' |'); print('|---|' + '---|' * len(ARMS))
for s in order:
    if s.startswith('LP'): continue
    print(f'| {s} | ' + ' | '.join(ev(T[s][a]) if a in T[s] else '-' for a in ARMS) + ' |')
allr = [r for s in T for r in T[s].values()]
print(f'\n{len(allr)} runs, science problems: {[r["id"] for r in allr if not r.get("science_ok")]}')
