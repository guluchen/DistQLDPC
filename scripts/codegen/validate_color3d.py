#!/usr/bin/env python3
"""Independent 3-colex/flag/manifold/chain/GF(2) checks; no builder imports.

Original GPL-3.0-or-later. No distance/support search or external program.
"""
import argparse
from collections import Counter,defaultdict
import hashlib
import itertools
import json
from pathlib import Path
from validate_css import basis,dot,equal_space,read_code,validate
from verify_css_witness import verify_witness


def require(value,message):
    if not value:raise ValueError(message)


def packed(vs):return sum(1<<v for v in vs)
def digest(value):return hashlib.sha256(json.dumps(value,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def support(w):
    out=[]
    while w:
        b=w&-w;out.append(b.bit_length()-1);w^=b
    return out


def components(adj,colors):
    unseen=set(range(len(adj)));out=[]
    while unseen:
        start=min(unseen);stack=[start];found={start};unseen.remove(start)
        while stack:
            u=stack.pop()
            for i in reversed(colors):
                v=adj[u][i]
                if v not in found:found.add(v);unseen.remove(v);stack.append(v)
        out.append(found)
    return out


def periodic_source(case,cert):
    """Independent downward cell boundaries and complete flags, not corner/permutation enumeration."""
    L=case['periods'];positions=list(itertools.product(*(range(l) for l in L)));index={p:i for i,p in enumerate(positions)}
    require(cert['positions']==[list(p) for p in positions],'original position labels mismatch')
    groups=[[] for _ in range(4)];boundary={}
    for pos,p in enumerate(positions):
        for mask in range(8):
            cell=8*pos+mask;axes=[j for j in range(3) if mask&(1<<j)];groups[len(axes)].append(cell);terms=[]
            for j,axis in enumerate(axes):
                q=list(p);q[axis]=(q[axis]+1)%L[axis]
                terms.extend([(8*index[tuple(q)]+(mask^(1<<axis)),(-1)**j),
                              (8*pos+(mask^(1<<axis)),-(-1)**j)])
            boundary[cell]=terms
    for d in (2,3):
        for cell in groups[d]:
            composed=Counter()
            for face,s in boundary[cell]:
                for edge,t in boundary[face]:composed[edge]+=s*t
            require(all(v==0 for v in composed.values()),'integer primal boundary does not square to zero')
    ranks=[0]
    for d in (1,2,3):
        below={cell:i for i,cell in enumerate(groups[d-1])}
        ranks.append(len(basis([packed(below[c] for c,_ in boundary[cell]) for cell in groups[d]])))
    ranks.append(0);betti=[len(groups[d])-ranks[d]-ranks[d+1] for d in range(4)]
    require(betti==[1,3,3,1],'original cubical torus Betti mismatch')
    expected=set()
    for cube in groups[3]:
        for face,_ in boundary[cube]:
            for edge,_ in boundary[face]:
                for vertex,_ in boundary[edge]:expected.add((vertex,edge,face,cube))
    flags=[tuple(f) for f in cert['flags']]
    require(len(flags)==len(set(flags))==48*len(positions) and set(flags)==expected,'complete primal maximal flags mismatch')
    require(all(len(f)==4 for f in flags),'invalid flag width')
    facets=defaultdict(list)
    for v,f in enumerate(flags):
        for rank in range(4):facets[(rank,f[:rank]+f[rank+1:])].append(v)
    adj=cert['adjacency']
    for (color,_),vs in facets.items():
        require(len(vs)==2,'primal flag facet not two-sided');u,v=vs
        require(adj[u][color]==v and adj[v][color]==u,'actual missing-rank flag adjacency mismatch')
    cellgroups=defaultdict(list);facegroups=defaultdict(list)
    for v,f in enumerate(flags):
        for cell in f:cellgroups[cell].append(v)
        for pair in itertools.combinations(f,2):facegroups[pair].append(v)
    require(cert['cell_keys']==sorted(cellgroups) and cert['cells']==[cellgroups[c] for c in sorted(cellgroups)],'inflated original cells mismatch')
    require(cert['face_keys']==[list(p) for p in sorted(facegroups)] and cert['faces']==[facegroups[p] for p in sorted(facegroups)],'inflated comparable-cell faces mismatch')
    expected_cells={(len(support(cell%8)),frozenset(vs)) for cell,vs in cellgroups.items()}
    expected_faces={(tuple(i for i in range(4) if i not in [len(support(pair[0]%8)),len(support(pair[1]%8))]),frozenset(vs)) for pair,vs in facegroups.items()}
    return expected_cells,expected_faces,betti


def topology(case,cert):
    adj=cert['adjacency'];n=len(adj)
    require(n==case['n'],'actual n mismatch')
    for u,row in enumerate(adj):
        require(len(row)==4 and len(set(row))==4,'non-simple four-valent graph')
        for i,v in enumerate(row):require(type(v)==int and 0<=v<n and v!=u and adj[v][i]==u,'colored neighbor involution fails')
    require(len(components(adj,list(range(4))))==1,'disconnected colex')
    parity={0:0};queue=[0]
    for u in queue:
        for v in adj[u]:
            if v not in parity:parity[v]=1-parity[u];queue.append(v)
            require(parity[v]!=parity[u],'nonorientable colored triangulation')
    cells=[];faces=[]
    for missing in range(4):
        for vs in components(adj,[i for i in range(4) if i!=missing]):cells.append((missing,frozenset(vs)))
    for colors in itertools.combinations(range(4),2):
        for vs in components(adj,list(colors)):
            require(len(vs)>=4 and len(vs)%2==0,'degenerate two-color face')
            # Traverse the actual alternating cycle, requiring a simple polygon.
            v=min(vs);walk=[];color=colors[0]
            while v not in walk:
                walk.append(v);v=adj[v][color];color=colors[1] if color==colors[0] else colors[0]
            require(v==walk[0] and set(walk)==vs and color==colors[0],'two-color face not simple cycle')
            faces.append((colors,frozenset(vs)))
    require(len(cells)==len(cert['cells']) and Counter(vs for _,vs in cells)==Counter(frozenset(vs) for vs in cert['cells']),'three-color volume residue mismatch')
    require(len(faces)==len(cert['faces']) and Counter(vs for _,vs in faces)==Counter(frozenset(vs) for vs in cert['faces']),'two-color face residue mismatch')
    # A connected cubic residue with bicolored polygon faces is a closed
    # surface: every edge has two faces and each vertex link is a triangle.
    # Bipartition gives consistent orientation. Euler2 then proves sphere.
    for missing,vs in cells:
        colors=[i for i in range(4) if i!=missing]
        fs=[(cs,ws) for cs,ws in faces if missing not in cs and ws<=vs]
        require(len(vs)-3*len(vs)//2+len(fs)==2,'volume boundary is not a sphere')
        pervertex=Counter(v for _,ws in fs for v in ws)
        require(set(pervertex)==set(vs) and set(pervertex.values())=={3},'volume boundary vertex link mismatch')
        edge_faces=Counter()
        for cs,ws in fs:
            for u in ws:
                for color in cs:
                    if u<adj[u][color]:edge_faces[(u,color)]+=1
        require(len(edge_faces)==3*len(vs)//2 and set(edge_faces.values())=={2},'volume boundary not closed manifold')
        require(all(len({tuple(cs) for cs,ws in fs if u in ws})==3 for u in vs),'volume vertex link not triangle')
    # Reconstruct all finite cellular boundaries from residues and actual edges.
    edges=[(u,v,i) for u,row in enumerate(adj) for i,v in enumerate(row) if u<v];ei={(u,v,i):e for e,(u,v,i) in enumerate(edges)}
    d1=[(1<<u)|(1<<v) for u,v,_ in edges];d2=[]
    for colors,vs in faces:
        d2.append(packed(ei[(u,adj[u][i],i)] for u in vs for i in colors if u<adj[u][i]))
    d3=[]
    for missing,vs in cells:d3.append(packed(j for j,(colors,ws) in enumerate(faces) if missing not in colors and ws<=vs))
    for columns,below in ((d2,d1),(d3,d2)):
        for w in columns:
            boundary=0
            for j in support(w):boundary^=below[j]
            require(boundary==0,'colex boundary does not square to zero')
    sizes=[n,len(edges),len(faces),len(cells)];ranks=[0,len(basis(d1)),len(basis(d2)),len(basis(d3)),0]
    betti=[sizes[d]-ranks[d]-ranks[d+1] for d in range(4)]
    target=[1,1,1,1] if case['kind']=='rp3' else [1,3,3,1]
    require(betti==target,'actual colex homology mismatch')
    if case['kind']=='rp3':
        require(adj==[[u^flip for flip in (1,2,4,7)] for u in range(8)],'source projective-space cube involutions mismatch')
        require(cert['flags']==[] and cert['positions']==[],'unexpected RP3 primal data')
    else:
        ec,ef,primalbetti=periodic_source(case,cert)
        require(set(cells)==ec and set(faces)==ef,'primal incidence and colored residues disagree')
        V=len(cert['positions'])
        require(sizes==[48*V,96*V,56*V,8*V],'finite inflation cell counts mismatch')
        require(set(map(len,cert['cells']))=={16,48} and set(map(len,cert['faces']))=={4,6,8},'finite local check weights mismatch')
    return dict(cells=sizes,colex_boundary_ranks=ranks[1:4],betti=betti,all_volume_boundaries_spheres=True,all_flag_facets_and_colored_residues_verified=True)


def rowspace_components(n,rows):
    p=basis(rows)
    for a in sorted(p):
        for b in p:
            if b>a and ((p[b]>>a)&1):p[b]^=p[a]
    parent=list(range(n))
    def root(q):
        while parent[q]!=q:parent[q]=parent[parent[q]];q=parent[q]
        return q
    for w in p.values():
        qs=support(w)
        for q in qs[1:]:parent[root(q)]=root(qs[0])
    return len({root(q) for q in range(n)})


def certify(case,cert,n,m):
    require(cert['case']==case and cert['parameter_sha256']==digest(case),'parameter identity mismatch')
    topo=topology(case,cert)
    require(m[0]==[packed(vs) for vs in cert['cells']] and m[1]==[packed(vs) for vs in cert['faces']],'actual static X-volume/Z-face matrix mismatch')
    result=validate(n,m);require(result['k']==case['k']==3*topo['betti'][1],'actual logical dimension mismatch')
    require(rowspace_components(n,m[0]+m[1])==1,'physical stabilizer space splits into coordinate blocks')
    if case['kind']=='rp3':
        cube_faces=[packed(u for u in range(8) if (u>>i)&1==bit) for i in range(3) for bit in (0,1)]
        require(equal_space(m[0],[255]) and equal_space(m[1],cube_faces),'published cube anchor stabilizer equivalence fails')
    else:
        V=len(cert['positions']);require(result['rank_Hx']==8*V-3 and result['rank_Hz']==40*V-6,'finite CSS ranks disagree')
    words=[]
    for half,logical in (('X',m[3]),('Z',m[2])):
        i,w=min(enumerate(logical),key=lambda iw:(len(support(iw[1])),iw[0]));qs=support(w)
        verify_witness(n,m,half,qs);words.append(dict(half=half,basis='Gz' if half=='X' else 'Gx',zero_based_row=i,weight=len(qs),support=qs))
    result.update(stem=f'COLOR_{n}_{case["k"]}_unknown',topology=topo,published_exact=case['published_exact'],
                  individual_source_distance_status='PUBLISHED_EXACT_ANCHOR' if case['published_exact'] else 'NO_PUBLISHED_INDIVIDUAL_EXACT_ASSERTED_NOT_A_GLOBAL_OPEN_PROBLEM_CLAIM',
                  physical_stabilizer_rowspace_connected=True,physical_XZ_identity_map=False,
                  independently_checked_uppers=words,independent_overall_upper=min(w['weight'] for w in words),
                  parameter_sha256=digest(case),certificate_sha256=digest(cert),
                  scientific_status='STATIC_3COLEX_CONSTRUCTION_AND_ACTUAL_BASIS_UPPERS_ONLY_NO_DISTANCE_PROOF')
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path(__file__).with_name('color3d_cases.json'))
    ap.add_argument('--certificates',type=Path,default=Path('optimization/experiments/GH-185/raw/certificates'));ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args();results=[]
    for c in json.loads(args.cases.read_text()):
        stem=f'COLOR_{c["n"]}_{c["k"]}_unknown';cert=json.loads((args.certificates/f'{stem}.json').read_text());n,m=read_code(args.dir,stem);results.append(certify(c,cert,n,m))
    text=json.dumps(results,indent=2)+'\n';args.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
