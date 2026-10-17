#!/usr/bin/env python3
"""GH-130 S1 server analysis.
usage: analyze_gh130.py GH130_PANEL/results.jsonl GH129_PANEL/results.jsonl GH130_TIER5/results.json \
       GH129_TIER5/results.json MAIN_SERVER.md GH124_CC_TIER5/results.json
Seed-median judging (docs/OPTIMIZATION_LOOP_POLICY.md): cell = code x mode; ratio = median_s(cand) / median_s(main)
(same mode, same run batch); a timed-out run counts as its limit. Tier pass: per-mode geomean < 1, no cell > 1.25.
Cells where -frontier=auto turns frontier off on both halves (all TN cells) run main's search unchanged (per-probe
identity verified on a sample, ident_server.py); their ratio is 1 by identity and they are not re-run; main's
GH-129 panel medians are shown for reference. GH-129 (-frontier=on) medians are shown as a replicate for on-cells.
Tier 5: auto-on cells were re-run (6 h); auto-off cells = main's recorded run (identical search)."""
import json, math, re, statistics, sys
from collections import defaultdict

P, P129, T5, T5_129, MS, CC5 = sys.argv[1:7]
def load_panel(p):
    runs = [json.loads(l) for l in open(p) if l.strip()]
    errs = [r for r in runs if 'error' in r]; runs = [r for r in runs if 'error' not in r]
    cell = defaultdict(dict)
    for r in runs: cell[(r['tier'], r['case'])].setdefault(r['arm'], {})[r['seed']] = r
    return runs, errs, cell
runs, errs, cell = load_panel(P)
_, _, cell129 = load_panel(P129)
g = lambda x: math.exp(sum(map(math.log, x)) / len(x))
out = []; pr = out.append
def ser(arm):
    return [(arm[s]['limit'] if arm[s]['timeout'] else arm[s]['wall']) for s in sorted(arm)], sum(arm[s]['timeout'] for s in arm)
def fmt(xs, tt):
    return f'{statistics.median(xs):.4g} ({min(xs):.4g}-{max(xs):.4g}{", %dT" % tt if tt else ""})'
pr('## Panel run counts and correctness (auto-on cells)\n')
nbad = [r for r in runs if not r['science_ok']]; nto = [r for r in runs if r['timeout']]
pr(f'- Runs: {len(runs)} (runner errors: {len(errs)}). Answers vs stem d: {sum(r["solved"] for r in runs)} correct, '
   f'{len(nbad)} wrong/bound violations, {len(nto)} without an answer (timeout).')
pr(f'- Runner backstop kills: {sum(r["runner_killed"] for r in runs)}; non-zero rc: {sum(r["rc"] != 0 for r in runs)}; '
   f'max RSS: {max(r["maxrss_kb"] for r in runs) / 1024:.0f} MB.')
for r in nbad: pr(f'  - PROBLEM {r["case"]} {r["arm"]} seed {r["seed"]}: {r["issues"]}')
for r in nto: pr(f'  - TIMEOUT {r["case"]} {r["arm"]} seed {r["seed"]} (limit {r["limit"]} s, final lb {r["final_lb"]}, ub {r["final_ub"]})')
pr('')
ratios = defaultdict(list); flagged = []
pr('## Seed panel: per cell (wall s, median over seeds 0-4 (range); "T" = timeouts counted as the limit)\n')
pr('| Tier | Code | Mode | auto decision | main median (range) | cand median (range) | ratio cand/main | cand worst / main best | CPU median ratio | GH-129 on/main (replicate) |')
pr('|---:|---|---|---|---|---|---:|---:|---:|---:|')
allcells = sorted(set(cell) | set(cell129))
for (t, c) in allcells:
    for mode, ma, ca in (('no-card', 'main-nc', 'cand-nc'), ('card-mto', 'main-mto', 'cand-mto')):
        old = cell129.get((t, c))
        r129 = statistics.median(ser(old[ca])[0]) / statistics.median(ser(old[ma])[0]) if old else None
        if (t, c) in cell:
            arms = cell[(t, c)]
            xm, tm = ser(arms[ma]); xc, tc = ser(arms[ca])
            assert len(xm) == 5 and len(xc) == 5, (c, mode)
            r = statistics.median(xc) / statistics.median(xm)
            ur = statistics.median([arms[ca][s]['utime'] for s in arms[ca]]) / max(1e-3, statistics.median([arms[ma][s]['utime'] for s in arms[ma]]))
            ratios[(t, mode)].append(r)
            if r > 1: flagged.append((t, c, mode, r))
            pr(f'| {t} | {c} | {mode} | on/on | {fmt(xm, tm)} | {fmt(xc, tc)} | {r:.4g} | {max(xc) / min(xm):.3g} | {ur:.3g} | {r129:.4g} |')
        else:
            xm, tm = ser(old[ma])
            ratios[(t, mode)].append(1.0)
            pr(f'| {t} | {c} | {mode} | off/off | {fmt(xm, tm)} (GH-129 batch) | = main (identical search) | 1 | - | - | {r129:.4g} |')
