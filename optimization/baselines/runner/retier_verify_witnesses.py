#!/usr/bin/env python3
"""Independent GF(2) witness check (pure Python, no DistQLDPC code) for the 2026-11-04 re-tier panel.
For every 'c witness X...: q1 q2 ...' / 'c witness Z...: ...' line in the given logs (columns 0-based):
  X-type word e:  Hz e = 0  and  e not in rowspace(Hx)   (H_other e = 0, e not in rowspan H_same)
  Z-type word e:  Hx e = 0  and  e not in rowspace(Hz)
Rows of the bundled Gz (X-type) and Gx (Z-type) are checked as candidate words too.
Matrix paths come from the log's '# start ... cmd: ... PATH' header (relative to the run dir).
Output: one JSON record per log with every witness weight and pass/fail, plus the lightest passing weight per type.
usage: verify_witnesses.py RUNDIR LOG... > out.jsonl"""
import json, os, re, sys

root = sys.argv[1]
cache = {}


def load(prefix, k):
    rows = []
    for l in open(os.path.join(root, f'{prefix}_{k}.txt')):
        v = l.split()
        if v and not l.startswith('#'): rows.append(sum(1 << i for i, c in enumerate(v) if c == '1'))
    return rows


def basis(rows):
    b = {}
    for r in rows:
        while r:
            h = r.bit_length() - 1
            if h in b: r ^= b[h]
            else: b[h] = r; break
    return b


def in_span(b, v):
    while v:
        h = v.bit_length() - 1
        if h not in b: return False
        v ^= b[h]
    return True


def code(prefix):
    if prefix not in cache:
        hx, hz = load(prefix, 'Hx'), load(prefix, 'Hz')
        cache[prefix] = dict(Hx=hx, Hz=hz, bx=basis(hx), bz=basis(hz))
    return cache[prefix]


for f in sys.argv[2:]:
    prefix = None; ans = None; wits = []
    for l in open(f):
        if l.startswith('# start') and prefix is None:
            prefix = l.split()[-1]
        m = re.search(r'\tc witness (X|Z)([^:]*): ([\d ]+)\s*$', l)
        if m: wits.append((m.group(1), m.group(2).strip(), [int(x) for x in m.group(3).split()]))
        m = re.match(r'\s*[\d.]+\to (\d+)', l)
        if m: ans = int(m.group(1))
    c = code(prefix); rec = dict(log=os.path.basename(f), prefix=prefix, answer=ans, witnesses=[])
    # the bundled logical basis rows are candidate witnesses too (CC's ub-basis prints no support):
    # Gz rows = X-type words (ker Hz / row Hx), Gx rows = Z-type words (ker Hx / row Hz)
    for t, k in (('X', 'Gz'), ('Z', 'Gx')):
        for g in load(prefix, k):
            wits.append((t, 'basis ' + k, [i for i in range(g.bit_length()) if g >> i & 1]))
    best = {}
    for t, tag, sup in wits:
        e = sum(1 << q for q in set(sup))
        same, other, bsame = (c['Hx'], c['Hz'], c['bx']) if t == 'X' else (c['Hz'], c['Hx'], c['bz'])
        ok_ker = all(bin(e & h).count('1') % 2 == 0 for h in other)
        ok_nt = not in_span(bsame, e)
        ok = ok_ker and ok_nt and len(set(sup)) == len(sup)
        rec['witnesses'].append(dict(type=t, tag=tag, weight=len(set(sup)), ker=ok_ker, nontrivial=ok_nt, ok=ok))
        if ok: best[t] = min(best.get(t, 10**9), len(sup))
    rec['lightest_ok'] = best
    rec['all_ok'] = all(w['ok'] for w in rec['witnesses'])
    rec['answer_witnessed'] = ans is not None and min(best.values(), default=None) == ans
    print(json.dumps(rec))
