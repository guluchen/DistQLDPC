#!/usr/bin/env python3
"""Independent column-lift incidence, paired differences and Tanner girth."""
import argparse
from collections import Counter,deque
from itertools import combinations
import json
import hashlib
from pathlib import Path
from validate_css import read_code,validate,basis,contains

ROOT=Path(__file__).resolve().parents[2]


def matching_check(case,matching):
    j,l,p=case['J'],case['L'],case['P']
    if len(matching)!=j or any(len(row)!=j for row in matching):raise ValueError('matching shape mismatch')
    for x in range(j):
        for z in range(j):
            pairs=matching[x][z]
            if len(pairs)!=l//2 or any(len(pair)!=2 for pair in pairs):raise ValueError('not a perfect pair partition')
            if sorted(v for pair in pairs for v in pair)!=list(range(l)):raise ValueError('matching does not cover each column once')
            for u,v in pairs:
                if (case['D'][z][u]-case['E'][x][u]-case['D'][z][v]+case['E'][x][v])%p:
                    raise ValueError('paired mixed-difference equation failed')
            differences=Counter((d-e)%p for d,e in zip(case['D'][z],case['E'][x]))
            if any(count%2 for count in differences.values()):raise ValueError('mixed polynomial does not cancel in GF(2)')


def reconstruct(case):
    # Iterate variable columns, independently of the generator's row formula.
    p,j,l=case['P'],case['J'],case['L'];n=p*l;result=[]
    for exponents in (case['E'],case['D']):
        rows=[0]*(j*p)
        for block in range(l):
            for b in range(p):
                col=block*p+b
                for i in range(j):rows[i*p+(b+exponents[i][block])%p] |= 1 << col
        result.append(rows)
    return tuple(result)


def source_identity(case):
    projection={k:case[k] for k in ('P','J','L','E','D')}
    digest=hashlib.sha256(json.dumps(projection,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    if digest!=case['parameter_projection_sha256']:raise ValueError('source parameter projection digest mismatch')
    if case['n']!=276:
        text=('CPM_CSS_V1\n'+f'{case["source_instance"]} {case["P"]} {case["L"]} {case["J"]} {case["J"]}\n'+
              ''.join(' '.join(map(str,row))+'\n' for row in case['E']+case['D']))
        if hashlib.sha256(text.encode()).hexdigest()!=case['parameter_sha256']:
            raise ValueError('published source-file SHA256 mismatch')
    return digest


def logical_up_to_four(n,parity,stabilizers):
    """Exhaustive small-support oracle: all <=4 words split into two <=2 sets."""
    columns=[sum(((row >> q)&1) << j for j,row in enumerate(parity)) for q in range(n)]
    span=basis(stabilizers);buckets={0:[0]}
    for size in (1,2):
        for support in combinations(range(n),size):
            word=syndrome=0
            for q in support:word ^= 1 << q;syndrome ^= columns[q]
            for previous in buckets.get(syndrome,[]):
                candidate=word ^ previous
                if candidate and not contains(span,candidate):return candidate
            buckets.setdefault(syndrome,[]).append(word)
    return None


def tanner_girth(case,rows):
    p,j,l=case['P'],case['J'],case['L'];m=len(rows);n=p*l
    graph=[[] for _ in range(m+n)]
    for r,row in enumerate(rows):
        word=row
        while word:
            bit=word & -word;q=bit.bit_length()-1;word ^= bit
            graph[r].append(m+q);graph[m+q].append(r)
    if any(len(graph[r])!=l for r in range(m)) or any(len(graph[m+q])!=j for q in range(n)):
        raise ValueError('Tanner regularity mismatch')
    # Translating all lift coordinates preserves every CPM edge. Every cycle
    # can therefore be translated to meet a check lift 0 in one block row.
    # BFS from these J representatives suffices to find the shortest cycle.
    best=m+n+1;witness=None
    for root in range(0,j*p,p):
        dist=[-1]*(m+n);parent=[-1]*(m+n);dist[root]=0;queue=deque([root])
        while queue:
            u=queue.popleft()
            for v in graph[u]:
                if dist[v]<0:dist[v]=dist[u]+1;parent[v]=u;queue.append(v)
                elif parent[u]!=v and parent[v]!=u and dist[u]+dist[v]+1<best:
                    a,b=u,v;left=[a];right=[b]
                    while dist[a]>dist[b]:a=parent[a];left.append(a)
                    while dist[b]>dist[a]:b=parent[b];right.append(b)
                    while a!=b:a=parent[a];b=parent[b];left.append(a);right.append(b)
                    cycle=left+list(reversed(right[:-1]))
                    if len(set(cycle))!=len(cycle) or any(cycle[(i+1)%len(cycle)] not in graph[q] for i,q in enumerate(cycle)):
                        raise ValueError('invalid Tanner cycle witness')
                    best=len(cycle);witness=cycle
        if any(d<0 for d in dist):raise ValueError('disconnected Tanner graph')
    if witness is None:raise ValueError('no cycle found in complete CPM protograph')
    return dict(girth=best,cycle_vertices=witness,check_representatives_checked=j)


def certify(case,directory,matching):
    stem=f'PP_{case["n"]}_{case["k"]}_unknown';n,m=read_code(directory,stem)
    matching_check(case,matching)
    digest=source_identity(case)
    if tuple(m[:2])!=reconstruct(case):raise ValueError('independent lift incidence mismatch')
    algebra=validate(n,m)
    if (n,algebra['k'])!=(case['n'],case['k']):raise ValueError('published dimension mismatch')
    girths=[tanner_girth(case,rows) for rows in m[:2]]
    if any(record['girth']!=case['girth'] for record in girths):raise ValueError('source Tanner girth mismatch')
    small=None
    if n<=128:
        if any(logical_up_to_four(n,a,b) is not None for a,b in ((m[0],m[1]),(m[1],m[0]))):
            raise ValueError('tiny independent support exclusion failed')
        small=5
    return dict(stem=stem,**algebra,paired_difference_equations='PASS',independent_column_lift_incidence='PASS',
                row_weight=case['L'],column_weight=case['J'],tanner_girth=girths,
                source_parameter_projection_sha256=digest,
                tiny_exhaustive_both_half_lower_bound=small,
                claimed_exact_d=case['d'],claim_provenance=case['claim_provenance'])


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--dir',type=Path,default=ROOT/'data/matrices/untiered')
    ap.add_argument('--certificates',type=Path,default=ROOT/'optimization/experiments/GH-167/raw/pairings.json')
    ap.add_argument('--output',type=Path,required=True)
    args=ap.parse_args();cases=json.loads(Path(__file__).with_name('pair_partition_cases.json').read_text())
    certificates={row['stem']:row['matching'] for row in json.loads(args.certificates.read_text())}
    content=json.dumps([certify(c,args.dir,certificates[f'PP_{c["n"]}_{c["k"]}_unknown']) for c in cases],indent=2)+'\n'
    args.output.write_text(content);print(content,end='')


if __name__=='__main__':main()
