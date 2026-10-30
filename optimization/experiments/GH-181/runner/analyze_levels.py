#!/usr/bin/env python3
"""GH-181 per-level node counts (panel or ablation results): for each code, half and level, the median over seeds 0-4 of
the CC nodes of each arm and the ratio to the first arm. Only codes with a level of >= 1000 nodes are listed.
usage: analyze_levels.py results.jsonl ARM0 ARM1 [ARM2 ...]"""
import json, re, sys, statistics as st, collections
R = [json.loads(l) for l in open(sys.argv[1])]
arms = sys.argv[2:]
d = collections.defaultdict(lambda: collections.defaultdict(lambda: collections.defaultdict(dict)))
for r in R:
    if r.get('arm') not in arms: continue
    for L in r['levels']:
        m = re.match(r'(\w) level (\d+) (EMPTY|FOUND) nodes (\d+) ', L)
        if m: d[r['stem']][(m.group(1), int(m.group(2)))][r['arm']][r['seed']] = int(m.group(4))
print('| Code | half | level | ' + ' | '.join(f'{a} nodes (median)' for a in arms) + ' | ' + ' | '.join(f'{a}/{arms[0]}' for a in arms[1:]) + ' |')
print('|---|---|---:|' + '---:|' * (2 * len(arms) - 1))
for stem in sorted(d):
    for (h, w) in sorted(d[stem], key=lambda x: (x[1], x[0])):
        v = d[stem][(h, w)]
        if any(a not in v for a in arms): continue
        med = [st.median(v[a].values()) for a in arms]
        if med[0] < 1000: continue
        print(f'| {stem} | {h} | {w} | ' + ' | '.join(f'{x:,.0f}' for x in med) + ' | ' + ' | '.join(f'{x / med[0]:.3f}' for x in med[1:]) + ' |')
