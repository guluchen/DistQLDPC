#!/usr/bin/env python3
"""Independent quotient-action, surface-link and shortest-cycle certificates.

No generator, enumerator or logical-builder imports. GPL-3.0-or-later.
Cells are reconstructed from explicit permutation cycles, not supplied cells.
"""
import argparse
from collections import deque
import hashlib
import json
from pathlib import Path
import sys
import time
from validate_css import read_code,validate,basis,contains,dot


def cycles(perm):
    seen=set();result=[]
    for start in range(len(perm)):
        if start in seen:continue
        row=[];a=start
        while a not in seen:seen.add(a);row.append(a);a=perm[a]
        if a!=start:raise ValueError('not a permutation cycle')
        result.append(row)
    return result


def step(table,a,word):
    for char in word:a=table[a]['rRsS'.index(char)]
    return a


def connected(adjacency):
    reached={0};pending=[0]
    for a in pending:
        for b in adjacency[a]:
            if b not in reached:reached.add(b);pending.append(b)
    return len(reached)==len(adjacency)


def reconstruct(case,table):
    order=len(table)
    if order!=2*case['n']:raise ValueError('quotient order mismatch')
    if any(len(row)!=4 or any(not 0<=v<order for v in row) for row in table):
        raise ValueError('invalid table dimensions')
    for g in range(4):
        if sorted(row[g] for row in table)!=list(range(order)):raise ValueError('generator is not a permutation')
    for a in range(order):
        if any(table[table[a][g]][g^1]!=a for g in range(4)):raise ValueError('inverse mismatch')
    words=['r'*case['r'],'s'*case['s'],'rsrs']+case['words']
    words+=[''.join('rRsS'['rRsS'.index(c)^1] for c in w) for w in case['words']]
    if any(step(table,a,w)!=a for a in range(order) for w in words):
        raise ValueError('published relation failed')
    if not connected(table):raise ValueError('disconnected action')
    faces=cycles([row[0] for row in table]);vertices=cycles([row[2] for row in table])
    edges=cycles([step(table,a,'rs') for a in range(order)])
    if {len(c) for c in faces}!={case['r']} or {len(c) for c in vertices}!={case['s']} or {len(c) for c in edges}!={2}:
        raise ValueError('local stabilizer order mismatch')
    def index(cells):return {a:i for i,c in enumerate(cells) for a in c}
    vi,fi,ei=map(index,(vertices,faces,edges))
    endpoints=[sorted({vi[a] for a in edge}) for edge in edges]
    dual=[sorted({fi[a] for a in edge}) for edge in edges]
    if any(len(pair)!=2 for pair in endpoints+dual):raise ValueError('loop or self-adjacent face')
    hx=[sum(1 << e for e,pair in enumerate(endpoints) if v in pair) for v in range(len(vertices))]
    hz=[sum(1 << e for e,pair in enumerate(dual) if f in pair) for f in range(len(faces))]
    directions=[[] for _ in edges]
    links=[{} for _ in vertices]
    for face in faces:
        boundary=[ei[a] for a in face];corners=[vi[a] for a in face]
        if len(set(boundary))!=case['r'] or len(set(corners))!=case['r']:
            raise ValueError('non-simple face boundary')
        for i,a in enumerate(face):
            e=ei[a];u=vi[a];v=vi[table[a][0]]
            if sorted((u,v))!=endpoints[e]:raise ValueError('boundary endpoint mismatch')
            directions[e].append(1 if u<v else -1)
            before=boundary[(i-1)%len(face)];after=boundary[i]
            links[u].setdefault(before,[]).append(after)
            links[u].setdefault(after,[]).append(before)
    if any(sorted(d)!=[-1,1] for d in directions):raise ValueError('surface is not consistently oriented')
    for v,link in enumerate(links):
        incident={e for e,pair in enumerate(endpoints) if v in pair}
        if set(link)!=incident or any(len(x)!=2 for x in link.values()):raise ValueError('non-manifold vertex link')
        start=next(iter(link));seen={start};pending=[start]
        for e in pending:
            for f in link[e]:
                if f not in seen:seen.add(f);pending.append(f)
        if seen!=incident:raise ValueError('disconnected vertex link')
    graph=[[] for _ in vertices]
    for a,b in endpoints:graph[a].append(b);graph[b].append(a)
    if not connected(graph):raise ValueError('disconnected surface')
    chi=len(vertices)-len(edges)+len(faces)
    if chi>=0 or chi%2:raise ValueError('not a closed orientable negative-curvature surface')
    return hx,hz,dict(vertices=len(vertices),edges=len(edges),faces=len(faces),
                      euler_characteristic=chi,genus=1-chi//2,
                      endpoints=endpoints,dual_endpoints=dual)


