#!/usr/bin/env python3
"""GH-181 ablation (TN_200, TN_250; seeds 0-4): per arm the median wall (range), wall ratio and total-node ratio vs main
(medians over seeds). usage: analyze_ablation.py results.jsonl"""
import json, re, sys, statistics as st, collections
R = [json.loads(l) for l in open(sys.argv[1])]
d = collections.defaultdict(lambda: collections.defaultdict(list))
for r in R:
    n = sum(int(m.group(1)) for L in r['levels'] if 'nodes-by-budget' not in L and ' gh181 ' not in L for m in [re.search(r' nodes (\d+) ', L)] if m)
    d[r['stem']][r['arm']].append((r['seed'], r['wall'], n, r['result'][1] if r['result'] else None))
ARMS = [('main', 'main CC'), ('mainmrv', 'main + mrv'), ('ov', '+sparseov'), ('xu', '+xorunit'), ('sparse', '+sparse'),
        ('spov', '+sparse,sparseov'), ('spmrv', '+sparse,sparsemrv'), ('sp', '+sparse,sparseov,sparsemrv (candidate)'),
        ('spxu', '+sparse,sparseov,sparsemrv,xorunit')]
print('| Code | arm | wall median (range) s | wall / main | total nodes median | nodes / main | answers |')
print('|---|---|---|---:|---:|---:|---|')
for stem in sorted(d):
    mw = st.median(x[1] for x in d[stem]['main']); mn = st.median(x[2] for x in d[stem]['main'])
    for a, name in ARMS:
        v = d[stem][a]; w = [x[1] for x in v]; n = [x[2] for x in v]
        print(f'| {stem} | {name} | {st.median(w):.3f} ({min(w):.3f}-{max(w):.3f}) | {st.median(w) / mw:.3f} | {st.median(n):,.0f} | '
              f'{st.median(n) / mn:.3f} | {sorted(set(x[3] for x in v))} |')
