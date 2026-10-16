#!/usr/bin/env python3
"""GH-127 S0: random small CSS codes for the orbit-split / ladder oracle (answers compared with -engine=cc).
Families (deterministic from --seed):
  qc2  two-block circulant  Hx=[A|B], Hz=[B^T|A^T], A,B random circulants (l x l)        -> 2 orbits typical
  bb   bivariate bicycle    A,B sums of 3 monomials x^a, y^b on Z_l x Z_m                 -> 2 orbits typical
  lp   lifted product over Z_L, A (mA x nA), B (mB x nB) random polynomial matrices:
       Hx=[A(x)I_mB | I_mA(x)B], Hz=[I_nA(x)B^T | A^T(x)I_nB] (lifted)                     -> nA*mB+mA*nB orbits
  hgp  hypergraph product of two random cyclic codes                                       -> few orbits
  rnd  unstructured: random sparse Hx, Hz = random sparse vectors of ker(Hx)                -> no symmetry
Writes STEM_Hx.txt / STEM_Hz.txt into OUTDIR; Gx/Gz are then made with scripts/compute_logicals.py.
Usage: gen_random.py OUTDIR [--seed S] [--count N]"""
import argparse, os, random


def circ(L, exps):
    M = [[0] * L for _ in range(L)]
    for t in range(L):
        for e in exps:
            M[t][(t + e) % L] ^= 1
    return M


def zeros(r, c):
    return [[0] * c for _ in range(r)]


def T(M):
    return [list(r) for r in zip(*M)] if M else []


def hcat(*Ms):
    return [sum((M[i] for M in Ms), []) for i in range(len(Ms[0]))]


def lift(P, L):
    """P: block matrix of exponent lists (None = 0 block)."""
    R, C = len(P), len(P[0])
    M = zeros(R * L, C * L)
    for i in range(R):
        for j in range(C):
            if P[i][j] is None:
                continue
            c = circ(L, P[i][j])
            for a in range(L):
                for b in range(L):
                    M[i * L + a][j * L + b] = c[a][b]
    return M


def kron_I_right(P, k):   # P (x) I_k on block level
    R, C = len(P), len(P[0])
    return [[P[i][j] if p == q else None for j in range(C) for q in range(k)] for i in range(R) for p in range(k)]


def kron_I_left(k, P):    # I_k (x) P on block level
    R, C = len(P), len(P[0])
    return [[P[i][j] if a == b else None for b in range(k) for j in range(C)] for a in range(k) for i in range(R)]


def rank2(M):
    rows = [int("".join(map(str, r)), 2) for r in M if any(r)]
    basis = []
    for v in rows:
        for b in basis:
            v = min(v, v ^ b)
        if v:
            basis.append(v)
    return len(basis)


def kernel(M, n):
    rows = [r[:] for r in M]
    piv = []
    r = 0
    for c in range(n):
        p = next((i for i in range(r, len(rows)) if rows[i][c]), None)
        if p is None:
            continue
        rows[r], rows[p] = rows[p], rows[r]
        for i in range(len(rows)):
            if i != r and rows[i][c]:
                rows[i] = [x ^ y for x, y in zip(rows[i], rows[r])]
        piv.append(c)
        r += 1
    free = [c for c in range(n) if c not in piv]
    K = []
    for f in free:
        v = [0] * n
        v[f] = 1
        for i, c in enumerate(piv):
            if rows[i][f]:
                v[c] = 1
        K.append(v)
    return K


def rpoly(rng, L, w):
    return sorted(rng.sample(range(L), min(w, L)))


NMAX = 64


