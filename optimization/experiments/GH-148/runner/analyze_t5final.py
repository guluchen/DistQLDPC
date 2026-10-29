#!/usr/bin/env python3
"""GH-148 final Tier 5 table: candidate (run_queue results.jsonl of the 54-cell run on cores 0-53) vs main 12b3e05's
recorded Tier 5 (baselines/main-12b3e05 raw server_tier5_results.json: same server, cores 0-53, 4 GB, 6 h, default seed).
Per cell: solved/time, final lb/ub of both, candidate time to main's final lb (first candidate lb event >= main's final
lb), main's time to that lb. Semantic checks: candidate answer/lb/ub against the stem at 12b3e05 (old) and at e52d15b
(new {lb}to{ub} names), and against main's final bounds (cand lb <= main ub, cand ub >= main lb).
usage: analyze_t5final.py CAND.jsonl MAIN.json STEMS_OLD_TO_NEW.tsv > table.md"""
import json, sys
cand = {(r['stem'], r['mode']): r for r in (json.loads(l) for l in open(sys.argv[1]) if l.strip()) if 'error' not in r}
base = {(r['stem'], r['mode']): r for r in json.load(open(sys.argv[2]))['results']}
newname = dict(l.split() for l in open(sys.argv[3]) if l.strip())
def fix(r):   # "c d_ub: -" at a timeout marks the run withdrawn; recompute the finals from the events
    lbs = [v for _, v in r['lb_events']]; ubs = [v for _, v in r['ub_events']]
    r['final_lb'] = max(lbs) if lbs else None; r['final_ub'] = min(ubs) if ubs else None
    return r
def rng(stem):
    f = stem.split('_')[3]
    if f.isdigit(): return int(f), int(f)
    if f.startswith('ge'): return int(f[2:]), None
    x, y = f.split('to'); return int(x), int(y)
def t_to(r, lb):
    for t, v in r['lb_events']:
        if v >= lb: return t
    return None
def s(t): return '-' if t is None else (f'{t:.0f}' if t >= 10 else f'{t:.1f}')
def fin(x): return '-' if x is None else str(x)
fam = {}; issues = []; rows = []
keys = sorted(base, key=lambda k: (k[0].split('_')[0], int(k[0].split('_')[1]), k[0], k[1] != 'no-card'))
print('| Code (12b3e05 stem) | e52d15b stem | Mode | main solved @ s | main lb / ub | cand solved @ s | cand lb / ub | main lb reached: main @ s | cand @ s | cand/main time | change |')
print('|---|---|---|---|---:|---|---:|---:|---:|---:|---|')
for k in keys:
    b = fix(base[k]); c = cand.get(k)
    st, mode = k; f = st.split('_')[0]
    d = fam.setdefault(f, dict(cells=0, msolved=0, csolved=0, lbup=0, lbdown=0, ublo=0, ubhi=0, faster=[], missing=0))
    d['cells'] += 1; d['msolved'] += bool(b['result'])
    if c is None:
        d['missing'] += 1; issues.append(f'{st} {mode}: candidate cell missing'); continue
    c = fix(c); d['csolved'] += bool(c['result'])
    for name in (st, newname.get(st, st)):
        lo, hi = rng(name)
        if c['result'] and (c['result'][1] < lo or (hi is not None and c['result'][1] > hi)): issues.append(f'{st} {mode}: answer {c["result"][1]} outside {name}')
        if hi is not None and c['final_lb'] is not None and c['final_lb'] > hi: issues.append(f'{st} {mode}: lb {c["final_lb"]} > upper value of {name}')
        if c['final_ub'] is not None and c['final_ub'] < lo: issues.append(f'{st} {mode}: ub {c["final_ub"]} < lower value of {name}')
    if b['final_ub'] is not None and c['final_lb'] is not None and c['final_lb'] > b['final_ub']: issues.append(f'{st} {mode}: cand lb {c["final_lb"]} > main ub {b["final_ub"]}')
    if b['final_lb'] is not None and c['final_ub'] is not None and c['final_ub'] < b['final_lb']: issues.append(f'{st} {mode}: cand ub {c["final_ub"]} < main lb {b["final_lb"]}')
    if c['final_lb'] is not None and c['final_ub'] is not None and c['final_lb'] > c['final_ub']: issues.append(f'{st} {mode}: cand lb > cand ub')
    if not c.get('science_ok', True) or c.get('runner_killed'): issues.append(f'{st} {mode}: runner issues {c.get("issues")}')
    if b['result'] and c['result'] and b['result'][1] != c['result'][1]: issues.append(f'{st} {mode}: answers differ {b["result"][1]} vs {c["result"][1]}')
    ml = b['final_lb']; tm = t_to(b, ml) if ml else None; tc = t_to(c, ml) if ml else None
    ratio = tc / tm if tm and tc else None
    if ratio: d['faster'].append(ratio)
    ch = []
    if bool(b['result']) != bool(c['result']): ch.append('SOLVED' if c['result'] else 'LOST')
    if not (b['result'] and c['result']):
        if (c['final_lb'] or 0) > (ml or 0): d['lbup'] += 1; ch.append(f'lb {ml}->{c["final_lb"]}')
        if (c['final_lb'] or 0) < (ml or 0): d['lbdown'] += 1; ch.append(f'lb {ml}->{c["final_lb"]} (lower)')
    if c['final_ub'] is not None and b['final_ub'] is not None and c['final_ub'] != b['final_ub']:
        if c['final_ub'] < b['final_ub']: d['ublo'] += 1; ch.append(f'ub {b["final_ub"]}->{c["final_ub"]}')
        else: d['ubhi'] += 1; ch.append(f'ub {b["final_ub"]}->{c["final_ub"]} (higher)')
    if c['final_ub'] is not None and b['final_ub'] is None: d['ublo'] += 1; ch.append(f'ub - -> {c["final_ub"]}')
    print(f"| {st} | {newname.get(st, st) if newname.get(st, st) != st else '='} | {mode} | {s(b['result'][0]) + ' (d=' + str(b['result'][1]) + ')' if b['result'] else 'timeout'} | "
          f"{fin(b['final_lb'])} / {fin(b['final_ub'])} | {s(c['result'][0]) + ' (d=' + str(c['result'][1]) + ')' if c['result'] else 'timeout'} | {fin(c['final_lb'])} / {fin(c['final_ub'])} | "
          f"{fin(ml)}: {s(tm)} | {s(tc)} | {'-' if ratio is None else f'{ratio:.3g}'} | {'; '.join(ch)} |")
print()
print('| Family | cells | solved main / cand | final lb higher / lower | ub lower / higher | time to main\'s final lb, cand/main: geomean (min-max) |')
print('|---|---:|---:|---:|---:|---|')
import math
for f, d in fam.items():
    g = math.exp(sum(map(math.log, d['faster'])) / len(d['faster'])) if d['faster'] else None
    gs = f"{g:.3g} ({min(d['faster']):.3g}-{max(d['faster']):.3g})" if g else '-'
    print(f"| {f} | {d['cells']} | {d['msolved']} / {d['csolved']} | {d['lbup']} / {d['lbdown']} | {d['ublo']} / {d['ubhi']} | {gs} |")
print()
print('semantic issues:', issues if issues else 'none')
