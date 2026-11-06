#!/usr/bin/env python3
"""GH-225 follow-up (lb push): per code, every run's arm, binary, time to each lb above the stem lb, and the node counts
of the last completed level (to show the trees differ). usage: summ_push.py RESULTS.jsonl... > summary.md"""
import json, re, sys
BIN = {'push': 'main 755e0c21 (gated erasure default)', 'push2': 'main 1239e9a2', 'lb': 'main 755e0c21 (gated erasure default)'}
runs = []
for p in sys.argv[1:]:
    for l in open(p):
        if l.strip(): runs.append(json.loads(l))
print('# GH-225 follow-up: lb push runs (12 h, yfclab2 CPUs 64-95)\n')
print('Runs stopped early by hand (rc -15) were relabelled `-seed=1/2` arms that ran 1.5-2x slower; they were replaced by the')
print('main 1239e9a2 arms after about 4 h. "+erasure" = 1239e9a2 CC default plus ungated erasure.\n')
for stem in sorted({r['stem'] for r in runs}):
    lo = int(stem.split('_')[3].split('to')[0])
    print(f'## {stem}\n\n| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |\n|---|---|---|---:|---:|---|---|')
    for r in [r for r in runs if r['stem'] == stem]:
        ev = {}
        for t, v in r['lb_events']:
            if v > lo and v not in ev: ev[v] = int(t)
        lv = {}
        for x in r['levels']:
            m = re.match(r'([XZ]) level (\d+) EMPTY nodes (\d+)', x)
            if m: lv[(int(m.group(2)), m.group(1))] = m.group(3)
        L = max([k[0] for k in lv], default=None)
        last = f"{L}: {lv.get((L, 'X'), '-')} / {lv.get((L, 'Z'), '-')}" if L else '-'
        a = ' '.join(x for x in r['args'] if x not in ('-engine=cc', '-cc-stats')).replace(
            '-cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,sparsemrv,erasure', '+erasure') or '(default)'
        print(f"| {r['id']} | {BIN[r['id'].split('.')[0]]} | {a} | {r['rc']} | {r['final_lb']} | "
              f"{', '.join(f'{v}@{t}' for v, t in sorted(ev.items())) or '-'} | {last} |")
    print()
