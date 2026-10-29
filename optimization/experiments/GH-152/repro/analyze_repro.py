#!/usr/bin/env python3
"""GH-152 reproduction analysis: parse the runner logs (each line prefixed by elapsed seconds) of the -cc-rules=...,mrv runs.
Per half and level: EMPTY/FOUND, nodes, level time, elapsed time at completion. The certified lower bound at time t is
min over the searched halves of (largest completed EMPTY level + 1); with a verified dual map only the X half is searched.
Also extracts the GF(2)-verification lines (orbits: 'verified_generators', dual map: 'Tanner swap map: verified').
usage: analyze_repro.py LOGDIR   -> prints a markdown table and a JSON summary per code"""
import glob, json, os, re, sys
CLAIM = {'TN_288_2_9to24': 22, 'TN_324_4_9to25': 22, 'TN_432_8_9to29': 23, 'TN_496_2_17to30': 23, 'TN_540_4_9to34': 23, 'TN_576_2_9to37': 24}
OLD = {'TN_288_2_9to24': 20, 'TN_324_4_9to25': 20, 'TN_432_8_9to29': 21, 'TN_496_2_17to30': 22, 'TN_540_4_9to34': 21, 'TN_576_2_9to37': 22}
LV = re.compile(r'^\s*([\d.]+)\tc cc: ([XZ]) half level (\d+) (EMPTY|FOUND|ABANDONED|\S+) nodes (\d+) seeds (\d+) time ([\d.]+)s')
out = {}
for f in sorted(glob.glob(os.path.join(sys.argv[1], '*.log'))):
    stem = os.path.basename(f).split('.')[1]
    halves = {'X', 'Z'}; levels = {}; ver = []; found = []; status = []; last_t = 0.0
    for line in open(f, errors='replace'):
        m = LV.match(line)
        if m:
            t, h, w, st, nodes, seeds, lt = m.groups()
            levels.setdefault(h, []).append(dict(level=int(w), status=st, nodes=int(nodes), level_s=float(lt), at=float(t)))
            if st != 'EMPTY': found.append(line.strip())
        if 'searching the X half only' in line: halves = {'X'}
        if re.search(r'verified_generators=|cc aut: Tanner|dual map', line): ver.append(line.split('\t', 1)[-1].strip()[:200])
        if re.search(r'^\s*[\d.]+\t(o |s |c status|error|warning|c d_lb|c d |c cc: .*(TIMEOUT|timeout|interrupt))', line): status.append(line.split('\t', 1)[-1].strip())
        mt = re.match(r'^\s*([\d.]+)\t', line)
        if mt: last_t = float(mt.group(1))
    done = {h: 0 for h in halves}; events = []; lb = None
    allv = sorted(((v['at'], h, v) for h in halves for v in levels.get(h, [])), key=lambda x: (x[0], x[1]))
    for at, h, v in allv:
        if v['status'] == 'EMPTY' and v['level'] > done[h]:
            done[h] = max(done[h], v['level'])
        nl = min(done.values()) + 1
        if lb is None or nl > lb:
            lb = nl; events.append((lb, round(at, 1)))
    rows = []
    for w in range(18, max([v['level'] for h in halves for v in levels.get(h, [])] + [0]) + 1):
        cell = []
        for h in sorted(halves):
            v = next((v for v in levels.get(h, []) if v['level'] == w), None)
            if v: cell.append(f"{h} {v['status']} {v['nodes']/1e6:.1f}M {v['level_s']:.0f}s @{v['at']:.0f}s")
        rows.append((w, '; '.join(cell)))
    out[stem] = dict(claimed=CLAIM.get(stem), old_cc=OLD.get(stem), reproduced_lb=lb, halves=sorted(halves), lb_events=events,
                     levels=rows, verification=ver, nonempty=found, status=status, last_elapsed=last_t)
print('| Code | claimed lb | reproduced lb (mrv) | reproduced? | lb events (lb@s, from 18) |')
print('|---|---:|---:|---|---|')
for s, r in out.items():
    ev = ' '.join(f'{a}@{b:.0f}' for a, b in r['lb_events'] if a >= 18)
    print(f"| {s} | {r['claimed']} | {r['reproduced_lb']} | {'YES' if r['reproduced_lb'] is not None and r['reproduced_lb'] >= r['claimed'] else 'no'} | {ev} |")
print()
for s, r in out.items():
    print(f'### {s} (halves searched: {"+".join(r["halves"])}; last log line at {r["last_elapsed"]:.0f} s)')
    for w, c in r['levels']: print(f'- level {w}: {c}')
    for v in r['verification']: print(f'  - `{v}`')
    for x in r['nonempty']: print(f'  - NON-EMPTY: {x}')
    for x in r['status'][-4:]: print(f'  - status: `{x}`')
    print()
json.dump(out, open(os.path.join(sys.argv[1], '..', 'summary.json'), 'w'), indent=1)
