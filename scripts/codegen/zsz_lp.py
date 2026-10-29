#!/usr/bin/env python3
"""Original nonabelian ZSZ-LP generator, GPL-3.0-or-later (GH-166).

Hong 2607.27644v1 Eqs.1,5-10,13 and Tables 1/3. Full CSS data codes,
no fold/surgery/gauge substitution. No third-party implementation/data copied.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=json.loads(Path(__file__).with_name('zsz_lp_cases.json').read_text())


def parameters(case):
    l1,l2,q=case['l1'],case['l2'],case['q']
    if l1<2 or l2<2 or not 0<q<l1 or pow(q,l2,l1)!=1:
        raise ValueError('invalid finite semidirect-product parameters')
    return l1,l2,q


def multiply(case,g,h):
    l1,l2,q=parameters(case);a,b=g;c,d=h
    return ((a+pow(q,b%l2,l1)*c)%l1,(b+d)%l2)


def inverse(case,g):
    l1,l2,q=parameters(case);a,b=g
    return (-pow(q,-b,l1)*a%l1,-b%l2)


def regular(case,polynomial,left):
    l1,l2,_=parameters(case);size=l1*l2;rows=[0]*size
    for i in range(l1):
        for j in range(l2):
            col=i*l2+j
            for g in polynomial:
                u,v=multiply(case,g,(i,j)) if left else multiply(case,(i,j),g)
                rows[u*l2+v] ^= 1 << col
    return rows


def transpose(rows):
    size=len(rows)
    return [sum(((row >> j)&1) << i for i,row in enumerate(rows)) for j in range(size)]


def checks(case):
    l1,l2,_=parameters(case);size=l1*l2
    a,b=regular(case,case['a'],True),regular(case,case['b'],True)
    c,d=regular(case,case['c'],False),regular(case,case['dpoly'],False)
    at,bt,ct,dt=map(transpose,(a,b,c,d))
    hx=[a[i]|(b[i] << (2*size))|(ct[i] << (4*size)) for i in range(size)]
    hx += [(a[i] << size)|(b[i] << (3*size))|(dt[i] << (4*size)) for i in range(size)]
    hz=[c[i]|(d[i] << size)|(at[i] << (4*size)) for i in range(size)]
    hz += [(c[i] << (2*size))|(d[i] << (3*size))|(bt[i] << (4*size)) for i in range(size)]
    return 5*size,hx,hz,dict(left_seed=[a[i]|(b[i] << size) for i in range(size)],
                           right_seed=[c[i]|(d[i] << size) for i in range(size)])


def generate(case,out):
    from validate_css import basis
    n,hx,hz,seeds=checks(case)
    k=n-len(basis(hx))-len(basis(hz));size=n//5
    if (n,k)!=(case['n'],case['k']) or k!=size:raise ValueError('published dimensions mismatch')
    if any(len(basis(seed))!=size for seed in seeds.values()):raise ValueError('classical seed rank deficiency')
    if any(bin(row).count('1')!=9 for row in hx+hz):raise ValueError('expected weight-9 checks')
    stem=f'LP_{n}_{k}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):
        raise FileExistsError(f'{stem}: refusing matrix overwrite')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(
            f'# nonabelian ZSZ-LP; {kind}; arXiv:2607.27644v1 Table 3 row {case["row"]}; group=({case["l1"]},{case["l2"]},{case["q"]})\n'+
            ''.join(' '.join(str((row >> j)&1) for j in range(n))+'\n' for row in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),
                    '--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    group=ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--n',type=int,choices=[c['n'] for c in CASES])
    group.add_argument('--all',action='store_true')
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered')
    args=ap.parse_args()
    for c in CASES if args.all else [c for c in CASES if c['n']==args.n]:print(generate(c,args.out),flush=True)


if __name__=='__main__':main()
