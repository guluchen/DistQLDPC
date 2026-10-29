#!/usr/bin/env python3
"""Original binary expansion of Lee2610.06820v1 group-valued PP mathematics.

GPL-3.0-or-later. Numeric facts cited; no third-party code/matrix files copied.
"""
import argparse
import json
import math
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('quaternary_pp_cases.json')
# Multiplication matrices in trace-self-dual basis (omega,omega^2), Eq35.
RHO=(((0,0),(0,0)),((1,0),(0,1)),((0,1),(1,1)),((1,1),(1,0)))


def coordinates(g,moduli):
    out=[]
    for m in moduli:out.append(g%m);g//=m
    if g:raise ValueError('group label out of range')
    return out


def encode(xs,moduli):
    value=0;scale=1
    for x,m in zip(xs,moduli):value+=(x%m)*scale;scale*=m
    return value


def add(a,b,moduli):return encode([x+y for x,y in zip(coordinates(a,moduli),coordinates(b,moduli))],moduli)


def negative(a,moduli):return encode([-x for x in coordinates(a,moduli)],moduli)


def checks(c):
    moduli=c['group_moduli'];p=math.prod(moduli);coeff=c['C'];exp=c['E'];choices=c['row_choices']
    if not moduli or any(m<1 for m in moduli) or len(coeff)!=3 or len(exp)!=3 or len(choices)!=3:raise ValueError('invalid shape/group')
    if any(len(row)!=8 or any(v not in (0,1,2,3) for v in row) for row in coeff):raise ValueError('GF4 array malformed')
    if any(len(row)!=8 or any(v<0 or v>=p for v in row) for row in exp):raise ValueError('group labels malformed')
    for pair in choices:
        if len(pair)!=2 or len(set(pair))!=2 or any(t not in (0,1,2) for t in pair):raise ValueError('row pair must be independent')
    matrices=[]
    for half in (0,1):
        raw=[[0]*p for _ in range(6)]
        for i in range(3):
            for ell in range(8):
                src=(ell+4)%8 if half else ell
                e=negative(exp[i][src],moduli) if half else exp[i][src]
                for a in range(2):
                    for b in range(2):
                        if not RHO[coeff[i][src]][a][b]:continue
                        for g in range(p):
                            h=add(g,negative(e,moduli),moduli)
                            raw[2*i+a][g] ^= 1 << ((2*ell+b)*p+h)
        rows=[]
        for i,pair in enumerate(choices):
            variants=(raw[2*i],raw[2*i+1],[x^y for x,y in zip(raw[2*i],raw[2*i+1])])
            for t in pair:rows.extend(variants[t])
        matrices.append(rows)
    n=16*p
    if n!=c['n']:raise ValueError('source length mismatch')
    return n,*matrices


def generate(c,out):
    n,hx,hz=checks(c);stem=f'PP_{n}_{c["k"]}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{k}.txt').exists() for k in ('Hx','Hz','Gx','Gz')):raise FileExistsError('refusing overwrite')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(f'# original quaternary group-valued PP; {kind}; Lee arXiv2610.06820v1; {c["source_id"]}\n'+
            ''.join(' '.join(str((r>>q)&1) for q in range(n))+'\n' for r in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True);g.add_argument('--n',type=int);g.add_argument('--all',action='store_true')
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');a=ap.parse_args();cases=[c for c in json.loads(CASES.read_text()) if a.all or c['n']==a.n]
    if not cases:ap.error('unknown fixed reference')
    for c in cases:print(generate(c,a.out),flush=True)


if __name__=='__main__':main()
