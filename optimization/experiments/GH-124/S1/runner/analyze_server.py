#!/usr/bin/env python3
"""GH-124 S1 server analysis.
usage: analyze_server.py PANEL/results.jsonl TIER5/results.json MAIN_SERVER.md > server_summary.md
Seed-median judging (docs/OPTIMIZATION_LOOP_POLICY.md): cell ratio = median_s(CC) / median_s(main mode); a timed-out
run counts as its limit (censored: the true time is larger). Tier pass: per-mode geomean < 1 and no cell > 1.25."""
import json, math, re, statistics, sys
from collections import defaultdict

P, T5, MS = sys.argv[1:4]
runs = [json.loads(l) for l in open(P) if l.strip()]
errs = [r for r in runs if 'error' in r]
runs = [r for r in runs if 'error' not in r]
cell = defaultdict(dict)
for r in runs:
    cell[(r['tier'], r['case'])].setdefault(r['arm'], {})[r['seed']] = r
g = lambda x: math.exp(sum(map(math.log, x)) / len(x))
out = []
pr = out.append

pr('## Panel run counts and correctness\n')
nbad = [r for r in runs if not r['science_ok']]
nto = [r for r in runs if r['timeout']]
pr(f'- Runs: {len(runs)} (runner errors: {len(errs)}). Answers checked against the stem d: '
   f'{sum(r["solved"] for r in runs)} correct, {len(nbad)} wrong/bound violations, {len(nto)} without an answer (timeout).')
pr(f'- Withdrawn-bound (CC trap) runs: {sum(r["withdrawn"] for r in runs)}; runner backstop kills: '
   f'{sum(r["runner_killed"] for r in runs)}; non-zero rc: {sum(r["rc"] != 0 for r in runs)}; '
   f'max RSS: {max(r["maxrss_kb"] for r in runs) / 1024:.0f} MB.')
for r in nbad: pr(f'  - PROBLEM {r["case"]} {r["arm"]} seed {r["seed"]}: {r["issues"]}')
for r in nto: pr(f'  - TIMEOUT {r["case"]} {r["arm"]} seed {r["seed"]} (limit {r["limit"]} s, final lb {r["final_lb"]}, ub {r["final_ub"]})')
pr('')

ratios = defaultdict(list); flagged = []
pr('## Seed panel: per cell (wall s; seeds 0-4; "T" = timeout counted as the limit)\n')
pr('| Tier | Code | main no-card median (range) | main card-mto median (range) | CC median (range) | ratio vs no-card | ratio vs card-mto | CC worst seed / main best seed (nc / mto) |')
pr('|---:|---|---|---|---|---:|---:|---|')


def ser(arm):
    xs = [(arm[s]['limit'] if arm[s]['timeout'] else arm[s]['wall']) for s in sorted(arm)]
    tt = sum(arm[s]['timeout'] for s in arm)
    return xs, tt


for (t, c) in sorted(cell, key=lambda k: (k[0], k[1])):
    arms = cell[(t, c)]; meds = {}; rng = {}
    for a in ['main-nc', 'main-mto', 'cc']:
        xs, tt = ser(arms[a]); meds[a] = statistics.median(xs)
        rng[a] = f'{statistics.median(xs):.4g} ({min(xs):.4g}-{max(xs):.4g}{", %dT" % tt if tt else ""})'
        assert len(xs) == 5, (c, a, len(xs))
    rn = meds['cc'] / meds['main-nc']; rm = meds['cc'] / meds['main-mto']
    ccw = max(ser(arms['cc'])[0]); wb = (ccw / min(ser(arms['main-nc'])[0]), ccw / min(ser(arms['main-mto'])[0]))
    if t >= 1:
        ratios[(t, 'no-card')].append(rn); ratios[(t, 'card-mto')].append(rm)
        for m, x in (('no-card', rn), ('card-mto', rm)):
            if x > 1: flagged.append((t, c, m, x))
    pr(f'| {t} | {c} | {rng["main-nc"]} | {rng["main-mto"]} | {rng["cc"]} | {rn:.4g} | {rm:.4g} | {wb[0]:.3g} / {wb[1]:.3g} |')
pr('')
pr('## Per-tier geomean of seed-median ratios (CC / main) and gate\n')
pr('| Tier | cells | geomean vs no-card | geomean vs card-mto | max cell ratio | cells > 1 | cells > 1.25 | gate (geomean < 1 per mode, no cell > 1.25) |')
pr('|---:|---:|---:|---:|---:|---:|---:|---|')
for t in [1, 2, 3, 4]:
    a, b = ratios[(t, 'no-card')], ratios[(t, 'card-mto')]
    mx = max(a + b); n1 = sum(x > 1 for x in a + b); n125 = sum(x > 1.25 for x in a + b)
    ok = g(a) < 1 and g(b) < 1 and n125 == 0
    pr(f'| {t} | {len(a)} | {g(a):.4g} | {g(b):.4g} | {mx:.4g} | {n1} | {n125} | {"PASS" if ok else "FAIL"} |')
