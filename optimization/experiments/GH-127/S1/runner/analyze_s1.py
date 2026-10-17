#!/usr/bin/env python3
"""GH-127 S1 analysis.
usage: analyze_s1.py PANEL/results.jsonl TIER5_A/results.json TIER5_B/results.json SERVER.md CC_TIER5/results.json
Seed-median judging (docs/OPTIMIZATION_LOOP_POLICY.md): cell ratio = median_s(variant) / median_s(main), same mode;
a timed-out run counts as its limit (censored). Tier pass: per-mode geomean < 1 and no cell > 1.25.
Missing Tier 5 files are skipped (partial report)."""
import json, math, os, re, statistics, sys
from collections import defaultdict

P, TA, TB, MS, CC = sys.argv[1:6]
runs = [json.loads(l) for l in open(P) if l.strip()]
errs = [r for r in runs if 'error' in r]
runs = [r for r in runs if 'error' not in r]
cell = defaultdict(lambda: defaultdict(dict))   # (tier, case, mode) -> arm -> seed -> rec
for r in runs:
    cell[(r['tier'], r['case'], r['mode'])][r['arm']][r['seed']] = r
g = lambda x: math.exp(sum(map(math.log, x)) / len(x)) if x else float('nan')
VAR = ['A', 'B']
NAME = {'A': 'A (unit:8)', 'B': 'B (unit:4)'}
out = []; pr = out.append


def tval(r): return r['limit'] if r['timeout'] else r['wall']


def ser(arm):
    xs = [tval(arm[s]) for s in sorted(arm)]
    return xs, sum(arm[s]['timeout'] for s in arm)


pr('## Panel run counts and correctness\n')
pr('| Arm | runs | correct answers | wrong answers / bound violations | timeouts | non-zero rc | max RSS MB |')
pr('|---|---:|---:|---:|---:|---:|---:|')
for arm in ['main'] + VAR:
    rs = [r for r in runs if r['arm'] == arm]
    if not rs: continue
    pr(f'| {arm} | {len(rs)} | {sum(r["solved"] for r in rs)} | {sum(not r["science_ok"] for r in rs)} | '
       f'{sum(r["timeout"] for r in rs)} | {sum(r["rc"] != 0 for r in rs)} | {max(r["maxrss_kb"] for r in rs) / 1024:.0f} |')
pr(f'\nRunner errors: {len(errs)}; runner backstop kills: {sum(r["runner_killed"] for r in runs)}.\n')
for r in runs:
    if not r['science_ok']: pr(f'- PROBLEM T{r["tier"]} {r["case"]} {r["arm"]} {r["mode"]} seed {r["seed"]}: {r["issues"]}')
for r in sorted(runs, key=lambda r: (r['tier'], r['case'], r['arm'], r['mode'], r['seed'])):
    if r['timeout']:
        pr(f'- TIMEOUT T{r["tier"]} {r["case"]} {r["arm"]} {r["mode"]} seed {r["seed"]} (limit {r["limit"]} s, '
           f'final lb {r["final_lb"]}, ub {r["final_ub"]})')
pr('')

ratios = defaultdict(list); flagged = defaultdict(list); rows = []
pr('## Seed panel, tiers 1-4: per cell (wall s, median over seeds 0-4, range; "T" = timeouts counted at the limit)\n')
pr('| Tier | Code | Mode | main median (range) | A median (range) | A ratio | B median (range) | B ratio | A worst / main best | B worst / main best |')
pr('|---:|---|---|---|---|---:|---|---:|---:|---:|')
for key in sorted(cell, key=lambda k: (k[0], k[1], k[2] != 'no-card')):
    t, c, m = key
    if t == 0: continue
    arms = cell[key]
    if not all(len(arms[a]) == 5 for a in ['main'] + VAR): pr(f'| {t} | {c} | {m} | incomplete | | | | | | |'); continue
    meds = {}; rng = {}
    for a in ['main'] + VAR:
        xs, tt = ser(arms[a]); meds[a] = statistics.median(xs)
        rng[a] = f'{meds[a]:.4g} ({min(xs):.4g}-{max(xs):.4g}{", %dT" % tt if tt else ""})'
    mb = min(ser(arms['main'])[0])
    rr = {}
    for v in VAR:
        rr[v] = meds[v] / meds['main']; ratios[(v, t, m)].append(rr[v])
        if rr[v] > 1: flagged[v].append((t, c, m, rr[v]))
    pr(f'| {t} | {c} | {m} | {rng["main"]} | {rng["A"]} | {rr["A"]:.3f} | {rng["B"]} | {rr["B"]:.3f} | '
       f'{max(ser(arms["A"])[0]) / mb:.3g} | {max(ser(arms["B"])[0]) / mb:.3g} |')
