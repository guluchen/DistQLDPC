#!/usr/bin/env python3
"""GH-133 Tier 5 table: new rules (S1 cc results.jsonl) vs GH-124 S1 Tier 5 (old rules, results.json). usage: analyze_tier5.py NEW.jsonl OLD.json"""
import json, sys
new = {json.loads(l)['stem']: json.loads(l) for l in open(sys.argv[1]) if l.strip() and '"cc5.' in l}
old = {r['stem']: r for r in json.load(open(sys.argv[2]))['results']}
alias = {'BB_360_12_24': 'BB_360_12_17to24', 'LP_1054_140_20': 'LP_1054_140_17to32', 'LP_1428_184_24': 'LP_1428_184_ge17', 'LP_1768_224_22': 'LP_1768_224_ge17', 'TN_252_2_21': 'TN_252_2_17to28'}
def ev(r, lo=15): return ' '.join(f'{v}@{int(t)}' for t, v in r['lb_events'] if v >= lo)
print('| Code | GH-124 (old rules): result, lb/ub, wall s | GH-133 (new rules): result, lb/ub, wall s | lb events new (value@s) | lb events old | time to equal lb (old s -> new s) |')
print('|---|---|---|---|---|---|')
for s in sorted(new):
    n = new[s]; o = old.get(s) or old.get(alias.get(s, ''), None)
    nr = f"d={n['result'][1]} @ {n['result'][0]:.0f}" if n['result'] else 'TIMEOUT'
    if o:
        orr = f"d={o['result'][1]} @ {o['result'][0]:.0f}" if o['result'] else 'TIMEOUT'
        ocol = f"{orr}, {o['final_lb']}/{o['final_ub']}, {o['wall']:.0f}"
        # time at which the new run reached the old final lb, and the old reached the same
        lbo = o['final_lb']; tn = next((t for t, v in n['lb_events'] if v >= lbo), None); to = next((t for t, v in o['lb_events'] if v >= lbo), None)
        cmp = f"lb {lbo}: {to:.0f} -> {tn:.0f}" if tn is not None and to is not None else '-'
        oev = ev(o)
    else: ocol = 'n/a (new code)'; cmp = '-'; oev = '-'
    print(f"| {s} | {ocol} | {nr}, {n['final_lb']}/{n['final_ub']}, {n['wall']:.0f} | {ev(n)} | {oev} | {cmp} |")
