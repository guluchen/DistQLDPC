#!/usr/bin/env python3
"""Independent bounded classical exhaustive proof + HGP Theorem1, Linux only.

Does not solve quantum distance on the Mac. Only <=8-bit tiny units permitted.
No external solver or logical-builder imports. GPL-3.0-or-later.
"""
import argparse
from collections import Counter
import hashlib
import json
import os
from pathlib import Path
import platform
import resource
import signal
import subprocess
import sys
from validate_expurgated_hgp import factors,transpose_word
from validate_css import basis,contains,read_code
from verify_css_witness import verify_witness

ROOT=Path(__file__).resolve().parents[2]


def classical_distance(n,supports):
    if not sys.platform.startswith('linux') and n>8:raise ValueError('source-distance search is Linux-only; Mac tiny units<=8 bits')
    matrix=[[int(q in row) for q in range(n)] for row in supports]
    pivot_columns=[];r=0
    for col in range(n):
        pivot=next((i for i in range(r,len(matrix)) if matrix[i][col]),None)
        if pivot is None:continue
        matrix[r],matrix[pivot]=matrix[pivot],matrix[r]
        for i in range(len(matrix)):
            if i!=r and matrix[i][col]:matrix[i]=[a^b for a,b in zip(matrix[i],matrix[r])]
        pivot_columns.append(col);r+=1
    free=[q for q in range(n) if q not in pivot_columns]
    if not free or len(free)>20:raise ValueError('nontrivial dimension<=20 required for bounded exhaustive check')
    generators=[]
    for q in free:
        word=1<<q
        for i,p in enumerate(pivot_columns):
            if matrix[i][q]:word|=1<<p
        generators.append(word)
    weights=Counter({0:1});best=None;word=0
    for count in range(1,1<<len(free)):
        bit=(count&-count).bit_length()-1;word^=generators[bit]
        weight=bin(word).count('1');weights[weight]+=1
        if best is None or (weight,word)<best:best=(weight,word)
    if sum(weights.values())!=1<<len(free) or weights[0]!=1:raise ValueError('enumeration not complete/injective')
    support=[q for q in range(n) if (best[1]>>q)&1]
    if not support or any(len(set(support)&set(row))%2 for row in supports):raise ValueError('classical witness syndrome')
    return dict(n=n,rank=r,dimension=len(free),enumerated_codewords=1<<len(free),
                weight_enumerator=dict(sorted(weights.items())),distance=best[0],support=support)


def certify(c,matrices_dir):
    n=c['classical_n'];raw,h=factors(c);proof=classical_distance(n,raw);r=len(h)
    if proof['distance']<4:raise ValueError('SCIENTIFIC MISMATCH: independent distance contradicts distinct-column/even-word lower bound')
    if proof['rank']!=r or proof['dimension']!=n-r:raise ValueError('independent kernel dimension mismatch')
    stem=f'HGP_{c["n"]}_{c["k"]}_unknown';N,m=read_code(matrices_dir,stem)
    span=basis([sum(1<<q for q in row) for row in h]);j=next(q for q in range(n) if not contains(span,1<<q))
    z=sum(1<<(q*n+j) for q in proof['support']);x=transpose_word(z,n,r);witnesses=[]
    for half,word in (('Z',z),('X',x)):
        support=[q for q in range(N) if (word>>q)&1];verify_witness(N,m,half,support)
        if len(support)!=proof['distance']:raise ValueError('product witness weight mismatch')
        witnesses.append(dict(half=half,support=support,weight=len(support)))
    return dict(stem=stem,classical_proof=proof,derived_quantum_d=proof['distance'],structural_lower_bound=4,
                method='exhaustive classical kernel + full-row-rank same-factor HGP Theorem1',
                independently_checked_quantum_words=witnesses,
                input_sha256={kind:hashlib.sha256((matrices_dir/f'{stem}_{kind}.txt').read_bytes()).hexdigest() for kind in ('Hx','Hz','Gx','Gz')})


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--ci',action='store_true',required=True)
    ap.add_argument('--matrices',type=Path,default=ROOT/'data/matrices/untiered')
    ap.add_argument('--cases',type=Path,default=Path(__file__).with_name('expurgated_hgp_cases.json'))
    ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    if not sys.platform.startswith('linux') or os.environ.get('GITHUB_ACTIONS')!='true':ap.error('bounded Linux Actions check only')
    if args.out.exists():raise FileExistsError('refusing evidence overwrite')
    cpu=min(os.sched_getaffinity(0));os.sched_setaffinity(0,{cpu})
    resource.setrlimit(resource.RLIMIT_AS,(4294967296,4294967296));resource.setrlimit(resource.RLIMIT_CPU,(60,62));signal.alarm(90)
    records=[certify(c,args.matrices) for c in json.loads(args.cases.read_text())]
    out=dict(source_head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
             method='original independent classical exhaustive search and published HGP mathematics',
             platform=platform.platform(),python=sys.version,cpu=cpu,address_space_limit=4294967296,cpu_limit=60,wall_backstop=90,
             script_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
             cases_sha256=hashlib.sha256(args.cases.read_bytes()).hexdigest(),results=records)
    text=json.dumps(out,indent=2)+'\n';args.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
