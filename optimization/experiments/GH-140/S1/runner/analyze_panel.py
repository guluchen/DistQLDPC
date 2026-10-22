#!/usr/bin/env python3
"""GH-140 panel: per cell (tier, code) over seeds 0-4: wall median off/on and ratio on/off, total CC nodes (sum over
completed levels) median ratio, answers, and the ub-search effect (median wall of the first d_ub event equal to the
answer, on arm). Several files (repetitions) are pooled: each (file, seed) is one sample.
usage: analyze_panel.py results.jsonl [results2.jsonl ...]"""
import json, re, sys, math, statistics as st, collections
P = []
for fi, path in enumerate(sys.argv[1:]):
    for l in open(path):
        r = json.loads(l)
        if r.get('id', '').startswith('cc.'):
            r['seed'] = (fi, r['seed']); P.append(r)
cell = collections.defaultdict(lambda: collections.defaultdict(dict))
for r in P:
    n = 0
    for L in r['levels']:
        m = re.search(r' nodes (\d+) ', L)
        if m and 'nodes-by-budget' not in L: n += int(m.group(1))
    d = r['result'][1] if r['result'] else None
    tub = min([t for t, x in r['ub_events'] if d is not None and x == d], default=None)
    cell[(r['tier'], r['stem'])][r['seed']][r['arm']] = (r['wall'], n, d, tub)
print('| Tier | Code | off wall median (range) | on wall median (range) | ratio on/off | nodes on/off (median) | on: first d_ub = d at (median s) | off: same | answers |')
print('|---:|---|---|---|---:|---:|---:|---:|---|')
per = collections.defaultdict(list)
for (tier, stem), d in sorted(cell.items()):
    seeds = [s for s in d if 'off' in d[s] and 'on' in d[s]]
    wo = [d[s]['off'][0] for s in seeds]; wn = [d[s]['on'][0] for s in seeds]
    nr = [d[s]['on'][1] / d[s]['off'][1] for s in seeds if d[s]['off'][1] > 0]
    ans = sorted(set(str(d[s][a][2]) for s in seeds for a in ('off', 'on')))
    tu = [d[s]['on'][3] for s in seeds if d[s]['on'][3] is not None]
    to = [d[s]['off'][3] for s in seeds if d[s]['off'][3] is not None]
    ratio = st.median(wn) / st.median(wo); per[tier].append(ratio)
    print(f'| {tier} | {stem} | {st.median(wo):.3f} ({min(wo):.3f}-{max(wo):.3f}) | {st.median(wn):.3f} ({min(wn):.3f}-{max(wn):.3f}) | '
          f'{ratio:.3f} | {st.median(nr):.3f} | {st.median(tu):.3f} | {st.median(to):.3f} | {",".join(ans)} |' if nr and tu and to else
          f'| {tier} | {stem} | {st.median(wo):.3f} | {st.median(wn):.3f} | {ratio:.3f} | - | - | - | {",".join(ans)} |')
print()
print('| Tier | cells | geomean | max cell | cells > 1.25 |')
print('|---:|---:|---:|---:|---:|')
for t, v in sorted(per.items()):
    print(f'| {t} | {len(v)} | {math.exp(sum(map(math.log, v)) / len(v)):.3f} | {max(v):.3f} | {sum(x > 1.25 for x in v)} |')
bad = [r['id'] for r in P if not r.get('science_ok')]
print(f'\n{len(P)} runs, science problems: {bad}')
