#!/usr/bin/env python3
"""GH-146 S0 arm scores: per checkpoint, for every arm the mean over codes of (median ub over seeds) minus the best
arm's median, and the mean over all (code, seed) cells of ub / best ub of that code at that checkpoint.
usage: score.py RESULTS.jsonl LOGDIR T1,T2,..."""
import json, os, re, sys, statistics
rf, ld, cps = sys.argv[1], sys.argv[2], [float(x) for x in sys.argv[3].split(',')]
rs = []
for l in open(rf):
    r = json.loads(l)
    if 'stem' not in r: continue
    ev = []
    for line in open(os.path.join(ld, r['id'] + '.log')):
        m = re.match(r'\s*([0-9.]+)\t(c cc: ub-search: [XZ] half word of weight|c ub-pre [XZ]: word of weight) (\d+)', line)
        if m: ev.append((float(m.group(1)), int(m.group(3))))
    r['ev'] = ev; rs.append(r)
arms = sorted({r['arm'] for r in rs}); stems = sorted({r['stem'] for r in rs})
def ub(r, t):
    v = [u for e, u in r['ev'] if e <= t]; return min(v) if v else 10**6
for t in cps:
    print(f'## checkpoint {t:g} s')
    print('| arm | mean (median - best median) | mean ub / best-seen ub | codes where its median is best |')
    print('|---|---:|---:|---:|')
    med = {(a, s): statistics.median([ub(r, t) for r in rs if r['arm'] == a and r['stem'] == s]) for a in arms for s in stems}
    best = {s: min(med[(a, s)] for a in arms) for s in stems}
    bestseen = {s: min(ub(r, t) for r in rs if r['stem'] == s) for s in stems}
    rows = []
    for a in arms:
        d = statistics.mean(med[(a, s)] - best[s] for s in stems)
        q = statistics.mean(ub(r, t) / bestseen[r['stem']] for r in rs if r['arm'] == a)
        nb = sum(med[(a, s)] == best[s] for s in stems)
        rows.append((d, a, q, nb))
    for d, a, q, nb in sorted(rows): print(f'| {a} | {d:.2f} | {q:.3f} | {nb}/{len(stems)} |')
    print()
