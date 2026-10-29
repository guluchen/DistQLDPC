#!/usr/bin/env python3
"""GH-157 S0: per code, -ub-search=off, default seed, all runs serial on one pinned core (63): main 123011d vs the candidate
c3c315d with `charge` (gap 0, minr 3, raise on), `charge` with the gap gate off (-cc-lb-gap=1000), `ecover` alone and
`charge,ecover`. Prints total nodes, wall, and for the three most expensive levels of main the nodes and search time per
arm, plus the candidate's evaluations / prunes per level and prunes by remaining budget. usage: analyze_s0.py s0_results.jsonl"""
import json, re, sys, collections
by = collections.defaultdict(dict)
for l in open(sys.argv[1]):
    r = json.loads(l)
    lv = {}; lb = {}; bb = {}
    for L in r['levels']:
        m = re.match(r'(\w) level (\d+) (\w+) nodes (\d+) .* time ([\d.]+)s', L)
        if m: lv[(m.group(1), int(m.group(2)))] = (int(m.group(4)), float(m.group(5)))
        m = re.match(r'(\w) level (\d+) lb lbeval (\d+) chgprune (\d+) ecprune (\d+)', L)
        if m: lb[(m.group(1), int(m.group(2)))] = (int(m.group(3)), int(m.group(4)) + int(m.group(5)))
        m = re.match(r'(\w) level (\d+) lbprune-by-budget (.*)', L)
        if m: bb[(m.group(1), int(m.group(2)))] = [int(x) for x in m.group(3).split()]
    by[r['stem']][r['arm']] = (r, lv, lb, bb)
arms = ['cand', 'gapinf', 'ecover', 'both']
print('| Code | arm | wall s (ratio) | total nodes (ratio) | top levels: nodes ratio / time ratio | evaluations, prune rate (top level) |')
print('|---|---|---|---|---|---|')
for stem, d in by.items():
    r0, l0, _, _ = d['main']
    keys = sorted(l0, key=lambda k: -l0[k][1])[:3]
    keys.sort(key=lambda k: (k[1], k[0]))
    n0 = sum(v[0] for v in l0.values())
    print(f"| {stem} | main | {r0['wall']:.2f} | {n0/1e6:.2f}M | " + ', '.join(f'{k[0]}{k[1]}: {l0[k][0]/1e6:.2f}M {l0[k][1]:.2f}s' for k in keys) + ' | |')
    for a in arms:
        if a not in d: continue
        r, lv, lb, bb = d[a]
        n = sum(v[0] for v in lv.values())
        top = max(keys, key=lambda k: l0[k][1])
        e = lb.get(top)
        print(f"| | {a} | {r['wall']:.2f} ({r['wall']/r0['wall']:.3f}) | {n/1e6:.2f}M ({n/n0:.3f}) | " +
              ', '.join(f'{k[0]}{k[1]}: {lv[k][0]/l0[k][0]:.3f} / {lv[k][1]/l0[k][1]:.3f}' for k in keys if k in lv) +
              (f' | {top[0]}{top[1]}: {e[0]/1e6:.2f}M, {e[1]/max(e[0],1):.2f}' if e else ' | -') + ' |')
