#!/usr/bin/env python3
"""Independent GF(2) witness check (GH-124 S0e), written from the CSS definitions only.
X half: e with Hz e = 0 that is not in rowspace(Hx)  (also reported: odd overlap with some Gx row).
Z half: e with Hx e = 0 that is not in rowspace(Hz)  (also reported: odd overlap with some Gz row).
usage: wcheck.py STEM_PREFIX HALF q1 q2 ...    (prints one line: VALID/INVALID with details)
   or: import and call check(prefix, half, support)"""
import sys


def load(path):
    rows = []
    for line in open(path):
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        bits = [c for c in s if c in "01"]
        v = 0
        for i, c in enumerate(bits):
            if c == "1":
                v |= 1 << i
        rows.append((v, len(bits)))
    n = rows[0][1]
    assert all(w == n for _, w in rows), path
    return [v for v, _ in rows], n


def basis(rows):
    piv = {}   # leading bit -> reduced row
    for r in rows:
        x = r
        while x:
            hb = x.bit_length() - 1
            if hb in piv:
                x ^= piv[hb]
            else:
                piv[hb] = x
                break
    return piv


def in_span(piv, v):
    x = v
    while x:
        hb = x.bit_length() - 1
        if hb not in piv:
            return False
        x ^= piv[hb]
    return True


_cache = {}


def mats(prefix):
    if prefix not in _cache:
        M = {k: load(f"{prefix}_{k}.txt") for k in ("Hx", "Hz", "Gx", "Gz")}
        n = M["Hx"][1]
        assert all(M[k][1] == n for k in M)
        _cache[prefix] = (n, {k: M[k][0] for k in M}, {"Hx": basis(M["Hx"][0]), "Hz": basis(M["Hz"][0])})
    return _cache[prefix]


def check(prefix, half, support):
    n, M, B = mats(prefix)
    H, S, G = (("Hz", "Hx", "Gx") if half == "X" else ("Hx", "Hz", "Gz"))
    if len(set(support)) != len(support) or any(q < 0 or q >= n for q in support):
        return False, "bad support"
    e = 0
    for q in support:
        e |= 1 << q
    syn_ok = all(bin(r & e).count("1") % 2 == 0 for r in M[H])
    not_stab = not in_span(B[S], e)
    odd_g = any(bin(r & e).count("1") % 2 == 1 for r in M[G])
    ok = syn_ok and not_stab and odd_g
    return ok, f"weight {len(support)} {H}e=0:{syn_ok} notin_row({S}):{not_stab} odd_overlap_{G}:{odd_g}"


if __name__ == "__main__":
    ok, why = check(sys.argv[1], sys.argv[2], [int(x) for x in sys.argv[3:]])
    print(("VALID " if ok else "INVALID ") + why)
