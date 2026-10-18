#!/usr/bin/env python3
"""GH-129 S1 server analysis.
usage: analyze_gh129.py PANEL/results.jsonl TIER5/results.json MAIN_SERVER.md GH124_CC_TIER5/results.json
Seed-median judging (docs/OPTIMIZATION_LOOP_POLICY.md): cell = code x mode; ratio = median_s(cand) / median_s(main)
(same mode); a timed-out run counts as its limit (censored). Tier pass: per-mode geomean < 1 and no cell > 1.25.
Tier 5: candidate (-frontier=on, default seed, 1 run per mode) vs main's recorded run (SERVER.md) and vs the
optional CC engine (GH-124 S1, one run per code; old stem names are matched on family_n_k)."""
import json, math, re, statistics, sys
from collections import defaultdict

P, T5, MS, CC5 = sys.argv[1:5]
runs = [json.loads(l) for l in open(P) if l.strip()]
errs = [r for r in runs if 'error' in r]
runs = [r for r in runs if 'error' not in r]
cell = defaultdict(dict)
for r in runs:
    cell[(r['tier'], r['case'])].setdefault(r['arm'], {})[r['seed']] = r
g = lambda x: math.exp(sum(map(math.log, x)) / len(x))
out = []; pr = out.append
pr('## Panel run counts and correctness\n')
nbad = [r for r in runs if not r['science_ok']]
nto = [r for r in runs if r['timeout']]
pr(f'- Runs: {len(runs)} (runner errors: {len(errs)}). Answers vs stem d: {sum(r["solved"] for r in runs)} correct, '
   f'{len(nbad)} wrong/bound violations, {len(nto)} without an answer (timeout).')
pr(f'- Runner backstop kills: {sum(r["runner_killed"] for r in runs)}; non-zero rc: {sum(r["rc"] != 0 for r in runs)}; '
   f'max RSS: {max(r["maxrss_kb"] for r in runs) / 1024:.0f} MB.')
for r in nbad: pr(f'  - PROBLEM {r["case"]} {r["arm"]} seed {r["seed"]}: {r["issues"]}')
for r in nto: pr(f'  - TIMEOUT {r["case"]} {r["arm"]} seed {r["seed"]} (limit {r["limit"]} s, final lb {r["final_lb"]}, ub {r["final_ub"]})')
pr('')


def ser(arm):
    xs = [(arm[s]['limit'] if arm[s]['timeout'] else arm[s]['wall']) for s in sorted(arm)]
    return xs, sum(arm[s]['timeout'] for s in arm)


def fmt(xs, tt):
    return f'{statistics.median(xs):.4g} ({min(xs):.4g}-{max(xs):.4g}{", %dT" % tt if tt else ""})'


ratios = defaultdict(list); flagged = []
pr('## Seed panel: per cell (wall s, median over seeds 0-4 (range); "T" = timeouts counted as the limit)\n')
pr('| Tier | Code | Mode | main median (range) | cand median (range) | ratio cand/main | cand worst / main best | CPU (utime) median ratio |')
pr('|---:|---|---|---|---|---:|---:|---:|')
for (t, c) in sorted(cell):
    arms = cell[(t, c)]
    for mode, ma, ca in (('no-card', 'main-nc', 'cand-nc'), ('card-mto', 'main-mto', 'cand-mto')):
        xm, tm = ser(arms[ma]); xc, tc = ser(arms[ca])
        assert len(xm) == 5 and len(xc) == 5, (c, mode, len(xm), len(xc))
        r = statistics.median(xc) / statistics.median(xm)
        ur = statistics.median([arms[ca][s]['utime'] for s in arms[ca]]) / max(1e-3, statistics.median([arms[ma][s]['utime'] for s in arms[ma]]))
        ratios[(t, mode)].append(r)
        if r > 1: flagged.append((t, c, mode, r))
        pr(f'| {t} | {c} | {mode} | {fmt(xm, tm)} | {fmt(xc, tc)} | {r:.4g} | {max(xc) / min(xm):.3g} | {ur:.3g} |')
pr('')
pr('## Per-tier geomean of seed-median ratios (cand / main) and gate\n')
pr('| Tier | cells per mode | geomean no-card | geomean card-mto | max cell ratio | cells > 1 | cells > 1.25 | gate (geomean < 1 per mode, no cell > 1.25) |')
pr('|---:|---:|---:|---:|---:|---:|---:|---|')
for t in sorted(set(t for t, _ in ratios)):
    a, b = ratios[(t, 'no-card')], ratios[(t, 'card-mto')]
    mx = max(a + b); n1 = sum(x > 1 for x in a + b); n125 = sum(x > 1.25 for x in a + b)
    ok = g(a) < 1 and g(b) < 1 and n125 == 0
    pr(f'| {t} | {len(a)} | {g(a):.4g} | {g(b):.4g} | {mx:.4g} | {n1} | {n125} | {"PASS" if ok else "FAIL"} |')
pr('')
pr('Cells with ratio > 1: ' + (', '.join(f'T{t} {c} {m} {x:.3f}' for t, c, m, x in flagged) or 'none') + '.\n')

