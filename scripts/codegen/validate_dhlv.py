#!/usr/bin/env python3
"""Independent faithful group/edge/square/actual binary-chain audit (GPL3+).

No constructor imports, no distance/support search or third-party solver.
Actual Pauli weight is binary coordinate weight, not edge-block weight.
"""
import argparse
from collections import Counter,defaultdict
import hashlib
import itertools
import json
from pathlib import Path
from validate_css import basis,dot,read_code,validate
from verify_css_witness import verify_witness


def require(value,message):
    if not value:raise ValueError(message)


def digest(value):return hashlib.sha256(json.dumps(value,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def support(w):
    out=[]
    while w:
        b=w&-w;out.append(b.bit_length()-1);w^=b
    return out
def pack(vs):return sum(1<<v for v in vs)


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


def geometry(case,cert):
    m=case['rotation_order'];G=2*m;table=cert['multiplication'];elements=cert['elements']
    expected=[list(g) for g in itertools.product(range(m),range(2))]
    require(elements==expected,'dihedral element labels mismatch')
    # Faithful polygon permutations; compose every pair, independently of
    # the builder's dihedral multiplication formula.
    permutations=[tuple((r+(1 if s==0 else -1)*p)%m for p in range(m)) for r,s in elements]
    lookup={p:i for i,p in enumerate(permutations)}
    require(len(lookup)==G and len(table)==G,'nonfaithful/wrong-size group action')
    for a,row in enumerate(table):
        require(len(row)==G and all(row[b]==lookup[tuple(permutations[a][permutations[b][p]] for p in range(m))] for b in range(G)),'faithful group composition fails')
    require(table[0]==list(range(G)) and all(table[g][0]==g for g in range(G)),'identity mismatch')
    index={tuple(g):i for i,g in enumerate(elements)}
    A=[index[tuple(g)] for g in case['A']];B=[index[tuple(g)] for g in case['B']];delta=len(A)
    inverse=[next(j for j in range(G) if table[g][j]==table[j][g]==0) for g in range(G)]
    for labels in (A,B):
        require(len(labels)==len(set(labels))==delta and 0 not in labels and {inverse[a] for a in labels}==set(labels),'non-distinct/non-symmetric generating set')
        seen={0};queue=[0]
        for g in queue:
            for h in labels:
                v=table[h][g]
                if v not in seen:seen.add(v);queue.append(v)
        require(len(seen)==G,'source Cayley graph disconnected')
    HA,HB=case['HA'],case['HB'];ma,mb=len(HA),len(HB)
    require(all(len(row)==delta and set(row)<={0,1} for row in HA+HB),'invalid binary local parity matrix')
    require(len(basis([pack(j for j,b in enumerate(row) if b) for row in HA]))==ma and len(basis([pack(j for j,b in enumerate(row) if b) for row in HB]))==mb,'local parity rank mismatch')
    require(all(any(row[j] for row in HA) and any(row[j] for row in HB) for j in range(delta)),'zero local column')
    require((cert['ma'],cert['mb'])==(ma,mb),'edge stalk dimensions mismatch')
    vertices=cert['vertices'];require(vertices==[[g,x,y] for g in range(G) for x in (0,1) for y in (0,1)],'four-part vertex labels mismatch')
    vi={tuple(v):i for i,v in enumerate(vertices)};edges=cert['edges'];seen=set();adj=[[] for _ in vertices];offset=0
    for e in edges:
        axis,side,g,label=[e[key] for key in ('axis','side','base','label')]
        require(axis in ('A','B') and side in (0,1) and 0<=g<G and 0<=label<delta,'invalid edge label')
        key=(axis,side,g,label);require(key not in seen,'duplicate edge');seen.add(key)
        h=(A if axis=='A' else B)[label]
        ends=([vi[(g,0,side)],vi[(table[h][g],1,side)]] if axis=='A' else [vi[(g,side,0)],vi[(table[g][h],side,1)]])
        require(e['ends']==ends and e['width']==(mb if axis=='A' else ma) and e['offset']==offset,'actual edge endpoints/stalk width/offset mismatch')
        offset+=e['width'];u,v=ends;adj[u].append(v);adj[v].append(u)
    require(seen==set(itertools.product(('A','B'),(0,1),range(G),range(delta))),'incomplete edge set')
    reached={0};queue=[0]
    for u in queue:
        for v in adj[u]:
            if v not in reached:reached.add(v);queue.append(v)
    require(len(reached)==4*G and all(len(row)==2*delta for row in adj),'four-part complex disconnected or irregular')
    # Identify edges by actual ordered endpoints, not builder key lookup.
    endpoint_edge={tuple(e['ends']):i for i,e in enumerate(edges)}
    require(len(endpoint_edge)==len(edges),'parallel source edges collapsed')
    seen=set();edge_faces=[[] for _ in edges];vertex_faces=[[] for _ in vertices]
    for f,square in enumerate(cert['squares']):
        g,a,b=[square[key] for key in ('base','a','b')];require(0<=g<G and 0<=a<delta and 0<=b<delta,'invalid square label')
        key=(g,a,b);require(key not in seen,'duplicate square');seen.add(key)
        ag=table[A[a]][g];gb=table[g][B[b]];agb=table[ag][B[b]]
        require(agb==table[A[a]][gb],'actual left-right square does not close')
        vs=[vi[(g,0,0)],vi[(ag,1,0)],vi[(gb,0,1)],vi[(agb,1,1)]]
        es=[endpoint_edge[(vs[0],vs[1])],endpoint_edge[(vs[2],vs[3])],endpoint_edge[(vs[0],vs[2])],endpoint_edge[(vs[1],vs[3])]]
        require(square['vertices']==vs and square['edges']==es,'actual square incidence mismatch')
        for edge in es:edge_faces[edge].append(f)
        for v in vs:vertex_faces[v].append(f)
    require(seen==set(itertools.product(range(G),range(delta),range(delta))),'incomplete square set')
    require(all(len(fs)==delta for fs in edge_faces) and all(len(fs)==delta*delta for fs in vertex_faces),'local full-star incidence mismatch')
    require(offset==case['n']==cert['n']==2*G*delta*(ma+mb),'actual binary physical dimension mismatch')
    return dict(table=table,A=A,B=B,HA=HA,HB=HB,ma=ma,mb=mb,edge_faces=edge_faces,vertex_faces=vertex_faces)


def actual_chain(case,cert,n,matrices,data):
    hx,hz=matrices[:2];ma,mb=data['ma'],data['mb'];HA,HB=data['HA'],data['HB'];edges=cert['edges'];squares=cert['squares']
    require(len(hx)==len(cert['vertices'])*ma*mb and len(hz)==len(squares),'actual boundary dimensions mismatch')
    # Inspect every physical COLUMN of d1 through its endpoint tensor map.
    for e in edges:
        local=HA if e['axis']=='A' else HB
        for q in range(e['width']):
            actual={i for i,row in enumerate(hx) if (row>>(e['offset']+q))&1};expected=set()
            for v in e['ends']:
                if e['axis']=='A':expected.update((v*ma+ia)*mb+q for ia in range(ma) if local[ia][e['label']])
                else:expected.update((v*ma+q)*mb+ib for ib in range(mb) if local[ib][e['label']])
            require(actual==expected,'actual binary d1 endpoint/local-label column mismatch')
    # Reconstruct d2 by edge full stars, recovering the missing direction
    # of each incident square; do not reuse the constructor face assembly.
    d2_columns=[0]*n
    for eid,e in enumerate(edges):
        local=HB if e['axis']=='A' else HA;key='b' if e['axis']=='A' else 'a'
        labels=[squares[f][key] for f in data['edge_faces'][eid]]
        require(sorted(labels)==list(range(len(data['A']))),'edge-to-face local labels not bijective')
        for q,row in enumerate(local):d2_columns[e['offset']+q]=pack(f for f in data['edge_faces'][eid] if row[squares[f][key]])
    for q,column in enumerate(d2_columns):require(column==pack(f for f,row in enumerate(hz) if (row>>q)&1),'actual binary d2 edge-star column mismatch')
    # Every corner has two separate tensor paths, each the SAME actual
    # HA[:,a] tensor HB[:,b]. Check each path before their GF2 cancellation.
    paths=0
    for f,square in enumerate(squares):
        expected=pack(ia*mb+ib for ia in range(ma) for ib in range(mb) if HA[ia][square['a']] and HB[ib][square['b']])
        for v in square['vertices']:
            incident=[edges[eid] for eid in square['edges'] if v in edges[eid]['ends']]
            require(len(incident)==2,'square corner not two-sided')
            for e in incident:
                mapped=0
                for ia in range(ma):
                    for ib in range(mb):
                        bit=0
                        for q in range(e['width']):bit^=((hx[(v*ma+ia)*mb+ib]>>(e['offset']+q))&1)*((hz[f]>>(e['offset']+q))&1)
                        if bit:mapped^=1<<(ia*mb+ib)
                require(mapped==expected,'actual corner tensor path is wrong');paths+=1
    return dict(binary_columns_and_all_edge_full_stars_verified=True,actual_corner_tensor_paths_verified=paths,binary_chain_composition_verified=True)


def certify(case,cert,n,matrices):
    require(cert['case']==case and cert['parameter_sha256']==digest(case),'case/certificate identity mismatch')
    data=geometry(case,cert);chain=actual_chain(case,cert,n,matrices,data)
    result=validate(n,matrices);require(result['k']==case['k']==cert['k'],'actual k mismatch')
    require(rowspace_components(n,matrices[0]+matrices[1])==1,'physical stabilizer space splits into coordinate blocks')
    G=len(cert['elements']);delta=len(case['A']);ma,mb=data['ma'],data['mb']
    require(result['k']>=n-4*G*ma*mb-G*delta*delta>0,'actual dimension below finite counting bound')
    words=[]
    for half,logical in (('X',matrices[3]),('Z',matrices[2])):
        i,w=min(enumerate(logical),key=lambda iw:(len(support(iw[1])),iw[0]));qs=support(w);verify_witness(n,matrices,half,qs)
        words.append(dict(half=half,basis='Gz' if half=='X' else 'Gx',zero_based_row=i,weight=len(qs),support=qs))
    result.update(stem=f'DHLV_{n}_{case["k"]}_unknown',case_id=case['id'],group_order=G,degree=delta,local_parity_ranks=[ma,mb],
                  faithful_group_action_and_every_left_right_square_verified=True,chain=chain,physical_stabilizer_rowspace_connected=True,
                  physical_weight='expanded binary bits, not geometric edge blocks',published_exact=None,
                  individual_source_distance_status='ORIGINAL_FINITE_INSTANCE_NO_PUBLISHED_INDIVIDUAL_EXACT_ASSERTED_NOT_A_GLOBAL_OPEN_PROBLEM_CLAIM',
                  good_distance_and_linear_decoder_hypotheses='NOT_CERTIFIED_FOR_THESE_FINITE_SPECIALIZATIONS',
                  independently_checked_uppers=words,independent_overall_upper=min(w['weight'] for w in words),
                  parameter_sha256=digest(case),certificate_sha256=digest(cert),scientific_status='FINITE_DHLV_CHAIN_AND_ACTUAL_BASIS_UPPERS_ONLY_NO_DISTANCE_PROOF')
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'));ap.add_argument('--cases',type=Path,default=Path(__file__).with_name('dhlv_cases.json'))
    ap.add_argument('--certificates',type=Path,default=Path('optimization/experiments/GH-186/raw/certificates'));ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();results=[]
    for c in json.loads(args.cases.read_text()):
        stem=f'DHLV_{c["n"]}_{c["k"]}_unknown';cert=json.loads((args.certificates/f'{stem}.json').read_text());n,matrices=read_code(args.dir,stem);results.append(certify(c,cert,n,matrices))
    text=json.dumps(results,indent=2)+'\n';args.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
