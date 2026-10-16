#!/usr/bin/env python3
"""Generate toric codes (L x L torus, n = 2L^2, k = 2, d = L) and unrotated planar surface codes
(n = L^2 + (L-1)^2, k = 1, d = L) as {stem}_Hx.txt / {stem}_Hz.txt (0/1 rows, space separated).
Gx/Gz are then produced with scripts/compute_logicals.py.
usage: gen_codes.py OUTDIR L [L ...]"""
import sys
from pathlib import Path


def write(path, rows, n, header):
    with open(path, "w") as f:
        f.write(f"# {header}\n")
        for r in rows:
            v = [0] * n
            for q in r:
                v[q] ^= 1
            f.write(" ".join(map(str, v)) + "\n")


def toric(L):
    n = 2 * L * L
    h = lambda i, j: (i % L) * L + (j % L)
    v = lambda i, j: L * L + (i % L) * L + (j % L)
    stars = [[h(i, j), h(i, j - 1), v(i, j), v(i - 1, j)] for i in range(L) for j in range(L)]
    plaqs = [[h(i, j), h(i + 1, j), v(i, j), v(i, j + 1)] for i in range(L) for j in range(L)]
    return n, stars, plaqs


def planar(L):
    N = 2 * L - 1
    idx = {}
    for r in range(N):
        for c in range(N):
            if (r + c) % 2 == 0:
                idx[(r, c)] = len(idx)
    n = len(idx)
    def nb(r, c):
        return [idx[(a, b)] for a, b in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)) if (a, b) in idx]
    xs = [nb(r, c) for r in range(1, N, 2) for c in range(0, N, 2)]
    zs = [nb(r, c) for r in range(0, N, 2) for c in range(1, N, 2)]
    return n, xs, zs


def check_commute(n, A, B):
    for a in A:
        sa = set(a)
        for b in B:
            if len(sa.intersection(b)) % 2:
                raise SystemExit("non-commuting stabilizers")


def main():
    out = Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
    for L in map(int, sys.argv[2:]):
        n, X, Z = toric(L)
        check_commute(n, X, Z)
        stem = f"TORIC_{n}_2_{L}"
        write(out / f"{stem}_Hx.txt", X, n, f"toric code L={L}: X-type stabilizers (stars)")
        write(out / f"{stem}_Hz.txt", Z, n, f"toric code L={L}: Z-type stabilizers (plaquettes)")
        n, X, Z = planar(L)
        check_commute(n, X, Z)
        stem = f"PLANAR_{n}_1_{L}"
        write(out / f"{stem}_Hx.txt", X, n, f"planar surface code L={L}: X-type stabilizers")
        write(out / f"{stem}_Hz.txt", Z, n, f"planar surface code L={L}: Z-type stabilizers")
        print("generated L", L)


if __name__ == "__main__":
    main()
