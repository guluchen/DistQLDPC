#!/usr/bin/env python3
"""GH-146 S0: MaxSAT -ub-pre=60 pre-pass, old finder vs -ub-isd=stern: per code U0 per seed and the median pre-pass
seconds (as printed by the binary), stop reasons. usage: prepass_compare.py OLD.jsonl NEW.jsonl"""
import json, sys, statistics
def load(f):
    d = {}
    for l in open(f):
        r = json.loads(l)
        if 'stem' in r: d.setdefault(r['stem'], []).append(r)
    return d
o, n = load(sys.argv[1]), load(sys.argv[2])
def key(s): return (int(s.split('_')[1]), s)
def tierof(rs): return rs[0]['tier']
print('| tier | code | old U0 (seeds 0-4) | old pre-pass s (median) | stern U0 (seeds 0-4) | stern pre-pass s (median) | stern stop reasons |')
print('|---:|---|---|---:|---|---:|---|')
eq = better = worse = 0; dsame = dtot = 0
for s in sorted(o, key=lambda s: (tierof(o[s]), key(s))):
    a = sorted(o[s], key=lambda r: r['seed']); b = sorted(n.get(s, []), key=lambda r: r['seed'])
    ua = [r.get('u0') for r in a]; ub = [r.get('u0') for r in b]
    ta = statistics.median(r.get('pre_seconds', 0) for r in a); tb = statistics.median(r.get('pre_seconds', 0) for r in b) if b else None
    stops = sorted({r.get('stop') for r in b})
    ma, mb = statistics.median([x for x in ua if x]), statistics.median([x for x in ub if x])
    eq += ma == mb; better += mb < ma; worse += mb > ma
    d = s.split('_')[3]
    if d.isdigit():
        dtot += 2 * len(a); dsame += sum(x == int(d) for x in ua) + sum(x == int(d) for x in ub)
    print(f'| {tierof(a)} | {s} | {"/".join(map(str, ua))} | {ta:.2f} | {"/".join(map(str, ub))} | {tb:.2f} | {", ".join(stops)} |')
print(f'\nmedian U0: stern lower on {better}, equal on {eq}, higher on {worse} codes')