pr('')
pr('Cells with ratio > 1: ' + (', '.join(f'T{t} {c} {m} {x:.3f}' for t, c, m, x in flagged) or 'none') + '.\n')

# Tier 0 (correctness only) and CPU-time cross-check
t0 = [r for r in runs if r['tier'] == 0]
pr(f'Tier 0 (correctness only, 600 s): {len(t0)} runs, {sum(r["solved"] for r in t0)} correct answers, '
   f'{sum(not r["science_ok"] for r in t0)} problems, {sum(r["timeout"] for r in t0)} timeouts; '
   f'slowest run {max(r["wall"] for r in t0):.2f} s.\n')
pr('CPU-time cross-check (median utime ratio CC/main, tiers 1-4): ' + ', '.join(
    f'{c} {statistics.median([cell[(t, c)]["cc"][s]["utime"] for s in range(5)]) / max(1e-3, statistics.median([cell[(t, c)]["main-nc"][s]["utime"] for s in range(5)])):.3g}/'
    f'{statistics.median([cell[(t, c)]["cc"][s]["utime"] for s in range(5)]) / max(1e-3, statistics.median([cell[(t, c)]["main-mto"][s]["utime"] for s in range(5)])):.3g}'
    for (t, c) in sorted(cell) if t >= 1) + '\n')

# ---- Tier 5
main5 = {}
for l in open(MS):
    m = re.match(r'\| (\S+) \| (no-card|card-mto) \| (\d+) \| (\S+) \| (\S+) \| (\S+) \| (.*) \|$', l.strip())
    if m and m.group(1)[:2] in ('BB', 'LP', 'TN'):
        main5[(m.group(1), m.group(2))] = dict(wall=int(m.group(3)), res=m.group(4), lb=m.group(5), ub=m.group(6), ev=m.group(7))
t5 = json.load(open(T5))['results']
pr('## Tier 5 (CC, default seed, 21600 s) against main 398054e (SERVER.md, 1 run per mode)\n')
pr('| Code | CC result | CC wall s | CC final lb / ub | CC lb events (value@s) | main no-card: result, lb/ub, wall | main card-mto: result, lb/ub, wall | lb >= main | ub <= main | check |')
pr('|---|---|---:|---|---|---|---|---|---|---|')
solved_cc = 0; solved_main = 0; crit = []
for r in sorted(t5, key=lambda r: r['stem']):
    s = r['stem']; mn = main5[(s, 'no-card')]; mm = main5[(s, 'card-mto')]
    res = f'd={r["result"][1]} @ {r["result"][0]} s' if r['result'] else 'TIMEOUT'
    solved_cc += 2 if r['result'] else 0
    solved_main += (mn['res'] == 'solved') + (mm['res'] == 'solved')
    ev = []; last = None
    for e, v in r['lb_events']:
        if v >= 15 and v != last: ev.append(f'{v}@{e:.0f}')
        last = v
    lbok = all(r['final_lb'] is not None and r['final_lb'] >= int(x['lb']) for x in (mn, mm))
    ubs = [int(x['ub']) for x in (mn, mm) if x['ub'] != '-']
    ubok = all(r['final_ub'] is not None and r['final_ub'] <= u for u in ubs) if ubs else True
    if not lbok or not ubok: crit.append(s)
    if (mn['res'] == 'solved' or mm['res'] == 'solved') and not r['result']: crit.append(s + ' (main solved, CC not)')
    pr(f'| {s} | {res} | {r["wall"]:.0f} | {r["final_lb"]} / {r["final_ub"] if r["final_ub"] is not None else "-"} | '
       f'{", ".join(ev[-6:])} | {mn["res"]}, {mn["lb"]}/{mn["ub"]}, {mn["wall"]} | {mm["res"]}, {mm["lb"]}/{mm["ub"]}, {mm["wall"]} | '
       f'{"yes" if lbok else "NO"} | {"yes" if ubok else "NO"} | {"ok" if r["science_ok"] else r["issues"]} |')
pr('')
pr(f'Solved cells (code x mode; one CC run covers both mode cells): CC {solved_cc} of {2 * len(t5)}, main {solved_main} of {2 * len(t5)}. '
   f'Tier 5 criterion failures: {crit or "none"}. Science problems: {sum(not r["science_ok"] for r in t5)}.')
print('\n'.join(out))
