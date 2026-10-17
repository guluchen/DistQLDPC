#!/usr/bin/env python3
"""GH-129 random small CSS codes, second set (larger distances than gen_random_codes.py, which gave mostly d=1).
Families (each code then gets a random qubit permutation and random row mixing: every row of Hx/Hz is XORed
in place with 0-2 other current rows of the same matrix (elementary row operations), plus 0-2 appended redundant row sums; row spaces are unchanged,
so the code is equivalent but the parity rows the frontier rule sees are different and denser):
  tor: HGP(cyclic repetition a, cyclic repetition b), a, b in 3..6 (toric-like, d = min(a, b));
  hgp: HGP of random classical codes with column weight 3 (n1 in 6..9);
  tz:  a tier0 benchmark code (expected d from its stem).
Gx/Gz from scripts/compute_logicals.py. Usage: gen_random_codes2.py OUTDIR COUNT SEED REPO"""
import random, subprocess, sys
from pathlib import Path

def read(path):
    rows = []
    for line in Path(path).read_text().splitlines():
        bits = [c for c in line if c in "01"]
        if bits: rows.append(sum(1 << i for i, c in enumerate(bits) if c == "1"))
    n = len([c for c in Path(path).read_text().splitlines()[0] if c in "01"])
    return n, rows

def write(path, rows, n):
    path.write_text("\n".join(" ".join(str((r >> c) & 1) for c in range(n)) for r in rows) + "\n")

def hgp_mats(H1, n1, H2, n2):
    m1, m2 = len(H1), len(H2)
    bit = lambda H, i, a: (H[i] >> a) & 1
    Hx, Hz = [], []
    for i in range(m1):
        for b in range(n2):
            v = 0
            for a in range(n1):
                if bit(H1, i, a): v |= 1 << (a * n2 + b)
            for j in range(m2):
                if bit(H2, j, b): v |= 1 << (n1 * n2 + i * m2 + j)
            Hx.append(v)
    for a in range(n1):
        for j in range(m2):
            v = 0
            for b in range(n2):
                if bit(H2, j, b): v |= 1 << (a * n2 + b)
            for i in range(m1):
                if bit(H1, i, a): v |= 1 << (n1 * n2 + i * m2 + j)
            Hz.append(v)
    return n1 * n2 + m1 * m2, Hx, Hz

def cyc(a):
    return [(1 << i) | (1 << ((i + 1) % a)) for i in range(a)]

def randcl(rng):
    n = rng.randint(6, 9); m = rng.randint(4, n - 1)
    H = [0] * m
    for c in range(n):
        for i in rng.sample(range(m), 3): H[i] |= 1 << c
    return n, H

def permute(rows, perm):
    out = []
    for r in rows:
        v = 0
        for c, p in enumerate(perm):
            if (r >> c) & 1: v |= 1 << p
        out.append(v)
    return out

def mix(rows, rng):
    out = list(rows)
    for i in range(len(out)):   # in-place elementary row operations (invertible: row space unchanged)
        for j in rng.sample(range(len(rows)), min(len(rows), rng.randint(0, 2))):
            if j != i: out[i] ^= out[j]
    for _ in range(rng.randint(0, 2)):
        a, b = rng.sample(range(len(rows)), 2) if len(rows) > 1 else (0, 0)
        out.append(rows[a] ^ rows[b])
    return [r for r in out if r]

def main():
    out, count, seed, repo = Path(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
    out.mkdir(parents=True, exist_ok=True)
    rng = random.Random(seed)
    t0 = sorted({p.name[:-7] for p in Path(repo, "data/matrices/tier0").glob("*_Hx.txt")})
    made = 0
    while made < count:
        fam = ("tor", "hgp", "tz")[made % 3]
        if fam == "tor":
            a, b = rng.randint(3, 6), rng.randint(3, 6)
            n, Hx, Hz = hgp_mats(cyc(a), a, cyc(b), b); tag = f"{a}x{b}"
        elif fam == "hgp":
            n1, H1 = randcl(rng); n2, H2 = randcl(rng)
            n, Hx, Hz = hgp_mats(H1, n1, H2, n2); tag = f"{n1}x{n2}"
        else:
            stem = rng.choice(t0)
            n, Hx = read(f"{repo}/data/matrices/tier0/{stem}_Hx.txt"); _, Hz = read(f"{repo}/data/matrices/tier0/{stem}_Hz.txt")
            tag = stem.replace("_", "")
        perm = list(range(n)); rng.shuffle(perm)
        Hx, Hz = mix(permute(Hx, perm), rng), mix(permute(Hz, perm), rng)
        assert all(bin(x & z).count("1") % 2 == 0 for x in Hx for z in Hz)
        stem = f"R129{fam}{made:03d}{tag}"
        write(out / f"{stem}_Hx.txt", Hx, n); write(out / f"{stem}_Hz.txt", Hz, n)
        r = subprocess.run([sys.executable, f"{repo}/scripts/compute_logicals.py", "--dir", str(out), stem], capture_output=True, text=True)
        gx = out / f"{stem}_Gx.txt"
        if r.returncode != 0 or not gx.exists() or not gx.read_text().strip():
            for s in ("Hx", "Hz", "Gx", "Gz"): (out / f"{stem}_{s}.txt").unlink(missing_ok=True)
            continue
        print(stem, n, len(Hx), len(Hz)); made += 1

main()
