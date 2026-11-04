#!/usr/bin/env python3
"""Summarise results.jsonl of the 2026-11-04 re-tier panel. usage: analyze.py DIR  -> DIR/summary.json, prints table"""
import json, statistics, sys
from collections import defaultdict

D = sys.argv[1]
codes = {c['stem']: c for c in json.load(open(f'{D}/codes.json'))}
R = [json.loads(l) for l in open(f'{D}/results.jsonl')]
PANEL = 5000
by = defaultdict(list)
for r in R: by[(r['stem'], r['cfg'])].append(r)


def ptime(r):
    return r['wall'] if r['result'] is not None and r['wall'] <= PANEL else None


def tier_of(t):
    if t is None or t >= PANEL: return 5
    return 0 if t < 1 else 1 if t < 10 else 2 if t < 100 else 3 if t < 2000 else 4


def cell(stem, cfg):
    rs = by.get((stem, cfg), [])
    panel = {}
    for r in rs:
        if r['limit'] == PANEL or r['seed'] == 0 and cfg.startswith('maxsat'):
            panel[r['seed']] = ptime(r)
    longr = [r for r in rs if r['limit'] > PANEL]
    vals = [PANEL if v is None else v for _, v in sorted(panel.items())]
    med = statistics.median(vals) if vals else None
    out = dict(seeds={s: (None if v is None else round(v, 2)) for s, v in sorted(panel.items())}, n=len(vals),
               timeouts=sum(v is None for v in panel.values()),
               median=None if med is None else round(med, 2))
    if longr:
        l = longr[0]
        out['long'] = dict(seed=l['seed'], wall=round(l['wall'], 1), result=l['result'], lb=l['final_lb'], ub=l['final_ub'],
                           memout=l['memout'], limit=l['limit'],
                           lb_events=l['lb_events'], ub_events=l['ub_events'])
    out['memout'] = [r['id'] for r in rs if r['memout']]
    out['results'] = sorted({r['result'] for r in rs if r['result'] is not None})
    return out


summary = {}
for s, c in codes.items():
    e = dict(group=c['group'], claim=c['claim'])
    for cfg in ('maxsat-no-card', 'maxsat-card-mto', 'cc', 'ccopt'):
        if (s, cfg) in by: e[cfg] = cell(s, cfg)
    rs = [r for r in R if r['stem'] == s]
    lbs = [(r['final_lb'], r['id']) for r in rs if r['final_lb'] is not None]
    ubs = [(r['final_ub'], r['id']) for r in rs if r['final_ub'] is not None]
    solved = sorted({r['result'] for r in rs if r['result'] is not None})
    e['solved'] = solved
    e['lb'] = max(lbs)[0] if lbs else None
    e['lb_runs'] = sorted(i for v, i in lbs if v == e['lb']) if lbs else []
    e['ub'] = min(ubs)[0] if ubs else None
    e['ub_runs'] = sorted(i for v, i in ubs if v == e['ub']) if ubs else []
    meds = [e[m]['median'] if e.get(m) and e[m]['n'] >= 5 or (e.get(m) and e[m]['timeouts'] >= 3) else None
            for m in ('maxsat-no-card', 'maxsat-card-mto')]
    if all(m is not None for m in meds):
        slow = max(meds); e['slower_median'] = slow
        e['slower_mode'] = ('maxsat-no-card', 'maxsat-card-mto')[meds.index(slow)]
        e['rule_tier'] = tier_of(slow)
    else:
        # tier 5 codes with only the 6 h seed-0 run
        longs = [e[m].get('long') for m in ('maxsat-no-card', 'maxsat-card-mto') if e.get(m)]
        if len(longs) == 2 and all(l and (l['result'] is None or l['wall'] > PANEL) for l in longs):
            e['rule_tier'] = 5; e['slower_median'] = None
        else:
            e['rule_tier'] = None
    summary[s] = e
json.dump(summary, open(f'{D}/summary.json', 'w'), indent=1)


def f(x):
    return '-' if x is None else (f'{x:.2f}' if x < 100 else f'{x:.0f}')


print('| stem | grp | claim | no-card med | card-mto med | cc med | ccopt med | lb | ub | solved | rule tier |')
for s, e in sorted(summary.items(), key=lambda kv: (kv[1]['group'], int(kv[0].split('_')[1]))):
    g = lambda m: (f(e[m]['median']) + (f"({e[m]['timeouts']}T/{e[m]['n']})" if e[m]['timeouts'] else '') +
                   (f" L:{e[m]['long']['result'] or 'T'}@{e[m]['long']['wall']:.0f}" if 'long' in e[m] else '')) if m in e else ''
    print(f"| {s} | {e['group']} | {e['claim'].get('lo')}..{e['claim'].get('hi')} | {g('maxsat-no-card')} | {g('maxsat-card-mto')} | "
          f"{g('cc')} | {g('ccopt')} | {e['lb']} | {e['ub']} | {e['solved']} | {e['rule_tier']} |")
