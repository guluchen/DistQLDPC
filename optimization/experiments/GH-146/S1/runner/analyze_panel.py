#!/usr/bin/env python3
"""GH-146 S1 panel summary: median over seeds of wall seconds per (code, engine/mode, arm) (a run without an answer
counts as its limit), ratio = median(new) / median(old), geomean per (tier, mode), max cell, cells > 1.25; answers vs
stem; median time of the first c d_ub equal to the answer per arm. usage: analyze_panel.py RESULTS.jsonl [...]"""
import json, math, statistics, sys, collections
rs = []
for fn in sys.argv[1:]:
    rs += [json.loads(l) for l in open(fn) if l.strip()]
rs = [r for r in rs if 'error' not in r]
cell = collections.defaultdict(list)
for r in rs:
    t = r['wall'] if r['solved'] else float(r['limit'])
    cell[(r['tier'], r['stem'], r['mode'], r['arm'])].append((r['seed'], t, r))
def gm(xs): return math.exp(sum(math.log(x) for x in xs) / len(xs)) if xs else float('nan')
def first_d(r):
    if not r['result']: return None
    h = [e for e, u in r['ub_events'] if u == r['result'][1]]
    return min(h) if h else None
MODES = ('cc', 'no-card', 'card-mto')
print('| Tier | Code | Engine / mode | old median s (seeds 0-4) | new median s (seeds 0-4) | ratio new/old | first d_ub = d: old / new (median s) | answers |')
print('|---:|---|---|---|---|---:|---|---|')
ratios = collections.defaultdict(list); bad = []
keys = sorted({(t, s, m) for (t, s, m, a) in cell}, key=lambda k: (k[0], int(k[1].split('_')[1]), k[1], MODES.index(k[2])))
for (t, s, m) in keys:
    A = sorted(cell.get((t, s, m, 'old'), [])); B = sorted(cell.get((t, s, m, 'new'), []))
    if len(A) < 5 or len(B) < 5: print(f'| {t} | {s} | {m} | incomplete ({len(A)}/{len(B)}) | | | | |'); continue
    ma = statistics.median(x[1] for x in A); mb = statistics.median(x[1] for x in B)
    ratio = mb / ma; ratios[(t, m)].append(ratio)
    fa = [first_d(x[2]) for x in A]; fb = [first_d(x[2]) for x in B]
    fa = [x for x in fa if x is not None]; fb = [x for x in fb if x is not None]
    ans = sorted({x[2]['result'][1] for x in A + B if x[2]['result']})
    unsolved = sum(not x[2]['solved'] for x in A), sum(not x[2]['solved'] for x in B)
    for x in A + B:
        if not x[2]['science_ok']: bad.append((x[2]['id'], x[2]['issues']))
    fmt = lambda L: ' '.join(('%.2f' % x[1]) + ('T' if not x[2]['solved'] else '') for x in L)
    fd = f'{statistics.median(fa) if fa else float("nan"):.3f} / {statistics.median(fb) if fb else float("nan"):.3f}'
    print(f'| {t} | {s} | {m} | {ma:.2f} ({fmt(A)}) | {mb:.2f} ({fmt(B)}) | {ratio:.3f} | {fd} | {ans}{" unsolved %d/%d" % unsolved if any(unsolved) else ""} |')
print()
print('| Tier | Engine / mode | cells | geomean new/old | max cell | cells > 1.25 |')
print('|---:|---|---:|---:|---:|---:|')
for t in sorted({k[0] for k in ratios}):
    for m in MODES:
        xs = ratios[(t, m)]
        if xs: print(f'| {t} | {m} | {len(xs)} | {gm(xs):.3f} | {max(xs):.3f} | {sum(x > 1.25 for x in xs)} |')
print()
print(f'runs: {len(rs)}; science problems: {bad}')
