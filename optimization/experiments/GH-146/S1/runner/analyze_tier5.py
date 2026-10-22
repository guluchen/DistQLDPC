#!/usr/bin/env python3
"""GH-146 Tier 5 table: the new-finder runs (s1_queue results.jsonl; CC: -engine=cc -ub-search=on -ub-isd=stern;
MaxSAT: -ub-pre=on -ub-isd=stern, both modes) vs the recorded Tier 5 of GH-140 (CC, -ub-search=on, binary 793905c:
GH-140/S1/server/tier5_on.jsonl) and GH-144 (MaxSAT, -ub-pre=60, binary 6d2b7a1: GH-144/S1/server/tier5.jsonl), all
on yfclab2, 6 h, default seed, 4 GB, pinned cores. usage: analyze_tier5.py NEW.jsonl GH140_TIER5.jsonl GH144_TIER5.jsonl"""
import json, sys
def load(f, mode=None):
    out = {}
    for l in open(f):
        if not l.strip(): continue
        r = json.loads(l)
        if 'error' in r: continue
        lbs = [v for _, v in r['lb_events']]; ubs = [v for _, v in r['ub_events']]
        r['flb'] = max(lbs) if lbs else None; r['fub'] = min(ubs) if ubs else None
        key = '_'.join(r['stem'].split('_')[:3])   # family_n_k (stems were renamed between rounds)
        out[(key, mode or r.get('mode') or 'cc')] = r
    return out
new = load(sys.argv[1]); old = load(sys.argv[2], 'cc'); old.update(load(sys.argv[3]))
def res(r): return '-' if r is None else (f"d={r['result'][1]} @ {r['result'][0]:.0f} s" if r['result'] else 'TIMEOUT')
def f(x): return '-' if x is None else str(x)
def ubt(r):
    if r is None or r['fub'] is None: return '-'
    return f"{r['fub']} @ {min(t for t, v in r['ub_events'] if v == r['fub']):.1f}"
print('| Code | Engine / mode | baseline (GH-140 CC / GH-144 MaxSAT) | lb | ub @ s | **new finder (-ub-isd=stern)** | lb | ub @ s | change |')
print('|---|---|---|---:|---|---|---:|---|---|')
solved = [0, 0]; ub_lower = ub_higher = lb_up = lb_down = 0; science = []
keys = sorted(set(new) | set(old), key=lambda k: (k[0].split('_')[0], int(k[0].split('_')[1]), k[0], ('cc', 'no-card', 'card-mto').index(k[1])))
for k in keys:
    b, c = old.get(k), new.get(k)
    stem = (c or b)['stem']
    ch = []
    if b and c:
        solved[0] += bool(b['result']); solved[1] += bool(c['result'])
        if c['result'] and not b['result']: ch.append('SOLVED')
        if b['result'] and not c['result']: ch.append('LOST')
        if b['result'] and c['result']: ch.append(f"{c['result'][0] / max(b['result'][0], 1):.2f}x time")
        if b['fub'] is not None and c['fub'] is not None:
            if c['fub'] < b['fub']: ub_lower += 1; ch.append(f"ub {b['fub']}->{c['fub']}")
            if c['fub'] > b['fub']: ub_higher += 1; ch.append(f"ub {b['fub']}->{c['fub']} (higher)")
        if (c['flb'] or 0) > (b['flb'] or 0): lb_up += 1; ch.append(f"lb {b['flb']}->{c['flb']}")
        if (c['flb'] or 0) < (b['flb'] or 0): lb_down += 1; ch.append(f"lb {b['flb']}->{c['flb']} (lower)")
    if c and not c.get('science_ok', True): science.append((c['id'], c['issues']))
    print(f"| {stem} | {k[1]} | {res(b)} | {f(b and b['flb'])} | {ubt(b)} | {res(c)} | {f(c and c['flb'])} | {ubt(c)} | {', '.join(ch)} |")
print(f'\nsolved cells: baseline {solved[0]}, new {solved[1]}; ub lower on {ub_lower}, higher on {ub_higher}; final lb higher on {lb_up}, lower on {lb_down}; science problems: {science}')
