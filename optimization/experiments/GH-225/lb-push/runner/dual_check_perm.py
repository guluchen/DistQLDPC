#!/usr/bin/env python3
"""Independent GF(2) check (pure Python) of an explicit XZ-dual map pi (X-half qubit i -> Z-half qubit pi[i], from a file of n integers):
pi(rows of Hz) in rs Hx, pi(rows of Hx) in rs Hz, rank Hx = rank Hz. usage: dual_check_perm.py MATRIX_PREFIX PERM_FILE"""
import sys
def rows(path):
    out = []
    for l in open(path):
        if l.startswith('#') or not l.strip(): continue
        v = 0
        for i, x in enumerate(l.split()):
            if x == '1': v |= 1 << i
        out.append(v)
    return out
def basis(rs):
    piv = {}
    for r in rs:
        while r:
            h = r.bit_length() - 1
            if h in piv: r ^= piv[h]
            else: piv[h] = r; break
    return piv
def inspan(piv, v):
    while v:
        h = v.bit_length() - 1
        if h not in piv: return False
        v ^= piv[h]
    return True
prefix, pf = sys.argv[1:3]
hx, hz = rows(prefix + '_Hx.txt'), rows(prefix + '_Hz.txt')
perm = list(map(int, open(pf).read().split()))
assert sorted(perm) == list(range(len(perm)))
def image(v):
    o = 0
    while v:
        low = v & -v; o |= 1 << perm[low.bit_length() - 1]; v ^= low
    return o
bx, bz = basis(hx), basis(hz)
print(prefix.split('/')[-1], 'explicit map: is a permutation True; rank Hx', len(bx), 'rank Hz', len(bz),
      'pi(Hz) in rs Hx:', all(inspan(bx, image(r)) for r in hz), 'pi(Hx) in rs Hz:', all(inspan(bz, image(r)) for r in hx))