def gen(fam, rng):
    if fam == "qc2":
        l = rng.randint(6, 24 if NMAX <= 64 else 60)
        A, B = circ(l, rpoly(rng, l, rng.choice([2, 3]))), circ(l, rpoly(rng, l, rng.choice([2, 3])))
        return hcat(A, B), hcat(T(B), T(A)), "qc2_l%d" % l
    if fam == "bb":
        l, m = rng.choice([(3, 3), (3, 4), (4, 4), (3, 5), (4, 5), (3, 6), (5, 5), (4, 6), (3, 7)] if NMAX <= 64 else
                          [(4, 6), (3, 7), (5, 5), (3, 9), (6, 6), (4, 9), (6, 7), (5, 8), (6, 8), (7, 7), (6, 9), (8, 8)])
        def mono(kind, e):
            S = circ(l if kind == "x" else m, [e])
            I = [[int(i == j) for j in range(m if kind == "x" else l)] for i in range(m if kind == "x" else l)]
            X, Y = (S, I) if kind == "x" else (I, S)
            return [[X[i // m][j // m] & Y[i % m][j % m] for j in range(l * m)] for i in range(l * m)]
        def poly():
            M = zeros(l * m, l * m)
            for _ in range(3):
                kind = rng.choice("xy")
                P = mono(kind, rng.randrange(l if kind == "x" else m))
                M = [[a ^ b for a, b in zip(r, s)] for r, s in zip(M, P)]
            return M
        A, B = poly(), poly()
        return hcat(A, B), hcat(T(B), T(A)), "bb_%dx%d" % (l, m)
    if fam == "lp":
        (mA, nA), (mB, nB) = rng.choice([((1, 2), (1, 1)), ((1, 3), (1, 1)), ((1, 2), (1, 2)), ((2, 3), (1, 1)), ((1, 2), (2, 2))])
        L = rng.randint(3, 9 if NMAX <= 64 else 24)
        while (nA * mB + mA * nB) * L > NMAX:
            L -= 1
        PA = [[rpoly(rng, L, rng.choice([1, 2])) for _ in range(nA)] for _ in range(mA)]
        PB = [[rpoly(rng, L, rng.choice([1, 2])) for _ in range(nB)] for _ in range(mB)]
        Hx = hcat(lift(kron_I_right(PA, mB), L), lift(kron_I_left(mA, PB), L))
        # Hz = [I_nA (x) B^T | A^T (x) I_nB] in lifted form (transposes of the lifted blocks; abelian group)
        X1 = lift(kron_I_left(nA, PB), L)            # (nA mB) x (nA nB) ... rows index (a, i_B), cols (a, j_B)
        X2 = lift(kron_I_right(PA, nB), L)           # (mA nB) x (nA nB)
        Hz = hcat(T(X1), T(X2))
        return Hx, Hz, "lp_%dx%d_%dx%d_L%d" % (mA, nA, mB, nB, L)
    if fam == "hgp":
        n1, n2 = rng.randint(3, 5), rng.randint(3, 6)
        H1, H2 = circ(n1, rpoly(rng, n1, 2)), circ(n2, rpoly(rng, n2, rng.choice([2, 3])))
        I1 = [[int(i == j) for j in range(n1)] for i in range(n1)]
        I2 = [[int(i == j) for j in range(n2)] for i in range(n2)]
        kr = lambda P, Q: [[P[i // len(Q)][j // len(Q[0])] & Q[i % len(Q)][j % len(Q[0])] for j in range(len(P[0]) * len(Q[0]))] for i in range(len(P) * len(Q))]
        Hx = hcat(kr(H1, I2), kr(I1, T(H2)))
        Hz = hcat(kr(I1, H2), kr(T(H1), I2))
        return Hx, Hz, "hgp_%dx%d" % (n1, n2)
    n = rng.randint(12, 30)
    r = rng.randint(n // 4, n // 2)
    Hx = [[0] * n for _ in range(r)]
    for row in Hx:
        for c in rng.sample(range(n), 4):
            row[c] = 1
    K = kernel(Hx, n)
    Hz = []
    for _ in range(rng.randint(len(K) // 4 + 1, max(1, len(K) // 2))):
        v = [0] * n
        for b in rng.sample(K, rng.choice([1, 2])):
            v = [x ^ y for x, y in zip(v, b)]
        if any(v):
            Hz.append(v)
    return Hx, Hz, "rnd_n%d" % n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("outdir"); ap.add_argument("--seed", type=int, default=127); ap.add_argument("--count", type=int, default=60)
    ap.add_argument("--families", default="qc2,bb,lp,hgp,rnd"); ap.add_argument("--nmax", type=int, default=64)
    ap.add_argument("--prefix", default="r")
    a = ap.parse_args()
    os.makedirs(a.outdir, exist_ok=True)
    rng = random.Random(a.seed)
    fams = a.families.split(",")
    global NMAX
    NMAX = a.nmax
    made = 0
    tries = 0
    while made < a.count and tries < 50 * a.count:
        tries += 1
        fam = fams[made % len(fams)]
        Hx, Hz, tag = gen(fam, rng)
        n = len(Hx[0])
        if n > a.nmax or any(len(r) != n for r in Hx + Hz):
            continue
        if any(sum(x & y for x, y in zip(r, s)) % 2 for r in Hx for s in Hz):
            raise SystemExit("non-commuting %s" % tag)
        k = n - rank2(Hx) - rank2(Hz)
        if k < 1:
            continue
        stem = "%s%03d_%s" % (a.prefix, made, tag)
        for name, M in (("Hx", Hx), ("Hz", Hz)):
            with open(os.path.join(a.outdir, "%s_%s.txt" % (stem, name)), "w") as f:
                for row in M:
                    f.write(" ".join(map(str, row)) + "\n")
        print(stem, "n=%d k=%d" % (n, k))
        made += 1


if __name__ == "__main__":
    main()
