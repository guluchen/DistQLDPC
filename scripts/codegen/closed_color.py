#!/usr/bin/env python3
"""Original closed4.8.10 STATIC color CSS construction, GPL-3.0-or-later.

Published reflection/Wythoff and static plaquette mathematics only. Original
finite integral covers; no third-party constructor/matrices/distance program.
"""
import argparse
from collections import deque
from functools import lru_cache
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from closed_color_quotient import Quotient,walk
ROOT=Path(__file__).resolve().parents[2]
CASES=json.loads(Path(__file__).with_name('closed_color_cases.json').read_text())
ALPHABET='rRsS'


def source_relators(c):
    words=[tuple(ALPHABET.index(ch) for ch in w) for w in c['words']]
    return [(0,)*c['r'],(2,)*c['s'],(0,2)*2]+words+[tuple(g^1 for g in w) for w in words]


def cells(adjacency,parity):
    n=len(adjacency)
    if len(parity)!=n or any(len(row)!=3 or len(set(row))!=3 for row in adjacency):raise ValueError('nontrivalent graph')
    edges=[]
    for u,row in enumerate(adjacency):
        for i,v in enumerate(row):
            if not 0<=v<n or v==u or adjacency[v][i]!=u or parity[u]==parity[v]:raise ValueError('invalid colored involution/bipartition')
            if u<v:edges.append([u,v,i])
    edges.sort();edge_ids={(u,v):i for i,(u,v,_) in enumerate(edges)}
    if len(edge_ids)!=len(edges):raise ValueError('parallel colors collapse')
    seen=set();faces=[]
    for u in range(n):
        for color in range(3):
            if (u,color) in seen:continue
            start=(u,color);v,i=start;vertices=[];colors=[]
            while (v,i) not in seen:
                seen.add((v,i));vertices.append(v);colors.append(i)
                w=adjacency[v][i];i=(i+(1 if parity[w]==0 else -1))%3;v=w
            if (v,i)!=start or len(set(vertices))!=len(vertices) or len(set(colors))!=2:raise ValueError('invalid/simple face cycle')
            boundary=[];signs=[]
            for a,b in zip(vertices,vertices[1:]+vertices[:1]):
                boundary.append(edge_ids[(min(a,b),max(a,b))]);signs.append(1 if a<b else -1)
            faces.append(dict(vertices=vertices,edge_colors=colors,edge_ids=boundary,edge_signs=signs,color=next(iter(set(range(3))-set(colors)))))
    if {len(f['vertices']) for f in faces}!={4,8,10}:raise ValueError('wrong4.8.10 local face orders')
    return dict(adjacency=adjacency,vertex_parity=parity,edges=edges,faces=faces)


@lru_cache(maxsize=3)
def base_complex(source_edges,r,s,words):
    c=dict(r=r,s=s,words=list(words));table,stats=Quotient(source_relators(c)).run()
    if len(table)!=2*source_edges:raise ValueError('source quotient order mismatch')
    phi=[None]*len(table);phi[0]=0;queue=[0]
    for u in queue:
        for g,v in enumerate(table[u]):
            image=table[phi[u]][g^1]
            if phi[v] is None:phi[v]=image;queue.append(v)
            elif phi[v]!=image:raise ValueError('source reflection does not descend')
    if sorted(phi)!=list(range(len(table))) or any(phi[phi[u]]!=u for u in range(len(table))):raise ValueError('reflection is not an involution')
    adjacency=[];parity=[]
    # Semidirect product G rtimes C2; a=(r,1),b=(1,1),c=(S,1).
    for u in range(len(table)):
        for e in range(2):
            adjacency.append([2*table[u][1 if e else 0]+1-e,2*u+1-e,2*table[u][2 if e else 3]+1-e]);parity.append(e)
    data=cells(adjacency,parity)
    data.update(oriented_table=table,reflection_automorphism=phi,source_edges=source_edges,r=r,s=s,words=list(words),enumeration_stats=stats)
    return data


def tree(vertices,adjacency,allowed):
    parent=[None]*vertices;parent[0]=(-1,-1);queue=deque([0]);edges=[]
    while queue:
        u=queue.popleft()
        for e,v in sorted(adjacency[u]):
            if e in allowed and parent[v] is None:parent[v]=(u,e);edges.append(e);queue.append(v)
    if any(p is None for p in parent):raise ValueError('tree graph disconnected')
    return set(edges)


