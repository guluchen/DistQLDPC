#!/usr/bin/env python3
"""GH-157 panel (adapted from GH-152): per cell (tier, code) over seeds 0-4, for the pairs main -> cand (main's CC defaults
vs + charge) and autbase -> autcand (both with -cc-aut=on, GH-152 binary vs GH-157 on GH-152): wall median and range,
ratio of medians, total CC nodes (sum over levels, deterministic per seed) median ratio, search ns per node, answers.
Per tier: geomean of the cell ratios, max cell, cells > 1.25. usage: analyze_panel.py results.jsonl [prefix]"""
import json, re, sys, math, statistics as st, collections
R = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
pref = sys.argv[2] if len(sys.argv) > 2 else 'cc.'
P = [r for r in R if r.get('id', '').startswith(pref) and 'levels' in r]
cell = collections.defaultdict(lambda: collections.defaultdict(dict))
for r in P:
    n = t = 0
    for L in r['levels']:
        m = re.search(r' level \d+ \w+ nodes (\d+) .* time ([\d.]+)s', L)
        if m: n += int(m.group(1)); t += float(m.group(2))
    cell[(r['tier'], r['stem'])][r['seed']][r['arm']] = (r['wall'], n, t, r['result'][1] if r['result'] else None)
for old, new in (('main', 'cand'), ('autbase', 'autcand')):
    print(f'\n### {old} -> {new}\n')
    print(f'| Tier | Code | {old} wall median (range) | {new} wall median (range) | ratio | nodes {new}/{old} (median) | search ns/node | answers |')
    print('|---:|---|---|---|---:|---:|---|---|')
    per = collections.defaultdict(list)
    for (tier, stem), d in sorted(cell.items()):
        seeds = [s for s in d if old in d[s] and new in d[s]]
        if not seeds: continue
        wo = [d[s][old][0] for s in seeds]; wn = [d[s][new][0] for s in seeds]
        nr = [d[s][new][1] / d[s][old][1] for s in seeds if d[s][old][1] > 0]
        npo = [1e9 * d[s][old][2] / d[s][old][1] for s in seeds if d[s][old][1] > 1e5]
        npn = [1e9 * d[s][new][2] / d[s][new][1] for s in seeds if d[s][new][1] > 1e5]
        ans = sorted(set(d[s][a][3] for s in seeds for a in (old, new)))
        ratio = st.median(wn) / st.median(wo); per[tier].append(ratio)
        nps = f'{st.median(npo):.0f} -> {st.median(npn):.0f}' if npo and npn else '(process floor)'
        print(f'| {tier} | {stem} | {st.median(wo):.3f} ({min(wo):.3f}-{max(wo):.3f}) | {st.median(wn):.3f} ({min(wn):.3f}-{max(wn):.3f}) | '
              f'{ratio:.3f} | {st.median(nr) if nr else float("nan"):.3f} | {nps} | {ans} |')
    print('\n| Tier | cells | geomean | max cell | cells > 1.25 |')
    print('|---:|---:|---:|---:|---:|')
    for t, v in sorted(per.items()):
        print(f'| {t} | {len(v)} | {math.exp(sum(map(math.log, v)) / len(v)):.3f} | {max(v):.3f} | {sum(x > 1.25 for x in v)} |')
bad = [r['id'] for r in P if not r.get('science_ok')]
print(f'\n{len(P)} runs, science problems: {bad}')
