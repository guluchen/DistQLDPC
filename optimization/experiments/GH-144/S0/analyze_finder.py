#!/usr/bin/env python3
"""GH-144 S0 finder table: per code, U0 per seed vs the stem's d (or bounds), pre-pass seconds (as printed), process
wall to the summary line, stop reasons. usage: analyze_finder.py RESULTS.jsonl [LABEL] > table.md"""
import json, sys, collections, statistics
rs = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
label = sys.argv[2] if len(sys.argv) > 2 else sys.argv[1]
by = collections.defaultdict(list)
for r in rs:
    if 'u0' in r: by[(r['tier'], r['stem'])].append(r)
print(f'### {label}\n')
print('| Tier | Code | d / stem bounds | U0 per seed | U0 = d | pre-pass s per seed | median s | proc wall to U0 s (median) | iterations X+Z (median) | stop |')
print('|---:|---|---|---|---|---|---:|---:|---:|---|')
hit = tot = 0
for (t, stem), L in sorted(by.items(), key=lambda kv: (kv[0][0], int(kv[0][1].split('_')[1]), kv[0][1])):
    L.sort(key=lambda r: r['seed'])
    f = stem.split('_')[3]
    d = int(f) if f.isdigit() else None
    eq = ''
    if d is not None:
        k = sum(r['u0'] == d for r in L); hit += k; tot += len(L); eq = f'{k}/{len(L)}'
    stops = collections.Counter('budget' if r['stop'] == 'time budget' else 'conv' for r in L)
    print(f"| {t} | {stem} | {f} | {'/'.join(str(r['u0']) for r in L)} | {eq} | {' '.join('%.2f' % r['pre_seconds'] for r in L)} | "
          f"{statistics.median(r['pre_seconds'] for r in L):.2f} | {statistics.median(r['proc_wall_to_summary'] for r in L):.2f} | "
          f"{int(statistics.median(r['it_x'] + r['it_z'] for r in L))} | {', '.join(f'{k} {v}' for k, v in stops.items())} |")
print(f'\ncodes with a numeric stem: U0 = d in {hit}/{tot} runs\n')
