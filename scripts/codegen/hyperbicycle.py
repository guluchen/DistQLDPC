#!/usr/bin/env python3
"""Original repeated-cyclic CSS hyperbicycle construction, GPL-3.0-or-later.

Kovalev--Pryadko arXiv:1212.6703v2 Eq19, chi=1 only. Source G_X/G_Z
are stabilizers; repository Gx/Gz are complete logical quotient bases.
No author code or matrices are used. Distance is not computed here.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))
from validate_css import basis, dot

CASES = json.loads(Path(__file__).with_name('hyperbicycle_cases.json').read_text())


def blocks(n, c, exponents):
    """Top block row of a row-right circulant of order c*n."""
    if type(n) is not int or type(c) is not int or n < 1 or c < 1:
        raise ValueError('positive integer block length and count required')
    if not exponents or any(type(e) is not int or e < 0 or e >= c*n
                            for e in exponents) or len(set(exponents)) != len(exponents):
        raise ValueError('distinct nonnegative reduced exponents required')
    out = [[0]*n for _ in range(c)]
    for r in range(n):
        for e in exponents:
            i, col = divmod((r+e) % (c*n), n)
            out[i][r] ^= 1 << col
    return out


def transpose(rows, n):
    return [sum(((row >> j) & 1) << i for i, row in enumerate(rows))
            for j in range(n)]


def positions(row):
    while row:
        bit = row & -row
        yield bit.bit_length()-1
        row ^= bit


def checks(case):
    if case['chi'] != 1:
        raise ValueError('only preregistered chi=1 is implemented')
    a, b, c = case['n1'], case['n2'], case['c']
    aa, bb = blocks(a,c,case['h1']), blocks(b,c,case['h2'])
    at, bt = [transpose(x,a) for x in aa], [transpose(x,b) for x in bb]
    volume = a*b*c
    def coord(v,s,u):
        return (v*c+s)*a+u
    hx, hz = [], []
    for v in range(b):
        for s in range(c):
            for u in range(a):
                x = z = 0
                for i in range(c):
                    for j in positions(aa[i][u]):
                        x ^= 1 << coord(v,(s+i)%c,j)
                    for j in positions(bb[i][v]):
                        x ^= 1 << (volume+coord(j,(s+i)%c,u))
                    for j in positions(bt[i][v]):
                        z ^= 1 << coord(j,(s-i)%c,u)
                    for j in positions(at[i][u]):
                        z ^= 1 << (volume+coord(v,(s-i)%c,j))
                hx.append(x)
                hz.append(z)
    return 2*volume, hx, hz


def generate(case, out):
    n, hx, hz = checks(case)
    k = n-len(basis(hx))-len(basis(hz))
    if n != case['n'] or k != case['k'] or k <= 0:
        raise ValueError('actual dimension disagrees with frozen reference; stop before writes')
    if any(dot(x,z) for x in hx for z in hz):
        raise ValueError('stabilizers do not commute; stop before writes')
    stem = f'LP_{n}_{k}_unknown'
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):
        raise FileExistsError('refusing to overwrite '+stem)
    out.mkdir(parents=True, exist_ok=True)
    for kind, rows in (('Hx',hx),('Hz',hz)):
        with (out/f'{stem}_{kind}.txt').open('w') as f:
            f.write(f'# CSS hyperbicycle {case["id"]}; {kind}; arXiv1212.6703v2 Eq19; chi1; c{case["c"]}\n')
            for row in rows:
                f.write(' '.join(str((row >> j) & 1) for j in range(n))+'\n')
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),
                    '--method','bitset','--dir',str(out),stem], check=True)
    return stem


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    group = ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--all',action='store_true')
    group.add_argument('--case',choices=[x['id'] for x in CASES])
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered')
    args = ap.parse_args()
    for case in CASES if args.all else [x for x in CASES if x['id']==args.case]:
        print(generate(case,args.out),flush=True)


if __name__ == '__main__':
    main()
