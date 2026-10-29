#!/usr/bin/env python3
"""Original pair-partition CPM reconstruction (GH-167), GPL-3.0-or-later.

Okada-Kasai 2607.14091v4 Sec.II: C(s) row a meets column a-s modulo P.
Only published mathematical parameters used; no external implementation.
"""
import argparse
from collections import defaultdict
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=json.loads(Path(__file__).with_name('pair_partition_cases.json').read_text())


def dimensions(case):
    p,j,l=case['P'],case['J'],case['L']
    if p<2 or any(p%d==0 for d in range(2,int(p**0.5)+1)) or not 0<j<l or l%2:
        raise ValueError('positive prime lift, 0<J<L and even L required')
    for key in ('E','D'):
        rows=case[key]
        if len(rows)!=j or any(len(row)!=l or any(not isinstance(v,int) or not 0<=v<p for v in row) for row in rows):
            raise ValueError('invalid exponent dimensions or residues')
    return p,j,l


def pairing_certificate(case):
    p,j,l=dimensions(case);result=[]
    for i in range(j):
        row=[]
        for z in range(j):
            groups=defaultdict(list)
            for q in range(l):groups[(case['D'][z][q]-case['E'][i][q])%p].append(q)
            if any(len(v)%2 for v in groups.values()):raise ValueError('odd mixed-difference multiplicity; CSS pairing fails')
            # This is a valid reconstructed certificate, not a claim about
            # the author's original matching used before exponent search.
            row.append([v[t:t+2] for _,v in sorted(groups.items()) for t in range(0,len(v),2)])
        result.append(row)
    return result


def checks(case):
    p,j,l=dimensions(case);certificate=pairing_certificate(case)
    def expand(exponents):
        return [sum(1 << (q*p+(a-exponents[i][q])%p) for q in range(l))
                for i in range(j) for a in range(p)]
    return p*l,expand(case['E']),expand(case['D']),certificate


def generate(case,out):
    from validate_css import basis
    n,hx,hz,_=checks(case);k=n-len(basis(hx))-len(basis(hz))
    if (n,k)!=(case['n'],case['k']):raise ValueError('published dimensions mismatch')
    stem=f'PP_{n}_{k}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):
        raise FileExistsError(f'{stem}: refusing overwrite')
    for kind,rows in (('Hx',hx),('Hz',hz)):
        (out/f'{stem}_{kind}.txt').write_text(
            f'# pair-partition CPM; {kind}; arXiv:2607.14091v4; source {case["source_instance"]}; J={case["J"]} L={case["L"]} P={case["P"]}\n'+
            ''.join(' '.join(str((row >> q)&1) for q in range(n))+'\n' for row in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),
                    '--method','bitset','--dir',str(out),stem],check=True)
    return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    group=ap.add_mutually_exclusive_group(required=True)
    group.add_argument('--n',type=int,choices=[c['n'] for c in CASES]);group.add_argument('--all',action='store_true')
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered')
    ap.add_argument('--certificates',type=Path,help='new JSON matching certificate file')
    args=ap.parse_args()
    if args.certificates and args.certificates.exists():raise FileExistsError('refusing certificate overwrite')
    certificates=[]
    for c in CASES if args.all else [c for c in CASES if c['n']==args.n]:
        stem=generate(c,args.out);print(stem,flush=True)
        certificates.append(dict(stem=stem,matching=pairing_certificate(c),origin='reconstructed equal-difference pairing, not original search seed'))
    if args.certificates:args.certificates.write_text(json.dumps(certificates,indent=2)+'\n')


if __name__=='__main__':main()
