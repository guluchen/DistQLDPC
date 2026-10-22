#!/usr/bin/env python3
"""GH-140 S0 finder-only runs (-cc-ub-only): per code and arm over seeds: time of the first d_ub event equal to the true
distance (stems with a numeric d), and the best ub after 60 s and after the whole budget (600 s). Event times are wall
seconds from process start (parse, detector check, dual-map detection included). With -ub-basis on (arm base) the first
event is the basis-row bound (column 'basis'). usage: analyze_finder.py results.jsonl [results2.jsonl ...]"""
import json, sys, statistics as st, collections
R = []
for p in sys.argv[1:]:
    R += [json.loads(l) for l in open(p) if l.strip()]
cell = collections.defaultdict(dict)
for r in R:
    if 'stem' not in r: continue
    cell[(r['arm'], r['tier'], r['stem'])][r['seed']] = r
def dval(stem):
    f = stem.split('_')[3]
    return int(f) if f.isdigit() else None
def ub_at(r, T):
    v = [x for t, x in r['ub_events'] if t <= T]
    return min(v) if v else None
def fmt_list(v):
    return '/'.join('-' if x is None else (f'{x:.2f}' if isinstance(x, float) else str(x)) for x in v)
print('| arm | tier | code | d (stem) | basis ub | time to ub = d, per seed (s) | median | ub @ 60 s per seed | ub @ 600 s per seed |')
print('|---|---:|---|---|---:|---|---:|---|---|')
for (arm, tier, stem), d in sorted(cell.items(), key=lambda kv: (kv[0][0], kv[0][1], kv[0][2])):
    seeds = sorted(d)
    dv = dval(stem)
    basis = d[seeds[0]]['ub_events'][0][1] if arm == 'base' and d[seeds[0]]['ub_events'] else '-'
    tt = []
    for s in seeds:
        r = d[s]
        tt.append(min([t for t, x in r['ub_events'] if dv is not None and x <= dv], default=None))
    med = st.median([t for t in tt if t is not None]) if dv is not None and all(t is not None for t in tt) else None
    print(f"| {arm} | {tier} | {stem} | {dv if dv is not None else stem.split('_')[3]} | {basis} | {fmt_list(tt) if dv is not None else 'n/a'} | "
          f"{'-' if med is None else f'{med:.2f}'} | {fmt_list([ub_at(d[s], 60) for s in seeds])} | {fmt_list([ub_at(d[s], 1e9) for s in seeds])} |")
bad = [r['id'] for r in R if 'stem' in r and not r.get('science_ok')]
print(f'\n{len(R)} runs, science problems: {bad}')
