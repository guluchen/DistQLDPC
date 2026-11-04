#!/usr/bin/env python3
"""Build optimization/baselines/SERVER.md and main_server_reference.json for main 02879a93 (re-tier 2026-11-04)
from the raw panel records.  usage: make_baseline.py RESULTS.jsonl[,MORE.jsonl] placement.json witness_check.jsonl OLD_REF.json OUTDIR
Statistics: MaxSAT cells (both cardinality modes) = median over seeds 0-4 with a timed-out seed counted as 5000 s; seed 0
ran with the 6 h limit (the MaxSAT child ignores -cpu-lim, only the parent's deadline differs) and counts as timed out
in the 5000 s panel when it took longer; tier 5 = the 6 h seed-0 run.  CC rows are information only."""
import json, statistics, sys
from collections import defaultdict

res_files, place_f, wit_f, old_f, out = sys.argv[1:6]
R = [json.loads(l) for f in res_files.split(',') for l in open(f)]
P = json.load(open(place_f))
W = [json.loads(l) for l in open(wit_f)]
OLD = {(r['case'], r['mode']): r for r in json.load(open(old_f))['rows']}
PANEL, LONG = 5000, 21600
SHA = 'f451e14a16393126ab6ddec2bede969fbc5d7b89dfb869eb53c71daafc81e54b'
by = defaultdict(list)
for r in R: by[(r['stem'], r['cfg'])].append(r)
newname = {p['old_stem']: p for p in P}
witbest = defaultdict(lambda: None)
for w in W:
    st = w['log'].split('.')[0]
    if w['lightest_ok']:
        v = min(w['lightest_ok'].values())
        witbest[st] = v if witbest[st] is None else min(witbest[st], v)


def fmt(x):
    if x is None: return '-'
    return f'{x:.2f}' if x < 100 else f'{x:.0f}'


def ptime(r):
    return r['wall'] if r['result'] is not None and r['wall'] <= PANEL else None


rows, t5rows, ccrows, place = [], [], [], []
for p in sorted(P, key=lambda p: (p['tier'], int(p['stem'].split('_')[1]), p['stem'])):
    s, new, t = p['old_stem'], p['stem'], p['tier']
    for mode in ('card-mto', 'no-card'):
        rs = {r['seed']: r for r in by[(s, 'maxsat-' + mode)] if r['limit'] == PANEL or r['seed'] == 0}
        old = OLD.get((s, mode))
        if t <= 4:
            seeds = {sd: ptime(r) for sd, r in sorted(rs.items())}
            vals = [PANEL if v is None else v for v in seeds.values()]
            med = statistics.median(vals)
            row = dict(tier=t, case=new, mode=mode, n=len(vals), median_s=round(med, 2), min_s=round(min(vals), 2),
                       max_s=round(max(vals), 2), limit_s=PANEL, solved=sum(v is not None for v in seeds.values()) > len(vals) / 2,
                       timeouts=sum(v is None for v in seeds.values()),
                       seed_wall_s={str(k): round(r['wall'], 2) for k, r in rs.items()},
                       seed_solved={str(k): v is not None for k, v in seeds.items()},
                       result=sorted({r['result'] for r in rs.values() if r['result'] is not None}),
                       final_lb=max(r['final_lb'] or 0 for r in rs.values()),
                       final_ub=min(r['final_ub'] or 10**9 for r in rs.values()))
            if old:
                row['prev_c914ef5_median_s'] = old['median_s']; row['ratio_vs_c914ef5'] = round(med / old['median_s'], 3)
            rows.append(row)
        else:
            r = rs[0]
            row = dict(tier=5, case=new, mode=mode, n=1, median_s=round(r['wall'], 1), limit_s=LONG,
                       solved=r['result'] is not None, result=None if r['result'] is None else [round(r['wall'], 1), r['result']],
                       final_lb=r['final_lb'], final_ub=r['final_ub'], lb_events=r['lb_events'], ub_events=r['ub_events'],
                       withdrawn=r['withdrawn'], panel_seeds_5000s={str(k): (None if ptime(x) is None else round(ptime(x), 1))
                                                                    for k, x in sorted(rs.items()) if k > 0})
            if old: row['prev_c914ef5'] = dict(wall_s=old['median_s'], solved=old['solved'], final_lb=old.get('final_lb'), final_ub=old.get('final_ub'))
            t5rows.append(row)
    cc = {r['seed']: r for r in by[(s, 'cc')] if r['limit'] == PANEL}
    cl = [r for r in by[(s, 'cc')] if r['limit'] == LONG]
    co = {r['seed']: r for r in by[(s, 'ccopt')]}
    crow = dict(tier=t, case=new)
    if cc:
        v = [PANEL if ptime(r) is None else ptime(r) for r in cc.values()]
        crow['cc_default'] = dict(seeds={str(k): (None if ptime(r) is None else round(r['wall'], 2)) for k, r in sorted(cc.items())},
                                  median_s=round(statistics.median(v), 2), lb=max(r['final_lb'] or 0 for r in cc.values()),
                                  ub=min(r['final_ub'] or 10**9 for r in cc.values()))
    for i, l in enumerate(sorted(cl, key=lambda r: r['seed'])):
        crow['cc_default_6h' + ('' if l['seed'] == 0 else f'_seed{l["seed"]}')] = dict(
            wall_s=round(l['wall'], 1), result=l['result'], lb=l['final_lb'], ub=l['final_ub'], seed=l['seed'])
    if co:
        v = [PANEL if ptime(r) is None else ptime(r) for r in co.values()]
        crow['cc_optin_full'] = dict(seeds={str(k): (None if ptime(r) is None else round(r['wall'], 2)) for k, r in sorted(co.items())},
                                     median_s=round(statistics.median(v), 2), lb=max(r['final_lb'] or 0 for r in co.values()),
                                     ub=min(r['final_ub'] or 10**9 for r in co.values()))
    crow['lightest_verified_witness'] = witbest[s]
    ccrows.append(crow)
    place.append(dict(case=new, old_stem=s, old_dir=p['old_dir'], new_tier=t, slower_mode=p.get('slower_mode'),
                      slower_median_s=p.get('slower_median'), note=p.get('note', '')))

