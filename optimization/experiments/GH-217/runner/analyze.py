#!/usr/bin/env python3
"""GH-217 judgement. Codes are identified by the content of their Hx/Hz files (renames do not matter) and grouped by the
tier directory they have in NEWROOT (a checkout of main at judging time). Panel cells (ids cc.STEM.ARM.sSEED): ratio =
median wall(arm) / median wall(main) over the seeds both have; per tier geomean, max cell, cells > 1.25. Tier 5 cells
(ids t5.STEM.ARM): for every code main solved, time ratio arm / main (rule: <= 1.2); otherwise final lbs and the time each
arm reached main's final lb. usage: analyze.py RUNROOT NEWROOT ARMS results.jsonl...   (RUNROOT: worktree the jobs used)"""
import collections, glob, hashlib, json, math, os, statistics as st, sys
RUNROOT, NEWROOT, ARMS = sys.argv[1], sys.argv[2], sys.argv[3].split(',')
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
g = lambda v: math.exp(sum(map(math.log, v)) / len(v)) if v else float('nan')
bad = [r['id'] for r in R if not r.get('science_ok')]
P = collections.defaultdict(lambda: collections.defaultdict(dict))
T5 = collections.defaultdict(dict)
for r in R:
    tier, stem = where(r)
    if r['id'].startswith('cc.'): P[(tier, stem)][r['seed']][r['arm']] = r
    elif r['id'].startswith('t5.'): T5[(tier, stem)][r['arm']] = r
print('## Panel (5-seed medians; wall s, ratio vs main)\n')
print('| Tier | Code | main | ' + ' | '.join(f'{a} | {a}/main' for a in ARMS) + ' | answers |')
print('|---|---|---:|' + '---:|---:|' * len(ARMS) + '---|')
per = collections.defaultdict(lambda: collections.defaultdict(list))
for (tier, stem), d in sorted(P.items()):
    seeds = [s for s in d if 'main' in d[s]]
    mm = st.median([d[s]['main']['wall'] for s in seeds])
    cols = []
    for a in ARMS:
        ss = [s for s in seeds if a in d[s]]
        if not ss: cols += ['-', '-']; continue
        m = st.median([d[s][a]['wall'] for s in ss]); mref = st.median([d[s]['main']['wall'] for s in ss])
        per[tier][a].append((m / mref, stem)); cols += [f'{m:.3f}', f'{m / mref:.3f}']
    ans = sorted(set((d[s][a]['result'] or [0, None])[1] for s in d for a in d[s]), key=str)
    print(f'| {tier} | {stem} | {mm:.3f} | ' + ' | '.join(cols) + f' | {ans} |')
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
print('| Tier | Code | main | ' + ' | '.join(ARMS) + ' | rule |')
print('|---|---|---|' + '---|' * len(ARMS) + '---|')
for (tier, stem), d in sorted(T5.items()):
    if 'main' not in d: continue
    m = d['main']; cols = []; verdict = ''
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
        verdict = 'main unsolved (info)'
    print(f'| {tier} | {stem} | {ms} | ' + ' | '.join(cols) + f' | {verdict} |')
print(f'\n{len(R)} runs, science problems: {bad}')
