#!/usr/bin/env python3
"""GH-148 Tier 5 table (GH-144 analyzer): candidate runs (run_queue results.jsonl, arm 'cand') vs main 12b3e05's own Tier 5
(baselines/main-12b3e05 raw results.json, same server/limits; or GH-144 S1 tier5.jsonl as fallback), and the
concurrent main-12b3e05 drift controls (arm 'main') where present. usage: analyze_tier5.py CAND.jsonl[,CAND2.jsonl]
BASE.jsonl > table.md"""
import json, sys
allr = [json.loads(l) for fn in sys.argv[1].split(',') for l in open(fn) if l.strip()]
cand = [r for r in allr if r.get('arm') == 'cand']
drift = {('_'.join(r['stem'].split('_')[:3]), r['mode']): r for r in allr if r.get('arm') == 'main' and 'error' not in r}
def key(stem):   # family_n_k: the recorded baseline predates the BB_*_ge28 -> ge30 renames (PR #141)
    return '_'.join(stem.split('_')[:3])
def fix(r):   # a timeout prints "c d_ub: -" when no ub exists; the runner then marks the run withdrawn and drops
    lbs = [v for _, v in r['lb_events']]; ubs = [v for _, v in r['ub_events']]   # final_lb: recompute from the events
    r['final_lb'] = max(lbs) if lbs else None; r['final_ub'] = min(ubs) if ubs else None
    return r
cand = {(key(r['stem']), r['mode']): fix(r) for r in cand if 'error' not in r}
_b = json.load(open(sys.argv[2]))['results'] if sys.argv[2].endswith('.json') else [json.loads(l) for l in open(sys.argv[2]) if l.strip()]
base = {(key(r['stem']), r['mode']): fix(r) for r in _b if 'error' not in r}
names = {}
for (k, m), r in cand.items(): names[k] = r['stem']
def res(r):
    if r is None: return 'missing'
    return f"d={r['result'][1]} @ {r['result'][0]:.0f} s" if r['result'] else 'TIMEOUT'
def lbs(r):
    return ', '.join(f'{v}@{t:.0f}' for t, v in r['lb_events']) if r else ''
def ubs(r):
    return ', '.join(f'{v}@{t:.1f}' for t, v in r['ub_events']) if r and r['ub_events'] else '-'
def fin(x): return '-' if x is None else str(x)
print('| Code | Mode | main (recorded) | lb | ub | **-stab-overlap=auto** | lb | ub | ub events (value@s) | lb events (value@s) | change | main drift control (12b3e05, concurrent) |')
print('|---|---|---|---:|---:|---|---:|---:|---|---|---|---|')
solved = [0, 0]; lb_up = lb_down = ub_new = ub_better = 0; science = []
keys = sorted(set(base) | set(cand), key=lambda k: (k[0].split('_')[0], int(k[0].split('_')[1]), k[0], k[1]))
for k in keys:
    b, c = base.get(k), cand.get(k)
    if b and b['result']: solved[0] += 1
    if c and c['result']: solved[1] += 1
    ch = []
    if b and c:
        if bool(b['result']) != bool(c['result']): ch.append('SOLVED' if c['result'] else 'LOST')
        elif b['result'] and c['result']: ch.append(f"{c['result'][0] / b['result'][0]:.2f}x time")
        bl, cl = b['final_lb'] or 0, c['final_lb'] or 0
        if b['result'] and c['result']: bl = cl = 0   # both solved: compared by time
        if cl > bl: lb_up += 1; ch.append(f'lb {bl}->{cl}')
        if cl < bl: lb_down += 1; ch.append(f'lb {bl}->{cl} (lower)')
        bu, cu = b['final_ub'], c['final_ub']
        if cu is not None and bu is None: ub_new += 1; ch.append(f'ub - -> {cu}')
        elif cu is not None and bu is not None and cu < bu: ub_better += 1; ch.append(f'ub {bu}->{cu}')
        elif cu is not None and bu is not None and cu > bu: ch.append(f'ub {bu}->{cu} (higher)')
    if c and not c.get('science_ok', True): science.append((c['id'], c['issues']))
    print(f"| {names.get(k[0], k[0])} | {k[1]} | {res(b)} | {fin(b and b['final_lb'])} | {fin(b and b['final_ub'])} | {res(c)} | {fin(c and c['final_lb'])} | "
          f"{fin(c and c['final_ub'])} | {ubs(c)} | {lbs(c)} | {'; '.join(ch)} | {(res(fix(drift[k])) + ' lb ' + fin(drift[k]['final_lb']) + ' ub ' + fin(drift[k]['final_ub']) + ' (lb events ' + lbs(drift[k]) + ')') if k in drift else ''} |")
print()
print(f'solved cells: main (recorded) {solved[0]}, candidate {solved[1]} (of {len(keys)}); final lb higher on {lb_up}, lower on {lb_down}; '
      f'ub where main had none: {ub_new}; ub lower than main: {ub_better}; science problems: {science}')
