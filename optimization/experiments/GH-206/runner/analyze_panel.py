#!/usr/bin/env python3
"""GH-183 panel (from GH-162's): per cell (tier, code) over seeds 0-4, for each candidate arm X and each reference arm
REF in {main, tb}: ratio = median wall(X) / median wall(REF); median over seeds of the total CC node ratio; seed ranges.
Per tier and reference: geomean of the ratios, max cell, cells > 1.25. usage: analyze_panel.py results.jsonl [ARMS]"""
import json, re, sys, math, statistics as st, collections
R = [json.loads(l) for l in open(sys.argv[1])]
P = [r for r in R if r.get('id', '').startswith('cc.') and 'wall' in r]
cell = collections.defaultdict(lambda: collections.defaultdict(dict))
arms_seen = []
for r in P:
    n = t = 0
    for L in r['levels']:
        m = re.search(r' nodes (\d+) .* time ([\d.]+)s', L)
        if m and 'nodes-by-budget' not in L: n += int(m.group(1)); t += float(m.group(2))
    cell[(r['tier'], r['stem'])][r['seed']][r['arm']] = (r['wall'], n, t, r['result'][1] if r['result'] else None)
    if r['arm'] not in arms_seen: arms_seen.append(r['arm'])
arms = sys.argv[2].split(',') if len(sys.argv) > 2 else arms_seen
g = lambda v: math.exp(sum(map(math.log, v)) / len(v)) if v else float('nan')
print('Wall time median over seeds 0-4 (range), seconds:\n')
print('| Tier | Code | ' + ' | '.join(arms) + ' | answers |')
print('|---:|---|' + '---|' * len(arms) + '---|')
for (tier, stem), d in sorted(cell.items()):
    cols = []
    for a in arms:
        w = [d[s][a][0] for s in d if a in d[s]]
        cols.append(f'{st.median(w):.3f} ({min(w):.3f}-{max(w):.3f})' if w else '-')
    ans = sorted(set(d[s][a][3] for s in d for a in arms if a in d[s]))
    print(f'| {tier} | {stem} | ' + ' | '.join(cols) + f' | {ans} |')
for ref in ('main', 'tb'):
    for x in arms:
        if x in ('main', ref) or (ref == 'tb' and x == 'tb'): continue
        print(f'\n### {x} vs {ref}\n')
        print('| Tier | Code | wall ratio | nodes ratio (median over seeds) |')
        print('|---:|---|---:|---:|')
        per = collections.defaultdict(list)
        for (tier, stem), d in sorted(cell.items()):
            ss = [s for s in d if x in d[s] and ref in d[s]]
            if not ss: continue
            ratio = st.median([d[s][x][0] for s in ss]) / st.median([d[s][ref][0] for s in ss])
            nr = [d[s][x][1] / d[s][ref][1] for s in ss if d[s][ref][1] > 0]
            per[tier].append(ratio)
            print(f'| {tier} | {stem} | {ratio:.3f} | {st.median(nr):.3f} |' if nr else f'| {tier} | {stem} | {ratio:.3f} | - |')
        print('\n| Tier | cells | geomean | max cell | cells > 1.25 |')
        print('|---:|---:|---:|---:|---:|')
        for t, v in sorted(per.items()):
            print(f'| {t} | {len(v)} | {g(v):.3f} | {max(v):.3f} | {sum(r > 1.25 for r in v)} |')
bad = [r['id'] for r in P if not r.get('science_ok')]
print(f'\n{len(P)} runs, science problems: {bad}')
