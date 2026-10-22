#!/usr/bin/env python3
"""GH-140 Tier 5 (yfclab2, 6 h, default seed): -ub-search=on (ids t5.*.on) vs the same binary with -ub-search=off run
in the same session (ids t5.*.off) and vs GH-138's Tier 5 (same rules, no finder; ids cc5.*). Per code: result and
time, final lb, final ub and when it was first reached. Per-level node counts are deterministic and identical between
the arms for every completed level (checked here), so time differences on common levels are machine load.
usage: analyze_tier5.py ON.jsonl OFF.jsonl GH138.jsonl"""
import json, re, sys
def load(p, pre, suf=''):
    out = {}
    for l in open(p):
        r = json.loads(l)
        if r.get('id', '').startswith(pre) and r['id'].endswith(suf): out['_'.join(r['stem'].split('_')[:3])] = r
    return out
N, F, O = load(sys.argv[1], 't5.', '.on'), load(sys.argv[2], 't5.', '.off'), load(sys.argv[3], 'cc5.')
def res(r):
    if r is None: return '-'
    return f"d={r['result'][1]} @ {r['wall']:.0f} s" if r['result'] else f"timeout, lb {r['final_lb']}"
def ubinfo(r):
    if r is None or not r['ub_events']: return '-'
    v = r['final_ub'] if r['final_ub'] is not None else min(x for _, x in r['ub_events'])
    t = min(t for t, x in r['ub_events'] if x == v)
    return f'{v} @ {t:.1f}'
def lbt(r, v):
    for t, x in r['lb_events']:
        if x >= v: return t
    return r['wall'] if r['result'] and r['result'][1] >= v else None
def levels(r):
    d = {}
    for L in r['levels']:
        m = re.match(r'(\w) level (\d+) (\w+) nodes (\d+) .* time ([\d.]+)s', L)
        if m: d[(m.group(1), int(m.group(2)))] = (m.group(3), int(m.group(4)), float(m.group(5)))
    return d
print('| Code | GH-138 (6 h) | ub | off, this session | ub | **on (ub-search)** | lb | ub @ s | time to the final lb (s): GH-138 / off / on | completed levels: same nodes on/off |')
print('|---|---|---|---|---|---|---:|---|---|---|')
cnt = dict(o=0, f=0, n=0); mism = []
for k in sorted(N, key=lambda s: (s[:2], int(s.split('_')[1]))):
    n, f, o = N[k], F.get(k), O.get(k)
    cnt['n'] += bool(n['result']); cnt['f'] += bool(f and f['result']); cnt['o'] += bool(o and o['result'])
    same = '-'
    if f:
        ln, lf = levels(n), levels(f)
        common = [x for x in ln if x in lf and ln[x][0] == lf[x][0] == 'EMPTY']
        bad = [x for x in common if ln[x][1] != lf[x][1]]
        if bad: mism.append((k, bad))
        same = f'{len(common) - len(bad)}/{len(common)}'
    L = n['final_lb']
    tt = ' / '.join('-' if (r is None or lbt(r, L) is None) else f'{lbt(r, L):.0f}' for r in (o, f, n))
    print(f"| {n['stem']} | {res(o)} | {ubinfo(o)} | {res(f)} | {ubinfo(f)} | **{res(n)}** | {n['final_lb']} | {ubinfo(n)} | {tt} | {same} |")
print(f"\nsolved codes: GH-138 {cnt['o']}, off (this session) {cnt['f']}, on {cnt['n']} (of {len(N)}); node-count mismatches on "
      f"common EMPTY levels: {mism}; science problems: {[r['id'] for r in list(N.values()) + list(F.values()) if not r.get('science_ok')]}")