# ---- Tier 5
main5 = {}
for l in open(MS):
    m = re.match(r'\| (\S+) \| (no-card|card-mto) \| (\d+) \| (\S+) \| (\S+) \| (\S+) \| (.*) \|$', l.strip())
    if m and m.group(1)[:2] in ('BB', 'LP', 'TN'):
        main5[(m.group(1), m.group(2))] = dict(wall=int(m.group(3)), res=m.group(4), lb=m.group(5), ub=m.group(6), ev=m.group(7))
key = lambda s: '_'.join(s.split('_')[:3])
cc5 = {key(r['stem']): r for r in json.load(open(CC5))['results']}
t5 = json.load(open(T5))['results']
pr('## Tier 5 (candidate -frontier=on, default seed, 21600 s) vs main 398054e (SERVER.md) and the CC engine (GH-124 S1)\n')
pr('| Code | Mode | cand result (time) | cand final lb / ub | cand lb events (value@s, last 6) | cand ub events (value@s, last 4) | main: result, lb/ub, wall | CC: result, lb/ub, wall | cand lb vs main | cand ub vs main | check |')
pr('|---|---|---|---|---|---|---|---|---|---|---|')
sc = sm = scc = 0; worse = []; better = []
for r in sorted(t5, key=lambda r: (r['stem'], r['mode'])):
    s, mode = r['stem'], r['mode']; mn = main5[(s, mode)]; cc = cc5[key(s)]
    res = f'd={r["result"][1]} @ {r["result"][0]:.0f} s' if r['result'] else 'TIMEOUT'
    sc += bool(r['result']); sm += mn['res'] == 'solved'; scc += bool(cc['result'])   # per cell
    ev = []; last = None
    for e, v in r['lb_events']:
        if v != last: ev.append(f'{v}@{e:.0f}')
        last = v
    uv = []; last = None
    for e, v in r['ub_events']:
        if v != last: uv.append(f'{v}@{e:.0f}')
        last = v
    # The MaxSAT path prints 'c d_ub: -' at a timeout to say "no upper bound"; s1_tier5.py (written for CC, where '-'
    # withdraws a bound) then stores final_lb/final_ub = None. Recompute both from the timestamped events.
    flb = max([v for _, v in r['lb_events']], default=None)
    fub = min([v for _, v in r['ub_events']], default=None)
    mlb = int(mn['lb']); mub = None if mn['ub'] == '-' else int(mn['ub'])
    lbc = 'n/a' if flb is None else ('>' if flb > mlb else '=' if flb == mlb else '<')
    ubc = ('=' if fub == mub else '-') if fub is None or mub is None else ('<' if fub < mub else '=' if fub == mub else '>')
    if fub is not None and mub is None: ubc = 'new'
    if fub is None and mub is not None: ubc = 'missing'
    if lbc == '<' or ubc in ('>', 'missing') or (mn['res'] == 'solved' and not r['result']): worse.append(f'{s} {mode}')
    if lbc == '>' or ubc in ('<', 'new') or (r['result'] and mn['res'] != 'solved'): better.append(f'{s} {mode}')
    ccres = f'd={cc["result"][1]} @ {cc["result"][0]:.0f} s' if cc['result'] else 'TIMEOUT'
    pr(f'| {s} | {mode} | {res} | {flb} / {fub if fub is not None else "-"} | {", ".join(ev[-6:])} | {", ".join(uv[-4:])} | '
       f'{mn["res"]}, {mn["lb"]}/{mn["ub"]}, {mn["wall"]} | {ccres}, {cc["final_lb"]}/{cc["final_ub"] if cc["final_ub"] is not None else "-"}, {cc["wall"]:.0f} | '
       f'{lbc} | {ubc} | {"ok" if r["science_ok"] else r["issues"]} |')
pr('')
pr(f'Solved cells: cand {sc} of {len(t5)}, main {sm} of {len(t5)}, CC {scc} of {len(t5)} (one CC run per code covers both mode cells).')
pr(f'Cells where cand is worse than main (lower lb, higher/missing ub, or unsolved where main solved): {worse or "none"}.')
pr(f'Cells where cand is better than main: {len(better)} ({", ".join(better)}).')
pr(f'Science problems: {sum(not r["science_ok"] for r in t5)}.')
pr('')
pr('### Time to reach the final lower bound of main (cells where both reach the same lb >= 16), cand / main\n')
pr('| Code | Mode | lb | cand s | main s | ratio |')
pr('|---|---|---:|---:|---:|---:|')
rs = []
for r in sorted(t5, key=lambda r: (r['stem'], r['mode'])):
    mn = main5[(r['stem'], r['mode'])]; mlb = int(mn['lb'])
    if mlb < 16: continue
    mt = [int(x.split('@')[1]) for x in mn['ev'].split(', ') if int(x.split('@')[0]) == mlb]
    ct = [e for e, v in r['lb_events'] if v == mlb]
    if not mt or not ct: continue
    rr = max(ct[0], 1) / max(mt[0], 1); rs.append(rr)
    pr(f"| {r['stem']} | {r['mode']} | {mlb} | {ct[0]:.0f} | {mt[0]} | {rr:.2f} |")
if rs: pr(f'\nGeomean {math.exp(sum(map(math.log, rs)) / len(rs)):.3f} over {len(rs)} cells.')
print('\n'.join(out))
