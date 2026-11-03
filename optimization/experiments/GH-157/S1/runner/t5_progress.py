#!/usr/bin/env python3
"""GH-157 Tier 5 progress / analysis: lb events (value@seconds) of the GH-157 runs (live logs or results.jsonl) against
the GH-152 Tier 5 arms (old = main's CC code, new = -cc-aut=on; same CC code as main 123011d) and the same-session main
controls. For each code: final lb (or answer), time to reach each lb >= 18, and the time ratio at the largest lb reached
by both. usage: t5_progress.py GH152_tier5_results.jsonl LOGDIR_OR_RESULTS"""
import json, os, re, sys, glob
g = {}
for l in open(sys.argv[1]):
    r = json.loads(l); g[(r['stem'], {'old': 'main152', 'new': 'aut152'}[r['arm']])] = r
runs = {}
src = sys.argv[2]
if os.path.isdir(src):
    for f in glob.glob(src + '/t5.*.log'):
        _, stem, arm = os.path.basename(f)[:-4].split('.')
        lbs, ans = [], None
        for line in open(f):
            m = re.match(r'\s*([\d.]+)\tc d_lb: (\d+)', line)
            if m: lbs.append((float(m.group(1)), int(m.group(2))))
            m = re.match(r'\s*([\d.]+)\to (\d+)', line)
            if m: ans = (float(m.group(1)), int(m.group(2)))
        runs[(stem, arm)] = dict(lb_events=lbs, result=ans)
else:
    for l in open(src):
        r = json.loads(l)
        if 'lb_events' in r: runs[(r['stem'], r['arm'])] = r
def first(ev, v):
    for t, x in ev:
        if x >= v: return t
    return None
def summ(r):
    if r.get('result'): return f"d={r['result'][1]} @ {r['result'][0]:.0f}s"
    ev = r['lb_events']; return f"lb {max([x for _, x in ev], default=0)} ({ev[-1][0]:.0f}s)" if ev else 'lb -'
stems = sorted(set(s for s, _ in runs))
print('| Code | GH-152 main | GH-157 cand | GH-152 aut | GH-157 autcand | main control (this session) | cand/main152 time at largest common lb | autcand/aut152 |')
print('|---|---|---|---|---|---|---|---|')
for s in stems:
    row = [s]
    for key, d in (('main152', g), ('cand', runs), ('aut152', g), ('autcand', runs), ('main', runs)):
        r = d.get((s, key)); row.append(summ(r) if r else '-')
    for a, b in (('cand', 'main152'), ('autcand', 'aut152')):
        ra, rb = runs.get((s, a)), g.get((s, b))
        if not ra or not rb: row.append('-'); continue
        ea = [(t, x) for t, x in ra['lb_events']] + ([(ra['result'][0], ra['result'][1])] if ra.get('result') else [])
        eb = [(t, x) for t, x in rb['lb_events']] + ([(rb['result'][0], rb['result'][1])] if rb.get('result') else [])
        common = [v for v in range(18, 60) if first(ea, v) is not None and first(eb, v) is not None]
        if not common: row.append('-'); continue
        v = max(common); ta, tb = first(ea, v), first(eb, v)
        row.append(f'lb {v}: {tb:.0f} -> {ta:.0f} s ({ta / tb:.3f})' if tb > 0 else f'lb {v}')
    print('| ' + ' | '.join(row) + ' |')