def integral_cocycle(base):
    vertices=len(base['adjacency']);edges=base['edges'];faces=base['faces'];primal=[[] for _ in range(vertices)]
    for e,(u,v,_) in enumerate(edges):primal[u].append((e,v));primal[v].append((e,u))
    T=tree(vertices,primal,set(range(len(edges))));inc=[[] for _ in edges]
    for f,face in enumerate(faces):
        for e,sign in zip(face['edge_ids'],face['edge_signs']):inc[e].append((f,sign))
    dual=[[] for _ in faces];orient=[]
    for e,ends in enumerate(inc):
        if len(ends)!=2 or sorted(s for _,s in ends)!=[-1,1] or ends[0][0]==ends[1][0]:raise ValueError('not a closed oriented edge')
        tail=next(f for f,s in ends if s==-1);head=next(f for f,s in ends if s==1);orient.append((tail,head))
        dual[tail].append((e,head));dual[head].append((e,tail))
    S=tree(len(faces),dual,set(range(len(edges)))-T);left=sorted(set(range(len(edges)))-T-S)
    if len(left)!=2-vertices+len(edges)-len(faces) or not left:raise ValueError('wrong tree-cotree homology dimension')
    selected=left[0];tail,head=orient[selected];queue=deque([head]);parent={head:None}
    while queue and tail not in parent:
        u=queue.popleft()
        for e,v in sorted(dual[u]):
            if e in S and v not in parent:parent[v]=(u,e);queue.append(v)
    if tail not in parent:raise ValueError('dual tree path missing')
    steps=[];v=tail
    while v!=head:
        u,e=parent[v];steps.append((e,u,v));v=u
    steps=list(reversed(steps));steps=[(selected,tail,head)]+steps;voltage=[0]*len(edges)
    for e,u,v in steps:voltage[e]+=1 if orient[e]==(u,v) else -1
    if voltage[selected]!=1 or any(voltage[e] for e in T):raise ValueError('nonprimitive cocycle')
    if any(sum(voltage[e]*s for e,s in zip(f['edge_ids'],f['edge_signs'])) for f in faces):raise ValueError('face has nonzero integral voltage')
    return dict(primal_tree_edges=sorted(T),dual_tree_edges=sorted(S),leftover_edges=left,selected_edge=selected,dual_cycle_oriented_steps=steps,voltage=voltage)


def cover(base,q,cocycle):
    if not isinstance(q,int) or q<1:raise ValueError('positive cover degree required')
    adjacency=[[-1]*3 for _ in range(len(base['adjacency'])*q)]
    for e,(u,v,color) in enumerate(base['edges']):
        for t in range(q):
            a=u*q+t;b=v*q+(t+cocycle['voltage'][e])%q
            adjacency[a][color]=b;adjacency[b][color]=a
    return cells(adjacency,[p for p in base['vertex_parity'] for _ in range(q)])


def construct(c):
    base=base_complex(c['source_edges'],c['r'],c['s'],tuple(c['words']));cocycle=integral_cocycle(base);final=cover(base,c['degree'],cocycle)
    n=len(final['adjacency']);chi=n-len(final['edges'])+len(final['faces']);genus=(2-chi)//2
    if (n,genus)!=(c['n'],c['genus']):raise ValueError('frozen cover dimensions/genus mismatch')
    rows=[sum(1<<q for q in f['vertices']) for f in final['faces']]
    cert=dict(case=c,parameter_sha256=hashlib.sha256(json.dumps(c,sort_keys=True,separators=(',',':')).encode()).hexdigest(),base=base,cocycle=cocycle,final=final)
    return rows,cert


def generate(c,out):
    from validate_css import basis
    rows,cert=construct(c);n=c['n'];rank=len(basis(rows));k=n-2*rank
    if k!=c['k'] or k!=4*c['genus'] or rank!=len(rows)-2:raise ValueError('actual static CSS rank mismatch')
    stem=f'COLOR_{n}_{k}_unknown';out.mkdir(parents=True,exist_ok=True)
    if any((out/f'{stem}_{kind}.txt').exists() for kind in ('Hx','Hz','Gx','Gz')):raise FileExistsError('refusing matrix overwrite')
    for kind in ('Hx','Hz'):
        (out/f'{stem}_{kind}.txt').write_text(f'# closed static4.8.10 color; genus={c["genus"]}; {kind}; original Wythoff/cyclic-cover reconstruction\n'+''.join(' '.join(str((row>>q)&1) for q in range(n))+'\n' for row in rows))
    subprocess.run([sys.executable,str(ROOT/'scripts/compute_logicals.py'),'--method','bitset','--dir',str(out),stem],check=True)
    return stem,cert


def main():
    ap=argparse.ArgumentParser(description=__doc__);g=ap.add_mutually_exclusive_group(required=True);g.add_argument('--all',action='store_true');g.add_argument('--n',type=int,choices=[c['n'] for c in CASES]);ap.add_argument('--out',type=Path,default=ROOT/'data/matrices/untiered');ap.add_argument('--certificates',type=Path,required=True);args=ap.parse_args();args.certificates.mkdir(parents=True,exist_ok=False)
    for c in CASES:
        if args.all or c['n']==args.n:
            stem,cert=generate(c,args.out);(args.certificates/f'{stem}.json').write_text(json.dumps(cert,indent=2)+'\n');print(stem,flush=True)


if __name__=='__main__':main()