def shortest_cycle(n,parity,stabilizers,detectors,seconds=30):
    """All-root BFS fundamental cycles, exact homological distance.

    Every closed word decomposes into simple cycles; a nontrivial word has a
    nontrivial component. Root a BFS tree on a shortest nontrivial cycle C.
    Its edge fundamental cycles sum to C, so one has nonzero detector label.
    For every edge uv of C, dist(root,u)+dist(root,v)+1 <= |C|. Therefore the
    best nonzero fundamental-cycle walk over all roots has length exactly d.
    Cancel tree backtracks to get an actual GF(2) witness. No external solver.
    """
    columns=[[i for i,r in enumerate(parity) if (r >> q)&1] for q in range(n)]
    if any(len(c)!=2 for c in columns):raise ValueError('surface oracle requires graph incidence columns')
    graph=[[] for _ in parity]
    labels=[sum(dot(1 << q,r) << i for i,r in enumerate(detectors)) for q in range(n)]
    for q,(u,v) in enumerate(columns):graph[u].append((v,q));graph[v].append((u,q))
    best=n+1;best_word=None;deadline=time.monotonic()+seconds
    for root in range(len(graph)):
        if time.monotonic()>deadline:raise RuntimeError('surface verification budget; server package required')
        dist=[-1]*len(graph);path_label=[0]*len(graph);parent=[None]*len(graph)
        dist[root]=0;queue=deque([root])
        while queue:
            u=queue.popleft()
            for v,e in graph[u]:
                if dist[v]<0:
                    dist[v]=dist[u]+1;path_label[v]=path_label[u]^labels[e]
                    parent[v]=(u,e);queue.append(v)
        for e,(u,v) in enumerate(columns):
            length=dist[u]+dist[v]+1
            if length>=best or not (path_label[u]^path_label[v]^labels[e]):continue
            word=1 << e
            for a in (u,v):
                while a!=root:
                    a,q=parent[a];word ^= 1 << q
            weight=bin(word).count('1')
            if not word or any(dot(word,r) for r in parity) or contains(basis(stabilizers),word):
                raise ValueError('invalid BFS logical witness')
            best=weight;best_word=word
    if best_word is None:raise ValueError('no nontrivial graph cycle')
    return dict(distance=best,support=[q for q in range(n) if (best_word >> q)&1],
                method='ALL_ROOT_BFS_FUNDAMENTAL_CYCLES',roots_checked=len(graph))


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--certificates',type=Path,default=Path('optimization/experiments/GH-165/raw/quotients'))
    ap.add_argument('--output',type=Path,required=True)
    ap.add_argument('--distances',action='store_true',help='full independent graph distances, Linux only')
    args=ap.parse_args()
    if args.distances and not sys.platform.startswith('linux'):ap.error('full distance verification runs on Linux; tiny unit oracles only on Mac')
    cases=json.loads(Path(__file__).with_name('hyperbolic_cases.json').read_text());results=[]
    for c in cases:
        if c['status']!='READY_FOR_VALIDATION':continue
        stem=f'HYP_{c["n"]}_{c["k"]}_unknown';path=args.certificates/f'{stem}.json'
        data=json.loads(path.read_text());n,m=read_code(args.dir,stem)
        x,z,topology=reconstruct(c,data['table'])
        if (x,z)!=tuple(m[:2]):raise ValueError('independent incidence disagrees')
        algebra=validate(n,m)
        if algebra['k']!=2*topology['genus'] or algebra['k']!=c['k']:raise ValueError('homological dimension mismatch')
        result=dict(stem=stem,**algebra,topology={k:v for k,v in topology.items() if not k.endswith('endpoints')},
                    quotient_sha256=hashlib.sha256(path.read_bytes()).hexdigest())
        if args.distances:
            primal=shortest_cycle(n,m[0],m[1],m[3]);dual=shortest_cycle(n,m[1],m[0],m[2])
            if (primal['distance'],dual['distance'])!=(c['primal'],c['dual']):raise ValueError('surface distance contradicts published half distances')
            result.update(primal_Z=primal,dual_X=dual)
        results.append(result)
    content=json.dumps(results,indent=2)+'\n';args.output.write_text(content);print(content,end='')


if __name__=='__main__':main()
