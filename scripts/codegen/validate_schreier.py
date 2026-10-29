#!/usr/bin/env python3
"""Independent inverse-arc/corner/local-code enumeration audit; no generator import."""
import argparse
from itertools import product
import json
from pathlib import Path
from validate_css import read_code,validate,basis,equal_space,dot
from verify_css_witness import verify_witness

ROOT=Path(__file__).resolve().parents[2]


def codewords(strings):
    d=len(strings[0]);parity=[[int(x) for x in s] for s in strings]
    return [v for v in range(1<<d) if all(sum(((v>>i)&1)*row[i] for i in range(d))%2==0 for row in parity)]


def literal_actions(c):
    p=c['p'];two=c['mode']=='2+2';vertices=list(product(range(2),range(2) if two else range(1),range(p)))
    lookup={v:i for i,v in enumerate(vertices)}
    def neighbours(v,data,axis):
        a,b,g=v;layer=[a,b][axis]
        if not two and axis==1:return [lookup[(a,b,(g+e)%p)] for e in data]
        internal=data[0] if layer==0 else data[2];dest=[]
        for e in internal:dest.append(lookup[(a,b,(g+e)%p)])
        for e in data[1]:
            h=(g+e)%p if layer==0 else (g-e)%p
            dest.append(lookup[(1-a,b,h) if axis==0 else (a,1-b,h)])
        return dest
    A=[neighbours(v,c['A'],0) for v in vertices];B=[neighbours(v,c['B'],1) for v in vertices]
    d=len(A[0])
    for u in range(len(vertices)):
        if len(set(A[u]))!=d or len(set(B[u]))!=d:raise ValueError('local edge multiplicity unsupported')
        for a in range(d):
            for b in range(d):
                if B[A[u][a]][b]!=A[B[u][b]][a]:raise ValueError('literal labelled graphs do not commute')
    def inv(graph):
        result=[]
        for u,neighbours_u in enumerate(graph):
            row=[]
            for v in neighbours_u:
                candidates=[j for j,w in enumerate(graph[v]) if w==u]
                if len(candidates)!=1:raise ValueError('inverse arc is not unique')
                row.append(candidates[0])
            result.append(row)
        return result
    return vertices,A,B,inv(A),inv(B)


def connected_sizes(matrix,n):
    # Canonical RREF support components of the actual stabilizer space.
    pivots=basis(matrix)
    for p in sorted(pivots):
        for q in pivots:
            if p!=q and ((pivots[q]>>p)&1):pivots[q]^=pivots[p]
    parent=list(range(n))
    def root(i):
        while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
        return i
    for row in pivots.values():
        bits=[]
        while row:bit=row&-row;bits.append(bit.bit_length()-1);row^=bit
        for j in bits[1:]:parent[root(j)]=root(bits[0])
    counts={}
    for i in range(n):r=root(i);counts[r]=counts.get(r,0)+1
    return sorted(counts.values())


def audit(c,generated,directory):
    stem=generated['stem'];n,m=read_code(directory,stem);result=validate(n,m)
    if (n,result['k'])!=(generated['n'],generated['k']) or (c['k'] is not None and c['k']!=result['k']):raise ValueError('source/actual dimension mismatch')
    vertices,A,B,ia,ib=literal_actions(c);M=len(vertices);d=len(A[0])
    if n!=M*d*d:raise ValueError('physical qubit count mismatch')
    stars={kind:[[None]*(d*d) for _ in vertices] for kind in ['00','10','01','11']}
    for q in range(n):
        u,a,b=q//(d*d),(q//d)%d,q%d
        au,bu=A[u][a],B[u][b];ab=B[au][b]
        corners=[('00',u,a,b),('10',au,ia[u][a],b),('01',bu,a,ib[u][b]),('11',ab,ia[bu][a],ib[au][b])]
        for kind,v,i,j in corners:
            if stars[kind][v][i*d+j] is not None:raise ValueError('duplicate literal local incidence')
            stars[kind][v][i*d+j]=q
    if any(None in star or len(set(star))!=d*d for group in stars.values() for star in group):raise ValueError('literal local view incomplete')
    # Enumerate the complete local kernels (at most128vectors); independent of
    # the generator's free-variable nullspace basis and tensor implementation.
    ca,cb=codewords(c['HA']),codewords(c['HB'])
    aa=[sum(int(x)<<i for i,x in enumerate(s)) for s in c['HA']];bb=[sum(int(x)<<i for i,x in enumerate(s)) for s in c['HB']]
    local0=[sum(((x>>i)&1)*((y>>j)&1)<<(i*d+j) for i in range(d) for j in range(d)) for x in ca for y in cb]
    local1=[sum(((x>>i)&1)*((y>>j)&1)<<(i*d+j) for i in range(d) for j in range(d)) for x in aa for y in bb]
    expected=[]
    for kinds,local in [(('00','11'),list(basis(local0).values())),(('10','01'),local1)]:
        matrix=[]
        for kind in kinds:
            for star in stars[kind]:
                for row in local:matrix.append(sum(((row>>i)&1)<<q for i,q in enumerate(star)))
        expected.append(matrix)
    if not equal_space(expected[0],m[0]) or not equal_space(expected[1],m[1]):raise ValueError('literal Tanner tensor pullback differs from actual stabilizer space')
    # Actual local shared strips must match row/column coordinates in both
    # endpoint views, as required by source Lemma3; do not assume an XZ map.
    views0=[star for k in ['00','11'] for star in stars[k]];views1=[star for k in ['10','01'] for star in stars[k]]
    positions0=[{q:divmod(i,d) for i,q in enumerate(s)} for s in views0]
    positions1=[{q:divmod(i,d) for i,q in enumerate(s)} for s in views1]
    strips=0
    for x in positions0:
        for y in positions1:
            common=x.keys()&y.keys()
            if not common:continue
            rows=all(x[q][1]==y[q][1] for q in common)
            cols=all(x[q][0]==y[q][0] for q in common)
            if not(rows or cols) or len(common)%d:raise ValueError('shared tensor strip labels fail')
            strips+=1
    words=[]
    for half,logical in [('X',m[3]),('Z',m[2])]:
        w=min(logical,key=lambda r:bin(r).count('1'));support=[i for i in range(n) if (w>>i)&1]
        verify_witness(n,m,half,support)
        if c['published_exact'] is not None and len(support)<c['published_exact']:raise ValueError('basis word contradicts source exact distance')
        words.append(dict(half=half,weight=len(support),support=support,basis='computed complete quotient basis; upper only'))
    components=connected_sizes(m[0]+m[1],n)
    result.update(stem=stem,case_id=c['id'],source_exact=c['published_exact'],local_view_count=4*M,
        all_literal_inverse_arcs='PASS',all_four_corner_pullbacks='PASS',shared_tensor_strips_checked=strips,
        stabilizer_support_components=components,independently_checked_uppers=words,
        XZ_metric_map='not assumed; actual ranks can differ')
    return result


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--dir',type=Path,default=ROOT/'data/matrices/untiered/quarantine/GH-202');p.add_argument('--out',type=Path)
    p.add_argument('--generated',type=Path,default=ROOT/'optimization/experiments/GH-202/raw/generation.json');a=p.parse_args()
    generated={r['case_id']:r for r in json.loads(a.generated.read_text())}
    results=[audit(c,generated[c['id']],a.dir) for c in json.loads(Path(__file__).with_name('schreier_cases.json').read_text())]
    text=json.dumps(results,indent=2)+'\n'
    if a.out:a.out.write_text(text)
    print(text,end='')


if __name__=='__main__':main()
