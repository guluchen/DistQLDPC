#!/usr/bin/env python3
"""Build optimization/baselines/{main_mac_reference.json, README.md, main_server_reference.json, SERVER.md} for main
cbb0642 from the raw runs, with a comparison against the previous (main 398054e) tables.
usage: make_tables.py --mac-tsv results.tsv --mac-logs LOGDIR --panel panel/results.jsonl --tier5 tier5/results.json \
       --old-mac OLD_MAC.json --old-server OLD_SERVER.json --mac-sha SHA --server-sha SHA --out optimization/baselines
Statistics: Mac = median of 3 serial runs; server tiers 0-4 = median over seeds 0-4 (a timed-out run counts as its limit);
server tier 5 = one run per cell. Geomeans are over per-cell ratios new median / old median."""
import argparse, collections, json, math, re, statistics
ap = argparse.ArgumentParser()
for k in ('mac-tsv', 'mac-logs', 'panel', 'tier5', 'old-mac', 'old-server', 'mac-sha', 'server-sha', 'out'):
    ap.add_argument('--' + k, required=True)
ap.add_argument('--date', default='2026-10-18')
ap.add_argument('--mac-note', action='append', default=[], help='extra note line(s) for README.md')
a = ap.parse_args()
g = lambda x: math.exp(sum(map(math.log, x)) / len(x)) if x else float('nan')
MAC_LIMIT = {0: 600, 1: 1800, 2: 1800, 3: 1800, 4: 2000}
SRV_LIMIT = {0: 600, 1: 1800, 2: 1800, 3: 1800, 4: 5000, 5: 21600}
MODE_ORDER = {'card-mto': 0, 'no-card': 1}
old_mac = {(r['case'], r['mode']): r for r in json.load(open(a.old_mac))['rows']}
old_srv = {(r['case'], r['mode']): r for r in json.load(open(a.old_server))['rows']}
HOST_MAC = 'Mac (Apple M6, 12 CPUs), macOS'
HOST_SRV = 'yfclab2 (2x AMD EPYC 7742, 256 logical CPUs, Ubuntu 24.04, GCC 13.3)'
BIN_DESC = 'main cbb0642 (GH-130 adopted: -frontier=auto default)'


def stem_d(stem):
    f = stem.split('_')[3]
    return int(f) if f.isdigit() else None


def bounds_of(stem):
    f = stem.split('_')[3]
    if f.isdigit(): return int(f), int(f)
    if f.startswith('ge'): return int(f[2:]), None
    x, y = f.split('to'); return int(x), int(y)


def tier_rule(t):   # PI 2026-10-12: slower-mode time on the dedicated server
    if t is None or t > 5000: return 5
    return 0 if t < 1 else 1 if t < 10 else 2 if t < 100 else 3 if t < 2000 else 4


def fmt(x, nd=4):
    return f'{x:.{nd}f}'.rstrip('0').rstrip('.') if isinstance(x, float) else str(x)


# ---------------- Mac ----------------
mac = collections.defaultdict(list); problems = []
for l in open(a.mac_tsv):
    f = l.rstrip('\n').split('\t')
    if len(f) < 4: continue
    t, s, m, r = f[0].split('|'); t = int(t[1:]); rc = int(f[1]); wall = float(f[2])
    log = open(f'{a.mac_logs}/{s}.{m}.{r}.log').read()
    o = re.findall(r'^o (\d+)\s*$', log, re.M)
    lbs = [int(x) for x in re.findall(r'^c d_lb: (\d+)\s*$', log, re.M)]
    ubs = [int(x) for x in re.findall(r'^c d_ub: (\d+)\s*$', log, re.M)]
    d = stem_d(s); res = int(o[-1]) if o else None
    iss = []
    if rc != 0 or len(f) > 4: iss.append(f'rc {rc}' + (' MEMKILL' if len(f) > 4 else ''))
    if res != d: iss.append(f'answer {res} != stem d {d}')
    if any(x > d for x in lbs): iss.append('lb above stem d')
    if any(x < d for x in ubs): iss.append('ub below stem d')
    if iss: problems.append((f[0], iss))
    mac[(t, s, m)].append(dict(wall=wall, res=res, lb=max(lbs, default=None), ub=min(ubs, default=None), rc=rc, run=r))
