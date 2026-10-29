#!/usr/bin/env python3
"""GH-144 anytime-bound check over s1_queue results: per run, the c d_lb values never decrease, the c d_ub values never
increase, every lb <= every later ub, an answer equals the last lb and ub, and (science check of the runner) the
answer/bounds are consistent with the stem. usage: check_anytime.py RESULTS.jsonl [...]"""
import json, sys
n = bad = 0
for fn in sys.argv[1:]:
    for l in open(fn):
        r = json.loads(l)
        if 'error' in r: print('ERROR', r); bad += 1; continue
        n += 1; issues = []
        lbs = [v for _, v in r['lb_events']]; ubs = [v for _, v in r['ub_events']]
        if any(b < a for a, b in zip(lbs, lbs[1:])): issues.append('lb decreased')
        if any(b > a for a, b in zip(ubs, ubs[1:])): issues.append('ub increased')
        ev = sorted([(t, 'lb', v) for t, v in r['lb_events']] + [(t, 'ub', v) for t, v in r['ub_events']])
        maxlb = 0
        for t, k, v in ev:
            if k == 'lb': maxlb = max(maxlb, v)
            elif v < maxlb: issues.append(f'ub {v} below an earlier lb {maxlb}')
        if r['result'] and ((lbs and lbs[-1] != r['result'][1]) or (ubs and ubs[-1] != r['result'][1])): issues.append('answer != final bounds')
        if not r['science_ok']: issues += r['issues']
        if issues: bad += 1; print(r['id'], issues)
print(f'{n} runs checked, {bad} with issues')
