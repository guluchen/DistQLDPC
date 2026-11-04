#!/usr/bin/env python3
"""GH-225 judgement (GH-217 analyze.py with the baseline arm A instead of main; also prints per-cell seed ranges, the
erasure prune counts of E and flags cells whose A median is below 50 ms (10 ms child-polling floor, #224)). Codes are identified by the content of their Hx/Hz files (renames do not matter) and grouped by the
tier directory they have in NEWROOT (a checkout of main at judging time). Panel cells (ids cc.STEM.ARM.sSEED): ratio =
median wall(arm) / median wall(main) over the seeds both have; per tier geomean, max cell, cells > 1.25. Tier 5 cells
(ids t5.STEM.ARM): for every code main solved, time ratio arm / main (rule: <= 1.2); otherwise final lbs and the time each
arm reached main's final lb. usage: analyze.py RUNROOT NEWROOT ARMS results.jsonl...   (RUNROOT: worktree the jobs used)"""
import collections, glob, hashlib, json, math, os, statistics as st, sys
RUNROOT, NEWROOT, ARMS = sys.argv[1], sys.argv[2], sys.argv[3].split(',')
BASE = 'A'
def key(base): return hashlib.sha1(open(base + '_Hx.txt', 'rb').read() + b'|' + open(base + '_Hz.txt', 'rb').read()).hexdigest()
new = {}
for f in glob.glob(f'{NEWROOT}/data/matrices/*/*_Hx.txt'):
    new[key(f[:-7])] = (os.path.basename(os.path.dirname(f)), os.path.basename(f)[:-7])
R = []
for p in sys.argv[4:]:
    for l in open(p):
        r = json.loads(l)
        if 'wall' in r: R.append(r)
cache = {}
def where(r):
    c = glob.glob(f"{RUNROOT}/data/matrices/*/{r['stem']}_Hx.txt")[0][:-7]
    if c not in cache: cache[c] = new.get(key(c), ('missing', r['stem']))
    return cache[c]
import re
def nodes(r): return sum(int(m.group(1)) for lv in r['levels'] for m in [re.search(r'(?:EMPTY|FOUND|SKIP|ABORT)\S* nodes (\d+)', lv)] if m)
def eprunes(r): return sum(int(m.group(1)) for lv in r['levels'] for m in [re.search(r'erasure calls \d+ prune (\d+)', lv)] if m)
g = lambda v: math.exp(sum(map(math.log, v)) / len(v)) if v else float('nan')
bad = [r['id'] for r in R if not r.get('science_ok')]
P = collections.defaultdict(lambda: collections.defaultdict(dict))
T5 = collections.defaultdict(dict)
for r in R:
    tier, stem = where(r)
    if r['id'].startswith('cc.'): P[(tier, stem)][r['seed']][r['arm']] = r
    elif r['id'].startswith('t5.'): T5[(tier, stem)][r['arm']] = r
print('## Panel (5-seed medians; wall s, ratio vs A)\n')
print('| Tier | Code | A (range) | ' + ' | '.join(f'{a} (range) | {a}/A | {a} nodes/A | {a} erasure prunes' for a in ARMS) + ' | answers | note |')
print('|---|---|---:|' + '---:|---:|---:|---:|' * len(ARMS) + '---|---|')
per = collections.defaultdict(lambda: collections.defaultdict(list))
for (tier, stem), d in sorted(P.items()):
    seeds = [s for s in d if BASE in d[s]]
    mm = st.median([d[s][BASE]['wall'] for s in seeds])
    rng = lambda v: f'{st.median(v):.3f} ({min(v):.3f}-{max(v):.3f})'
    cols = []
    for a in ARMS:
        ss = [s for s in seeds if a in d[s]]
        if not ss: cols += ['-', '-']; continue
        m = st.median([d[s][a]['wall'] for s in ss]); mref = st.median([d[s][BASE]['wall'] for s in ss])
        per[tier][a].append((m / mref, stem))
        na = st.median([nodes(d[s][a]) for s in ss]); nb = st.median([nodes(d[s][BASE]) for s in ss])
        ep = st.median([eprunes(d[s][a]) for s in ss])
        cols += [rng([d[s][a]['wall'] for s in ss]), f'{m / mref:.3f}', f'{na / nb:.3f}' if nb else '-', f'{ep:.0f}']
    ans = sorted(set((d[s][a]['result'] or [0, None])[1] for s in d for a in d[s]), key=str)
    note = 'sub-50 ms (polling floor)' if mm < 0.05 else ''
    print(f'| {tier} | {stem} | {rng([d[s][BASE]["wall"] for s in seeds])} | ' + ' | '.join(cols) + f' | {ans} | {note} |')
print('\n| Tier | arm | cells | geomean | max cell | cells > 1.25 | verdict |')
print('|---|---|---:|---:|---:|---:|---|')
for tier in sorted(per):
    for a in ARMS:
        v = per[tier][a]
        if not v: continue
        rs = [x for x, _ in v]; mx = max(v)
        ok = g(rs) < 1 and mx[0] <= 1.25
        print(f'| {tier} | {a} | {len(v)} | {g(rs):.3f} | {mx[0]:.3f} ({mx[1]}) | {sum(x > 1.25 for x in rs)} | {"PASS" if ok else "FAIL"} |')
def lbt(r, v):
    if r['result'] and r['result'][1] <= v: return r['result'][0]
    for t, x in r['lb_events']:
        if x >= v: return t
    return None
print('\n## Tier-5-style runs (default seed, 6 h)\n')
print('| Tier | Code | A | ' + ' | '.join(ARMS) + ' | rule |')
print('|---|---|---|' + '---|' * len(ARMS) + '---|')
for (tier, stem), d in sorted(T5.items()):
    if BASE not in d: continue
    m = d[BASE]; cols = []; verdict = ''
    if m['result']:
        tm = m['result'][0]
        for a in ARMS:
            if a not in d: cols.append('-'); continue
            x = d[a]
            if x['result']:
                q = x['result'][0] / tm if tm > 0 else float('nan')
                cols.append(f"d={x['result'][1]} {x['result'][0]:.1f} s ({q:.2f}x)")
                if q > 1.2: verdict += f' {a} >1.2x'
            else:
                cols.append(f"UNSOLVED lb {x['final_lb']}"); verdict += f' {a} unsolved'
        ms = f"d={m['result'][1]} {tm:.1f} s"; verdict = verdict.strip() or 'ok'
    else:
        target = m['final_lb']; tm = lbt(m, target) if target else None
        for a in ARMS:
            if a not in d: cols.append('-'); continue
            x = d[a]; t = lbt(x, target) if target else None
            s = f"d={x['result'][1]} {x['result'][0]:.0f} s" if x['result'] else f"lb {x['final_lb']}"
            cols.append(s + (f'; lb {target} @ {t:.0f} s' if t is not None else f'; lb {target} not reached'))
        ms = f"lb {target} @ {tm:.0f} s" if tm is not None else f'lb {target}'
        verdict = 'A unsolved (info)'
    print(f'| {tier} | {stem} | {ms} | ' + ' | '.join(cols) + f' | {verdict} |')
print(f'\n{len(R)} runs, science problems: {bad}')
