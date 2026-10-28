#!/usr/bin/env python3
"""Clean-room repetition-product HGP matrices (Tillich-Zemor, arXiv:0903.0566v2).

No third-party code or matrix files. GPL-3.0-or-later, like DistQLDPC.
Run from the repository root; computes logicals with scripts/compute_logicals.py.
"""
import argparse
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
LADDER = (3, 5, 8, 12, 16, 24)


def checks(length):
    """H=[R x I | I x R^T], J=[I x R | R^T x I], R_i=e_i+e_(i+1).

    Columns: (v1,v2), then (c1,c2), with the second index fastest.
    H rows: (c1,v2); J rows: (v1,c2). Both have L*(L-1) rows.
    """
    if length < 2:
        raise ValueError('length must be >= 2')
    l = length
    n = l*l + (l-1)*(l-1)
    hx, hz = [], []
    for c in range(l-1):
        for v in range(l):
            row = [0]*n
            row[c*l+v] = row[(c+1)*l+v] = 1
            for t in (v-1, v):
                if 0 <= t < l-1:
                    row[l*l+c*(l-1)+t] = 1
            hx.append(row)
    for v in range(l):
        for c in range(l-1):
            row = [0]*n
            row[v*l+c] = row[v*l+c+1] = 1
            for t in (v-1, v):
                if 0 <= t < l-1:
                    row[l*l+t*(l-1)+c] = 1
            hz.append(row)
    return hx, hz


def generate(length, out):
    hx, hz = checks(length)
    stem = f'HGP_{len(hx[0])}_1_unknown'
    out.mkdir(parents=True, exist_ok=True)
    paths = [out / f'{stem}_{kind}.txt' for kind in ('Hx','Hz','Gx','Gz')]
    if any(p.exists() for p in paths):
        raise FileExistsError(f'{stem}: refusing to overwrite existing matrices')
    for kind, rows in (('Hx', hx), ('Hz', hz)):
        (out / f'{stem}_{kind}.txt').write_text(
            f'# repetition HGP L={length}; {kind}; arXiv:0903.0566v2\n' +
            ''.join(' '.join(map(str, row))+'\n' for row in rows))
    subprocess.run([sys.executable, str(ROOT/'scripts/compute_logicals.py'),
                    '--dir', str(out), stem], check=True)
    return stem


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    group = ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--length', type=int)
    group.add_argument('--ladder', action='store_true')
    ap.add_argument('--out', type=Path, default=ROOT/'data/matrices/untiered')
    args = ap.parse_args()
    for length in LADDER if args.ladder else [args.length]:
        print(generate(length, args.out), flush=True)


if __name__ == '__main__':
    main()
