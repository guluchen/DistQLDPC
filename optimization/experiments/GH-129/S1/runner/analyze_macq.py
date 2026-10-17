#!/usr/bin/env python3
"""GH-129 Mac quick check: cand -frontier=on, 3 serial runs per tier0-2 cell, vs the recorded Mac main table
(optimization/baselines/README.md, main 398054e) plus one drift sample of frozen main abd1770 per cell.
usage: analyze_macq.py results.tsv logs_dir README.md"""
import math, re, statistics, sys, collections
res, logs, readme = sys.argv[1:4]
ref = {}
for l in open(readme):
    m = re.match(r'\| (\d) \| (\S+) \| (no-card|card-mto) \| 3 \| ([\d.]+) \| ([\d.]+) \| ([\d.]+) \|', l)
    if m: ref[(m.group(2), m.group(3))] = tuple(map(float, m.group(4, 5, 6)))
runs = collections.defaultdict(list); drift = {}; tier = {}; bad = []
for l in open(res):
    f = l.rstrip('\n').split('\t'); t, c, m, arm, k = f[0].split('|'); tier[c] = int(t[-1])
    log = open(f'{logs}/{c}.{m}.{arm}{k}.log').read(); o = re.findall(r'^o (\d+)', log, re.M)
    if f[1] != '0' or not o or o[-1] != c.split('_')[3] or len(f) > 4: bad.append(f[0])
    (runs[(c, m)].append(float(f[2])) if arm == 'cand' else drift.__setitem__((c, m), float(f[2])))
g = lambda x: math.exp(sum(map(math.log, x)) / len(x))
print('| Tier | Code | Mode | cand runs (s) | cand median | main recorded median (range) | ratio | main drift sample |')
print('|---:|---|---|---|---:|---|---:|---|')
rat = collections.defaultdict(list)
for (c, m) in sorted(runs, key=lambda k: (tier[k[0]], k)):
    x = runs[(c, m)]; md = statistics.median(x); r0 = ref[(c, m)]; r = md / r0[0]; rat[(tier[c], m)].append(r)
    d = drift[(c, m)]; out = '' if r0[1] * 0.97 <= d <= r0[2] * 1.03 else ' **out**'
    print(f'| {tier[c]} | {c} | {m} | {", ".join("%.4g" % v for v in x)} | {md:.4g} | {r0[0]:.4g} ({r0[1]:.4g}-{r0[2]:.4g}) | {r:.3f} | {d:.4g}{out} |')
print('\n| Tier | geomean no-card | geomean card-mto | max cell |\n|---:|---:|---:|---:|')
for t in (0, 1, 2):
    a, b = rat[(t, 'no-card')], rat[(t, 'card-mto')]
    print(f'| {t} | {g(a):.3f} | {g(b):.3f} | {max(a + b):.3f} |')
print(f'\nRuns with rc != 0, wrong answer or memory kill: {bad or "none"} ({sum(len(v) for v in runs.values())} cand runs, {len(drift)} main samples).')
