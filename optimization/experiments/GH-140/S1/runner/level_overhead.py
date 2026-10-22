#!/usr/bin/env python3
"""GH-140 Tier 5: per-level search seconds, on (-ub-search=on) vs off (same binary, same session), for completed levels
with identical node counts that ran while both processes were alive (level intervals reconstructed as the cumulative
sum of level times from each process start). Ratio on/off of the level seconds = the CC search's slowdown from the
time-sliced finder (its slices are not counted in the level time when they run between levels, but are when they run
inside a level). usage: level_overhead.py ON.jsonl OFF.jsonl"""
import json, re, sys, math, statistics as st
def load(p, suf):
    out = {}
    for l in open(p):
        r = json.loads(l)
        if r.get('id', '').startswith('t5.') and r['id'].endswith(suf): out[r['stem']] = r
    return out
def lv(r):
    out, t = {}, 0.0
    for L in r['levels']:
        m = re.match(r'(\w) level (\d+) (\w+) nodes (\d+) .* time ([\d.]+)s', L)
        if not m: continue
        dt = float(m.group(5)); out[(m.group(1), int(m.group(2)))] = (m.group(3), int(m.group(4)), dt, r['start'] + t, r['start'] + t + dt); t += dt
    return out
N, F = load(sys.argv[1], '.on'), load(sys.argv[2], '.off')
allr = []
print('| Code | levels compared | level seconds on/off: median (min-max) |')
print('|---|---:|---|')
for k in sorted(N, key=lambda s: (s[:2], int(s.split('_')[1]))):
    if k not in F: continue
    a, b = lv(N[k]), lv(F[k])
    lo = max(N[k]['start'], F[k]['start']); hi = min(N[k]['start'] + N[k]['wall'], F[k]['start'] + F[k]['wall'])
    rs = []
    for x in a:
        if x in b and a[x][1] == b[x][1] and a[x][2] > 10 and b[x][2] > 10 and a[x][3] >= lo and a[x][4] <= hi and b[x][3] >= lo and b[x][4] <= hi:
            rs.append(a[x][2] / b[x][2])
    if rs:
        allr += rs
        print(f'| {k} | {len(rs)} | {st.median(rs):.3f} ({min(rs):.3f}-{max(rs):.3f}) |')
if allr: print(f'\nall {len(allr)} levels: median {st.median(allr):.3f}, geomean {math.exp(sum(map(math.log, allr)) / len(allr)):.3f}')
