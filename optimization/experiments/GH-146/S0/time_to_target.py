#!/usr/bin/env python3
"""GH-146 S0: per open code, target = the larger of the two arms' median ub at the budget (a value both arms reach in
most seeds); time until each seed's ub <= target (budget+ if never), median per arm, and the ratio old/stern of the
medians. usage: time_to_target.py RESULTS.jsonl LOGDIR BUDGET"""
import json, os, re, sys, statistics
rf, ld, B = sys.argv[1], sys.argv[2], float(sys.argv[3])
rs = []
for l in open(rf):
    r = json.loads(l)
    ev = []
    for line in open(os.path.join(ld, r['id'] + '.log')):
        m = re.match(r'\s*([0-9.]+)\tc cc: ub-search: [XZ] half word of weight (\d+)', line)
        if m: ev.append((float(m.group(1)), int(m.group(2))))
    r['ev'] = ev; rs.append(r)
stems = sorted({r['stem'] for r in rs}, key=lambda s: (s.split('_')[0], int(s.split('_')[1])))
def ub(r, t):
    v = [u for e, u in r['ev'] if e <= t]; return min(v) if v else 10**6
print('| code | target ub | old: time to target per seed (s) | median | stern: time to target per seed (s) | median | old / stern |')
print('|---|---:|---|---:|---|---:|---:|')
for s in stems:
    g = {a: sorted([r for r in rs if r['stem'] == s and r['arm'] == a], key=lambda r: r['seed']) for a in ('old', 'stern')}
    tgt = max(statistics.median([ub(r, B) for r in g[a]]) for a in g)
    tt = {}
    for a in g:
        tt[a] = [min([e for e, u in r['ev'] if u <= tgt], default=float('inf')) for r in g[a]]
    md = {a: statistics.median(tt[a]) for a in g}
    f = lambda v: '/'.join('>%g' % B if x == float('inf') else '%.1f' % x for x in v)
    fm = lambda x: '>%g' % B if x == float('inf') else '%.1f' % x
    ratio = md['old'] / md['stern'] if md['stern'] > 0 and md['old'] != float('inf') else float('nan')
    print(f"| {s} | {int(tgt)} | {f(tt['old'])} | {fm(md['old'])} | {f(tt['stern'])} | {fm(md['stern'])} | {ratio:.1f} |")