json.dump(dict(host='yfclab2 (2x AMD EPYC 7742, 256 logical CPUs, Ubuntu 24.04, GCC 13.3)',
               baseline_binary='main 02879a93 (PR #203 merge; -ub-isd=stern, -stab-overlap=auto, -cc-aut=on, CC charge default) built on yfclab2 (frozen/server-main-02879a93/distqldpc)',
               binary_sha256=SHA, collected='2026-11-04',
               method='runner/server_retier_20261104.py: one queue over all 75 bundled codes; MaxSAT -no-card / -card-mto x seeds 0-4 (seed 0 run with the 6 h limit; > 5000 s counts as a timeout in the 5000 s panel; seeds 3-4 skipped when seeds 0-2 all timed out), limit 5000 s for every code (tiers 0-4 alike); tier 5 = the 6 h seed-0 run; CC default -engine=cc -v seeds 0-2 (5000 s; 6 h seed 0 for tier 5 and for library codes whose seed 0 timed out), library codes also CC opt-in full; one process per pinned logical CPU in 0-71 (no SMT siblings used), 4 GB cap (prlimit --as)',
               previous_table='main c914ef5 (2026-10-21, 5-seed medians with per-tier limits; tier 5 one 6 h run), ratio_vs_c914ef5 = median_s / its median_s',
               rows=rows + t5rows, cc_rows=ccrows, placement=place),
          open(f'{out}/main_server_reference.json', 'w'), indent=1)

# ---------------- SERVER.md ----------------
L = []
A = L.append
A('# Recorded main baseline times on yfclab2 (2026-11-04)\n')
A(f'Binary: main 02879a93 (PR #203 merge) built on yfclab2 (frozen/server-main-02879a93/distqldpc), sha256 `{SHA}`. '
  'Runner: runner/server_retier_20261104.py (one dynamic queue over all 75 bundled codes; the former untiered library codes were measured in the same panel), '
  'one process per pinned logical CPU in 0-71 (their SMT siblings 128-199 left idle), 4 GB cap (prlimit --as). '
  'MaxSAT (the default engine) in both cardinality modes of the tier rule, `-no-card` and `-card-mto`, seeds 0-4 (`-seed=0` = default search), '
  '**limit 5000 s for every code** (the c914ef5 table used 600/1800/5000 s by tier; the uniform limit lets every code be placed by the rule); '
  'seed 0 ran with the 6 h limit (the MaxSAT child ignores -cpu-lim, so its first 5000 s are the 5000 s run) and counts as timed out in the panel when it took longer; '
  'seeds 3-4 were skipped when seeds 0-2 all timed out (the median is then the limit). The recorded time is the 5-seed median (a timed-out seed counts as 5000 s). '
  'Tier 5: the 6 h seed-0 run per mode. CC rows are for information (default `-engine=cc -v`, seeds 0-2, 5000 s; 6 h seed 0 on tier 5). '
  'Column "vs c914ef5" = this median / the main c914ef5 median (2026-10-21 table, git history), for codes that had a c914ef5 row.\n')
