#!/usr/bin/env python3
"""Independent wedge/rail incidence checks for static triangular4.8.8 CSS.

Uses u=R-x,v=(y-6)/2 inequalities and physical-column pullback.
No generator or logical-builder imports. GPL-3.0-or-later.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
from validate_css import basis,contains,dot,read_code,validate
from verify_css_witness import verify_witness


def wedge(m):
    if type(m)!=int or m<1:raise ValueError('invalid m')
    sites=[(u,v) for v in range(4*m-1) for u in range(4*m-2,-1,-1)
           if u<=2*v+2 and u+2*v<=8*m-4]
    present=set(sites);faces=[]
    def retain(points,required=False):
        face=frozenset(points)
        if face<=present:
            if face in faces:raise ValueError('duplicate independent face')
            faces.append(face)
        elif required:raise ValueError('boundary face outside wedge')
    for v in range(4*m-2):
        for u in range(4*m-1):
            if (u+1+2*v)%4==2 or (u==0 and v%2==0):
                retain(( (a,b) for a in (u,u+1) for b in (v,v+1)))
            if u%2==0 and (u+2*v)%4==2:
                retain(((a,b) for a in range(u,u+4) for b in (v,v+1)))
    for h in range(m-1):
        u,v=2+4*h,2*h
        retain(((u,v),(u,v+1),(u+1,v+1),(u+2,v+1)),True)
    for h in range(m):
        u,v=4*m-4-4*h,2*m-1+2*h
        retain(((u,v),(u+1,v),(u+2,v),(u,v+1)),True)
    right=-4*m-1
    faces.sort(key=lambda f:(min(v for u,v in f),-max(u for u,v in f),len(f),sorted((right-u,6+2*v) for u,v in f)))
    # Assemble incidences by looking up each physical column's faces.
    incidence={q:[] for q in sites}
    for i,f in enumerate(faces):
        for q in f:incidence[q].append(i)
    rows=[0]*len(faces)
    for q,point in enumerate(sites):
        for i in incidence[point]:rows[i]|=1<<q
    return sites,faces,rows


def face_graph(rows):
    graph=[set() for _ in rows]
    for i,row in enumerate(rows):
        for j in range(i):
            overlap=bin(row&rows[j]).count('1')
            if overlap not in (0,2):raise ValueError('face overlap is not zero or two')
            if overlap:graph[i].add(j);graph[j].add(i)
    return graph


def three_colors(graph):
    colors={}
    # DSATUR with deterministic branching, a graph check rather than assumed
    # color labels imported from the construction. No distance computation.
    def visit():
        if len(colors)==len(graph):return True
        uncolored=[i for i in range(len(graph)) if i not in colors]
        i=max(uncolored,key=lambda i:(len({colors[j] for j in graph[i] if j in colors}),len(graph[i]),-i))
        used={colors[j] for j in graph[i] if j in colors}
        for c in range(3):
            if c not in used:
                colors[i]=c
                if visit():return True
                del colors[i]
        return False
    import sys
    old=sys.getrecursionlimit();sys.setrecursionlimit(max(old,len(graph)+200))
    try:
        if not visit():raise ValueError('faces not three-colorable')
    finally:sys.setrecursionlimit(old)
    return [colors[i] for i in range(len(graph))]


def certify(c,n,matrices):
    m=c['m'];sites,faces,rows=wedge(m);hx,hz,gx,gz=matrices
    if hx!=rows or hz!=rows:raise ValueError('matrix differs from independent wedge columns')
    result=validate(n,matrices)
    if n!=8*m*m-1 or c['n']!=n or c['d']!=4*m-1 or c['k']!=1 or result['k']!=1:
        raise ValueError('source n,k,d formula mismatch')
    if len(rows)!=(n-1)//2 or len(set(rows))!=len(rows):raise ValueError('face count/duplicates')
    graph=face_graph(rows);colors=three_colors(graph)
    seen={0};todo=[0]
    while todo:
        for j in graph[todo.pop()]:
            if j not in seen:seen.add(j);todo.append(j)
    if len(seen)!=len(rows):raise ValueError('disconnected face graph')
    degrees=[sum((r>>q)&1 for r in rows) for q in range(n)]
    if not set(degrees)<={1,2,3} or not all(degrees):raise ValueError('invalid data-qubit degree')
    all_data=(1<<n)-1;boundary=sum(1<<q for q,(u,v) in enumerate(sites) if u==0)
    witnesses=[]
    for word,label in ((boundary,'right boundary'),(all_data,'all data')):
        support=[q for q in range(n) if (word>>q)&1]
        for half in ('X','Z'):
            verify_witness(n,matrices,half,support)
            witnesses.append(dict(half=half,label=label,support=support,weight=len(support)))
    if bin(boundary).count('1')!=c['d'] or not dot(boundary,all_data):raise ValueError('boundary upper word mismatch')
    # Both supplied quotient bases represent the same nonzero class as the
    # independently specified all-data logical because k=1.
    if not contains(basis(rows),gx[0]^all_data) or not contains(basis(rows),gz[0]^all_data):
        raise ValueError('logical differs from all-data class')
    result.update(stem=f'COLOR_{n}_1_unknown',m=m,published_static_d=c['d'],
        face_weights=dict(sorted(Counter(bin(r).count('1') for r in rows).items())),
        qubit_degrees=dict(sorted(Counter(degrees).items())),face_colors=colors,
        connected=True,independent_wedge_columns=True,witnesses=witnesses,verified_boundary_ub=c['d'])
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path(__file__).with_name('color488_cases.json'))
    ap.add_argument('--output',type=Path,required=True);args=ap.parse_args();results=[]
    for c in json.loads(args.cases.read_text()):
        n,m=read_code(args.dir,f'COLOR_{c["n"]}_1_unknown');results.append(certify(c,n,m))
    text=json.dumps(results,indent=2)+'\n';args.output.write_text(text);print(text,end='')


if __name__=='__main__':main()
