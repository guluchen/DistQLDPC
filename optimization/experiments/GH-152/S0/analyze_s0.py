#!/usr/bin/env python3
"""GH-152 S0: CC node counts per level, old (-engine=cc) vs new (-cc-aut=on), -ub-search=off, 3600 s cap, default seed.
Per code: the searched halves, nodes per level summed over halves (old -> new, ratio) for the last levels both arms
completed, seconds, and the final result / lb. usage: analyze_s0.py results.jsonl"""
import json, re, sys, collections
R = [json.loads(l) for l in open(sys.argv[1])]
T = collections.defaultdict(dict)
for r in R: T[r['stem']][r['arm']] = r
def levels(r):
    d = collections.defaultdict(dict)
    for L in r['levels']:
        m = re.match(r'(\w) level (\d+) (\w+) nodes (\d+) .* time ([\d.]+)s', L)
        if m: d[int(m.group(2))][m.group(1)] = (m.group(3), int(m.group(4)), float(m.group(5)))
    return d
def res(r): return f"d={r['result'][1]} @ {r['wall']:.0f} s" if r['result'] else f"TIMEOUT lb {r['final_lb']}"
print('| Code | old | new | level: nodes old -> new (ratio), seconds old -> new (last three levels done by both arms) |')
print('|---|---|---|---|')
for stem in sorted(T, key=lambda s: (s[:2], int(s.split('_')[1]))):
    o, n = T[stem].get('old'), T[stem].get('new')
    if not o or not n: continue
    lo, ln = levels(o), levels(n)
    done = lambda d, w: d[w] and all(v[0] in ('EMPTY', 'FOUND') for v in d[w].values())
    ws = sorted(w for w in lo if w in ln and done(lo, w) and done(ln, w) and sum(v[1] for v in lo[w].values()) > 0)
    parts = []
    for w in ws[-3:]:
        a = sum(v[1] for v in lo[w].values()); b = sum(v[1] for v in ln[w].values())
        ta = sum(v[2] for v in lo[w].values()); tb = sum(v[2] for v in ln[w].values())
        parts.append(f"{w} ({'+'.join(sorted(lo[w]))}->{'+'.join(sorted(ln[w]))}): {a/1e6:.2f}M -> {b/1e6:.2f}M ({b/a:.3f}), {ta:.1f} -> {tb:.1f} s")
    print(f"| {stem} | {res(o)} | {res(n)} | {'; '.join(parts)} |")
