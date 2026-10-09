#!/usr/bin/env python3
"""Offline (no solver) analysis of low-weight conjugate-logical coset representatives.

For each bundled CSS code (data/matrices/<code>_{Hx,Hz,Gx,Gz}.txt) and each logical
row g of Gx (coset g + rowspace(Hz), checked against x) and of Gz (coset g + rowspace(Hx),
checked against z), search for low-weight representatives u with u + g in the row space.
Every reported u is verified by exact GF(2) reduction against an echelon basis.

Reports per code: named distance, min / median / max of per-row best weights,
how many distinct low-weight reps were found, the greedy maximum number of pairwise
disjoint reps per row (cores available once a_j is true), and the size of the union of
the best reps over all rows (one root-level hitting set) plus how many disjoint such
unions a greedy packing finds (root-level cores for the global OR).

Pure Python, bitsets as ints. Deterministic (seeded).
"""
import json
import os
import random
import statistics
import sys
import time


def load(path):
    rows = []
    n = None
    with open(path) as f:
        for line in f:
            s = line.strip()
            if not s or s.startswith('#'):
                continue
            bits = [c for c in s if c in '01']
            if not bits:
                continue
            if n is None:
                n = len(bits)
            v = 0
            for i, c in enumerate(bits):
                if c == '1':
                    v |= 1 << i
            rows.append(v)
    return rows, n


def echelon(rows, order):
    """Echelon basis with pivots chosen by column priority `order` (list of columns).
    Returns list of (pivot, row) fully reduced on pivot columns."""
    rank_of = {c: k for k, c in enumerate(order)}
    basis = []  # (pivot, row)
    for r in rows:
        for p, b in basis:
            if (r >> p) & 1:
                r ^= b
        if r == 0:
            continue
        # pick pivot = highest-priority set column
        best = None
        x = r
        while x:
            low = x & -x
            c = low.bit_length() - 1
            if best is None or rank_of[c] < rank_of[best]:
                best = c
            x ^= low
        # eliminate this pivot from existing rows
        nb = []
        for p, b in basis:
            if (b >> best) & 1:
                b ^= r
            nb.append((p, b))
        nb.append((best, r))
        basis = nb
    return basis


def reduce(v, basis):
    for p, b in basis:
        if (v >> p) & 1:
            v ^= b
    return v


def wt(v):
    return bin(v).count('1')


def greedy_local(u, hrows):
    improved = True
    while improved:
        improved = False
        w = wt(u)
        for h in hrows:
            t = u ^ h
            wt_t = wt(t)
            if wt_t < w:
                u, w, improved = t, wt_t, True
    return u


