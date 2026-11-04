#!/usr/bin/env python3
"""GH-195 Tier 5 (template GH-162 analyze_tier5.py). New arm: tber (-engine=cc, rules + tiebreak + erasure), 6 h, default
seed. Baselines are the recorded 6 h runs on the same server (no rerun, per the cached-baseline rule):
  main = GH-152 Tier 5 arm "new" (-engine=cc -cc-aut=on = main 6083e66's CC default; gh152_t5.jsonl),
  tb   = GH-162 Tier 5 arm "tb" (PR #180 binary 97c8629) and GH-183 Tier 5 arm "tb" (TN_252).
Codes are matched on family_n_k (stems were renamed since). Per code and baseline: result or final lb, time to the
baseline's final value (ratio), and the largest level both completed (EMPTY in every searched half): nodes and level
time ratios. usage: analyze_tier5.py NEW.jsonl main=FILE:ARM [tb=FILE:ARM ...] [--xcheck X.jsonl]"""
import json, re, sys, math, collections
args = sys.argv[1:]
X = []
if '--xcheck' in args:
    i = args.index('--xcheck'); X = [json.loads(l) for l in open(args[i + 1])]; args = args[:i] + args[i + 2:]
key = lambda stem: '_'.join(stem.split('_')[:3])
NEW = {key(r['stem']): r for r in map(json.loads, open(args[0])) if r.get('id', '').startswith('t5.') and r.get('arm') == 'tber'}
BASE = collections.defaultdict(dict)
for spec in args[1:]:
    lab, rest = spec.split('=', 1); f, arm = rest.rsplit(':', 1)
    for l in open(f):
        r = json.loads(l)
        if r.get('id', '').startswith('t5.') and r.get('arm') == arm: BASE[lab][key(r['stem'])] = r
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
order = sorted(NEW, key=lambda s: (s[:2], int(s.split('_')[1]), s))
for lab in BASE:
    print(f'### tber vs {lab}\n')
    print(f'| Code | {lab} | tber | time to the {lab} final value: {lab} -> tber s (ratio) | largest level done by both: nodes (ratio), level s (ratio) |')
    print('|---|---|---|---|---|')
    nr, tr, tt = [], [], []
    for k in order:
        n, o = NEW[k], BASE[lab].get(k)
        if not o: continue
        target = o['result'][1] if o['result'] else o['final_lb']
        to, tn = lbt(o, target), lbt(n, target)
        lo, ln = levels(o), levels(n)
        both = [w for w in lo if w in ln and all(v[0] == 'EMPTY' for v in lo[w].values()) and all(v[0] == 'EMPTY' for v in ln[w].values())]
        det = '-'
        if both:
            w = max(both)
            a = (sum(v[1] for v in lo[w].values()), sum(v[2] for v in lo[w].values()))
            b = (sum(v[1] for v in ln[w].values()), sum(v[2] for v in ln[w].values()))
            if a[0] > 0 and a[1] > 1:
                det = f"{w} ({'+'.join(sorted(lo[w]))} -> {'+'.join(sorted(ln[w]))}): {a[0]/1e6:.1f}M -> {b[0]/1e6:.1f}M ({b[0]/a[0]:.3f}), {a[1]:.0f} -> {b[1]:.0f} ({b[1]/a[1]:.3f})"
                nr.append(b[0] / a[0]); tr.append(b[1] / a[1])
        ratio = '-'
        if to and tn and to > 1: ratio = f'{tn/to:.3f}'; tt.append(tn / to)
        print(f"| {n['stem']} | {res(o)} | {res(n)} | {to and round(to)} -> {tn and round(tn)} ({ratio}) | {det} |")
    print(f'\ngeomean over codes: time to the {lab} final value {g(tt):.3f} ({len(tt)} codes > 1 s); largest common level nodes {g(nr):.3f}, '
          f'level time {g(tr):.3f} ({len(nr)} codes)\n')
print('### Bound events (lb value@seconds, from 18)\n')
print('| Code | ' + ' | '.join(BASE) + ' | tber |')
print('|---|' + '---|' * (len(BASE) + 1))
for k in order:
    print(f"| {NEW[k]['stem']} | " + ' | '.join(ev(BASE[lab][k]) if k in BASE[lab] else '-' for lab in BASE) + f" | {ev(NEW[k])} |")
bad = [r['id'] for r in NEW.values() if not r.get('science_ok')]
print(f'\n{len(NEW)} new runs, science problems: {bad}')
if X:
    print('\nCross-checks (relabelled seeds, tber):\n')
    print('| run | result | lb events |')
    print('|---|---|---|')
    for r in X: print(f"| {r['id']} | {res(r)} | {ev(r)} |")
