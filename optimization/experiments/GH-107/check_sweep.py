#!/usr/bin/env python3
"""GH-89 post-hoc checks on a GH-60 tier0_science.py science.json (preregistered in PROPOSAL.md, item 5).
Prints counts, every problem, candidate timeouts without any d_lb, LB comparison on common timeouts,
and the TN_648_10_71 rows (name known wrong: true d <= 52)."""
import json, sys
d = json.load(open(sys.argv[1])); R = d['results']; m = d['meta']
print('meta', json.dumps({k: m[k] for k in ('base_sha256', 'cand_sha256', 'limit', 'jobs', 'all_ok', 'counts')}))
probs = [r for r in R if r['problems']]
for r in probs: print('PROBLEM', r['stem'], r['mode'], r['problems'], 'ok' if r['ok'] else 'CAND')
to = [r for r in R if r['cand']['status'] == 'TIMEOUT']
nolb = [r for r in to if not r['cand']['lbs']]
print(f'candidate timeouts {len(to)}; without any d_lb {len(nolb)}')
for r in nolb: print('NO_LB', r['stem'], r['mode'])
both = [r for r in R if r['cand']['status'] == 'TIMEOUT' and r['base']['status'] == 'TIMEOUT']
hi = sum(max(r['cand']['lbs'] or [0]) > max(r['base']['lbs'] or [0]) for r in both)
lo = [r for r in both if max(r['cand']['lbs'] or [0]) < max(r['base']['lbs'] or [0])]
print(f'both timeout {len(both)}: cand final LB higher {hi}, equal {len(both) - hi - len(lo)}, lower {len(lo)}')
for r in lo: print('LOWER_LB', r['stem'], r['mode'], max(r['cand']['lbs'] or [0]), max(r['base']['lbs'] or [0]))
for r in R:
    if r['base']['status'] == 'done' and r['cand']['status'] != 'done': print('ONLY_BASE_DONE', r['stem'], r['mode'], r['cand']['status'])
    if r['stem'].startswith('TN_648'): print('TN648', r['stem'], r['mode'], r['base']['status'], r['base']['o'], max(r['base']['lbs'] or [0]), min(r['base']['ubs'] or [0]), '|', r['cand']['status'], r['cand']['o'], max(r['cand']['lbs'] or [0]), min(r['cand']['ubs'] or [0]))
other = [r for r in R if r['cand']['status'] == 'OTHER']
print('candidate abnormal exits', len(other))
print('VERDICT', 'PASS' if not [r for r in R if not r['ok']] and not nolb and not other else 'CHECK')
