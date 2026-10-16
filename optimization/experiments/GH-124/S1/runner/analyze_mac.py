#!/usr/bin/env python3
"""GH-124 S1 Mac quick check analysis. usage: analyze_mac.py MACDIR BASELINE_README.md > mac_summary.md
MACDIR holds results.tsv and logs/; the baseline is main 398054e's optimization/baselines/README.md."""
import math, re, statistics, sys
D, B = sys.argv[1], sys.argv[2]
base = {}
for l in open(B):
    m = re.match(r'\|\s*(\d)\s*\|\s*(\S+)\s*\|\s*(no-card|card-mto)\s*\|\s*3\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)\s*\|\s*([\d.]+)', l)
    if m: base[(m.group(2), m.group(3))] = (int(m.group(1)), float(m.group(4)), float(m.group(5)), float(m.group(6)))
rows = [l.rstrip('\n').split('\t') for l in open(f'{D}/results.tsv') if l.strip()]
cc = {}; drift = {}; bad = []
for r in rows:
    rid, rc, wall = r[0], int(r[1]), float(r[2])
    arm, stem, tag = rid.split('.')
    txt = open(f'{D}/logs/{rid}.log').read()
    o = re.findall(r'^o (\d+)', txt, re.M); d = int(stem.split('_')[3])
    if rc != 0 or not o or int(o[-1]) != d or len(r) > 4: bad.append((rid, rc, o))
    if arm == 'cc': cc.setdefault(stem, []).append(wall)
    else: drift[(stem, tag)] = wall
print('| Tier | Code | CC runs (s) | CC median | main no-card / card-mto recorded median | ratio no-card / card-mto | main drift sample no-card / card-mto (recorded range) |')
print('|---:|---|---|---:|---|---|---|')
gm = {}
for stem in sorted(cc, key=lambda s: (base[(s, 'no-card')][0], s)):
    t = base[(stem, 'no-card')][0]; med = statistics.median(cc[stem]); rat = []; dr = []
    for m in ['no-card', 'card-mto']:
        _, bm, lo, hi = base[(stem, m)]; rat.append(med / bm); gm.setdefault((t, m), []).append(med / bm)
        w = drift[(stem, m)]; flag = '' if lo * 0.97 <= w <= hi * 1.03 else ' **out**'
        dr.append(f'{w:.4g} ({lo:.4g}-{hi:.4g}){flag}')
    print(f'| {t} | {stem} | {", ".join(f"{x:.4f}" for x in cc[stem])} | {med:.4f} | {base[(stem,"no-card")][1]:.4g} / {base[(stem,"card-mto")][1]:.4g} | {rat[0]:.4f} / {rat[1]:.4f} | {dr[0]} / {dr[1]} |')
print()
print('| Tier | geomean no-card | geomean card-mto | max cell ratio |')
print('|---:|---:|---:|---:|')
for t in [0, 1, 2]:
    a = gm[(t, 'no-card')]; b = gm[(t, 'card-mto')]
    g = lambda x: math.exp(sum(map(math.log, x)) / len(x))
    print(f'| {t} | {g(a):.4f} | {g(b):.4f} | {max(a + b):.3f} |')
print()
print(f'Runs: {len(rows)}; answer/rc problems: {len(bad)} {bad}')
