#!/usr/bin/env python3
"""Independent finite group, two-color orbit/manifold and integer-cover audit.

No constructor/enumerator imports, no distance or support search.
Original GPL-3.0-or-later mathematical reconstruction.
"""
import argparse
from collections import Counter,deque
import hashlib
import json
from pathlib import Path
from validate_css import basis,read_code,validate
from verify_css_witness import verify_witness


def fail(condition,message):
    if not condition:raise ValueError(message)


def support(w):
    out=[]
    while w:
        b=w&-w;out.append(b.bit_length()-1);w^=b
    return out


def reachable(adjacency,start=0):
    seen={start};queue=deque([start])
    while queue:
        u=queue.popleft()
        for v in adjacency[u]:
            if v not in seen:seen.add(v);queue.append(v)
    return seen


def walk(table,u,word):
    for g in word:u=table[u][g]
    return u


def source_group(c,base):
    table=base['oriented_table'];N=len(table);alphabet='rRsS'
    fail(N==2*c['source_edges'],'oriented group order mismatch')
    rel=[(0,)*c['r'],(2,)*c['s'],(0,2)*2]
    for text in c['words']:
        w=tuple(alphabet.index(ch) for ch in text);rel.extend([w,tuple(g^1 for g in w)])
    for u,row in enumerate(table):
        fail(len(row)==4 and all(0<=v<N for v in row),'invalid group action width')
        fail(all(table[row[g]][g^1]==u for g in range(4)),'source inverse relation')
        fail(all(walk(table,u,w)==u for w in rel),'source defining relation')
    for u in range(N):
        for word,expected in [((0,),c['r']),((2,),c['s']),((0,2),2)]:
            v=u
            for exponent in range(1,expected+1):
                v=walk(table,v,word)
                fail((v==u)==(exponent==expected),'source rotation has wrong exact order')
    # Alternate generator order, then certify regularity by commuting LEFT
    # translations at every state/edge. A relator action alone is insufficient.
    parent=[None]*N;parent[0]=(-1,-1);order=[0]
    for u in order:
        for g in (3,2,1,0):
            v=table[u][g]
            if parent[v] is None:parent[v]=(u,g);order.append(v)
    fail(len(order)==N,'source action disconnected')
    for start in range(N):
        left=[None]*N;left[0]=start
        for v in order[1:]:
            u,g=parent[v];left[v]=table[left[u]][g]
        fail(len(set(left))==N,'source action not regular')
        fail(all(left[table[u][g]]==table[left[u]][g] for u in range(N) for g in range(4)),'left/right regular-action commutation')
    phi=base['reflection_automorphism']
    fail(len(phi)==N and sorted(phi)==list(range(N)) and phi[0]==0,'invalid reflection permutation')
    fail(all(phi[phi[u]]==u and all(phi[table[u][g]]==table[phi[u]][g^1] for g in range(4)) for u in range(N)),'reflection automorphism fails')
    paths=[None]*N;paths[0]=()
    for v in order[1:]:
        u,g=parent[v];paths[v]=paths[u]+(g,)
    generators=[table[0][0],0,table[0][3]];expected=[]
    for u in range(N):
        for parity in (0,1):expected.append([2*walk(table,u,paths[phi[h] if parity else h])+1-parity for h in generators])
    fail(base['adjacency']==expected and base['vertex_parity']==[p for _ in range(N) for p in (0,1)],'semidirect reflection action mismatch')
    return N


