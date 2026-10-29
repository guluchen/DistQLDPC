#!/usr/bin/env python3
"""GH-195 panel (template GH-162 analyze_panel.py). Arms: main (main 6083e66 CC default), er (+erasure), tb (+tiebreak,
= PR #180), tber (+tiebreak,erasure). Two comparisons, each per cell (tier, code) over seeds 0-4: (a) er / main, (b) tber / tb:
wall median ratio, total CC nodes (sum over levels, deterministic per seed) median ratio, search time median ratio, and the
erasure calls/prunes of the new arm. Verdict per tier: geomean of the wall ratios < 1 and no cell > 1.25.
usage: analyze_panel.py results.jsonl"""
import json, re, sys, math, statistics as st, collections
R = [json.loads(l) for l in open(sys.argv[1])]
P = [r for r in R if r.get('id', '').startswith('cc.')]
cell = collections.defaultdict(lambda: collections.defaultdict(dict))
for r in P:
    n = t = ec = ep = 0
    for L in r['levels']:
        m = re.search(r' nodes (\d+) .* time ([\d.]+)s', L)
        if m and 'nodes-by-budget' not in L: n += int(m.group(1)); t += float(m.group(2))
        m = re.search(r'erasure calls (\d+) prune (\d+)', L)
        if m: ec += int(m.group(1)); ep += int(m.group(2))
    cell[(r['tier'], r['stem'])][r['seed']][r['arm']] = dict(wall=r['wall'], nodes=n, search=t, ans=r['result'][1] if r['result'] else None,
                                                           ec=ec, ep=ep)
gm = lambda v: math.exp(sum(map(math.log, v)) / len(v))
verdict = {}
for old, new, title in (('main', 'er', '(a) main default -> +erasure'), ('tb', 'tber', '(b) main default + tiebreak -> + tiebreak + erasure')):
    print(f'### {title}\n')
    print(f'| Tier | Code | {old} wall median (range) s | {new} wall median (range) s | wall ratio | nodes ratio (median) | search-time ratio (median) | {new} erasure calls / prunes (median) | answers |')
    print('|---:|---|---|---|---:|---:|---:|---|---|')
    per = collections.defaultdict(list)
    for (tier, stem), d in sorted(cell.items()):
        S = [s for s in d if old in d[s] and new in d[s]]
        wo = [d[s][old]['wall'] for s in S]; wn = [d[s][new]['wall'] for s in S]
        nr = [d[s][new]['nodes'] / d[s][old]['nodes'] for s in S if d[s][old]['nodes'] > 0]
        tr = [d[s][new]['search'] / d[s][old]['search'] for s in S if d[s][old]['search'] > 0]
        ec = st.median([d[s][new]['ec'] for s in S]); ep = st.median([d[s][new]['ep'] for s in S])
        ans = sorted(set(str(d[s][a]['ans']) for s in S for a in (old, new)))
        ratio = st.median(wn) / st.median(wo); per[tier].append(ratio)
        print(f'| {tier} | {stem} | {st.median(wo):.3f} ({min(wo):.3f}-{max(wo):.3f}) | {st.median(wn):.3f} ({min(wn):.3f}-{max(wn):.3f}) | {ratio:.3f} | '
              f'{st.median(nr) if nr else float("nan"):.3f} | {st.median(tr) if tr else float("nan"):.3f} | {ec:.0f} / {ep:.0f} | {",".join(ans)} |')
    print()
    print('| Tier | cells | geomean wall ratio | max cell | cells > 1.25 | verdict |')
    print('|---:|---:|---:|---:|---:|---|')
    for t, v in sorted(per.items()):
        ok = gm(v) < 1 and max(v) <= 1.25
        verdict[(title, t)] = ok
        print(f'| {t} | {len(v)} | {gm(v):.3f} | {max(v):.3f} | {sum(x > 1.25 for x in v)} | {"PASS" if ok else "FAIL"} |')
    print()
bad = [r['id'] for r in P if not r.get('science_ok')]
print(f'{len(P)} runs, science problems: {bad}')
print('OVERALL', 'PASS' if all(verdict.values()) else 'FAIL')