mac_rows = []; mac_ratio = collections.defaultdict(list)
for (t, s, m) in sorted(mac, key=lambda k: (k[0], k[1], MODE_ORDER[k[2]])):
    xs = sorted(v['wall'] for v in mac[(t, s, m)]); med = statistics.median(xs)
    v0 = mac[(t, s, m)][0]; old = old_mac.get((s, m)); ratio = round(med / old['median_s'], 4) if old else None
    if ratio: mac_ratio[(t, m)].append(ratio)
    mac_rows.append(dict(tier=t, case=s, mode=m, n=len(xs), median_s=round(med, 4), min_s=round(xs[0], 4),
                         max_s=round(xs[-1], 4), solved=all(v['res'] == stem_d(s) for v in mac[(t, s, m)]),
                         limit_s=MAC_LIMIT[t], result=f'o {v0["res"]}', final_lb=v0['lb'], final_ub=v0['ub'],
                         prev_398054e_median_s=old['median_s'] if old else None, ratio_vs_398054e=ratio,
                         sources=[f'mac_serial.py {a.date} serial, limit {MAC_LIMIT[t]}s']))
mac_method = ('runner/mac_jobs.py + runner/mac_serial.py: 3 serial runs per case/mode under caffeinate -i -s, 2 GB cap, '
              '>=2 cores free; default flags (frontier auto); limits tier0 600 s, tier1-3 1800 s, tier4 2000 s')
json.dump(dict(host=HOST_MAC, baseline_binary=BIN_DESC, binary_sha256=a.mac_sha, collected=a.date, method=mac_method,
               previous_table='main 398054e (2026-10-14), ratio_vs_398054e = median_s / its median_s', rows=mac_rows),
          open(f'{a.out}/main_mac_reference.json', 'w'), indent=1)
o = []; pr = o.append
pr(f'# Recorded main baseline times (PI 2026-10-11: record main\'s times instead of re-running main every time)\n')
pr(f'Host: {HOST_MAC}. Baseline binary: {BIN_DESC}, sha256 `{a.mac_sha}`. Collected {a.date}.\n')
pr(f'Method: {mac_method}. Column "vs 398054e" = this median / the main 398054e median (2026-10-14 table, git history).\n')
pr('| Tier | Case | Mode | Runs | Median s | Min s | Max s | 398054e median s | vs 398054e |')
pr('|---:|---|---|---:|---:|---:|---:|---:|---:|')
for r in mac_rows:
    pr(f'| {r["tier"]} | {r["case"]} | {r["mode"]} | {r["n"]} | {fmt(r["median_s"])} | {fmt(r["min_s"])} | {fmt(r["max_s"])} | '
       f'{fmt(r["prev_398054e_median_s"]) if r["prev_398054e_median_s"] is not None else "-"} | '
       f'{fmt(r["ratio_vs_398054e"], 3) if r["ratio_vs_398054e"] is not None else "-"} |')
pr('')
pr('Notes:')
pr('- Replaces the main 398054e table (2026-10-14) after GH-130 (PR #131, `-frontier=auto` default) was merged; old table is in git history.')
gm = ' '.join(f'tier{t} {m} {g(mac_ratio[(t, m)]):.3f}' for t in range(5) for m in ('no-card', 'card-mto') if mac_ratio[(t, m)])
pr(f'- vs main 398054e, geomean of per-cell median ratios: {gm}.')
fast = [r for r in mac_rows if r['ratio_vs_398054e'] is not None and r['ratio_vs_398054e'] < 0.9]
slow = [r for r in mac_rows if r['ratio_vs_398054e'] is not None and r['ratio_vs_398054e'] > 1.1]
pr('- Cells faster than 0.90x: ' + (', '.join(f'{r["case"]} {r["mode"]} {r["ratio_vs_398054e"]:.2f}' for r in fast) or 'none')
   + '. Cells slower than 1.10x: ' + (', '.join(f'{r["case"]} {r["mode"]} {r["ratio_vs_398054e"]:.2f}' for r in slow) or 'none')
   + '. `-frontier=auto` turns frontier branching on for every BB/GB/LP half of tiers 1-4 and off for every TN half (TN cells run the 398054e search unchanged; their ratios are host noise).')
