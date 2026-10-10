#!/usr/bin/env python3
"""GH-85 post-hoc checks on a tier0_science.py science.json (preregistered in PROPOSAL.md):
every candidate TIMEOUT must have emitted at least one `c d_lb`; reports final-LB comparison
for runs timing out in both versions (diagnostic only), and completion asymmetries.
Usage: posthoc_science.py science.json"""
import json, sys
d = json.load(open(sys.argv[1])); res = d['results']
to = [r for r in res if r['cand']['status'] == 'TIMEOUT']
nolb = [f"{r['stem']} {r['mode']}" for r in to if not r['cand']['lbs']]
base_to = [r for r in res if r['base']['status'] == 'TIMEOUT']
base_nolb = [f"{r['stem']} {r['mode']}" for r in base_to if not r['base']['lbs']]
both = [r for r in res if r['cand']['status'] == 'TIMEOUT' and r['base']['status'] == 'TIMEOUT']
hi = sum(max(r['cand']['lbs'] or [0]) > max(r['base']['lbs'] or [0]) for r in both)
lo = sum(max(r['cand']['lbs'] or [0]) < max(r['base']['lbs'] or [0]) for r in both)
print(f"candidate timeouts: {len(to)}; without any d_lb: {len(nolb)} {nolb}")
print(f"baseline timeouts: {len(base_to)}; without any d_lb: {len(base_nolb)}")
print(f"timeout in both: {len(both)}; candidate final d_lb higher in {hi}, lower in {lo} (diagnostic)")
oc = [f"{r['stem']} {r['mode']} d={r['cand']['o']}" for r in res if r['cand']['status'] == 'done' and r['base']['status'] != 'done']
ob = [f"{r['stem']} {r['mode']} d={r['base']['o']}" for r in res if r['base']['status'] == 'done' and r['cand']['status'] != 'done']
print(f"completed only by candidate ({len(oc)}): {oc}")
print(f"completed only by baseline ({len(ob)}): {ob}")
print(f"problems: {[(r['stem'], r['mode'], r['problems']) for r in res if r['problems']]}")
ok = not nolb and d['meta']['all_ok']
print('POSTHOC_PASS' if ok else 'POSTHOC_FAIL')
sys.exit(0 if ok else 2)