pr('')
pr('## Per-tier geomean of seed-median ratios (variant / main, same mode) and gate\n')
pr('| Variant | Tier | cells per mode | geomean no-card | geomean card-mto | max cell | cells > 1 | cells > 1.25 | gate (geomean < 1 per mode, no cell > 1.25) |')
pr('|---|---:|---:|---:|---:|---:|---:|---:|---|')
gate = {}
for v in VAR:
    for t in [1, 2, 3, 4]:
        a, b = ratios[(v, t, 'no-card')], ratios[(v, t, 'card-mto')]
        if not a or not b: continue
        mx = max(a + b); n1 = sum(x > 1 for x in a + b); n125 = sum(x > 1.25 for x in a + b)
        ok = g(a) < 1 and g(b) < 1 and n125 == 0; gate[(v, t)] = ok
        pr(f'| {NAME[v]} | {t} | {len(a)} | {g(a):.3f} | {g(b):.3f} | {mx:.3f} | {n1} | {n125} | {"PASS" if ok else "FAIL"} |')
pr('')
allv = {v: [x for (vv, t, m), xs in ratios.items() if vv == v for x in xs] for v in VAR}
for v in VAR:
    pr(f'- {NAME[v]}: geomean over all {len(allv[v])} tier1-4 cells {g(allv[v]):.3f}; cells > 1: ' +
       (', '.join(f'T{t} {c} {m} {x:.3f}' for t, c, m, x in sorted(flagged[v], key=lambda z: -z[3])) or 'none') + '.')
pr('')

# Tier 0
pr('## Tier 0 (correctness only, 600 s limit)\n')
pr('| Arm | runs | correct | problems | timeouts | slowest run s | geomean of seed-median ratio vs main (info) |')
pr('|---|---:|---:|---:|---:|---:|---:|')
for arm in ['main'] + VAR:
    rs = [r for r in runs if r['tier'] == 0 and r['arm'] == arm]
    if not rs: continue
    rat = []
    if arm != 'main':
        for key in cell:
            if key[0] == 0 and len(cell[key][arm]) == 5 and len(cell[key]['main']) == 5:
                rat.append(statistics.median(ser(cell[key][arm])[0]) / statistics.median(ser(cell[key]['main'])[0]))
    pr(f'| {arm} | {len(rs)} | {sum(r["solved"] for r in rs)} | {sum(not r["science_ok"] for r in rs)} | '
       f'{sum(r["timeout"] for r in rs)} | {max(r["wall"] for r in rs):.2f} | {g(rat):.3f} |' if rat else
       f'| {arm} | {len(rs)} | {sum(r["solved"] for r in rs)} | {sum(not r["science_ok"] for r in rs)} | '
       f'{sum(r["timeout"] for r in rs)} | {max(r["wall"] for r in rs):.2f} | - |')
pr('')

# CPU-time cross-check
pr('CPU-time cross-check (seed-median utime ratio A/main, B/main per tier1-4 cell): ' + '; '.join(
    f'{c} {m}: ' + '/'.join(
        f'{statistics.median([cell[(t, c, m)][v][s]["utime"] for s in range(5)]) / max(1e-3, statistics.median([cell[(t, c, m)]["main"][s]["utime"] for s in range(5)])):.3g}'
        for v in VAR)
    for (t, c, m) in sorted(cell) if t >= 1 and all(len(cell[(t, c, m)][a]) == 5 for a in ['main'] + VAR)) + '\n')

# ---- Tier 5
main5 = {}
for l in open(MS):
    mm = re.match(r'\| (\S+) \| (no-card|card-mto) \| (\d+) \| (\S+) \| (\S+) \| (\S+) \| (.*) \|$', l.strip())
    if mm and mm.group(1)[:2] in ('BB', 'LP', 'TN'):
        main5[(mm.group(1), mm.group(2))] = dict(wall=int(mm.group(3)), res=mm.group(4), lb=int(mm.group(5)),
                                                  ub=None if mm.group(6) == '-' else int(mm.group(6)), ev=mm.group(7))


def main_lbtime(x):
    evs = [(int(v), int(s)) for v, s in re.findall(r'(\d+)@(\d+)', x['ev'])]
    return min(s for v, s in evs if v == x['lb'])


OLD = {'BB_360_12_17to24': 'BB_360_12_24', 'TN_252_2_17to28': 'TN_252_2_21', 'LP_1054_140_17to32': 'LP_1054_140_20',
       'LP_1428_184_ge17': 'LP_1428_184_24', 'LP_1768_224_ge17': 'LP_1768_224_22'}
cc = {OLD.get(r['stem'], r['stem']): r for r in json.load(open(CC))['results']}
t5 = {}
for tag, f in (('A', TA), ('B', TB)):
    if os.path.exists(f):
        for r in json.load(open(f))['results']:
            # The MaxSAT path prints 'c d_ub: -' at a timeout when no upper bound is known; this is not a CC-style
            # bound withdrawal, so the final bounds are recomputed from the events (only an 'lb' '-' voids the lb).
            r['final_lb'] = None if any(w[1] == 'lb' for w in r['withdrawn']) else max([v for _, v in r['lb_events']], default=None)
            r['final_ub'] = min([v for _, v in r['ub_events']], default=None)
            t5[(r['stem'], r['mode'], tag)] = r


