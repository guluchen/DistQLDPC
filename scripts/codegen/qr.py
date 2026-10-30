#!/usr/bin/env python3
"""Original binary prime QR CSS cyclic-ideal construction (GPL3+).

Ketkar et al. quant-ph/0508070v2 Sec9; Grassl QIP22:86 Prop7;
Zurel--Jana--de Silva2603.18560v2 Theorem3/Corollary4. Dense CSS, not LDPC.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=json.loads(Path(__file__).with_name('qr_cases.json').read_text())


def prime(n):
    return type(n) is int and n>=2 and all(n%d for d in range(2,int(n**0.5)+1))


def rotate(word,shift,n):
    shift%=n
    return ((word << shift)|(word >> (n-shift)))&((1 << n)-1)


def checks(case):
    n=case['n']
    if not prime(n) or n%8!=7 or n>3000 or case['k']!=1:
        raise ValueError('binary CSS QR requires prime n=7 mod8, n<=3000, k=1')
    q={i*i%n for i in range(1,n)}
    if len(q)!=(n-1)//2 or 2 not in q or n-1 in q:
        raise ValueError('quadratic residue source conditions fail')
    e=1+sum(1 << i for i in q);basis={};rows=[];shifts=[]
    for shift in range(n):
        original=rotate(e,shift,n);row=original
        while row:
            pivot=row.bit_length()-1
            if pivot in basis:row^=basis[pivot]
            else:basis[pivot]=row;rows.append(original);shifts.append(shift);break
    if n-2*len(rows)!=case['k'] or any(bin(a&b).count('1')%2 for a in rows for b in rows):
        raise ValueError('actual quantum dimension or CSS commutation differs; stop before writes')
    return n,rows,dict(id=case['id'],n=n,k=case['k'],stem=f'QR_{n}_1_unknown',
        selected_shifts=shifts,idempotent_support=[0]+sorted(q),rank_Hx=len(rows),rank_Hz=len(rows),
        physical_convention='coefficient X^i is qubit i; shifts increasing, first independent physical rows')


def generate(case,out):
    n,rows,receipt=checks(case);stem=receipt['stem']
    if any((out/(stem+'_'+kind+'.txt')).exists() for kind in ('Hx','Hz','Gx','Gz')):
        raise FileExistsError('refusing overwrite '+stem)
    out.mkdir(parents=True,exist_ok=True)
    for kind in ('Hx','Hz'):
        with (out/(stem+'_'+kind+'.txt')).open('w') as f:
            f.write(f'# Binary QR CSS {case["id"]}; {kind}; physical X^i; dense CSS\n')
            for row in rows:f.write(' '.join(str((row >> j)&1) for j in range(n))+'\n')
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset',
                    '--dir',str(out),stem],check=True)
    return receipt


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    choice=ap.add_mutually_exclusive_group(required=True)
    choice.add_argument('--all',action='store_true');choice.add_argument('--case',choices=[c['id'] for c in CASES])
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered')
    ap.add_argument('--receipt',type=Path)
    a=ap.parse_args();results=[generate(c,a.out) for c in CASES if a.all or c['id']==a.case]
    text=json.dumps(results,indent=2)+'\n'
    if a.receipt:a.receipt.write_text(text)
    else:print(text,end='')


if __name__=='__main__':main()