pr(f'- Correctness: {sum(r["n"] for r in mac_rows)} runs, every answer equals the stem distance; ' +
   ('no run problems.' if not problems else 'PROBLEMS: ' + '; '.join(f'{k}: {v}' for k, v in problems)))
for n in a.mac_note: pr('- ' + n)
pr('- Every cached comparison runs one drift-check sample of the baseline per cell (`tier_cached_mac.py`); a sample outside the recorded range +-3% forces a full AB/BA/AB comparison for that cell.')
pr('- Tier 5 is not in this table: it needs the dedicated server (see SERVER.md).')
pr('- **Refresh rule (PI 2026-10-13):** whenever a PR that can change solver behaviour or speed is merged into main, re-record main\'s tier0-5 times as the new basis (this Mac table: tiers 0-4; SERVER.md: tiers 0-5) and re-check tier placement.')
open(f'{a.out}/README.md', 'w').write('\n'.join(o) + '\n')
print('MAC', len(mac_rows), 'cells;', sum(r['n'] for r in mac_rows), 'runs; problems', problems)
print('MAC geomeans:', gm)

# ---------------- server tiers 0-4 ----------------
panel = [json.loads(l) for l in open(a.panel) if l.strip()]
perr = [r for r in panel if 'error' in r]; panel = [r for r in panel if 'error' not in r]
cells = collections.defaultdict(dict)
for r in panel: cells[(r['tier'], r['case'], r['mode'])][r['seed']] = r
srv_rows = []; srv_ratio = collections.defaultdict(list); sproblems = [(r['case'], r['mode'], r['seed'], r['issues']) for r in panel if not r['science_ok']]
slower = collections.defaultdict(dict)
for (t, s, m) in sorted(cells, key=lambda k: (k[0], k[1], MODE_ORDER[k[2]])):
    seeds = cells[(t, s, m)]; lim = SRV_LIMIT[t]
    walls = {sd: (lim if seeds[sd]['timeout'] else seeds[sd]['wall']) for sd in sorted(seeds)}
    xs = list(walls.values()); med = statistics.median(xs); nto = sum(seeds[sd]['timeout'] for sd in seeds)
    old = old_srv.get((s, m)); ratio = round(med / old['median_s'], 4) if old else None
    if ratio: srv_ratio[(t, m)].append(ratio)
    r0 = seeds[min(seeds)]
    slower[s][m] = (med, nto)
    srv_rows.append(dict(tier=t, case=s, mode=m, n=len(xs), median_s=round(med, 2), min_s=round(min(xs), 2),
                         max_s=round(max(xs), 2), limit_s=lim, solved=all(seeds[sd]['solved'] for sd in seeds),
                         timeouts=nto, seed_wall_s={str(sd): round(w, 2) for sd, w in walls.items()},
                         seed_solved={str(sd): seeds[sd]['solved'] for sd in sorted(seeds)},
                         result=r0['result'], final_lb=r0['final_lb'], final_ub=r0['final_ub'],
                         prev_398054e_median_s=old['median_s'] if old else None, ratio_vs_398054e=ratio))

# ---------------- server tier 5 ----------------
t5 = json.load(open(a.tier5)); t5res = sorted(t5['results'], key=lambda r: (r['stem'], MODE_ORDER[r['mode']]))
t5problems = [(r['stem'], r['mode'], r['issues']) for r in t5res if not r['science_ok']]
for r in t5res:   # MaxSAT path: the final 'c d_ub: -' at a timeout means 'no upper bound', not a withdrawn bound
    r['final_lb'] = max([v for _, v in r['lb_events']], default=None)
    r['final_ub'] = min([v for _, v in r['ub_events']], default=None)


