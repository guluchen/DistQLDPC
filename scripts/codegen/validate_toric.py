#!/usr/bin/env python3
"""Independent column incidence, cellulation and signed-cover distance checks.

No generator or logical-builder imports; original GF(2)/graph algorithms only.
Full distance mode is intended for bounded Linux validation, not Mac timing.
"""
import argparse
from collections import deque
import json
from pathlib import Path
from validate_css import basis,contains,dot,read_code,validate


def indices(word):
    while word:
        b=word & -word;yield b.bit_length()-1;word^=b


def geometry(l):
    if l<3:raise ValueError('L>=3 required')
    # Derive stars and face membership by column endpoints, not row offsets.
    stars=[0]*(l*l);faces=[0]*(l*l)
    for q in range(2*l*l):
        axis,site=divmod(q,l*l);y,x=divmod(site,l)
        endpoints=((x,y),((x+1)%l,y)) if axis==0 else ((x,y),(x,(y+1)%l))
        adjacent=((x,y),(x,(y-1)%l)) if axis==0 else ((x,y),((x-1)%l,y))
        for a,b in endpoints:stars[b*l+a]|=1 << q
        for a,b in adjacent:faces[b*l+a]|=1 << q
    return stars,faces


def incidence_graph(n,rows):
    ends=[[] for _ in range(n)]
    for v,r in enumerate(rows):
        for q in indices(r):ends[q].append(v)
    if any(len(e)!=2 or e[0]==e[1] for e in ends):raise ValueError('edge must meet two different cells')
    graph=[[] for _ in rows]
    for q,(u,v) in enumerate(ends):graph[u].append((v,q));graph[v].append((u,q))
    seen={0};todo=[0]
    for u in todo:
        for v,_ in graph[u]:
            if v not in seen:seen.add(v);todo.append(v)
    if len(seen)!=len(rows):raise ValueError('disconnected cellulation')
    return graph,ends


def cellulation(n,vertices,faces):
    graph,ends=incidence_graph(n,vertices);incidence_graph(n,faces)
    if len(vertices)-n+len(faces)!=0:raise ValueError('Euler characteristic is not zero')
    for row in vertices+faces:
        if bin(row).count('1')!=4:raise ValueError('square/star must have four edges')
    for face in faces:
        degrees={}
        for q in indices(face):
            for v in ends[q]:degrees[v]=degrees.get(v,0)+1
        if len(degrees)!=4 or set(degrees.values())!={2}:raise ValueError('face is not a simple square')
    # Vertex link: incident edges joined by face corners must form one 4-cycle.
    corners=[[] for _ in vertices]
    for f in faces:
        nearby={v for q in indices(f) for v in ends[q]}
        for v in nearby:corners[v].append(list(indices(f & vertices[v])))
    for v,cs in enumerate(corners):
        link={q:[] for q in indices(vertices[v])}
        for pair in cs:
            if len(pair)!=2:raise ValueError('invalid face corner')
            a,b=pair;link[a].append(b);link[b].append(a)
        if len(cs)!=4 or any(len(ns)!=2 for ns in link.values()):raise ValueError('invalid vertex link degree')
        seen={next(iter(link))};todo=list(seen)
        for a in todo:
            for b in link[a]:
                if b not in seen:seen.add(b);todo.append(b)
        if len(seen)!=4:raise ValueError('pinched vertex link')
    return graph


def shortest_detected(graph,detectors):
    """All roots, each logical detector: shortest odd closed walk via BFS.

    Each Eulerian nontrivial edge set contains an odd-detected simple cycle.
    A signed-double-cover path root0 -> root1 is an odd closed walk. Cancelling
    repeated edges gives a nontrivial cycle word no heavier than the walk.
    Min over all roots/detectors is therefore exactly quotient distance.
    """
    best=None;support=None;winning_detector=None
    for j,detector in enumerate(detectors):
        for root in range(len(graph)):
            start=2*root;target=start+1;parents={start:None};queue=deque([(start,0)])
            found=False
            while queue and not found:
                state,depth=queue.popleft()
                if best is not None and depth+1>=best:continue
                u,sign=divmod(state,2)
                for v,q in graph[u]:
                    nxt=2*v+(sign ^ ((detector>>q)&1))
                    if nxt in parents:continue
                    parents[nxt]=(state,q)
                    if nxt==target:
                        word=0;at=nxt
                        while parents[at] is not None:
                            at,edge=parents[at];word ^= 1 << edge
                        if not dot(word,detector):raise ValueError('odd-cover path lost detection')
                        best=bin(word).count('1');support=list(indices(word));winning_detector=j;found=True;break
                    queue.append((nxt,depth+1))
    if best is None:raise ValueError('no detected graph cycle')
    return dict(distance=best,support=support,detector=winning_detector)


def certify(l,n,m,distance=False):
    hx,hz,gx,gz=m;xx,zz=geometry(l)
    if n!=2*l*l or hx!=xx or hz!=zz:raise ValueError('independent column geometry mismatch')
    r=validate(n,m)
    if r['k']!=2 or r['rank_Hx']!=l*l-1 or r['rank_Hz']!=l*l-1:raise ValueError('unexpected torus ranks')
    primal=cellulation(n,hx,hz);dual=cellulation(n,hz,hx)
    # Straight primal/dual strings; full homology pair independently verified.
    supports={'Z':[[x for x in range(l)],[l*l+y*l for y in range(l)]],
              'X':[[y*l for y in range(l)],[l*l+x for x in range(l)]]}
    witnesses=[]
    for half in ('X','Z'):
        parity,stab,det=(hz,hx,gx) if half=='X' else (hx,hz,gz)
        for support in supports[half]:
            w=sum(1 << q for q in support)
            if len(support)!=l or any(dot(w,h) for h in parity) or contains(basis(stab),w) or not any(dot(w,g) for g in det):
                raise ValueError('invalid winding logical')
            witnesses.append(dict(half=half,support=support,weight=l))
    pairing=[sum(dot(sum(1<<q for q in a),sum(1<<q for q in b)) << j for j,b in enumerate(supports['Z'])) for a in supports['X']]
    if pairing!=[1,2]:raise ValueError('winding intersection is not identity')
    r.update(length=l,genus=1,euler_characteristic=0,closed_connected_primal_dual=True,vertex_links='single 4-cycles',witnesses=witnesses)
    if distance:
        r['primal_Z']=shortest_detected(primal,gz);r['dual_X']=shortest_detected(dual,gx)
        for key,parity,stab,det in (('primal_Z',hx,hz,gz),('dual_X',hz,hx,gx)):
            result=r[key];w=sum(1<<q for q in result['support'])
            if result['distance']!=l or any(dot(w,h) for h in parity) or contains(basis(stab),w) or not any(dot(w,g) for g in det):
                raise ValueError('distance oracle contradicts reference or invalid witness')
        r['distance_status']='EXACT_BOTH_HALVES_INTERNAL_GRAPH_ORACLE_AND_GF2_WITNESS'
    else:r['distance_status']='NOT_RUN; published proof and winding uppers checked separately'
    return r


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--distance',action='store_true');ap.add_argument('--output',type=Path,required=True);a=ap.parse_args();records=[]
    for c in json.loads(Path(__file__).with_name('toric_cases.json').read_text()):
        stem=f'TOR_{c["n"]}_2_unknown';n,m=read_code(a.dir,stem);r=certify(c['length'],n,m,a.distance);r['stem']=stem;records.append(r)
    text=json.dumps(records,indent=2)+'\n';a.output.write_text(text);print(text,end='')


if __name__=='__main__':main()
