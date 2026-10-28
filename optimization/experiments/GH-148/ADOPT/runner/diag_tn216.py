#!/usr/bin/env python3
"""GH-148 TN_216 diagnosis from the existing 5-seed logs (no new runs): per probe (half, cap) the conflicts and wall
time of main and candidate, conflicts per second, and the candidate's OVERLAP counters (rows, propagations, conflicts
whose conflicting constraint was an overlap row). usage: diag_tn216.py LOGDIR"""
import re, sys, glob, statistics as st, collections
D = sys.argv[1]
FR = re.compile(r'^\s*([\d.]+)\tc FRONTIER (\S) cap (\d+) (\S+): conflicts (\d+) decisions (\d+)')
OV = re.compile(r'^\s*([\d.]+)\tc OVERLAP (\S) cap (\d+): rows (\d+) props (\d+) conflicts (\d+) cached_clauses (\d+)')
def parse(f):
    pr = []; ov = {}; prev = 0.0
    for l in open(f):
        m = FR.match(l)
        if m:
            t = float(m.group(1)); pr.append(dict(h=m.group(2), cap=int(m.group(3)), conf=int(m.group(5)), dec=int(m.group(6)), dt=t - prev)); prev = t
        m = OV.match(l)
        if m: ov[(m.group(2), int(m.group(3)))] = dict(props=int(m.group(5)), oconf=int(m.group(6)))
    return pr, ov
agg = collections.defaultdict(list); tot = collections.defaultdict(list)
for mode in ('no-card', 'card-mto'):
    for s in range(5):
        pm, _ = parse(f'{D}/s5.TN_216_4_18.{mode}.main.s{s}.log')
        pc, oc = parse(f'{D}/s5.TN_216_4_18.{mode}.cand.s{s}.log')
        km = {(p['h'], p['cap']): p for p in pm}; kc = {(p['h'], p['cap']): p for p in pc}
        assert [(p['h'], p['cap']) for p in pm] == [(p['h'], p['cap']) for p in pc], (mode, s)
        for k in kc:
            if k[1] < 16: continue
            a, b = km[k], kc[k]; o = oc.get(k, {})
            agg[(mode, k)].append((a['conf'], b['conf'], a['dt'], b['dt'], o.get('props', 0), o.get('oconf', 0)))
        cm = sum(p['conf'] for p in pm); cc = sum(p['conf'] for p in pc)
        tm = sum(p['dt'] for p in pm); tc = sum(p['dt'] for p in pc)
        tot[mode].append((cm, cc, tm, tc))
print('| Mode | probe | conflicts cand/main (median, range) | time cand/main (median) | conflicts/s main -> cand (median) | overlap props per conflict | overlap-row conflicts / all conflicts |')
print('|---|---|---|---|---|---:|---:|')
for (mode, k), v in sorted(agg.items(), key=lambda x: (x[0][0] != 'no-card', x[0][1][1], x[0][1][0])):
    cr = [b / a for a, b, *_ in v]; tr = [d / c for _, _, c, d, *_ in v]
    rm = [a / c for a, _, c, *_ in v]; rc = [b / d for _, b, _, d, *_ in v]
    pp = [p / b for _, b, _, _, p, _ in v]; oc = [o / b for _, b, _, _, _, o in v]
    print(f'| {mode} | {k[0]} cap {k[1]} | {st.median(cr):.2f} ({min(cr):.2f}-{max(cr):.2f}) | {st.median(tr):.2f} | '
          f'{st.median(rm):.0f} -> {st.median(rc):.0f} | {st.median(pp):.2f} | {100 * st.median(oc):.2f} % |')
for mode, v in tot.items():
    cr = [b / a for a, b, _, _ in v]; tr = [d / c for _, _, c, d in v]
    print(f'\n{mode} whole run: conflicts cand/main median {st.median(cr):.2f} ({min(cr):.2f}-{max(cr):.2f}); time cand/main median {st.median(tr):.2f} ({min(tr):.2f}-{max(tr):.2f}); '
          f'per-conflict time cand/main median {st.median([t / c for c, t in zip(cr, tr)]):.2f}')