def analyse(code, mdir, trials, cap_extra, seed):
    Hx, n = load(os.path.join(mdir, code + '_Hx.txt'))
    Hz, _ = load(os.path.join(mdir, code + '_Hz.txt'))
    Gx, _ = load(os.path.join(mdir, code + '_Gx.txt'))
    Gz, _ = load(os.path.join(mdir, code + '_Gz.txt'))
    rng = random.Random(seed)
    nat = list(range(n))
    exact = {'X': echelon(Hz, nat), 'Z': echelon(Hx, nat)}  # verification bases
    # (side, coset generator list, stabilizer rows): Gx vs rowspace(Hz) on x; Gz vs rowspace(Hx) on z
    sides = [('X', Gx, Hz), ('Z', Gz, Hx)]
    reps = {}  # (side, j) -> dict u -> wt
    for side, G, H in sides:
        for j, g in enumerate(G):
            u = greedy_local(g, H)
            reps[(side, j)] = {g: wt(g), u: wt(u)}
    t0 = time.time()
    for t in range(trials):
        order = nat[:]
        rng.shuffle(order)
        for side, G, H in sides:
            basis = echelon(H, order)
            for j, g in enumerate(G):
                u = reduce(g, basis)
                u = greedy_local(u, H)
                reps[(side, j)][u] = wt(u)
    elapsed = time.time() - t0
    # verify, filter
    out_rows = []
    best_reps = {}
    all_best = []
    for side, G, H in sides:
        for j, g in enumerate(G):
            d = reps[(side, j)]
            good = {}
            for u, w in d.items():
                if u == 0:
                    raise SystemExit('zero rep for %s %s %d (logical row in stabilizer space?)' % (code, side, j))
                if reduce(u ^ g, exact[side]) != 0:
                    raise SystemExit('VERIFY FAIL %s %s %d' % (code, side, j))
                good[u] = w
            wmin = min(good.values())
            cap = wmin + cap_extra
            low = sorted([u for u, w in good.items() if w <= cap], key=lambda u: (wt(u), u))
            # greedy disjoint packing among low reps
            used = 0
            pack = 0
            for u in low:
                if u & used == 0:
                    used |= u
                    pack += 1
            # packing over every verified rep found (any weight): cores once a_j is true
            used = 0
            pack_any = 0
            for u in sorted(good, key=lambda u: (wt(u), u)):
                if u & used == 0:
                    used |= u
                    pack_any += 1
            best = low[0]
            best_reps[(side, j)] = low
            all_best.append(best)
            out_rows.append((side, j, wt(g), wmin, len(low), pack, pack_any, len(good)))
    union = 0
    for u in all_best:
        union |= u
    # greedy disjoint "hitting-set unions": each needs one rep per row, disjoint from previous unions
    used = 0
    nunions = 0
    while True:
        cur = 0
        ok = True
        for key in sorted(best_reps):
            cand = [u for u in best_reps[key] if u & used == 0]
            if not cand:
                ok = False
                break
            # prefer reps overlapping current union (smaller union)
            cand.sort(key=lambda u: (wt(u & ~cur), wt(u)))
            cur |= cand[0]
        if not ok:
            break
        used |= cur
        nunions += 1
    return {
        'code': code, 'n': n, 'kx': len(Gx), 'kz': len(Gz),
        'rows': out_rows, 'union_best': wt(union), 'disjoint_unions': nunions,
        'search_s': round(elapsed, 2), 'trials': trials,
    }


def main():
    mdir = sys.argv[1]
    trials = int(sys.argv[2]) if len(sys.argv) > 2 else 200
    nmax = int(sys.argv[3]) if len(sys.argv) > 3 else 700
    codes = sorted({f.rsplit('_', 1)[0] for f in os.listdir(mdir) if f.endswith('_Hx.txt')})
    res = []
    for c in codes:
        _, n = load(os.path.join(mdir, c + '_Hx.txt'))
        if n > nmax:
            continue
        parts = c.split('_')
        dnamed = parts[3] if len(parts) >= 4 else '?'
        r = analyse(c, mdir, trials, 2, 12345)
        r['d_named'] = dnamed
        ws = [x[3] for x in r['rows']]
        packs = [x[5] for x in r['rows']]
        pany = [x[6] for x in r['rows']]
        ws_orig = [x[2] for x in r['rows']]
        print('%-20s n=%4d k=%3d d=%-7s origwt[min/med/max]=%d/%g/%d  bestwt[min/med/max]=%d/%g/%d  '
              'disj(w<=min+2)/row=%d/%g/%d disj(any)/row=%d/%g/%d  union=%d dUnions=%d (%.1fs)' % (
                  c, r['n'], r['kx'], dnamed, min(ws_orig), statistics.median(ws_orig), max(ws_orig),
                  min(ws), statistics.median(ws), max(ws), min(packs), statistics.median(packs), max(packs), min(pany), statistics.median(pany), max(pany),
                  r['union_best'], r['disjoint_unions'], r['search_s']), flush=True)
        res.append(r)
    with open(sys.argv[4] if len(sys.argv) > 4 else 'conj_offline.json', 'w') as f:
        json.dump(res, f, indent=1)


if __name__ == '__main__':
    main()
