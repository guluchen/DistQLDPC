#!/usr/bin/env python3
"""GH-133 oddcap panel: per (code, mode) medians off vs on, ratios, geomeans per tier/mode. usage: analyze_oddcap.py results.jsonl"""
import json, math, statistics as st, collections, sys
R = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
R = [r for r in R if 'science_ok' in r]
cells = collections.defaultdict(lambda: collections.defaultdict(list))
for r in R: cells[(r['tier'], r['stem'], r['mode'])][r['arm']].append(r['limit'] if r['result'] is None else r['wall'])
bad = [r['id'] for r in R if not r['science_ok']]
print(len(R), 'runs; science problems:', bad)
print('| Tier | Code | mode | off median (range) | on median (range) | ratio on/off | timeouts off/on |')
print('|---:|---|---|---|---|---:|---|')
geo = collections.defaultdict(list)
for (t, s, m), d in sorted(cells.items()):
    if len(d['off']) < 1 or len(d['on']) < 1: continue
    mo, mn = st.median(d['off']), st.median(d['on']); ratio = mn / mo; geo[(t, m)].append(ratio)
    lim = max(d['off'] + d['on'])
    print(f"| {t} | {s} | {m} | {mo:.2f} ({min(d['off']):.2f}-{max(d['off']):.2f}) | {mn:.2f} ({min(d['on']):.2f}-{max(d['on']):.2f}) | {ratio:.3f} | {sum(x >= 1800 for x in d['off'])}/{sum(x >= 1800 for x in d['on'])} (n={len(d['off'])}/{len(d['on'])}) |")
print()
for (t, m), v in sorted(geo.items()):
    print(f'tier {t} {m}: cells {len(v)} geomean {math.exp(sum(map(math.log, v))/len(v)):.4f} max {max(v):.3f}')
