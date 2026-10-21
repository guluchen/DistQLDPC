#!/usr/bin/env python3
"""GH-138 S0 Mac analysis: old rules (excl,pack,orbf,parity,leaf) vs new (+overlap), -cc-stats logs.
Per code: wall old/new, answer or final lb, top completed levels (nodes, s) old -> new; for tier5 codes without an own old
run, the old side is GH-133's Mac log of the same rule set ('new' arm of GH-133, binary d8fcce8, same Mac).
usage: analyze_s0mac.py RESULTS.tsv LOGDIR GH133_LOGDIR"""
import re, sys, os, math
res = {}
for l in open(sys.argv[1]):
    f = l.rstrip('\n').split('\t')
    if len(f) >= 5: res[f[0]] = dict(wall=float(f[2]), ans=f[4])
LD, OD = sys.argv[2], sys.argv[3]
def parse(p):
    lv, lb = {}, None
    for l in open(p, errors='replace'):
        m = re.match(r'c cc-stats: (\w) level (\d+) (\w+) nodes (\d+) .*time ([\d.]+)s', l)
        if m: lv[(m.group(1), int(m.group(2)))] = (m.group(3), int(m.group(4)), float(m.group(5)))
        m = re.match(r'c d_lb: (\d+)', l)
        if m: lb = int(m.group(1))
    return lv, lb
codes = sorted(set(k.rsplit('.', 1)[0] for k in res), key=lambda c: (c.split('.')[0], c))
print('| Tier | Code | old wall s | new wall s | ratio | result old / new | top common levels: nodes old -> new (ratio), s old -> new |')
print('|---:|---|---:|---:|---:|---|---|')
lvl_n, lvl_t = [], []
for c in codes:
    t, stem = c.split('.', 1)
    o, n = res.get(c + '.old'), res.get(c + '.new')
    src = 'own'
    po = f'{LD}/{c}.old.log'
    if not o:
        gstem = stem.replace('_ge28', '_ge17')
        po = f'{OD}/{t}.{gstem}.new.log'; src = 'GH-133'
    if not os.path.exists(po) or not n: continue
    lo, lbo = parse(po); ln, lbn = parse(f'{LD}/{c}.new.log')
    common = sorted([k for k in lo if k in ln and lo[k][0] == ln[k][0]], key=lambda k: (k[1], k[0]))[-3:]
    det = '; '.join(f'{h}{w}: {lo[(h,w)][1]/1e6:.1f}M -> {ln[(h,w)][1]/1e6:.1f}M ({ln[(h,w)][1]/lo[(h,w)][1]:.3f}), {lo[(h,w)][2]:.1f} -> {ln[(h,w)][2]:.1f}' for h, w in common)
    em = [k for k in common if lo[k][0] == 'EMPTY']
    if em:
        k = em[-1]; lvl_n.append(ln[k][1] / lo[k][1]); lvl_t.append(ln[k][2] / max(lo[k][2], 1e-9))
    ow = o['wall'] if o else None
    ro = (o['ans'] if o else 'TIMEOUT') if (o and o['ans'] != 'TIMEOUT') else f'lb {lbo}'
    rn = n['ans'] if n['ans'] != 'TIMEOUT' else f'lb {lbn}'
    ratio = f'{n["wall"]/ow:.3f}' if ow and o['ans'] != 'TIMEOUT' and n['ans'] != 'TIMEOUT' else '-'
    print(f'| {t[1]} | {stem}{" (old: GH-133 log)" if src != "own" else ""} | {ow if ow else "-"} | {n["wall"]} | {ratio} | {ro} / {rn} | {det} |')
g = lambda v: math.exp(sum(map(math.log, v)) / len(v))
print(f'\nlargest common EMPTY level per code: geomean nodes {g(lvl_n):.3f}, time {g(lvl_t):.3f} over {len(lvl_n)} codes')
