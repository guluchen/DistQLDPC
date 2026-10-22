#!/usr/bin/env python3
"""GH-138 Tier 5: new rules (overlap) vs GH-133 Tier 5 (rules excl,pack,orbf,parity,leaf), same server, 6 h, default seed.
Per code: result / final lb / time; lb events; per completed level (half, w): nodes and seconds old -> new.
usage: analyze_tier5.py GH138_results.jsonl GH133_results.jsonl"""
import json, re, sys, math
def load(p):
    out = {}
    for l in open(p):
        r = json.loads(l)
        if r.get('id', '').startswith('cc5.'): out['_'.join(r['stem'].split('_')[:3])] = r
    return out
def levels(r):
    d = {}
    for L in r['levels']:
        m = re.match(r'(\w) level (\d+) (\w+) nodes (\d+) .* time ([\d.]+)s', L)
        if m: d[(m.group(1), int(m.group(2)))] = (m.group(3), int(m.group(4)), float(m.group(5)))
    return d
N, O = load(sys.argv[1]), load(sys.argv[2])
def res(r):
    if r['result']: return f"d={r['result'][1]} @ {r['wall']:.0f}"
    return f"TIMEOUT lb {r['final_lb']}"
def lbt(r, v):
    for t, x in r['lb_events']:
        if x >= v: return t
    return None
print('| Code | GH-133 (old rules) | GH-138 (overlap) | time to old final lb: old -> new s (ratio) | largest common EMPTY level: nodes old -> new (ratio), s old -> new (ratio) |')
print('|---|---|---|---|---|')
nr, tr = [], []
for k in sorted(N, key=lambda s: (s[:2], int(s.split('_')[1]))):
    n, o = N[k], O.get(k)
    if not o: print(f'| {k} | - | {res(n)} | - | - |'); continue
    target = o['result'][1] if o['result'] else o['final_lb']
    to, tn = lbt(o, target), lbt(n, target)
    if o['result'] and n['result']: to, tn = o['wall'], n['wall']
    lo, ln = levels(o), levels(n)
    common = [x for x in lo if x in ln and lo[x][0] == 'EMPTY' and ln[x][0] == 'EMPTY']
    det = '-'
    if common:
        x = max(common, key=lambda x: (x[1], lo[x][2]))
        a, b = lo[x], ln[x]
        det = f'{x[0]}{x[1]}: {a[1]/1e6:.1f}M -> {b[1]/1e6:.1f}M ({b[1]/a[1]:.3f}), {a[2]:.0f} -> {b[2]:.0f} ({b[2]/max(a[2],1e-9):.3f})'
        nr.append(b[1]/a[1]); tr.append(b[2]/max(a[2],1e-9))
    ratio = f'{tn/to:.3f}' if to and tn else '-'
    print(f"| {n['stem']} | {res(o)} | {res(n)} (lb {n['final_lb']}) | {to and round(to)} -> {tn and round(tn)} ({ratio}) | {det} |")
g = lambda v: math.exp(sum(map(math.log, v)) / len(v))
print(f'\ngeomean over codes of the largest common EMPTY level: nodes {g(nr):.3f}, time {g(tr):.3f} ({len(nr)} codes)')
