#!/usr/bin/env python3
"""GH-225 lb reproduction: per code, time to each lb >= the old stem lb, final lb, and whether the search tree differs
from the original single runs (GH-225 arms A / E, GH-227 arms M / C): node counts of each half at level L are compared.
usage: analyze_lb.py ORIG_GH225.jsonl ORIG_GH227.jsonl REPRO_RESULTS.jsonl... > analysis.md"""
import json, re, sys

STEMS = ['TN_324_4_22to25', 'TN_496_2_27to30', 'TN_540_4_23to34', 'TN_648_14_21to28', 'COLOR_1027_1_28to37', 'TN_684_2_22to29',
         'COLOR_2791_1_26to61']


def load(path, tag):
    out = []
    for l in open(path):
        if not l.strip(): continue
        r = json.loads(l)
        if r.get('stem') in STEMS: r['tag'] = tag; out.append(r)
    return out


def nodes(r):
    d = {}
    for x in r.get('levels', []):
        m = re.match(r'([XZ]) level (\d+) (EMPTY|FOUND|\S+) nodes (\d+)', x)
        if m: d[(m.group(1), int(m.group(2)))] = (m.group(3), int(m.group(4)))
    return d


BIN = {'GH-225 A': '42d7d1d (PR #220 head)', 'GH-225 E': '5a201fd (A + erasure default)', 'GH-227 M': 'main 1239e9a2',
       'GH-227 C': '755e0c21 (gated erasure default)', 'repro E': 'main 1239e9a2', 'repro A': 'main 1239e9a2', 'repro C': 'main 755e0c21'}
orig = load(sys.argv[1], 'GH-225') + load(sys.argv[2], 'GH-227')
rep = []
for p in sys.argv[3:]: rep += load(p, 'repro')
print('# GH-225 lb reproduction: summary\n')
print('Times are wall seconds from process start to the `c d_lb` event (yfclab2, one pinned core per run, 4 GB cap).')
print('"tree" compares node counts per half and level with every original single run of the code at the deepest level both')
print('finished: "differs" = differs from all of them at that level; "same as X" = identical to run X there.')
print('Original runs: 6 h, default seed. Reproduction runs ("repro"): 12 h. "+erasure" = -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,sparsemrv,erasure (ungated on 1239e9a2).\n')
for s in STEMS:
    lo = int(s.split('_')[3].split('to')[0])
    rs = [r for r in orig + rep if r['stem'] == s]
    if not rs: continue
    print(f'## {s}\n')
    print('| run | binary / args | final lb | time to each lb > stem lb | tree |')
    print('|---|---|---:|---|---|')
    on = {f"{r['tag']} {r['arm']}": nodes(r) for r in orig if r['stem'] == s}
    for r in rs:
        name = f"{r['tag']} {r['arm']}"
        ev = {}
        for t, v in r['lb_events']:
            if v > lo and v not in ev: ev[v] = int(t)
        times = ', '.join(f'{v}@{t}' for v, t in sorted(ev.items())) or '-'
        tree = ''
        if True:
            n = nodes(r); same = []; lvl = None
            for o, on_ in on.items():
                if o == name: continue
                common = [k for k in n if k in on_ and n[k][0] == 'EMPTY' and on_[k][0] == 'EMPTY']
                if not common: continue
                k = max(common, key=lambda k: (k[1], k[0]))
                lvl = k if lvl is None or k[1] > lvl[1] else lvl
                if n[k][1] == on_[k][1]: same.append(f'{o} ({k[0]} level {k[1]})')
            tree = ('same as ' + '; '.join(same)) if same else f'differs (checked to level {lvl[1] if lvl else "-"})'
        b = BIN.get(name.split(' ')[0] + ' ' + name.split(' ')[1].split('.')[0], '?')
        a = ' '.join(x for x in r['args'] if x not in ('-engine=cc', '-cc-stats'))
        a = a.replace('-cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,sparsemrv,erasure', '+erasure')
        print(f"| {name} | {b} {a} | {r.get('final_lb')} | {times} | {tree} |")
    print()
