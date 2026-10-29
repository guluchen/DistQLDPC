#!/usr/bin/env python3
"""Original Haah Code1 reconstruction from1101.1962v2 Fig1/TableI/Eq8.

No third-party constructor or matrix file. GPL-3.0-or-later.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[2]
# Fig1: B' is the back/lower/left origin; +x points forward,+y right,+z up.
CORNERS={'A':(1,0,1),'B':(1,1,1),'C':(1,0,0),'D':(1,1,0),
         'Ap':(0,1,0),'Bp':(0,0,0),'Cp':(0,1,1),'Dp':(0,0,1)}
Z_LABELS={'A':'ZI','B':'ZZ','C':'IZ','D':'ZI','Ap':'IZ','Bp':'II','Cp':'ZI','Dp':'IZ'}
CASES=json.loads(Path(__file__).with_name('haah_cubic_cases.json').read_text())


def index(L,x,y,z,s):return 2*(((x%L)*L+(y%L))*L+(z%L))+s


def matrices(L):
    if not isinstance(L,int) or L<1:raise ValueError('positive integer side required')
    z_terms=[(*CORNERS[name],s) for name,label in Z_LABELS.items() for s,p in enumerate(label) if p=='Z']
    x_terms=[(1-x,1-y,1-z,1-s) for x,y,z,s in z_terms]
    out=[]
    for terms in (x_terms,z_terms):
        rows=[]
        for x in range(L):
            for y in range(L):
                for z in range(L):
                    row=0
                    for dx,dy,dz,s in terms:row^=1<<index(L,x+dx,y+dy,z+dz,s)
                    rows.append(row)
        out.append(rows)
    return tuple(out)


def generate(c,out):
    from validate_css import basis
    L=c['L'];hx,hz=matrices(L);n=2*L**3;k=n-len(basis(hx))-len(basis(hz))
    if (n,k)!=(c['n'],c['k']):raise ValueError('actual finite rank disagrees with frozen dimensions')
    stem=f'HCC_{n}_{k}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):raise FileExistsError('refusing matrix overwrite')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(f'# Haah Code1 periodic L={L}; {kind}; arXiv1101.1962v2 Fig1/TableI/Eq8; original reconstruction\n'+''.join(' '.join(str((r>>q)&1) for q in range(n))+'\n' for r in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--all',action='store_true');g.add_argument('--L',type=int,choices=[c['L'] for c in CASES]);ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');args=ap.parse_args()
    for c in CASES:
        if args.all or c['L']==args.L:print(generate(c,args.out),flush=True)


if __name__=='__main__':main()