pr('')
pr('## Per-tier geomean of seed-median ratios (cand / main) and gate\n')
pr('| Tier | cells per mode | geomean no-card | geomean card-mto | max cell ratio | cells > 1 | cells > 1.25 | gate |')
pr('|---:|---:|---:|---:|---:|---:|---:|---|')
for t in sorted(set(t for t, _ in ratios)):
    a, b = ratios[(t, 'no-card')], ratios[(t, 'card-mto')]
    mx = max(a + b); n1 = sum(x > 1 for x in a + b); n125 = sum(x > 1.25 for x in a + b)
    ok = g(a) < 1 and g(b) < 1 and n125 == 0
    ident = all(x == 1.0 for x in a + b)   # every cell runs main's search unchanged (auto off on both halves)
    v = 'PASS' if ok else ('NEUTRAL (identical to main)' if ident else 'FAIL')
    pr(f'| {t} | {len(a)} | {g(a):.4g} | {g(b):.4g} | {mx:.4g} | {n1} | {n125} | {v} |')
pr('')
pr('Cells with ratio > 1: ' + (', '.join(f'T{t} {c} {m} {x:.3f}' for t, c, m, x in flagged) or 'none') + '.\n')

main5 = {}
for l in open(MS):
    m = re.match(r'\| (\S+) \| (no-card|card-mto) \| (\d+) \| (\S+) \| (\S+) \| (\S+) \| (.*) \|$', l.strip())
    if m and m.group(1)[:2] in ('BB', 'LP', 'TN'):
        main5[(m.group(1), m.group(2))] = dict(wall=int(m.group(3)), res=m.group(4), lb=m.group(5), ub=m.group(6), ev=m.group(7))
key = lambda s: '_'.join(s.split('_')[:3])
cc5 = {key(r['stem']): r for r in json.load(open(CC5))['results']}
t5 = {(r['stem'], r['mode']): r for r in json.load(open(T5))['results']}
t5o = {(r['stem'], r['mode']): r for r in json.load(open(T5_129))['results']}
def evs(evl, k):
    ev = []; last = None
    for e, v in evl:
        if v != last: ev.append(f'{v}@{e:.0f}')
        last = v
    return ', '.join(ev[-k:])
def summ(r):
    flb = max([v for _, v in r['lb_events']], default=None); fub = min([v for _, v in r['ub_events']], default=None)
    res = f'd={r["result"][1]} @ {r["result"][0]:.0f} s' if r['result'] else 'TIMEOUT'
    return res, flb, fub
