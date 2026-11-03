#!/usr/bin/env python3
"""GH-181 panel (copied from GH-152; arms main = main 6083e66 CC, sp = candidate with sparse,sparseov,sparsemrv): per cell (tier, code) over seeds 0-4: wall median old/new and ratio, total CC nodes (sum over levels,
deterministic per seed) median ratio, ns per node old/new. usage: analyze_panel.py results.jsonl"""
import json, re, sys, math, statistics as st, collections
R = [json.loads(l) for l in open(sys.argv[1])]
P = [r for r in R if r.get('id', '').startswith('cc.')]
cell = collections.defaultdict(lambda: collections.defaultdict(dict))
for r in P:
    n = t = 0
    for L in r['levels']:
        m = re.search(r' nodes (\d+) .* time ([\d.]+)s', L)
        if m and 'nodes-by-budget' not in L: n += int(m.group(1)); t += float(m.group(2))
    cell[(r['tier'], r['stem'])][r['seed']][r['arm']] = (r['wall'], n, t, r['result'][1] if r['result'] else None)
print('| Tier | Code | main wall median (range) | sp wall median (range) | ratio | nodes sp/main (median over seeds) | search ns/node main -> sp | answers |')
print('|---:|---|---|---|---:|---:|---|---|')
per = collections.defaultdict(list); allr = []
for (tier, stem), d in sorted(cell.items()):
    wo = [d[s]['main'][0] for s in d]; wn = [d[s]['sp'][0] for s in d]
    nr = [d[s]['sp'][1] / d[s]['main'][1] for s in d if d[s]['main'][1] > 0]
    npo = [1e9 * d[s]['main'][2] / d[s]['main'][1] for s in d if d[s]['main'][1] > 1e5]
    npn = [1e9 * d[s]['sp'][2] / d[s]['sp'][1] for s in d if d[s]['sp'][1] > 1e5]
    ans = sorted(set(d[s][a][3] for s in d for a in ('main', 'sp')))
    ratio = st.median(wn) / st.median(wo); per[tier].append(ratio); allr.append(ratio)
    npn_s = f'{st.median(npo):.0f} -> {st.median(npn):.0f}' if npo and npn else '(process floor)'
    print(f'| {tier} | {stem} | {st.median(wo):.3f} ({min(wo):.3f}-{max(wo):.3f}) | {st.median(wn):.3f} ({min(wn):.3f}-{max(wn):.3f}) | {ratio:.3f} | '
          f'{st.median(nr):.3f} | {npn_s} | {ans} |' if nr else f'| {tier} | {stem} | ... | ... | {ratio:.3f} | - | - | {ans} |')
print()
print('| Tier | cells | geomean | max cell | cells > 1.25 |')
print('|---:|---:|---:|---:|---:|')
for t, v in sorted(per.items()):
    print(f'| {t} | {len(v)} | {math.exp(sum(map(math.log, v)) / len(v)):.3f} | {max(v):.3f} | {sum(x > 1.25 for x in v)} |')
bad = [r['id'] for r in P if not r.get('science_ok')]
print(f'\n{len(P)} runs, science problems: {bad}')
