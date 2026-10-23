#!/usr/bin/env python3
"""GH-148 S1 panel summary (GH-144 analyzer; GH-148 adds the identity rule): median over seeds of wall seconds per (code, mode, arm) (a run without an answer counts as
its limit), ratio = median(cand) / median(main), geomean per (tier, mode) and pooled per tier, max cell, cells > 1.25;
answers vs stem; first c d_ub time of the pre arm (pre-pass + start-up). Identity rule (preregistered in #148, GH-130 precedent): a cell whose candidate runs have, for every seed, exactly
main's per-probe sequence (half, cap, kind, conflicts) from -frontier-stats searched identically; its gate ratio is
1.000 (the measured ratio is still printed). usage: analyze_panel.py RESULTS.jsonl [...] > table.md"""
import json, math, statistics, sys, collections
rs = []
for fn in sys.argv[1:]:
    rs += [json.loads(l) for l in open(fn) if l.strip()]
rs = [r for r in rs if 'error' not in r]
cell = collections.defaultdict(list)
for r in rs:
    t = r['wall'] if r['solved'] else float(r['limit'])
    cell[(r['tier'], r['stem'], r['mode'], r['arm'])].append((r['seed'], t, r))
def gm(xs): return math.exp(sum(math.log(x) for x in xs) / len(xs)) if xs else float('nan')
print('| Tier | Code | Mode | main median s (seeds) | cand median s (seeds) | ratio cand/main | identical search | first d_ub s (median) | answers |')
print('|---:|---|---|---|---|---:|---|---:|---|')
ratios = collections.defaultdict(list); measured = collections.defaultdict(list); bad = []
keys = sorted({(t, s, m) for (t, s, m, a) in cell}, key=lambda k: (k[0], int(k[1].split('_')[1]), k[1], k[2]))
for (t, s, m) in keys:
    A = sorted(cell.get((t, s, m, 'main'), [])); B = sorted(cell.get((t, s, m, 'cand'), []))
    if len(A) < 5 or len(B) < 5: print(f'| {t} | {s} | {m} | incomplete ({len(A)}/{len(B)}) | | | | |'); continue
    ma = statistics.median(x[1] for x in A); mb = statistics.median(x[1] for x in B)
    ratio = mb / ma
    pa = {x[0]: [tuple(p[1:]) for p in x[2].get('probes', [])] for x in A}
    pb = {x[0]: [tuple(p[1:]) for p in x[2].get('probes', [])] for x in B}
    ident = all(pa.get(sd) and pa.get(sd) == pb.get(sd) for sd in pa) and set(pa) == set(pb)
    ratios[(t, m)].append(1.0 if ident else ratio); measured[(t, m)].append(ratio)
    fu = [x[2]['ub_events'][0][0] for x in B if x[2]['ub_events']]
    ans = sorted({x[2]['result'][1] for x in A + B if x[2]['result']})
    unsolved = sum(not x[2]['solved'] for x in A), sum(not x[2]['solved'] for x in B)
    for x in A + B:
        if not x[2]['science_ok']: bad.append((x[2]['id'], x[2]['issues']))
    fmt = lambda L: ' '.join(('%.2f' % x[1]) + ('T' if not x[2]['solved'] else '') for x in L)
    print(f'| {t} | {s} | {m} | {ma:.2f} ({fmt(A)}) | {mb:.2f} ({fmt(B)}) | {ratio:.3f} | {"yes (gate 1.000)" if ident else "no"} | {statistics.median(fu) if fu else float("nan"):.3f} | {ans}{" unsolved %d/%d" % unsolved if any(unsolved) else ""} |')
print()
print('| Tier | Mode | cells | geomean cand/main (gate, identity = 1) | geomean measured | max cell (gate) | cells > 1.25 |')
print('|---:|---|---:|---:|---:|---:|---:|')
for t in sorted({k[0] for k in ratios}):
    for m in ('no-card', 'card-mto', 'pooled'):
        xs = ratios[(t, m)] if m != 'pooled' else ratios[(t, 'no-card')] + ratios[(t, 'card-mto')]
        ys = measured[(t, m)] if m != 'pooled' else measured[(t, 'no-card')] + measured[(t, 'card-mto')]
        if xs: print(f'| {t} | {m} | {len(xs)} | {gm(xs):.3f} | {gm(ys):.3f} | {max(xs):.3f} | {sum(x > 1.25 for x in xs)} |')
print()
print(f'runs: {len(rs)}; science problems: {bad}')
