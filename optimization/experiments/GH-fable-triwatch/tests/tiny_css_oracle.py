#!/usr/bin/env python3
"""Tiny CSS distance oracle for experiment GH-fable-triwatch (test-only).

Writes small CSS codes (Hx/Hz/Gx/Gz) into a temporary matrix directory, computes
the exact minimum Pauli weight of N(S)\\S by brute force over all 4^n Pauli
operators, and compares it with the distance printed by a DistQLDPC binary in
every cardinality mode. Exit status is non-zero on any mismatch.

usage: tiny_css_oracle.py <distqldpc-binary> [more binaries...]
"""
import itertools, os, subprocess, sys, tempfile

def rank_gf2(rows):
    rows = [r for r in rows]
    rank = 0
    ncols = len(rows[0]) if rows else 0
    for col in range(ncols):
        piv = None
        for i in range(rank, len(rows)):
            if rows[i][col]:
                piv = i; break
        if piv is None: continue
        rows[rank], rows[piv] = rows[piv], rows[rank]
        for i in range(len(rows)):
            if i != rank and rows[i][col]:
                rows[i] = [a ^ b for a, b in zip(rows[i], rows[rank])]
        rank += 1
    return rank

def in_rowspace(v, rows):
    if not rows: return not any(v)
    return rank_gf2(rows + [v]) == rank_gf2(rows)

def kernel_basis_mod_rowspace(H, R, n):
    """Rows z with H z = 0 that are independent modulo rowspace(R)."""
    basis = []
    for bits in itertools.product([0, 1], repeat=n):
        z = list(bits)
        if not any(z): continue
        if any(sum(h[i] & z[i] for i in range(n)) % 2 for h in H): continue
        if in_rowspace(z, R + basis): continue
        basis.append(z)
    return basis

def brute_distance(Hx, Hz, n):
    best = None
    for xbits in itertools.product([0, 1], repeat=n):
        if any(sum(h[i] & xbits[i] for i in range(n)) % 2 for h in Hz):
            continue
        x_in_S = in_rowspace(list(xbits), Hx)
        for zbits in itertools.product([0, 1], repeat=n):
            if any(sum(h[i] & zbits[i] for i in range(n)) % 2 for h in Hx):
                continue
            if not any(xbits) and not any(zbits):
                continue
            if x_in_S and in_rowspace(list(zbits), Hz):
                continue  # stabilizer
            w = sum(1 for i in range(n) if xbits[i] or zbits[i])
            if best is None or w < best:
                best = w
    return best

CODES = {
    # [[4,2,2]] code: Hx = Hz = [1 1 1 1]
    "T422": ([[1, 1, 1, 1]], [[1, 1, 1, 1]]),
    # Steane [[7,1,3]]
    "T713": ([[0, 0, 0, 1, 1, 1, 1], [0, 1, 1, 0, 0, 1, 1], [1, 0, 1, 0, 1, 0, 1]],
             [[0, 0, 0, 1, 1, 1, 1], [0, 1, 1, 0, 0, 1, 1], [1, 0, 1, 0, 1, 0, 1]]),
    # Shor [[9,1,3]]
    "T913": ([[1, 1, 1, 1, 1, 1, 0, 0, 0], [0, 0, 0, 1, 1, 1, 1, 1, 1]],
             [[1, 1, 0, 0, 0, 0, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 0, 0], [0, 0, 0, 1, 1, 0, 0, 0, 0],
              [0, 0, 0, 0, 1, 1, 0, 0, 0], [0, 0, 0, 0, 0, 0, 1, 1, 0], [0, 0, 0, 0, 0, 0, 0, 1, 1]]),
    # [[6,2,2]] asymmetric toy: Hx=[1 1 1 1 0 0; 0 0 1 1 1 1], Hz=[1 1 0 0 1 1]
    "T622": ([[1, 1, 1, 1, 0, 0], [0, 0, 1, 1, 1, 1]], [[1, 1, 0, 0, 1, 1]]),
    # distance-1 toy: a qubit untouched by any check
    "T511": ([[1, 1, 1, 1, 0]], [[1, 1, 1, 1, 0]]),
}

def write_matrix(path, rows):
    with open(path, "w") as f:
        for r in rows:
            f.write(" ".join(str(v) for v in r) + "\n")

def main():
    bins = sys.argv[1:]
    if not bins:
        print(__doc__); return 2
    tmp = tempfile.mkdtemp(prefix="tinycss_")
    failures = 0
    for name, (Hx, Hz) in CODES.items():
        n = len(Hx[0])
        Gx = kernel_basis_mod_rowspace(Hx, Hz, n)  # Z-type logicals: Hx z = 0, z not in row(Hz)
        Gz = kernel_basis_mod_rowspace(Hz, Hx, n)  # X-type logicals
        if not Gx or not Gz:
            print(f"{name}: no logical operators, skipped"); continue
        write_matrix(os.path.join(tmp, f"{name}_Hx.txt"), Hx)
        write_matrix(os.path.join(tmp, f"{name}_Hz.txt"), Hz)
        write_matrix(os.path.join(tmp, f"{name}_Gx.txt"), Gx)
        write_matrix(os.path.join(tmp, f"{name}_Gz.txt"), Gz)
        d = brute_distance(Hx, Hz, n)
        for b in bins:
            for mode in ["", "-no-card", "-card-mto", "-card-sinz", "-card-both-force"]:
                cmd = [b] + ([mode] if mode else []) + ["-cpu-lim=60", os.path.join(tmp, name)]
                out = subprocess.run(cmd, capture_output=True, text=True).stdout
                got = None
                for line in out.splitlines():
                    if line.startswith("o "):
                        got = int(line.split()[1])
                ok = (got == d)
                failures += 0 if ok else 1
                print(f"{name:5s} n={n} k={len(Gx)} brute d={d} | {os.path.basename(os.path.dirname(os.path.dirname(b)))}/{os.path.basename(b)} {mode or 'default':16s} -> {got} {'OK' if ok else 'MISMATCH'}")
    print("tiny CSS oracle:", "PASS" if failures == 0 else f"FAIL ({failures} mismatches)")
    return 0 if failures == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
