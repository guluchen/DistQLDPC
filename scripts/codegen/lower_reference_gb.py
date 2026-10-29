#!/usr/bin/env python3
"""Original Mostad-Rosnes-Lin TableII cyclic GB construction; GPL-3.0-or-later.

Published mathematics credited in NOTICE; no author software/matrix/prose copied.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('lower_reference_gb_cases.json')


def build(c):
    l=c['l']
    if type(l)!=int or l<2 or c['n']!=2*l:raise ValueError('invalid cyclic length')
    for name in ('a','b'):
        s=c[name]
        if not s or len(s)!=len(set(s)) or any(type(e)!=int or not 0<=e<l for e in s):
            raise ValueError('invalid polynomial support')
    hx=[];hz=[]
    for r in range(l):
        hx.append(sum(1<<(block*l+(r-e)%l) for block,name in enumerate(('a','b')) for e in c[name]))
        hz.append(sum(1<<(block*l+(r+e)%l) for block,name in enumerate(('b','a')) for e in c[name]))
    return 2*l,hx,hz


def generate(c,out):
    n,hx,hz=build(c);stem=f'GB_{n}_{c["k"]}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):
        raise FileExistsError('refusing overwrite')
    for kind,rows in [('Hx',hx),('Hz',hz)]:
        (out/f'{stem}_{kind}.txt').write_text(f'# original MRL2025 GB {c["id"]}; {kind}; DOI10.1109/JSAIT.2025.3594310 TableII; first-column convention\n'+
            ''.join(' '.join(str((w>>q)&1) for q in range(n))+'\n' for w in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--n',type=int);g.add_argument('--all',action='store_true')
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');a=ap.parse_args()
    cases=[c for c in json.loads(CASES.read_text()) if a.all or c['n']==a.n]
    if not cases:ap.error('unknown frozen reference')
    for c in cases:print(generate(c,a.out),flush=True)


if __name__=='__main__':main()