A('## Tiers 0-4 (5 seeds; the median is the reference)\n')
A('| Tier | Case | Mode | Seeds | s0 | s1 | s2 | s3 | s4 | Median s | Min s | Max s | Solved | c914ef5 median s | vs c914ef5 |')
A('|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|---:|')
for r in rows:
    sv = []
    for k in '01234':
        if k not in r['seed_wall_s']: sv.append('-'); continue
        sv.append(fmt(r['seed_wall_s'][k]) if r['seed_solved'][k] else '5000T')
    solved = 'yes' if not r['timeouts'] else f"{r['n'] - r['timeouts']}/{r['n']}"
    A(f"| {r['tier']} | {r['case']} | {r['mode']} | {r['n']} | " + ' | '.join(sv) +
      f" | {fmt(r['median_s'])} | {fmt(r['min_s'])} | {fmt(r['max_s'])} | {solved} | "
      f"{fmt(r.get('prev_c914ef5_median_s'))} | {r.get('ratio_vs_c914ef5', '-')} |")
A('\n"T" marks a seed that reached 5000 s (counted as 5000 s in the median); for seed 0 this includes runs that finished later inside its 6 h limit.\n')
A('## Tier 5 (6 h, 1 run per cell, default seed)\n')
A('| Case | Mode | Wall s | Result | Final lb | Final ub | lb reached at (s) | c914ef5 (wall s, lb, ub) |')
A('|---|---|---:|---|---:|---:|---|---|')
for r in t5rows:
    ev = ', '.join(f'{x}@{t:.0f}' for t, x in r['lb_events'])
    o = r.get('prev_c914ef5')
    os_ = '-' if not o else f"{fmt(o['wall_s'])}, {o['final_lb']}, {o['final_ub'] if o['final_ub'] is not None else '-'}"
    A(f"| {r['case']} | {r['mode']} | {fmt(r['median_s'])} | {'solved' if r['solved'] else 'TIMEOUT'} | {r['final_lb'] if r['final_lb'] is not None else '-'} | "
      f"{r['final_ub'] if r['final_ub'] is not None else '-'} | {ev} | {os_} |")
A('\n## CC engine (information only; not used for tier placement)\n')
A('| Tier | Case | CC default s0 / s1 / s2 (s) | CC median s | CC 6 h (seed 0) | CC opt-in full median s | Lightest GF(2)-verified word |')
A('|---:|---|---|---:|---|---:|---:|')
for c in ccrows:
    d = c.get('cc_default'); l = c.get('cc_default_6h'); o = c.get('cc_optin_full')
    ds = '-' if not d else ' / '.join('T' if v is None else fmt(v) for v in d['seeds'].values())
    ls = '-' if not l else (f"solved {l['result']} in {fmt(l['wall_s'])} s" if l['result'] is not None else f"TIMEOUT lb {l['lb']} ub {l['ub']}")
    A(f"| {c['tier']} | {c['case']} | {ds} | {fmt(d['median_s']) if d else '-'} | {ls} | {fmt(o['median_s']) if o else '-'} | {c['lightest_verified_witness'] or '-'} |")
A('\n## Tier placement (rule PI 2026-10-12: slower-mode MaxSAT median on this server; <1 s t0, 1-10 t1, 10-100 t2, 100-2000 t3, 2000-5000 t4, else t5)\n')
A('| Case | Was | Slower mode | Slower-mode median s | Rule tier | Move |')
A('|---|---|---|---:|---:|---|')
for p in place:
    was = p['old_dir'] + ('/' + p['old_stem'] if p['old_stem'] != p['case'] else '')
    mv = 'no' if p['old_dir'] == f"tier{p['new_tier']}" and p['old_stem'] == p['case'] else f"{p['old_dir']} -> tier{p['new_tier']}"
    A(f"| {p['case']} | {was} | {(p['slower_mode'] or '-').replace('maxsat-', '')} | {fmt(p['slower_median_s']) if p['slower_median_s'] else 'unsolved / > 5000'} | {p['new_tier']} | {mv} |")
open(f'{out}/SERVER.md', 'w').write('\n'.join(L) + '\n')
print(len(rows), len(t5rows), len(ccrows))
