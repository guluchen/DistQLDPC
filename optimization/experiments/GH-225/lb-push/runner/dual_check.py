#!/usr/bin/env python3
"""Independent check (pure Python, no DistQLDPC code) of the XZ-dual map halfswap-inverse Z_l x Z_m used on the BB codes:
pi(h, (a, b)) = (1 - h, (-a, -b)) with qubit index h*(l*m) + a*m + b. Checks pi(rows of Hz) in rs Hx, pi(rows of Hx) in rs Hz,
and rank Hx = rank Hz; then pi maps ker Hz \\ rs Hx onto ker Hx \\ rs Hz preserving weight, so dX = dZ.
For COLOR, identity: Hx = Hz. usage: dual_check.py MATRIX_PREFIX l m | MATRIX_PREFIX identity"""
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
prefix = sys.argv[1]; hx = rows(prefix + '_Hx.txt'); hz = rows(prefix + '_Hz.txt')
if sys.argv[2] == 'identity':
    print(prefix.split('/')[-1], 'identity: Hx == Hz', hx == hz, 'as sets', set(hx) == set(hz)); sys.exit()
l, m = int(sys.argv[2]), int(sys.argv[3]); N = 2 * l * m; h0 = l * m
def pi(i):
    half = i // h0; x = i % h0; a, b = x // m, x % m
    return (1 - half) * h0 + ((l - a) % l) * m + ((m - b) % m)
perm = [pi(i) for i in range(N)]; assert sorted(perm) == list(range(N))
def image(v):
    o = 0; i = 0
    while v:
        low = v & -v; o |= 1 << perm[low.bit_length() - 1]; v ^= low
    return o
bx, bz = basis(hx), basis(hz)
print(prefix.split('/')[-1], f'halfswap-inverse Z_{l} x Z_{m}: rank Hx {len(bx)} rank Hz {len(bz)}',
      'pi(Hz) in rs Hx:', all(inspan(bx, image(r)) for r in hz), 'pi(Hx) in rs Hz:', all(inspan(bz, image(r)) for r in hx))