def ev_str(r):
    ev = []; last = None
    for e, v in r['lb_events']:
        if v != last: ev.append(f'{v}@{e:.0f}'); last = v
    if not r['result'] and r['final_lb'] is not None: ev.append(f'{r["final_lb"]}@{r["wall"]:.0f}')
    return ', '.join(ev)


for r in t5res:
    solved = bool(r['result'])
    srv_rows.append(dict(tier=5, case=r['stem'], mode=r['mode'], n=1, median_s=r['wall'], min_s=r['wall'], max_s=r['wall'],
                         limit_s=SRV_LIMIT[5], solved=solved, result=r['result'], final_lb=r['final_lb'], final_ub=r['final_ub'],
                         lb_events=r['lb_events'], ub_events=r['ub_events'], withdrawn=r['withdrawn'], science_ok=r['science_ok']))
    slower[r['stem']][r['mode']] = (r['wall'] if solved else None, 0 if solved else 1)
srv_method = ('tiers 0-4: runner/server_panel.py, 5 seeds (-seed=0..4; 0 = default search) per case/mode, one process per pinned physical core '
              '(taskset, cores 56-59,64-99), 4 GB cap (prlimit --as), limits tier0 600 s, tier1-3 1800 s, tier4 5000 s; the recorded time is the '
              '5-seed median (seed-median judging, PI 2026-10-14; a timed-out seed counts as the limit); tier 5: runner/server_tier5.py, 1 run per '
              'case/mode, default seed, 6 h limit, cores 0-55, run concurrently with tiers 0-4')
json.dump(dict(host=HOST_SRV, baseline_binary=BIN_DESC + ' built on yfclab2 (frozen/server-main-cbb0642/distqldpc)',
               binary_sha256=a.server_sha, collected=a.date, method=srv_method,
               previous_table='main 398054e (2026-10-14, 3-run medians), ratio_vs_398054e = median_s / its median_s', rows=srv_rows),
          open(f'{a.out}/main_server_reference.json', 'w'), indent=1)

o = []; pr = o.append
pr(f'# Recorded main baseline times on yfclab2 ({a.date})\n')
pr(f'Binary: {BIN_DESC} built on yfclab2 (frozen/server-main-cbb0642/distqldpc), sha256 `{a.server_sha}`. {srv_method}. '
   f'Column "vs 398054e" = this median / the main 398054e median (2026-10-14, 3-run medians, git history).\n')
pr('## Tiers 0-4 (5 seeds; the median is the reference)\n')
pr('| Tier | Case | Mode | Seeds | s0 | s1 | s2 | s3 | s4 | Median s | Min s | Max s | Solved | 398054e median s | vs 398054e |')
pr('|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|')
for r in srv_rows:
    if r['tier'] == 5: continue
    sw = r['seed_wall_s']; cellv = lambda k: (fmt(sw[k], 2) + ('T' if not r['seed_solved'][k] else '')) if k in sw else '-'
    pr(f'| {r["tier"]} | {r["case"]} | {r["mode"]} | {r["n"]} | {cellv("0")} | {cellv("1")} | {cellv("2")} | {cellv("3")} | {cellv("4")} | '
       f'{fmt(r["median_s"], 2)} | {fmt(r["min_s"], 2)} | {fmt(r["max_s"], 2)} | {"yes" if r["solved"] else str(5 - r["timeouts"]) + "/5"} | '
       f'{fmt(r["prev_398054e_median_s"], 2) if r["prev_398054e_median_s"] is not None else "-"} | '
       f'{fmt(r["ratio_vs_398054e"], 3) if r["ratio_vs_398054e"] is not None else "-"} |')
