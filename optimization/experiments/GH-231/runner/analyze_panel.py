#!/usr/bin/env python3
"""GH-231 panel analysis: per (stem, mode) the median wall time of each arm over its seeds, ratio arm/base, per-tier
geomeans (per mode and pooled), the max cell and the cells > 1.25. A run that did not answer counts as its limit.
usage: analyze_panel.py RESULTS.jsonl BASE_ARM ARM [ARM...]   (markdown on stdout)"""
import json, math, statistics, sys, collections
res, base, arms = sys.argv[1], sys.argv[2], sys.argv[3:]
rs = [json.loads(l) for l in open(res) if l.strip()]
rs = [r for r in rs if 'wall' in r]
bad = [(r['id'], r['issues']) for r in rs if not r.get('science_ok')]
t = collections.defaultdict(list); tier = {}; ans = collections.defaultdict(set)
for r in rs:
    t[(r['stem'], r['mode'], r['arm'])].append((r['seed'], r['wall'] if r['solved'] else float(r['limit'])))
    tier[r['stem']] = int(str(r['tier']).replace('tier', ''))
    if r['result']: ans[(r['stem'], r['mode'], r['arm'])].add(r['result'][1])
def med(k): return statistics.median([w for _, w in sorted(t[k])]) if t.get(k) else None
print(f'runs {len(rs)}; science problems {len(bad)} {bad[:5]}\n')
for a in arms:
    print(f'### arm {a} vs {base}\n')
    print('| Tier | Code | Mode | base median s (seeds) | arm median s (seeds) | ratio | answers |')
    print('|---:|---|---|---|---|---:|---|')
    cells = collections.defaultdict(list)
    for stem in sorted(tier, key=lambda s: (tier[s], s)):
        for mode in ('no-card', 'card-mto'):
            kb, ka = (stem, mode, base), (stem, mode, a)
            if kb not in t or ka not in t: continue
            mb, ma = med(kb), med(ka); r = ma / mb
            cells[(tier[stem], mode)].append((r, stem))
            sb = ' '.join('%.2f' % w for _, w in sorted(t[kb])); sa = ' '.join('%.2f' % w for _, w in sorted(t[ka]))
            print(f'| {tier[stem]} | {stem} | {mode} | {mb:.2f} ({sb}) | {ma:.2f} ({sa}) | {r:.3f} | {sorted(ans[kb] | ans[ka])} |')
    print('\n| Tier | Mode | cells | geomean | max cell | cells > 1.25 |\n|---:|---|---:|---:|---:|---|')
    for tr in sorted(set(k[0] for k in cells)):
        for mode in ('no-card', 'card-mto', 'pooled'):
            v = cells[(tr, mode)] if mode != 'pooled' else cells[(tr, 'no-card')] + cells[(tr, 'card-mto')]
            if not v: continue
            g = math.exp(sum(math.log(r) for r, _ in v) / len(v)); mx = max(v)
            print(f'| {tr} | {mode} | {len(v)} | {g:.3f} | {mx[0]:.3f} ({mx[1]}) | {[s for r, s in v if r > 1.25]} |')
    print()
