#!/usr/bin/env python3
"""Original periodic square-toric matrices; Kitaev quant-ph/9707021v1 Sec.1.

GPL-3.0-or-later. No third-party code or matrices used.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('toric_cases.json')


def checks(length):
    if length < 3:raise ValueError('simple square cellulation requires L>=3')
    l=length;n=2*l*l
    def edge(axis,x,y):return axis*l*l+(y%l)*l+x%l
    hx=[];hz=[]
    for y in range(l):
        for x in range(l):
            hx.append(sum(1 << q for q in (edge(0,x,y),edge(0,x-1,y),edge(1,x,y),edge(1,x,y-1))))
            hz.append(sum(1 << q for q in (edge(0,x,y),edge(1,x+1,y),edge(0,x,y+1),edge(1,x,y))))
    return n,hx,hz


def generate(length,out):
    n,hx,hz=checks(length);stem=f'TOR_{n}_2_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{k}.txt').exists() for k in ('Hx','Hz','Gx','Gz')):
        raise FileExistsError('refusing to overwrite existing code')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(f'# periodic square toric L={length}; {kind}; Kitaev quant-ph/9707021v1\n'+
            ''.join(' '.join(str((r>>q)&1) for q in range(n))+'\n' for r in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--length',type=int);g.add_argument('--all',action='store_true')
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');a=ap.parse_args()
    for l in ([c['length'] for c in json.loads(CASES.read_text())] if a.all else [a.length]):print(generate(l,a.out))


if __name__=='__main__':main()