pr('\n"T" marks a seed that reached the limit (counted as the limit in the median).\n')
pr('## Tier 5 (6 h, 1 run per cell, default seed)\n')
pr('| Case | Mode | Wall s | Result | Final lb | Final ub | lb reached at (s) | vs 398054e (result, lb/ub, wall) |')
pr('|---|---|---:|---|---:|---:|---|---|')
t5_better = []; t5_worse = []; nsolved = 0; nsolved_old = 0
for r in t5res:
    solved = bool(r['result']); nsolved += solved
    old = old_srv.get((r['stem'], r['mode']))
    if old is None: cmp = 'new code (not in the 398054e table)'
    else:
        osolved = old['solved']; nsolved_old += osolved
        olb, oub = old['final_lb'], old['final_ub']; nlb, nub = r['final_lb'], r['final_ub']
        parts = []
        if solved and osolved: parts.append(f'solved {old["median_s"]:.0f} s -> {r["wall"]:.0f} s ({r["wall"] / old["median_s"]:.2f}x)')
        elif solved and not osolved: parts.append(f'newly solved (398054e: TIMEOUT lb {olb} ub {oub if oub is not None else "-"})'); t5_better.append(f'{r["stem"]} {r["mode"]}')
        elif not solved and osolved: parts.append(f'NOT solved (398054e solved in {old["median_s"]:.0f} s)'); t5_worse.append(f'{r["stem"]} {r["mode"]}')
        else:
            lbc = 'lb =' if nlb == olb else (f'lb {olb} -> {nlb}')
            ubc = 'ub =' if nub == oub else (f'ub {oub if oub is not None else "-"} -> {nub if nub is not None else "-"}')
            parts.append(f'TIMEOUT both; {lbc}, {ubc}')
            if (nlb or 0) < (olb or 0) or (nub is None and oub is not None) or (nub is not None and oub is not None and nub > oub): t5_worse.append(f'{r["stem"]} {r["mode"]}')
            if (nlb or 0) > (olb or 0) or (nub is not None and oub is None) or (nub is not None and oub is not None and nub < oub): t5_better.append(f'{r["stem"]} {r["mode"]}')
        cmp = '; '.join(parts)
    pr(f'| {r["stem"]} | {r["mode"]} | {r["wall"]:.0f} | {"solved" if solved else "TIMEOUT"} | {r["final_lb"] if r["final_lb"] is not None else "-"} | '
       f'{r["final_ub"] if r["final_ub"] is not None else "-"} | {ev_str(r)} | {cmp} |')
pr('')
# tier placement re-check
pr('## Tier placement re-check (rule PI 2026-10-12: slower-mode median on this server; <1 s t0, 1-10 t1, 10-100 t2, 100-2000 t3, 2000-5000 t4, else t5)\n')
cur_tier = {r['case']: r['tier'] for r in srv_rows}
pr('| Case | Current tier | Slower mode | Slower-mode median s | Rule tier | Move? |')
pr('|---|---:|---|---:|---:|---|')
moves = []
for s in sorted(cur_tier, key=lambda s: (cur_tier[s], s)):
    mm = slower[s]
    if len(mm) < 2: continue
    unsolved = [m for m, (v, nto) in mm.items() if v is None or (cur_tier[s] <= 4 and nto >= 3)]
    if unsolved:
        sm, sv, rt = unsolved[0], None, 5
    else:
        sm = max(mm, key=lambda m: mm[m][0]); sv = mm[sm][0]; rt = tier_rule(sv)
    mv = '' if rt == cur_tier[s] else f'tier{cur_tier[s]} -> tier{rt}'
    if mv: moves.append(f'{s} ({mv}, {sm} {"unsolved" if sv is None else "%.0f s" % sv})')
    pr(f'| {s} | {cur_tier[s]} | {sm} | {"%.2f" % sv if sv is not None else "unsolved"} | {rt} | {mv or "no"} |')
pr('')
pr('Codes that the rule would move (listed only, not moved): ' + ('; '.join(moves) if moves else 'none') + '. '
   'Tier 5 rows use a single default-seed run (not a 5-seed median); for tier 0-4 cells with timed-out seeds the median counts the limit.\n')
