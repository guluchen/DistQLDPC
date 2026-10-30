#!/usr/bin/env python3
"""GH-162 pre: node counts per level by variant (from gh162_queue results.jsonl). For each code: the deepest level that every
variant refuted (EMPTY, X+Z summed; FOUND levels depend on where the word is met), nodes and level time of each variant relative to 'base'.
usage: analyze_pre.py results.jsonl"""
import json, re, sys, collections
rs = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
by = collections.defaultdict(dict)
for r in rs:
    if 'error' in r: continue
    lv = collections.defaultdict(lambda: [0, 0.0, 0])
    for s in r['levels']:
        m = re.match(r'([XZ]) level (\d+) (EMPTY) nodes (\d+) .* time ([\d.]+)s', s)
        if m:
            e = lv[int(m.group(2))]; e[0] += int(m.group(4)); e[1] += float(m.group(5)); e[2] += 1
    by[r['stem']][r['arm']] = (r, lv)
for stem in sorted(by):
    vs = by[stem]
    base = 'base' if 'base' in vs else 'main'
    if base not in vs: continue
    common = set.intersection(*[set(lv) for _, lv in vs.values()])
    if not common: continue
    L = max(common)
    b = vs[base][1][L]
    row = [f'{stem} L{L} {base} {b[0]/1e6:.2f}M {b[1]:.1f}s wall {vs[base][0]["wall"]:.1f} lb {vs[base][0]["final_lb"]}']
    for arm in sorted(vs):
        if arm == base: continue
        x = vs[arm][1][L]
        row.append(f'{arm} {x[0]/max(b[0],1):.3f}/{x[1]/max(b[1],1e-9):.3f} (wall {vs[arm][0]["wall"]:.1f}, lb {vs[arm][0]["final_lb"]})')
    print(' | '.join(row))
