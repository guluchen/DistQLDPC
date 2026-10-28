#!/usr/bin/env python3
"""Triangular honeycomb CSS color codes, generated from geometry (GH-156).

Original implementation, GPL-3.0-or-later. Mathematical sources:
Bombin-Martin-Delgado, quant-ph/0605138; Sahay-Brown, arXiv:2108.11395v3,
Sec. II, Fig. 1, Eqs. (1)-(2). No external code or matrix data copied.
"""
import argparse
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
LADDER = (3, 5, 13, 21, 37, 61)


def patch(distance):
    """Return sites, face centers and packed check rows in row-major order.

    Oblique triangular coordinates: 0 <= c <= r <= 3*(d-1)/2.
    Delete sites r+c == 2 (mod 3) to form the honeycomb; those deleted
    positions are face centers. A check meets its six nearest neighbors,
    clipped to the triangular patch (four sites at a boundary).
    """
    if distance < 3 or distance % 2 != 1:
        raise ValueError('distance must be an odd integer >= 3')
    bound = 3*((distance-1)//2)
    sites, faces = [], []
    for r in range(bound+1):
        for c in range(r+1):
            (faces if (r+c)%3 == 2 else sites).append((r,c))
    index = {site:i for i,site in enumerate(sites)}
    rows = []
    for r,c in faces:
        support = [index[p] for dr,dc in ((-1,-1),(-1,0),(0,-1),(0,1),(1,0),(1,1))
                   if (p := (r+dr,c+dc)) in index]
        rows.append(sum(1 << i for i in support))
    return sites, faces, rows


def generate(distance, out):
    sites, _, rows = patch(distance)
    n = len(sites)
    stem = f'COLOR_{n}_1_unknown'
    out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):
        raise FileExistsError(f'{stem}: refusing to overwrite existing matrices')
    # File body is identical for Hx/Hz; preserve the distinct matrix label.
    body = ''.join(' '.join(str((row >> j)&1) for j in range(n))+'\n' for row in rows)
    for kind in ('Hx','Hz'):
        (out/f'{stem}_{kind}.txt').write_text(
            f'# triangular 6.6.6 color code d={distance}; {kind}; arXiv:2108.11395v3 Sec.II\n'+body)
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),
                    '--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    group = ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--distance',type=int)
    group.add_argument('--ladder',action='store_true')
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered')
    args = ap.parse_args()
    for d in LADDER if args.ladder else (args.distance,):
        print(generate(d,args.out),flush=True)


if __name__ == '__main__':
    main()