pr('Notes:')
gm = ' '.join(f'tier{t} {m} {g(srv_ratio[(t, m)]):.3f}' for t in range(5) for m in ('no-card', 'card-mto') if srv_ratio[(t, m)])
pr(f'- Replaces the main 398054e table (2026-10-14) after GH-130 (PR #131, `-frontier=auto` default) was merged; old table is in git history. The 398054e table used 3-run medians; this one uses 5-seed medians, so small ratios also carry the seed spread.')
pr(f'- vs main 398054e, geomean of per-cell median ratios (tiers 0-4): {gm}.')
fast = [r for r in srv_rows if 1 <= r['tier'] <= 4 and r['ratio_vs_398054e'] is not None and r['ratio_vs_398054e'] < 0.9]
slow = [r for r in srv_rows if 1 <= r['tier'] <= 4 and r['ratio_vs_398054e'] is not None and r['ratio_vs_398054e'] > 1.1]
pr('- `-frontier=auto` turns frontier branching on for every BB/GB/LP half and off for every TN half of tiers 1-5, so TN cells run the 398054e search unchanged (GH-130 S1 identity check): their ratios here are seed spread (5-seed median vs 3 default-seed runs) plus host load, not a solver change. Tier 0 cells are all < 1 s and their ratios (0.35-0.78) are dominated by the host load of the two batches.')
pr('- Tier 1-4 cells faster than 0.90x: ' + (', '.join(f'{r["case"]} {r["mode"]} {r["ratio_vs_398054e"]:.2f}' for r in fast) or 'none')
   + '. Cells slower than 1.10x: ' + (', '.join(f'{r["case"]} {r["mode"]} {r["ratio_vs_398054e"]:.2f}' for r in slow) or 'none') + '.')
to = [r for r in srv_rows if r['tier'] <= 4 and r['timeouts']]
pr('- Tier 0-4 seeds that reached the limit: ' + (', '.join(f'{r["case"]} {r["mode"]} {r["timeouts"]}/5 (seeds {", ".join(k for k, v in r["seed_solved"].items() if not v)})' for r in to) or 'none') + '.')
pr(f'- Tier 5: {nsolved} of {len(t5res)} cells solved within 6 h (398054e: {nsolved_old} of {len([r for r in t5res if (r["stem"], r["mode"]) in old_srv])} comparable cells). '
   f'Cells better than 398054e (newly solved or tighter bound): {", ".join(t5_better) or "none"}. Worse: {", ".join(t5_worse) or "none"}.')
new5 = [r for r in t5res if (r['stem'], r['mode']) not in old_srv]
pr('- New tier5 codes (PR #132, Cain et al. via C. Crocker\'s Zenodo distances): ' + '; '.join(
    f'{r["stem"]} {r["mode"]}: {"solved d=%d at %.0f s" % (r["result"][1], r["result"][0]) if r["result"] else "TIMEOUT lb %s ub %s" % (r["final_lb"], r["final_ub"] if r["final_ub"] is not None else "-")}' for r in new5) + '.')
pr('- The lb sequence 3/5/9/17 comes from the doubling phase of the interleaved bound search (caps 2,4,8,16,32): lb 17 means no logical of weight <= 16 exists and the solver is searching for any logical of weight <= 32.')
pr(f'- Correctness: panel {len(panel)} runs ({len(perr)} runner errors), every answer equals the stem distance and no bound crosses it' +
   ('' if not sproblems else f' EXCEPT: {sproblems}') + f'; tier 5 {len(t5res)} runs, bounds consistent with the stems' + ('' if not t5problems else f' EXCEPT: {t5problems}') + '.')
open(f'{a.out}/SERVER.md', 'w').write('\n'.join(o) + '\n')
print('SERVER panel cells', len([r for r in srv_rows if r['tier'] <= 4]), 'runs', len(panel), 'errors', len(perr), 'problems', sproblems)
print('SERVER geomeans:', gm)
print('TIER5', len(t5res), 'cells, solved', nsolved, 'problems', t5problems, 'better', t5_better, 'worse', t5_worse)
print('MOVES', moves)
