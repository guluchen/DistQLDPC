#!/usr/bin/env python3
"""GH-129: random small CSS codes for the -frontier vs -engine=cc cross-check.
Families: (hgp) hypergraph products of random sparse classical codes; (rnd) random sparse Hx with
Hz rows = sums of 1-3 random kernel basis vectors of Hx (so Hx Hz^T = 0). Writes {stem}_{Hx,Hz}.txt,
then Gx/Gz with the repo's scripts/compute_logicals.py. Codes with k = 0 are skipped.
Usage: gen_random_codes.py OUTDIR COUNT SEED REPO"""
import random, subprocess, sys
from pathlib import Path

def rank_kernel(rows, n):
    """RREF over GF(2); returns kernel basis (list of int bitmasks) of the row space's orthogonal."""
    piv = {}
    for r in rows:
        v = r
        for p, b in piv.items():
            if (v >> p) & 1: v ^= b
        if v:
            p = (v & -v).bit_length() - 1
            for q in list(piv):
                if (piv[q] >> p) & 1: piv[q] ^= v
            piv[p] = v
    free = [c for c in range(n) if c not in piv]
    ker = []
    for f in free:
        v = 1 << f
        for p, b in piv.items():
            if (b >> f) & 1: v |= 1 << p
        ker.append(v)
    return ker

def sparse_rows(m, n, wmin, wmax, rng):
    rows = []
    for _ in range(m):
        w = rng.randint(wmin, min(wmax, n))
        v = 0
        for c in rng.sample(range(n), w): v |= 1 << c
        rows.append(v)
    return rows

def write(path, rows, n):
    path.write_text("\n".join(" ".join(str((r >> c) & 1) for c in range(n)) for r in rows) + "\n")

def hgp(rng):
    n1, n2 = rng.randint(5, 7), rng.randint(5, 7)
    m1, m2 = rng.randint(3, n1 - 1), rng.randint(3, n2 - 1)
    H1 = [[0] * n1 for _ in range(m1)]; H2 = [[0] * n2 for _ in range(m2)]
    for H, m, nn in ((H1, m1, n1), (H2, m2, n2)):
        for c in range(nn):   # every column weight 2 (classical distance >= 2 once columns differ)
            for i in rng.sample(range(m), 2): H[i][c] = 1
    N = n1 * n2 + m1 * m2
    Hx, Hz = [], []
    for i in range(m1):
        for b in range(n2):
            v = 0
            for a in range(n1):
                if H1[i][a]: v |= 1 << (a * n2 + b)
            for j in range(m2):
                if H2[j][b]: v |= 1 << (n1 * n2 + i * m2 + j)
            Hx.append(v)
    for a in range(n1):
        for j in range(m2):
            v = 0
            for b in range(n2):
                if H2[j][b]: v |= 1 << (a * n2 + b)
            for i in range(m1):
                if H1[i][a]: v |= 1 << (n1 * n2 + i * m2 + j)
            Hz.append(v)
    return N, Hx, Hz

def rnd(rng):
    n = rng.randint(14, 40)
    Hx = sparse_rows(rng.randint(n // 4, n // 2), n, 3, 6, rng)
    ker = rank_kernel(Hx, n)
    Hz = []
    for _ in range(rng.randint(max(1, len(ker) // 3), max(1, len(ker) - 2))):
        v = 0
        for b in rng.sample(ker, rng.randint(1, min(3, len(ker)))): v ^= b
        if v: Hz.append(v)
    return n, Hx, Hz

def main():
    global PREFIX
    out, count, seed, repo = Path(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
    PREFIX = sys.argv[5] if len(sys.argv) > 5 else ''
    out.mkdir(parents=True, exist_ok=True)
    rng = random.Random(seed)
    made = 0; tries = 0
    while made < count and tries < 50 * count:
        tries += 1
        fam = "hgp" if made % 2 == 0 else "rnd"
        n, Hx, Hz = (hgp if fam == "hgp" else rnd)(rng)
        if not Hx or not Hz: continue
        assert all(bin(a & b).count("1") % 2 == 0 for a in Hx for b in Hz)
        stem = f"R129{PREFIX}{fam}{made:03d}"
        write(out / f"{stem}_Hx.txt", Hx, n); write(out / f"{stem}_Hz.txt", Hz, n)
        r = subprocess.run([sys.executable, f"{repo}/scripts/compute_logicals.py", "--dir", str(out), stem], capture_output=True, text=True)
        gx = out / f"{stem}_Gx.txt"
        if r.returncode != 0 or not gx.exists() or not gx.read_text().strip():
            for s in ("Hx", "Hz", "Gx", "Gz"):
                (out / f"{stem}_{s}.txt").unlink(missing_ok=True)
            continue
        print(stem, n, len(Hx), len(Hz)); made += 1

PREFIX = ''
main()
