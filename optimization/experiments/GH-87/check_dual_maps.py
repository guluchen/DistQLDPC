#!/usr/bin/env python3
"""GH-87 independent GF(2) checker for the XZ-dual maps reported by `distqldpc -dualskip-report`.

Written from scratch in Python (shares no code with the C++ detector). For every code:
  * parse Hx, Hz, Gx, Gz from data/matrices;
  * rebuild each reported map from its description, check it is a permutation of 0..n-1, and check
    pi(rs Hz) = rs Hx and pi(rs [Hz;Gx]) = rs [Hx;Gz] by ranks: rank(pi A) = rank(B) = rank([pi A; B]);
  * independently enumerate the whole candidate family (identity, block/strided shifts, 2D shifts,
    half swap, half swap with group inverse), test every candidate the same way and require the
    accepted list (in family order) to equal the reported list, and the used map to be its first;
  * check the reported ranks.
Usage: check_dual_maps.py REPO_ROOT REPORT_DIR  (REPORT_DIR/<code>.report.txt). Prints ALL_PASS or failures.
"""
import os, re, sys, json


def load(path):
    rows, n = [], None
    with open(path) as f:
        for line in f:
            t = line.strip()
            if not t or t.startswith('#'):
                continue
            bits = [c for c in t if c in '01']
            if not bits:
                continue
            if n is None:
                n = len(bits)
            assert len(bits) == n, path
            v = 0
            for i, c in enumerate(bits):
                if c == '1':
                    v |= 1 << i
            rows.append(v)
    return rows, n


def rank(rows):
    piv = {}  # pivot bit -> row with that lowest set bit
    for v in rows:
        while v:
            p = (v & -v).bit_length() - 1
            if p in piv:
                v ^= piv[p]
            else:
                piv[p] = v
                break
    return len(piv)


def permute(v, pi):
    w = 0
    while v:
        low = v & -v
        i = low.bit_length() - 1
        w |= 1 << pi[i]
        v ^= low
    return w


def same_space(A, B, pi):
    """rs(pi A) == rs(B)."""
    PA = [permute(v, pi) for v in A]
    rb = rank(B)
    return rank(PA) == rb and rank(PA + B) == rb


