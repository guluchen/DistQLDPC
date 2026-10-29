#!/usr/bin/env python3
"""Original generalized Schreier Tanner mathematics (Mostad et al., 2025).

Published graph blocks, Def10/AppendixB; GPL-3.0-or-later. No author code.
Source and original cases fixed in GH202 before generation. No distance search.
"""
import argparse
from itertools import product
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
CASES=Path(__file__).with_name('schreier_cases.json')


def rows(strings):
    if not strings or len({len(r) for r in strings})!=1 or any(x not in '01' for r in strings for x in r):raise ValueError('invalid local parity matrix')
    return [sum(int(x)<<i for i,x in enumerate(r)) for r in strings]


def rref(matrix,width):
    work=list(matrix);pivots=[];r=0
    for col in range(width):
        pivot=next((i for i in range(r,len(work)) if (work[i]>>col)&1),None)
        if pivot is None:continue
        work[r],work[pivot]=work[pivot],work[r]
        for i in range(len(work)):
            if i!=r and (work[i]>>col)&1:work[i]^=work[r]
        pivots.append(col);r+=1
        if r==len(work):break
    return work[:r],pivots


def kernel(matrix,width):
    reduced,pivots=rref(matrix,width);out=[]
    for f in range(width):
        if f in pivots:continue
        vector=1<<f
        for r,p in zip(reduced,pivots):
            if (r>>f)&1:vector^=1<<p
        out.append(vector)
    return out


def tensor(a,b,d):
    return [sum(((x>>i)&1)*((y>>j)&1)<<(i*d+j) for i in range(d) for j in range(d)) for x in a for y in b]


def actions(case):
    p=case['p'];two=case['mode']=='2+2'
    if case['mode'] not in ('2+1','2+2') or p<3:raise ValueError('unsupported Schreier base')
    vertices=list(product(range(2),range(2) if two else range(1),range(p)))
    index={v:i for i,v in enumerate(vertices)}
    def maps(data,axis):
        if axis==1 and not two:
            return [[index[(a,b,(g+e)%p)] for a,b,g in vertices] for e in data]
        if len(data)!=3 or len(data[0])!=len(data[2]):raise ValueError('invalid split graph')
        if any(len(set(e%p for e in part))!=len(part) for part in data):raise ValueError('parallel labelled neighbors not supported by this fixed package')
        out=[]
        for label in range(len(data[0])+len(data[1])):
            perm=[]
            for a,b,g in vertices:
                layer=(a,b)[axis]
                if label<len(data[0]):e=data[2 if layer else 0][label];new=layer
                else:e=data[1][label-len(data[0])]*(1 if layer==0 else -1);new=1-layer
                v=(new,b,(g+e)%p) if axis==0 else (a,new,(g+e)%p)
                perm.append(index[v])
            out.append(perm)
        return out
    A=maps(case['A'],0);B=maps(case['B'],1)
    if len(A)!=len(B) or len(A)!=len(case['HA'][0]) or len(A)!=len(case['HB'][0]):raise ValueError('degree/local-code mismatch')
    for perm in A+B:
        if sorted(perm)!=list(range(len(vertices))):raise ValueError('not a permutation')
    def inverses(perms):
        inv=[]
        for perm in perms:
            candidates=[j for j,q in enumerate(perms) if all(q[perm[u]]==u for u in range(len(vertices)))]
            if len(candidates)!=1:raise ValueError('labels do not have a unique global inverse')
            inv.append(candidates[0])
        return inv
    ia,ib=inverses(A),inverses(B)
    if any(a[b[u]]!=b[a[u]] for a in A for b in B for u in range(len(vertices))):raise ValueError('labelled graph actions do not commute')
    return vertices,A,B,ia,ib


def construction(case):
    vertices,A,B,ia,ib=actions(case);M=len(vertices);d=len(A);n=M*d*d
    if n!=case['n']:raise ValueError('source n mismatch')
    stars={corner:[[None]*(d*d) for _ in vertices] for corner in ('00','11','10','01')}
    for u in range(M):
        for a in range(d):
            for b in range(d):
                q=(u*d+a)*d+b
                corners=[('00',u,a,b),('10',A[a][u],ia[a],b),('01',B[b][u],a,ib[b]),('11',A[a][B[b][u]],ia[a],ib[b])]
                for kind,v,i,j in corners:
                    if stars[kind][v][i*d+j] is not None:raise ValueError('duplicate local face incidence')
                    stars[kind][v][i*d+j]=q
    if any(None in star or len(set(star))!=d*d for groups in stars.values() for star in groups):raise ValueError('incomplete labelled local view')
    ha,hb=rows(case['HA']),rows(case['HB']);ga,gb=kernel(ha,d),kernel(hb,d)
    local0,local1=tensor(ga,gb,d),tensor(ha,hb,d)
    def pullback(kinds,local):
        out=[]
        for kind in kinds:
            for star in stars[kind]:
                for vector in local:out.append(sum(((vector>>j)&1)<<q for j,q in enumerate(star)))
        return out
    hx,hz=pullback(('00','11'),local0),pullback(('10','01'),local1)
    rx,rz=len(rref(hx,n)[0]),len(rref(hz,n)[0]);k=n-rx-rz
    if case['k'] is not None and k!=case['k']:raise ValueError('SOURCE_DIMENSION_HOLD: expected k=%d, actual k=%d'%(case['k'],k))
    if k<1:raise ValueError('no logical qubits')
    return dict(n=n,k=k,rank_Hx=rx,rank_Hz=rz,degree=d,base_vertices=M,local_dimensions=[len(ga),len(gb)]),hx,hz,stars


def generate(case,out):
    result,hx,hz,stars=construction(case);n=result['n'];stem='TN_%d_%d_unknown'%(n,result['k'])
    if any((out/(stem+'_'+k+'.txt')).exists() for k in ('Hx','Hz','Gx','Gz')):raise FileExistsError('refusing to overwrite '+stem)
    out.mkdir(parents=True,exist_ok=True)
    for kind,matrix in [('Hx',hx),('Hz',hz)]:
        header='# original Schreier Tanner; case=%s; p=%d; mode=%s; %s; Mostad-Rosnes-Lin2025 Def10/AppB\n'%(case['id'],case['p'],case['mode'],kind)
        (out/(stem+'_'+kind+'.txt')).write_text(header+''.join(' '.join(str((row>>i)&1) for i in range(n))+'\n' for row in matrix))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    result.update(stem=stem,case_id=case['id'],published_exact=case['published_exact'])
    return result


def main():
    p=argparse.ArgumentParser(description=__doc__);g=p.add_mutually_exclusive_group(required=True)
    g.add_argument('--all',action='store_true');g.add_argument('--case')
    p.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');p.add_argument('--receipt',type=Path);a=p.parse_args()
    selected=[c for c in json.loads(CASES.read_text()) if a.all or c['id']==a.case]
    if not selected:p.error('only frozen source/original cases supported')
    results=[]
    for c in selected:
        r=generate(c,a.out);results.append(r);print(json.dumps(r),flush=True)
    if a.receipt:a.receipt.write_text(json.dumps(results,indent=2)+'\n')


if __name__=='__main__':main()