def topology(data):
    adj=data['adjacency'];parity=data['vertex_parity'];edges=data['edges'];faces=data['faces'];n=len(adj)
    fail(len(parity)==n and all(p in (0,1) for p in parity),'invalid parity assignment')
    expected=[]
    for u,row in enumerate(adj):
        fail(len(row)==3 and len(set(row))==3,'nontrivalent local vertex')
        for color,v in enumerate(row):
            fail(0<=v<n and v!=u and adj[v][color]==u and parity[u]!=parity[v],'colored involution/bipartition fails')
            if u<v:expected.append([u,v,color])
    fail(sorted(expected)==edges and len({(u,v) for u,v,_ in edges})==len(edges),'actual edge incidence mismatch')
    fail(len(reachable(adj))==n,'disconnected cellulation')
    edge_index={(u,v):e for e,(u,v,_) in enumerate(edges)};inc=[[] for _ in edges];vf=[[] for _ in adj];links=[[] for _ in adj];darts=set();signatures=set()
    for f,face in enumerate(faces):
        vs,cs,es,ss=[face[k] for k in ('vertices','edge_colors','edge_ids','edge_signs')];color=face['color'];L=len(vs)
        fail(L in (4,8,10) and len(set(vs))==L and len(cs)==len(es)==len(ss)==L,'nonsimple face boundary')
        fail(color in (0,1,2) and set(cs)==set(range(3))-{color},'face coloring fails')
        fail(L==[8,4,10][color],'source color-specific face order fails')
        signature=(color,frozenset(vs));fail(signature not in signatures,'duplicate colored face');signatures.add(signature)
        for i,(u,v) in enumerate(zip(vs,vs[1:]+vs[:1])):
            fail(0<=u<n and 0<=v<n and 0<=cs[i]<3 and adj[u][cs[i]]==v,'face boundary not actual colored edge')
            fail((u,cs[i]) not in darts,'dart used by two faces');darts.add((u,cs[i]))
            e=edge_index[(min(u,v),max(u,v))]
            fail(es[i]==e and ss[i]==(1 if u<v else -1),'oriented face sign/edge mismatch')
            inc[e].append((f,ss[i]));vf[u].append(f);links[u].append((es[i-1],es[i]))
    fail(len(darts)==3*n,'missing oriented face darts')
    for e,ends in enumerate(inc):
        fail(len(ends)==2 and sorted(s for _,s in ends)==[-1,1] and ends[0][0]!=ends[1][0],'surface edge not closed oriented')
        fail(faces[ends[0][0]]['color']!=faces[ends[1][0]]['color'],'adjacent faces share color')
    for v in range(n):
        fail(len(vf[v])==3 and {faces[f]['color'] for f in vf[v]}=={0,1,2},'vertex face colors/link multiplicity')
        vertices={e for pair in links[v] for e in pair};degree=Counter(e for pair in links[v] for e in pair)
        fail(len(vertices)==3 and set(degree.values())=={2} and len({tuple(sorted(p)) for p in links[v]})==3,'vertex link not a circle')
    # Independent pair-generator connected components, not ribbon-dart walks.
    expected_faces=set()
    for missing in range(3):
        used=set();colors=set(range(3))-{missing}
        for start in range(n):
            if start in used:continue
            seen={start};queue=[start]
            for u in queue:
                for i in colors:
                    v=adj[u][i]
                    if v not in seen:seen.add(v);queue.append(v)
            used.update(seen);fail(len(seen) in (4,8,10),'wrong source pair-orbit order');expected_faces.add((missing,frozenset(seen)))
    fail(signatures==expected_faces,'two-color orbit face reconstruction mismatch')
    chi=n-len(edges)+len(faces);fail(chi<0 and chi%2==0,'invalid closed hyperbolic Euler characteristic')
    return (2-chi)//2,inc,signatures


def is_tree(edge_ids,vertices,endpoints):
    fail(len(edge_ids)==len(set(edge_ids))==vertices-1,'wrong tree size')
    adjacency=[[] for _ in range(vertices)]
    for e in edge_ids:
        fail(0<=e<len(endpoints),'tree edge outside width');u,v=endpoints[e];adjacency[u].append(v);adjacency[v].append(u)
    fail(len(reachable(adjacency))==vertices,'tree not connected')


