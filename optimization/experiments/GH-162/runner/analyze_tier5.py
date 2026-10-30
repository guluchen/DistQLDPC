#!/usr/bin/env python3
"""GH-162 Tier 5 (copied from GH-152): main 346d1c6 (-engine=cc) vs tb (-engine=cc, rules + tiebreak), same server session, 6 h, default seed, run concurrently.
Per code: result or final certified lb, time to the old arm's final value, bound events; per level w the CC nodes summed
over the searched halves (the new arm may search one half under a dual map) for the largest level both arms completed.
Optional xcheck results (relabelled seeds) are listed per code. usage: analyze_tier5.py results.jsonl [xcheck.jsonl]"""
import json, re, sys, math, collections
R = [json.loads(l) for l in open(sys.argv[1])]
X = [json.loads(l) for l in open(sys.argv[2])] if len(sys.argv) > 2 else []
T = collections.defaultdict(dict)
for r in R:
    if r.get('id', '').startswith('t5.'): T[r['stem']][r['arm']] = r
def levels(r):
    d = collections.defaultdict(dict)
    for L in r['levels']:
        m = re.match(r'(\w) level (\d+) (\w+) nodes (\d+) .* time ([\d.]+)s', L)
        if m: d[int(m.group(2))][m.group(1)] = (m.group(3), int(m.group(4)), float(m.group(5)))
    return d
def res(r):
    return f"d={r['result'][1]} @ {r['wall']:.0f} s" if r['result'] else f"TIMEOUT lb {r['final_lb']}"
def lbt(r, v):
    if r['result'] and r['result'][1] == v: return r['result'][0]
    for t, x in r['lb_events']:
        if x >= v: return t
    return None
def ev(r, lo=18):
    return ' '.join(f'{x}@{t:.0f}' for t, x in r['lb_events'] if x >= lo)
print('| Code | main | tb | time to the main arm final value: main -> tb s (ratio) | largest level done by both: nodes main -> tb (ratio), s main -> tb (ratio) |')
print('|---|---|---|---|---|')
nr, tr, changed = [], [], []
for stem in sorted(T, key=lambda s: (s[:2], int(s.split('_')[1]), s)):
    o, n = T[stem].get('main'), T[stem].get('tb')
    if not o or not n: print(f'| {stem} | {o and res(o)} | {n and res(n)} | - | - |'); continue
    target = o['result'][1] if o['result'] else o['final_lb']
    to, tn = lbt(o, target), lbt(n, target)
    lo, ln = levels(o), levels(n)
    both = [w for w in lo if w in ln and all(v[0] == 'EMPTY' for v in lo[w].values()) and all(v[0] == 'EMPTY' for v in ln[w].values())
            and len(lo[w]) >= 1 and len(ln[w]) >= 1]
    det = '-'
    if both:
        w = max(both)
        a = (sum(v[1] for v in lo[w].values()), sum(v[2] for v in lo[w].values()))
        b = (sum(v[1] for v in ln[w].values()), sum(v[2] for v in ln[w].values()))
        if a[0] > 0 and a[1] > 1:
            det = f"{w} ({'+'.join(sorted(lo[w]))} -> {'+'.join(sorted(ln[w]))}): {a[0]/1e6:.1f}M -> {b[0]/1e6:.1f}M ({b[0]/a[0]:.3f}), {a[1]:.0f} -> {b[1]:.0f} ({b[1]/a[1]:.3f})"
            nr.append(b[0] / a[0]); tr.append(b[1] / a[1])
    ratio = f'{tn/to:.3f}' if to and tn and to > 0 else '-'
    nv = n['result'][1] if n['result'] else n['final_lb']
    if (n['result'] is None) != (o['result'] is None) or nv != target: changed.append((stem, o, n))
    print(f"| {stem} | {res(o)} | {res(n)} | {to and round(to)} -> {tn and round(tn)} ({ratio}) | {det} |")
g = lambda v: math.exp(sum(map(math.log, v)) / len(v)) if v else float('nan')
print(f'\ngeomean over codes of the largest level done by both (levels > 1 s): nodes {g(nr):.3f}, time {g(tr):.3f} ({len(nr)} codes)')
print('\nBound events (lb value@seconds, from 18) where the final value changed:\n')
print('| Code | old | new |')
print('|---|---|---|')
for stem, o, n in changed: print(f'| {stem} | {ev(o)} | {ev(n)} |')
bad = [r['id'] for r in R if r.get('id', '').startswith('t5.') and not r.get('science_ok')]
print(f'\n{sum(1 for r in R if r.get("id","").startswith("t5."))} runs, science problems: {bad}')
if X:
    print('\nCross-checks (relabelled seeds, new arm):\n')
    print('| run | result | lb events |')
    print('|---|---|---|')
    for r in X: print(f"| {r['id']} | {res(r)} | {ev(r)} |")
