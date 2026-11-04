#!/usr/bin/env python3
"""GH-195 Tier 5 on main 02879a9 (since 2026-11-04): arm pairs run in the same session, 6 h, default seed:
def -> defer (+erasure on the CC default) and tbra -> tbraer (+erasure on tiebreak, -cc-roworder=auto). Per code: result or
final lb, time to the baseline's final value (ratio), largest level both completed (nodes, level time). Verdict (PI rule):
no solved code more than 1.2x slower. usage: analyze_tier5_pairs.py results.jsonl [more results.jsonl ...]"""
import json, re, sys, math, collections
T = collections.defaultdict(dict)
for f in sys.argv[1:]:
    for l in open(f):
        r = json.loads(l)
        if r.get('id', '').startswith('t5.'): T[r['stem']][r['arm']] = r
def levels(r):
    d = collections.defaultdict(dict)
    for L in r['levels']:
        m = re.match(r'(\w) level (\d+) (\w+) nodes (\d+) .* time ([\d.]+)s', L)
        if m: d[int(m.group(2))][m.group(1)] = (m.group(3), int(m.group(4)), float(m.group(5)))
    return d
res = lambda r: f"d={r['result'][1]} @ {r['wall']:.0f} s" if r['result'] else f"TIMEOUT lb {r['final_lb']}"
def lbt(r, v):
    if r['result'] and r['result'][1] == v: return r['result'][0]
    for t, x in r['lb_events']:
        if x >= v: return t
    return None
ev = lambda r, lo=18: ' '.join(f'{x}@{t:.0f}' for t, x in r['lb_events'] if x >= lo)
g = lambda v: math.exp(sum(map(math.log, v)) / len(v)) if v else float('nan')
order = sorted(T, key=lambda s: (s[:2], int(s.split('_')[1]), s))
verdict = True
for old, new in (('def', 'defer'), ('tbra', 'tbraer')):
    print(f'### {old} -> {new}\n')
    print(f'| Code | {old} | {new} | time to the {old} final value s (ratio) | largest level done by both: nodes (ratio), level s (ratio) |')
    print('|---|---|---|---|---|')
    tt = []
    for s in order:
        o, n = T[s].get(old), T[s].get(new)
        if not o or not n: continue
        target = o['result'][1] if o['result'] else o['final_lb']
        to, tn = lbt(o, target), lbt(n, target)
        lo, ln = levels(o), levels(n)
        both = [w for w in lo if w in ln and all(v[0] == 'EMPTY' for v in lo[w].values()) and all(v[0] == 'EMPTY' for v in ln[w].values())]
        det = '-'
        if both:
            w = max(both)
            a = (sum(v[1] for v in lo[w].values()), sum(v[2] for v in lo[w].values()))
            b = (sum(v[1] for v in ln[w].values()), sum(v[2] for v in ln[w].values()))
            if a[0] > 0 and a[1] > 0:
                det = f"{w} ({'+'.join(sorted(lo[w]))} -> {'+'.join(sorted(ln[w]))}): {a[0]/1e6:.1f}M -> {b[0]/1e6:.1f}M ({b[0]/a[0]:.3f}), {a[1]:.0f} -> {b[1]:.0f} ({b[1]/a[1]:.3f})"
        ratio = '-'
        if to and tn and to > 0:
            ratio = f'{tn/to:.3f}'; tt.append(tn / to)
            if o['result'] and n['result'] and tn / to > 1.2: verdict = False
        if o['result'] and not n['result']: verdict = False
        print(f"| {s} | {res(o)} | {res(n)} | {to and round(to)} -> {tn and round(tn)} ({ratio}) | {det} |")
    print(f'\ngeomean time to the baseline final value {g(tt):.3f} ({len(tt)} codes)\n')
print('### Bound events (lb value@seconds, from 18)\n')
arms = ['def', 'defer', 'tbra', 'tbraer']
print('| Code | ' + ' | '.join(arms) + ' |'); print('|---|' + '---|' * len(arms))
for s in order: print(f'| {s} | ' + ' | '.join(ev(T[s][a]) if a in T[s] else '-' for a in arms) + ' |')
bad = [r['id'] for s in T for r in T[s].values() if not r.get('science_ok')]
print(f'\nscience problems: {bad}')
print('TIER5', 'PASS' if verdict and not bad else 'FAIL', '(no solved code more than 1.2x slower)')