def integer_cover(c,cert,base_inc):
    base,final,co=cert['base'],cert['final'],cert['cocycle'];q=c['degree'];nb=len(base['adjacency']);eb=len(base['edges']);fb=len(base['faces']);voltage=co['voltage']
    fail(q>=1 and len(final['adjacency'])==q*nb and len(final['edges'])==q*eb and len(final['faces'])==q*fb,'cover cell counts mismatch')
    fail(len(voltage)==eb and all(isinstance(v,int) for v in voltage),'invalid integer voltage')
    T,S=co['primal_tree_edges'],co['dual_tree_edges'];is_tree(T,nb,[e[:2] for e in base['edges']]);is_tree(S,fb,[[a[0],b[0]] for a,b in base_inc])
    fail(not set(T)&set(S),'primal/dual trees overlap');left=sorted(set(range(eb))-set(T)-set(S))
    fail(co['leftover_edges']==left and co['selected_edge']==left[0] and len(left)==2-nb+eb-fb,'tree-cotree dimension/selection mismatch')
    fail(voltage[left[0]]==1 and all(voltage[e]==0 for e in T),'cover primitive period missing')
    fail(all(sum(voltage[e]*s for e,s in zip(f['edge_ids'],f['edge_signs']))==0 for f in base['faces']),'integral face voltage does not close')
    orientation=[(next(f for f,s in ends if s==-1),next(f for f,s in ends if s==1)) for ends in base_inc];steps=co['dual_cycle_oriented_steps'];rebuilt=[0]*eb
    fail(steps and steps[0][0]==left[0] and tuple(steps[0][1:])==orientation[left[0]],'wrong selected dual edge orientation')
    for i,(e,u,v) in enumerate(steps):
        fail((u,v) in (orientation[e],orientation[e][::-1]) and (i==0 or e in S),'dual path outside source cotree')
        fail(v==steps[(i+1)%len(steps)][1],'dual cycle not closed');rebuilt[e]+=1 if (u,v)==orientation[e] else -1
    fail(rebuilt==voltage,'signed dual cycle/voltage mismatch')
    base_eid={(u,v):e for e,(u,v,_) in enumerate(base['edges'])};edge_lifts=[[] for _ in range(eb)];edge_projection=[]
    for e,(u,v,color) in enumerate(final['edges']):
        bu,bv=u//q,v//q;be=base_eid.get((bu,bv));fail(be is not None and base['edges'][be][2]==color,'edge projection mismatch');edge_projection.append(be);edge_lifts[be].append(e)
        fail((v%q-u%q)%q==voltage[be]%q,'actual edge sheet voltage mismatch')
    fail(all(len(es)==q for es in edge_lifts),'edge projection fiber not q-to-one')
    for v,row in enumerate(final['adjacency']):
        fail(final['vertex_parity'][v]==base['vertex_parity'][v//q],'orientation parity not pulled back')
        fail([w//q for w in row]==base['adjacency'][v//q],'vertex neighborhood projection not a bijection')
    base_faces={(f['color'],frozenset(f['vertices'])):i for i,f in enumerate(base['faces'])};face_lifts=[[] for _ in range(fb)]
    for f,face in enumerate(final['faces']):
        projected=[v//q for v in face['vertices']];bf=base_faces.get((face['color'],frozenset(projected)));fail(bf is not None,'face projection missing');source=base['faces'][bf]
        fail(len(projected)==len(set(projected))==len(source['vertices']),'face projection not boundary bijection')
        j=source['vertices'].index(projected[0]);fail(projected==source['vertices'][j:]+source['vertices'][:j],'face orientation projection mismatch');face_lifts[bf].append(f)
        actual=Counter()
        for e,s in zip(face['edge_ids'],face['edge_signs']):actual[edge_projection[e]]+=s
        fail(dict(actual)==dict(zip(source['edge_ids'],source['edge_signs'])),'integer P1 d2=d2 P2 chain identity')
    fail(all(len(fs)==q for fs in face_lifts),'face fiber not q-to-one')
    # Explicit integral chain transfer, not just counting edges or congruences.
    for be,es in enumerate(edge_lifts):
        actual=Counter()
        for e in es:
            u,v,_=final['edges'][e];actual[u]-=1;actual[v]+=1
        u,v,_=base['edges'][be];expected=Counter({u*q+t:-1 for t in range(q)});expected.update({v*q+t:1 for t in range(q)})
        fail(dict(actual)==dict(expected),'integer d1 T1=T0 d1 transfer identity')
    for bf,fs in enumerate(face_lifts):
        actual=Counter()
        for f in fs:
            for e,s in zip(final['faces'][f]['edge_ids'],final['faces'][f]['edge_signs']):actual[e]+=s
        expected={e:s for be,s in zip(base['faces'][bf]['edge_ids'],base['faces'][bf]['edge_signs']) for e in edge_lifts[be]}
        fail(dict(actual)==expected,'integer d2 T2=T1 d2 transfer identity')
    return dict(integral_face_closure=True,primitive_period=1,all_vertex_edge_face_fibers_verified=True,integer_chain_projection_and_transfer_verified=True)


def rowspace_components(n,rows):
    # Unique reduced basis exposes a physical direct-sum partition even when
    # the input check rows have been mixed across its coordinate blocks.
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


def certify(c,cert,n,m):
    fail(cert['case']==c and cert['parameter_sha256']==hashlib.sha256(json.dumps(c,sort_keys=True,separators=(',',':')).encode()).hexdigest(),'case/certificate identity mismatch')
    source_group(c,cert['base']);baseg,baseinc,_=topology(cert['base']);g,_,_=topology(cert['final']);cover=integer_cover(c,cert,baseinc)
    fail(n==c['n']==len(cert['final']['adjacency']) and g==c['genus']==c['degree']*(baseg-1)+1,'finite genus/size mismatch')
    rows=[sum(1<<v for v in f['vertices']) for f in cert['final']['faces']];fail(m[0]==m[1]==rows,'actual static CSS face matrix mismatch')
    fail(rowspace_components(n,rows)==1,'physical stabilizer rowspace splits into coordinate blocks')
    result=validate(n,m);fail(result['k']==c['k']==4*g and result['rank_Hx']==result['rank_Hz']==len(rows)-2,'actual static rank/homology mismatch')
    for color in range(3):
        total=0
        for face,row in zip(cert['final']['faces'],rows):
            if face['color']==color:total^=row
        fail(total==(1<<n)-1,'face-color stabilizer dependency fails')
    words=[]
    for half,logical in (('X',m[3]),('Z',m[2])):
        i,w=min(enumerate(logical),key=lambda iw:(len(support(iw[1])),iw[0]));qs=support(w);verify_witness(n,m,half,qs);words.append(dict(half=half,basis='Gz' if half=='X' else 'Gx',zero_based_row=i,weight=len(qs),support=qs))
    result.update(stem=f'COLOR_{n}_{c["k"]}_unknown',genus=g,base_genus=baseg,degree=c['degree'],source_regular_action_and_reflection_verified=True,
                  all_closed_oriented_manifold_links_and_color_orbits_verified=True,cover=cover,physical_XZ_identity_map=True,physical_stabilizer_rowspace_connected=True,
                  independently_checked_uppers=words,independent_overall_upper=min(w['weight'] for w in words),published_exact=None,
                  parameter_sha256=cert['parameter_sha256'],certificate_sha256=hashlib.sha256(json.dumps(cert,sort_keys=True,separators=(',',':')).encode()).hexdigest(),
                  scientific_status='STATIC_CLOSED_COLOR_CONSTRUCTION_AND_ACTUAL_BASIS_UPPERS_ONLY_NO_DISTANCE_PROOF')
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'));ap.add_argument('--cases',type=Path,default=Path(__file__).with_name('closed_color_cases.json'));ap.add_argument('--certificates',type=Path,default=Path('optimization/experiments/GH-184/raw/certificates'));ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();results=[]
    for c in json.loads(args.cases.read_text()):
        stem=f'COLOR_{c["n"]}_{c["k"]}_unknown';cert=json.loads((args.certificates/f'{stem}.json').read_text());n,m=read_code(args.dir,stem);results.append(certify(c,cert,n,m))
    text=json.dumps(results,indent=2)+'\n';args.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
