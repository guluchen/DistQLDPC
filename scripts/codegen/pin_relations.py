#!/usr/bin/env python3
"""Original static pin-relation CSS generator from1906.11394v3 mathematics.

Qubits are UNIQUE flags, not chain cells. Original factor matrices are frozen;
no author software or matrix files, external algebra/distance programs used.
"""
import argparse
from collections import defaultdict
import hashlib
import itertools
import json
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('pin_relation_cases.json')


def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def support(w):
    out=[]
    while w:
        b=w&-w;out.append(b.bit_length()-1);w^=b
    return out


def rank(rows):
    p={}
    for w in rows:
        while w:
            i=w.bit_length()-1
            if i in p:w^=p[i]
            else:p[i]=w;break
    return len(p)


def tensor_chain(factors):
    D=len(factors);bases=[];indices=[]
    for j in range(D+1):
        level=[]
        for mask in range(1<<D):
            if len(support(mask))!=j:continue
            sizes=[len(h[0]) if (mask>>i)&1 else len(h) for i,h in enumerate(factors)]
            level.extend((mask,tuple(t)) for t in itertools.product(*(range(s) for s in sizes)))
        bases.append(level);indices.append({v:i for i,v in enumerate(level)})
    boundaries=[]
    for j in range(1,D+1):
        cols=[]
        for mask,t in bases[j]:
            w=0
            for i,h in enumerate(factors):
                if not (mask>>i)&1:continue
                for row in range(len(h)):
                    if h[row][t[i]]:
                        lower=list(t);lower[i]=row;w^=1<<indices[j-1][(mask^(1<<i),tuple(lower))]
            cols.append(w)
        boundaries.append(cols)
    return bases,boundaries


def complete_endpoints(sizes,columns):
    sizes=sizes[:];columns=[c[:] for c in columns];added=[None,None]
    odd=[i for i,w in enumerate(columns[0]) if len(support(w))%2]
    if odd:
        added[0]=sizes[0];sizes[0]+=1
        for i in odd:columns[0][i]^=1<<added[0]
    parity=0
    for w in columns[-1]:parity^=w
    if parity:added[1]=sizes[-1];sizes[-1]+=1;columns[-1].append(parity)
    return sizes,columns,added


def chain_flags(sizes,columns):
    paths=[(q,) for q in range(sizes[-1])]
    for boundary in reversed(columns):
        paths=[(low,)+path for path in paths for low in support(boundary[path[0]])]
    return sorted(paths)


def pinned_rows(flags,pins):
    rows=[];labels=[]
    for T in itertools.combinations(range(len(flags[0])),pins):
        groups=defaultdict(int)
        for q,f in enumerate(flags):groups[tuple(f[i] for i in T)]^=1<<q
        for p,w in sorted(groups.items()):labels.append(dict(type=list(T),pins=list(p)));rows.append(w)
    return rows,labels


def build(c):
    x,z=c['x'],c['z']
    if c['construction']=='complete':
        sizes=c['levels'];D=len(sizes)-1;bases=[];original=[];boundaries=[];added=[None,None]
        flags=list(itertools.product(*(range(s) for s in sizes)))
    else:
        factors=c['factors'];D=len(factors)
        for h in factors:
            if not h or not h[0] or any(len(row)!=len(h[0]) or any(b not in [0,1] for b in row) for row in h):raise ValueError('invalid frozen binary factor')
        bases,original=tensor_chain(factors);sizes,boundaries,added=complete_endpoints([len(b) for b in bases],original);flags=chain_flags(sizes,boundaries)
    if min(x,z)<=0 or x+z>D or len(set(flags))!=len(flags):raise ValueError('invalid pin dimensions/duplicate flag')
    hx,xlabels=pinned_rows(flags,x);hz,zlabels=pinned_rows(flags,z);n=len(flags);k=n-rank(hx)-rank(hz)
    if n!=c['n'] or ('k' in c and c['k']!=k):raise ValueError('frozen/source finite parameter mismatch')
    cert=dict(case=c,parameter_sha256=digest(c),D=D,n=n,k=k,levels=sizes,tensor_bases=bases,original_boundary_columns=original,completed_boundary_columns=boundaries,endpoint_added_pins=added,flags=flags,check_labels_X=xlabels,check_labels_Z=zlabels,rank_Hx=rank(hx),rank_Hz=rank(hz))
    return cert,hx,hz


def generate(c,out,certificates):
    cert,hx,hz=build(c);n,k=cert['n'],cert['k'];stem=f'PIN_{n}_{k}_unknown'
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ['Hx','Hz','Gx','Gz']) or (certificates/f'{stem}.json').exists():raise FileExistsError('refusing to overwrite matrix/certificate')
    certificates.mkdir(parents=True,exist_ok=True)
    if k<=0:
        cert['exclusion']='NO_LOGICAL_QUBITS_NO_PARAMETER_REPLACEMENT';(certificates/f'{stem}.json').write_text(json.dumps(cert,indent=2)+'\n');return 'EXCLUDED '+stem
    out.mkdir(parents=True,exist_ok=True)
    for kind,rows in [('Hx',hx),('Hz',hz)]:
        with (out/f'{stem}_{kind}.txt').open('w') as f:
            f.write(f'# original static pin-relation CSS; case={c["id"]}; {kind}; arXiv1906.11394v3; GH-189\n')
            for w in rows:f.write(' '.join(str((w>>q)&1) for q in range(n))+'\n')
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    (certificates/f'{stem}.json').write_text(json.dumps(cert,indent=2)+'\n');return stem


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True);g.add_argument('--all',action='store_true');g.add_argument('--n',type=int)
    ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');ap.add_argument('--certificates',type=Path,required=True);a=ap.parse_args()
    selected=[c for c in json.loads(CASES.read_text()) if a.all or c['n']==a.n]
    if not selected:ap.error('unknown frozen size')
    for c in selected:print(generate(c,a.out,a.certificates),flush=True)


if __name__=='__main__':main()
