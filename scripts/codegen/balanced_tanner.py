#!/usr/bin/env python3
"""Original finite Tanner-cycle balanced products (GH-160), GPL-3.0-or-later.

General construction: Breuckmann-Eberhardt, arXiv:2012.09271v3 IV-D/E/F.
Fixed finite specializations, no subsystem selection or asymptotic claim.
"""
import argparse
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
LADDER=(3,5,7,11,19,37)
LABELS=((5,3,2,1,6,4,7),(2,1,5,6,7,3,4),
        (7,4,1,6,3,2,5),(3,1,4,2,7,6,5))


def factor(length):
    if length < 3 or length%2 != 1:
        raise ValueError('cycle length must be odd and >=3')
    vertices=4*length
    offsets=(1,2,3,vertices//2,vertices-3,vertices-2,vertices-1)
    edges=sorted({tuple(sorted((x,(x+s)%vertices))) for x in range(vertices) for s in offsets})
    index={e:i for i,e in enumerate(edges)}
    rows=[]
    for x in range(vertices):
        for bit in range(3):
            rows.append(sum(1 << index[tuple(sorted((x,(x+s)%vertices)))]
                            for j,s in enumerate(offsets) if (LABELS[x%4][j] >> bit)&1))
    edge_action=[index[tuple(sorted(((x+4)%vertices,(y+4)%vertices)))] for x,y in edges]
    check_action=[3*((x+4)%vertices)+bit for x in range(vertices) for bit in range(3)]
    return edges,rows,edge_action,check_action


def checks(length):
    edges,a,te,tc=factor(length)
    m,r=len(edges),len(a)
    # d1=[A, I+T0]; columns of I+T0 map a vertical check-cell to
    # itself and its deck translate. d2=[I+T1; A], Hz=d2^T.
    hx=a[:]
    for q,target in enumerate(tc):
        hx[q] ^= 1 << (m+q)
        hx[target] ^= 1 << (m+q)
    hz=[]
    for e,target in enumerate(te):
        row=(1 << e) ^ (1 << target)
        row ^= sum(((a[q] >> e)&1) << (m+q) for q in range(r))
        hz.append(row)
    return m+r,hx,hz


def generate(length,out):
    n,hx,hz=checks(length)
    # Verify the dimension before assigning a stem; never discard homology.
    from validate_css import basis
    k=n-len(basis(hx))-len(basis(hz))
    if k != 2:raise ValueError(f'expected full CSS k=2, observed {k}')
    stem=f'BP_{n}_{k}_unknown'
    out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):
        raise FileExistsError(f'{stem}: refusing to overwrite')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(
            f'# Tanner-cycle balanced product l={length}; full CSS; {kind}; arXiv:2012.09271v3 IV-E\n'+
            ''.join(' '.join(str((row >> j)&1) for j in range(n))+'\n' for row in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),
                    '--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    group=ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--length',type=int)
    group.add_argument('--ladder',action='store_true')
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered')
    args=ap.parse_args()
    for length in LADDER if args.ladder else (args.length,):
        print(generate(length,args.out),flush=True)


if __name__=='__main__':main()