def family(n):
    out, seen = [], set()

    def add(desc, p):
        t = tuple(p)
        if t not in seen:
            seen.add(t)
            out.append((desc, p))
    add('identity', list(range(n)))
    for L in range(2, n + 1):
        if n % L:
            continue
        B = n // L
        add('blockshift L=%d' % L, [(i // L) * L + ((i % L) + 1) % L for i in range(n)])
        add('stridedshift L=%d' % L, [(((i // B) + 1) % L) * B + (i % B) for i in range(n)])
        for l in range(2, L):
            if L % l or L // l < 2:
                continue
            m = L // l
            add('2dshift-a L=%d (%dx%d)' % (L, l, m),
                [(i // L) * L + ((((i % L) // m) + 1) % l) * m + (i % L) % m for i in range(n)])
            add('2dshift-b L=%d (%dx%d)' % (L, l, m),
                [(i // L) * L + ((i % L) // m) * m + (((i % L) % m) + 1) % m for i in range(n)])
    if n % 2 == 0:
        h = n // 2
        add('halfswap', [(i + h) % n for i in range(n)])
        add('halfswap-inverse Z_h', [(1 - i // h) * h + (h - i % h) % h for i in range(n)])
        for l in range(2, h):
            if h % l or h // l < 2:
                continue
            m = h // l
            add('halfswap-inverse Z_%d x Z_%d' % (l, m),
                [(1 - i // h) * h + ((l - (i % h) // m) % l) * m + (m - (i % h) % m) % m for i in range(n)])
    return out


def perm_from_desc(desc, n):
    """Independent reconstruction of one map from its description (not via family())."""
    h = n // 2
    if desc == 'identity':
        return list(range(n))
    if desc == 'halfswap':
        return [(i + h) % n for i in range(n)]
    if desc == 'halfswap-inverse Z_h':
        return [(1 - i // h) * h + (h - i % h) % h for i in range(n)]
    m_ = re.fullmatch(r'halfswap-inverse Z_(\d+) x Z_(\d+)', desc)
    if m_:
        l, m = int(m_.group(1)), int(m_.group(2))
        assert l * m == h
        res = []
        for i in range(n):
            side, g = divmod(i, h)
            a, b = divmod(g, m)
            res.append((1 - side) * h + ((-a) % l) * m + (-b) % m)
        return res
    m_ = re.fullmatch(r'(blockshift|stridedshift) L=(\d+)', desc)
    if m_:
        L = int(m_.group(2)); assert n % L == 0
        if m_.group(1) == 'blockshift':
            return [i - i % L + (i + 1) % L if (i % L) != L - 1 else i - (L - 1) for i in range(n)]
        B = n // L
        return [(i + B) % n for i in range(n)]
    m_ = re.fullmatch(r'2dshift-(a|b) L=(\d+) \((\d+)x(\d+)\)', desc)
    if m_:
        L, l, m = int(m_.group(2)), int(m_.group(3)), int(m_.group(4)); assert l * m == L and n % L == 0
        res = []
        for i in range(n):
            base, loc = i - i % L, i % L
            a, b = divmod(loc, m)
            res.append(base + (((a + 1) % l) * m + b if m_.group(1) == 'a' else a * m + (b + 1) % m))
        return res
    raise ValueError('unknown map description: ' + desc)


def main():
    root, rdir = sys.argv[1], sys.argv[2]
    codes = sorted(f[:-len('.report.txt')] for f in os.listdir(rdir) if f.endswith('.report.txt'))
    fails, summary = [], {}
    for code in codes:
        txt = open(os.path.join(rdir, code + '.report.txt')).read()
        M = {k: load(os.path.join(root, 'data', 'matrices', '%s_%s.txt' % (code, k))) for k in ('Hx', 'Hz', 'Gx', 'Gz')}
        n = M['Hx'][1]
        Hx, Hz, Gx, Gz = (M[k][0] for k in ('Hx', 'Hz', 'Gx', 'Gz'))
        hdr = re.search(r'n=(\d+) rank Hz=(\d+) Hx=(\d+) \[Hz;Gx\]=(\d+) \[Hx;Gz\]=(\d+) candidates=(\d+) verified_maps=(\d+) detect_cpu=([\d.]+)s used=(.*)', txt)
        if not hdr:
            fails.append((code, 'no report header')); continue
        rep_maps = re.findall(r'^c dualskip map: (.*)$', txt, re.M)
        rk = (rank(Hz), rank(Hx), rank(Hz + Gx), rank(Hx + Gz))
        if int(hdr.group(1)) != n or tuple(int(hdr.group(i)) for i in range(2, 6)) != rk:
            fails.append((code, 'rank/n mismatch %s vs %s' % (hdr.groups()[:5], rk)))
        if int(hdr.group(7)) != len(rep_maps):
            fails.append((code, 'verified_maps count mismatch'))
        used = hdr.group(9).strip()
        if (used == 'none') != (len(rep_maps) == 0) or (rep_maps and used != rep_maps[0]):
            fails.append((code, 'used map inconsistent'))
        # every reported map, rebuilt independently from its description
        for d in rep_maps:
            pi = perm_from_desc(d, n)
            if sorted(pi) != list(range(n)):
                fails.append((code, 'not a permutation: ' + d)); continue
            if not (same_space(Hz, Hx, pi) and same_space(Hz + Gx, Hx + Gz, pi)):
                fails.append((code, 'reported map fails verification: ' + d))
        # re-enumerate the family; accepted set must equal the reported set
        fam = family(n)
        for d, p in fam:
            if perm_from_desc(d, n) != p:
                fails.append((code, 'family/desc reconstruction disagree: ' + d))
        ranks_ok = rk[0] == rk[1] and rk[2] == rk[3]
        acc = [d for d, p in fam if ranks_ok and same_space(Hz, Hx, p) and same_space(Hz + Gx, Hx + Gz, p)]
        if acc != rep_maps:
            fails.append((code, 'accepted set differs: python=%s report=%s' % (acc, rep_maps)))
        if ranks_ok and int(hdr.group(6)) != len(fam):
            fails.append((code, 'candidate count %s vs python %d' % (hdr.group(6), len(fam))))
        summary[code] = {'n': n, 'ranks': rk, 'family': len(fam), 'maps': acc, 'used': acc[0] if acc else None}
        print('%-22s n=%-5d ranks(Hz,Hx,[Hz;Gx],[Hx;Gz])=%s maps=%d used=%s' % (code, n, rk, len(acc), acc[0] if acc else 'none'), flush=True)
    json.dump(summary, open(os.path.join(rdir, 'dual_maps.json'), 'w'), indent=1, sort_keys=True)
    for f in fails:
        print('FAIL', *f)
    print('ALL_PASS' if not fails else 'FAILURES=%d' % len(fails))
    return 1 if fails else 0


if __name__ == '__main__':
    sys.exit(main())