def first_time(evs, val): return min(e for e, v in evs if v == val)


def desc(r):
    if r is None: return 'not run'
    if r['result']: return f'd={r["result"][1]} @ {r["result"][0]:.0f} s'
    lb = r['final_lb']; ub = r['final_ub']
    return f'T, {lb}/{ub if ub is not None else "-"} (lb@{first_time(r["lb_events"], lb):.0f})' if lb is not None else 'T, -/-'


def lb_of(r): return r['result'][1] if r['result'] else r['final_lb']


def ladder(r, lo=15, n=6):
    ev = []; last = None
    for e, v in r['lb_events']:
        if v >= lo and v != last: ev.append(f'{v}@{e:.0f}')
        last = v
    return ', '.join(ev[-n:])


pr('## Tier 5 (6 h, default seed): A and B against main 398054e (SERVER.md, 1 run per cell) and CC (GH-124 S1)\n')
pr('Cells: `d=X @ t` = solved at t s; `T, lb/ub (lb@t)` = timeout with the final bounds and the first time the final lb was printed.\n')
pr('| Code | Mode | main | A (unit:8) | B (unit:4) | CC (mode-free) | A lb vs main | B lb vs main | A lb events >= 15 | B lb events >= 15 | checks |')
pr('|---|---|---|---|---|---|---|---|---|---|---|')
cnt = defaultdict(int); cmp = {v: defaultdict(int) for v in VAR}; cmpcc = {v: defaultdict(int) for v in VAR}
stems = sorted({k[0] for k in main5})
for s in stems:
    for m in ('no-card', 'card-mto'):
        x = main5[(s, m)]
        mdesc = (f'd={x["lb"]} @ {x["wall"]} s' if x['res'] == 'solved' else
                 f'T, {x["lb"]}/{x["ub"] if x["ub"] is not None else "-"} (lb@{main_lbtime(x)})')
        cnt['main'] += x['res'] == 'solved'
        c = cc.get(s); cdesc = desc(c) if c else 'n/a'
        cnt['cc'] += bool(c and c['result'])
        cells = {}; marks = {}; chk = []
        for v in VAR:
            r = t5.get((s, m, v)); cells[v] = desc(r)
            if r is None: marks[v] = '-'; continue
            cnt[v] += bool(r['result'])
            lv = lb_of(r); ml = x['lb']
            marks[v] = '>' if lv > ml else '=' if lv == ml else '<'
            cmp[v][marks[v]] += 1
            if c: cmpcc[v]['>' if lv > lb_of(c) else '=' if lv == lb_of(c) else '<'] += 1
            if x['res'] == 'solved' and not r['result']: chk.append(f'{v}: main solved, {v} not')
            if not r['science_ok']: chk.append(f'{v}: {r["issues"]}')
            if r['final_ub'] is not None and x['ub'] is not None and r['final_ub'] > x['ub'] and not r['result']:
                chk.append(f'{v}: ub {r["final_ub"]} > main {x["ub"]}')
        pr(f'| {s} | {m} | {mdesc} | {cells["A"]} | {cells["B"]} | {cdesc} | {marks["A"]} | {marks["B"]} | '
           f'{ladder(t5[(s, m, "A")]) if (s, m, "A") in t5 else "-"} | {ladder(t5[(s, m, "B")]) if (s, m, "B") in t5 else "-"} | '
           f'{"; ".join(chk) or "ok"} |')
pr('')
pr(f'Solved cells (of {2 * len(stems)}): main {cnt["main"]}, A {cnt["A"]}, B {cnt["B"]}, CC {cnt["cc"]} (one CC run per code fills both mode cells).\n')
for v in VAR:
    pr(f'- {NAME[v]}: final lb (or d) vs main: higher {cmp[v][">"]}, equal {cmp[v]["="]}, lower {cmp[v]["<"]}; '
       f'vs CC: higher {cmpcc[v][">"]}, equal {cmpcc[v]["="]}, lower {cmpcc[v]["<"]}.')
pr('')
# solved-cell times
pr('| Code | Mode | main time to d | A time to d | B time to d | CC time to d |')
pr('|---|---|---:|---:|---:|---:|')
for s in stems:
    for m in ('no-card', 'card-mto'):
        x = main5[(s, m)]; c = cc.get(s)
        ra, rb = t5.get((s, m, 'A')), t5.get((s, m, 'B'))
        if not (x['res'] == 'solved' or (ra and ra['result']) or (rb and rb['result']) or (c and c['result'])): continue
        f = lambda r: f'{r["result"][0]:.0f} (d={r["result"][1]})' if r and r['result'] else 'T'
        pr(f'| {s} | {m} | {str(x["wall"]) if x["res"] == "solved" else "T"} | {f(ra)} | {f(rb)} | {f(c)} |')
pr('')
print('\n'.join(out))
