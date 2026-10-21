#!/usr/bin/env python3
"""GH-138 S1 summary (copied from GH-133) of the CC queue results (panel old vs new per cell; tier5 progress). usage: summarize_cc.py DIR"""
import json, math, statistics as st, collections, sys, time
D = sys.argv[1]
R = [json.loads(l) for l in open(f'{D}/results.jsonl')]
P = [r for r in R if r.get('id', '').startswith('cc.')]
cells = collections.defaultdict(lambda: collections.defaultdict(list))
for r in P: cells[(r['tier'], r['stem'])][r['arm']].append((r['seed'], r['wall'], r['result'][1] if r['result'] else None))
bad = [r['id'] for r in R if 'science_ok' in r and not r['science_ok']]
print(len(P), 'panel runs, science problems:', bad)
pert = collections.defaultdict(list)
print('tier stem | old median (range) | new median (range) | ratio new/old | answers')
for (t, s), d in sorted(cells.items()):
    wo = [w for _, w, _ in d['old']]; wn = [w for _, w, _ in d['new']]
    if not wo or not wn: print(t, s, 'incomplete', len(wo), len(wn)); continue
    mo, mn = st.median(wo), st.median(wn); ratio = mn / mo; pert[t].append(ratio)
    ans = sorted(set(a for _, _, a in d['old'] + d['new']))
    print(f'{t} {s:16s} | {mo:8.3f} ({min(wo):.3f}-{max(wo):.3f}) | {mn:8.3f} ({min(wn):.3f}-{max(wn):.3f}) | {ratio:.3f} | {ans} n={len(wo)}/{len(wn)}')
for t, v in sorted(pert.items()):
    print(f'tier {t}: cells {len(v)} geomean {math.exp(sum(map(math.log, v)) / len(v)):.4f} max {max(v):.3f} min {min(v):.3f}')
T5 = [r for r in R if r.get('id', '').startswith('cc5.')]
print('\ntier5 done:', len(T5))
for r in sorted(T5, key=lambda r: r['stem']):
    ev = ' '.join(f'{v}@{int(t)}' for t, v in r['lb_events'] if v >= 15)
    print(f"{r['stem']:18s} result {r['result']} lb/ub {r['final_lb']}/{r['final_ub']} wall {r['wall']:.0f} issues {r['issues']} | {ev}")
