#!/usr/bin/env python3
"""GH-146 S0 table: per code and arm, best verified ub at the given checkpoints (per seed, then the median), and the
time to reach the known d / the final best. With -v the child's c d_ub lines are not printed live, so the events are
taken from the run logs: every 'c cc: ub-search: X half word of weight W' (or 'c ub-pre X: word of weight W') line,
at the runner timestamp of that line (the binary flushes stdout right after it).
usage: analyze.py RESULTS.jsonl[,...] [T1,T2,..] [LOGDIR[,...]]   (LOGDIR i matches RESULTS i; default: none = use ub_events)"""
import json, os, re, sys, statistics
files = sys.argv[1].split(',')
cps = [float(x) for x in (sys.argv[2] if len(sys.argv) > 2 else '60,120').split(',')]
logdirs = sys.argv[3].split(',') if len(sys.argv) > 3 else [None] * len(files)
rs = []
for f, ld in zip(files, logdirs):
    for l in open(f):
        if not l.strip(): continue
        r = json.loads(l)
        if 'stem' not in r: continue
        if ld:
            ev = []
            for line in open(os.path.join(ld, r['id'] + '.log')):
                m = re.match(r'\s*([0-9.]+)\t(c cc: ub-search: [XZ] half word of weight|c ub-pre [XZ]: word of weight) (\d+)', line)
                if m: ev.append((float(m.group(1)), int(m.group(3))))
            r['ub_events'] = ev
        rs.append(r)
arms = []
for r in rs:
    if r['arm'] not in arms: arms.append(r['arm'])
stems = sorted({r['stem'] for r in rs}, key=lambda s: (s.split('_')[3].isdigit(), int(s.split('_')[1]), s))
bad = [r['id'] for r in rs if not r.get('science_ok', True)]
def ub_at(r, t):
    v = [u for (e, u) in r['ub_events'] if e <= t]
    return min(v) if v else None
def med(v):
    v = [x for x in v if x is not None]
    return statistics.median(v) if v else None
print('| code | arm | ' + ' | '.join(f'ub @ {c:g} s (per seed; median)' for c in cps) + ' | time to the final best (median s) |')
print('|---|---|' + '---|' * len(cps) + '---|')
for s in stems:
    for a in arms:
        g = sorted([r for r in rs if r['stem'] == s and r['arm'] == a], key=lambda r: r['seed'])
        if not g: continue
        cells = []
        for c in cps:
            v = [ub_at(r, c) for r in g]
            cells.append('/'.join(str(x) if x is not None else '-' for x in v) + f'; {med(v)}')
        d = s.split('_')[3]
        if d.isdigit():
            ts = []
            for r in g:
                hit = [e for (e, u) in r['ub_events'] if u <= int(d)]
                ts.append(min(hit) if hit else None)
            tt = 'to d: ' + '/'.join(f'{x:.2f}' if x is not None else '-' for x in ts)
        else:
            ts = []
            for r in g:
                fin = min(u for _, u in r['ub_events']) if r['ub_events'] else None
                ts.append(min(e for e, u in r['ub_events'] if u == fin) if fin is not None else None)
            tt = '/'.join(f'{x:.1f}' if x is not None else '-' for x in ts)
        print(f'| {s} | {a} | ' + ' | '.join(cells) + f' | {tt} |')
print(f'\n{len(rs)} runs; science problems: {bad}')
