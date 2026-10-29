#!/usr/bin/env python3
"""Original weight-8 BB generator; Lu-Yang-Guo 2609.06572v1, GPL-3.0-or-later.

No third-party implementation or matrix data copied. Polynomial parameters
are mathematical facts from Tables 1-3. All coordinates are modulo (l,m).
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=json.loads(Path(__file__).with_name('weight8_bb_cases.json').read_text())


def checks(case):
    l,m=case['l'],case['m']
    if l<1 or m<1: raise ValueError('positive grid dimensions required')
    v=l*m
    hx,hz=[],[]
    for x in range(l):
        for y in range(m):
            a=b=aa=bb=0
            for dx,dy in case['A']:
                a ^= 1 << (((x+dx)%l)*m+(y+dy)%m)
                aa ^= 1 << (((x-dx)%l)*m+(y-dy)%m)
            for dx,dy in case['B']:
                b ^= 1 << (((x+dx)%l)*m+(y+dy)%m)
                bb ^= 1 << (((x-dx)%l)*m+(y-dy)%m)
            hx.append(a | (b << v))
            hz.append(bb | (aa << v))
    return 2*v,hx,hz


def generate(case,out):
    from validate_css import basis
    n,hx,hz=checks(case)
    k=n-len(basis(hx))-len(basis(hz))
    if (n,k)!=(case['n'],case['k']):
        raise ValueError(f'published dimensions mismatch: observed {(n,k)}')
    if any(bin(r).count('1')!=8 for r in hx+hz):
        raise ValueError('selected case does not have weight-8 checks')
    stem=f'BB_{n}_{k}_unknown'
    out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):
        raise FileExistsError(f'{stem}: refusing overwrite')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(
            f'# weight-8 BB; {kind}; arXiv:2609.06572v1 Table {case["table"]} row {case["row"]}; l={case["l"]} m={case["m"]}\n'+
            ''.join(' '.join(str((r >> i)&1) for i in range(n))+'\n' for r in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),
                    '--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    group=ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--case',choices=[f'{c["n"]}-{c["k"]}' for c in CASES])
    group.add_argument('--all',action='store_true')
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered')
    args=ap.parse_args()
    for c in CASES if args.all else [c for c in CASES if f'{c["n"]}-{c["k"]}'==args.case]:
        print(generate(c,args.out),flush=True)


if __name__=='__main__':main()