pr('## Tier 5 (default seed, 21600 s): -frontier=auto vs main 398054e (SERVER.md), GH-129 -frontier=on and CC (GH-124 S1)\n')
pr('| Code | Mode | auto | auto result | auto lb / ub | auto lb events | auto ub events | main result, lb/ub, wall | GH-129 on result, lb/ub | CC result, lb/ub, wall | auto vs main | check |')
pr('|---|---|---|---|---|---|---|---|---|---|---|---|')
sc = sm = scc = so = 0; worse = []; better = []
for (s, mode) in sorted(main5):
    mn = main5[(s, mode)]; cc = cc5[key(s)]; o = t5o[(s, mode)]
    ores, olb, oub = summ(o)
    ccres = f'd={cc["result"][1]} @ {cc["result"][0]:.0f} s' if cc['result'] else 'TIMEOUT'
    mlb = int(mn['lb']); mub = None if mn['ub'] == '-' else int(mn['ub'])
    sm += mn['res'] == 'solved'; scc += bool(cc['result']); so += bool(o['result'])
    if (s, mode) in t5:
        r = t5[(s, mode)]; res, flb, fub = summ(r); sc += bool(r['result'])
        lbc = '>' if flb > mlb else '=' if flb == mlb else '<'
        if fub is None and mub is None: ubc = '='
        elif fub is None: ubc = 'missing'
        elif mub is None: ubc = 'new'
        else: ubc = '<' if fub < mub else '=' if fub == mub else '>'
        if lbc == '<' or ubc in ('>', 'missing') or (mn['res'] == 'solved' and not r['result']): worse.append(f'{s} {mode}')
        if lbc == '>' or ubc in ('<', 'new') or (r['result'] and mn['res'] != 'solved'): better.append(f'{s} {mode}')
        pr(f'| {s} | {mode} | on | {res} | {flb} / {fub if fub is not None else "-"} | {evs(r["lb_events"], 3)} | {evs(r["ub_events"], 3)} | '
           f'{mn["res"]}, {mn["lb"]}/{mn["ub"]}, {mn["wall"]} | {ores}, {olb}/{oub if oub is not None else "-"} | '
           f'{ccres}, {cc["final_lb"]}/{cc["final_ub"] if cc["final_ub"] is not None else "-"}, {cc["wall"]:.0f} | lb {lbc}, ub {ubc} | {"ok" if r["science_ok"] else r["issues"]} |')
    else:
        sc += mn['res'] == 'solved'
        pr(f'| {s} | {mode} | off | = main | {mn["lb"]} / {mn["ub"]} | (main) | (main) | {mn["res"]}, {mn["lb"]}/{mn["ub"]}, {mn["wall"]} | '
           f'{ores}, {olb}/{oub if oub is not None else "-"} | {ccres}, {cc["final_lb"]}/{cc["final_ub"] if cc["final_ub"] is not None else "-"}, {cc["wall"]:.0f} | identical | - |')
pr('')
pr(f'Solved cells (of {len(main5)}): auto {sc} (re-run on-cells + main\'s off-cells), main {sm}, GH-129 on {so}, CC {scc} (one CC run per code covers both modes).')
pr(f'auto-on cells worse than main: {worse or "none"}; better than main: {len(better)} ({", ".join(better)}).')
pr(f'Science problems in re-run cells: {sum(not r["science_ok"] for r in t5.values())}.\n')
pr('### Time to main\'s final lb (auto-on cells, lb >= 16): auto / main and GH-129 on / main\n')
pr('| Code | Mode | lb | auto s | GH-129 on s | main s | auto/main | on/main |')
pr('|---|---|---:|---:|---:|---:|---:|---:|')
rs = []
for (s, mode), r in sorted(t5.items()):
    mn = main5[(s, mode)]; mlb = int(mn['lb'])
    if mlb < 16: continue
    mt = [int(x.split('@')[1]) for x in mn['ev'].split(', ') if int(x.split('@')[0]) == mlb]
    ct = [e for e, v in r['lb_events'] if v >= mlb]; ot = [e for e, v in t5o[(s, mode)]['lb_events'] if v >= mlb]
    if not mt or not ct: continue
    rr = max(ct[0], 1) / max(mt[0], 1); rs.append(rr)
    orr = f'{max(ot[0], 1) / max(mt[0], 1):.2f}' if ot else '-'
    pr(f'| {s} | {mode} | {mlb} | {ct[0]:.0f} | {ot[0] if ot else "-"} | {mt[0]} | {rr:.2f} | {orr} |')
if rs: pr(f'\nGeomean auto/main {g(rs):.3f} over {len(rs)} cells.')
print('\n'.join(out))
