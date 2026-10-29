#!/usr/bin/env python3
"""Independent integral rank-one/vector-action/actual 2BGA audit, GPL3+.

No constructor imports or third-party group/distance programs. No support search.
"""
import argparse
from collections import Counter
import hashlib
import itertools
import json
import math
from pathlib import Path
from validate_css import basis,read_code,validate
from verify_css_witness import verify_witness


def require(value,message):
    if not value:raise ValueError(message)
def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def support(w):
    out=[]
    while w:
        b=w&-w;out.append(b.bit_length()-1);w^=b
    return out


def rowspace_components(n,rows):
    # Rows live in F2^(2n), preserving X and Z Pauli columns. Link the
    # two column coordinates of each physical qubit only AFTER row reduction.
    p=basis(rows)
    for a in sorted(p):
        for b in p:
            if b>a and ((p[b]>>a)&1):p[b]^=p[a]
    parent=list(range(n))
    def root(q):
        while parent[q]!=q:parent[q]=parent[parent[q]];q=parent[q]
        return q
    for w in p.values():
        qs=sorted({q%n for q in support(w)})
        for q in qs[1:]:parent[root(q)]=root(qs[0])
    return len({root(q) for q in range(n)})


def group_and_actions(case,cert):
    p=case['prime'];eta=case['eta'];require(p>2 and all(p%d for d in range(2,math.isqrt(p)+1)) and eta%p!=0,'invalid prime/unipotent parameter')
    expected=[list(g) for g in itertools.product(range(p),repeat=4) if (g[0]*g[3]-g[1]*g[2])%p==1]
    elements=cert['elements'];G=p*(p*p-1)
    require(len(elements)==G and elements==expected,'complete SL2 determinant-one enumeration mismatch')
    vectors=[v for v in itertools.product(range(p),repeat=2) if v!=(0,0)];vector_index={v:i for i,v in enumerate(vectors)}
    actions=[]
    for a,b,c,d in elements:
        action=tuple(vector_index[((a*x+b*y)%p,(c*x+d*y)%p)] for x,y in vectors)
        require(sorted(action)==list(range(p*p-1)),'non-bijective natural vector action');actions.append(action)
    lookup={a:i for i,a in enumerate(actions)};require(len(lookup)==G,'natural vector action not faithful')
    identity=elements.index([1,0,0,1]);minus=elements.index([p-1,0,0,p-1])
    require(identity==cert['identity'] and identity!=minus and actions[identity]!=actions[minus],'accidental projective quotient or wrong identity')
    index={tuple(g):i for i,g in enumerate(elements)};indices={}
    for key in ('A','B'):
        integer=[]
        for m,a,q,b in case[key+'_conjugators']:
            require(m*b-a*q==1 and math.gcd(m,q)==1 and 0<=m<=eta//2 and 0<=q<=eta//2 and abs(a)<eta/2 and abs(b)<eta/2,'invalid source integral conjugator')
            # Direct rank-one formula, independent of builder C*U*C^-1.
            integer.append([1-eta*m*q,eta*m*m,-eta*q*q,1+eta*m*q])
        require(integer==cert['integral_generators'][key],'source integral conjugation mismatch')
        indices[key]=[index[tuple(x%p for x in g)] for g in integer]
        require(len(indices[key])==len(set(indices[key]))==4 and identity not in indices[key],'source support collisions or identity')
        require(indices[key]==cert['support_indices'][key],'reduced source support index mismatch')
    rebuilt={}
    for key,left in (('A',False),('B',True)):
        perms=[]
        for h in indices[key]:
            permutation=[]
            for g in range(G):
                first,second=(actions[h],actions[g]) if left else (actions[g],actions[h])
                composed=tuple(first[second[v]] for v in range(p*p-1))
                require(composed in lookup,'generator product leaves complete group')
                permutation.append(lookup[composed])
            require(sorted(permutation)==list(range(G)) and all(permutation[g]!=g for g in range(G)),'source regular action fails')
            # Nontrivial unipotents have exact prime order on the regular action.
            current=list(range(G))
            for exponent in range(1,p+1):
                current=[permutation[g] for g in current]
                require((current==list(range(G)))==(exponent==p),'wrong exact generator order')
            perms.append(permutation)
        field='left_B' if left else 'right_A';require(cert[field]==perms,'independent faithful vector composition disagrees with source action');rebuilt[field]=perms
        reached={identity};queue=[identity]
        for g in queue:
            for permutation in perms:
                h=permutation[g]
                if h not in reached:reached.add(h);queue.append(h)
        require(len(reached)==G,'source support does not generate full SL2 group')
    R,L=rebuilt['right_A'],rebuilt['left_B'];squares=0
    for g in range(G):
        for a in range(4):
            for b in range(4):require(R[a][L[b][g]]==L[b][R[a][g]],'actual left-right square fails');squares+=1
        require(Counter(R[a][L[b][g]] for a in range(4) for b in range(4))==Counter(L[b][R[a][g]] for a in range(4) for b in range(4)),'binary two-path multiplicities disagree')
    inverses={}
    for name,perms in rebuilt.items():
        inv=[]
        for permutation in perms:
            inverse=[None]*G
            for g,h in enumerate(permutation):inverse[h]=g
            require(all(permutation[inverse[g]]==inverse[permutation[g]]==g for g in range(G)),'inverse action fails');inv.append(inverse)
        field='inverse_'+name;require(cert[field]==inv,'inverse transpose source action mismatch');inverses[field]=inv
    return dict(group_order=G,central_minus_identity_distinguished=True,faithful_nonprojective_vector_action_verified=True,
                all_generator_products_orders_and_generation_verified=True,commuting_squares=squares),rebuilt,inverses


def certify(case,cert,n,m):
    require(cert['case']==case and cert['parameter_sha256']==digest(case),'case/certificate identity mismatch')
    group,actions,inverses=group_and_actions(case,cert);G=group['group_order'];hx,hz=m[:2]
    require(n==cert['n']==case['n']==2*G and len(hx)==len(hz)==G,'actual 2BGA dimensions mismatch')
    R,L=actions['right_A'],actions['left_B'];Ri,Li=inverses['inverse_right_A'],inverses['inverse_left_B']
    for h in range(G):
        expected=[{Ri[a][h] for a in range(4)},{Li[b][h] for b in range(4)},{L[b][h] for b in range(4)},{R[a][h] for a in range(4)}]
        actual=[{g for g,row in enumerate(rows) if (row>>q)&1} for rows,q in ((hx,h),(hx,G+h),(hz,h),(hz,G+h))]
        require(actual==expected,'actual binary column/right-left inverse-transpose mismatch')
    require(all(len(support(w))==8 for w in hx+hz),'source check weight not eight')
    for rows in (hx,hz):
        total=0
        for w in rows:total^=w
        require(total==0,'even-support all-row dependency fails')
    result=validate(n,m);require(result['k']==cert['k']==case['k']>=2,'actual nontrivial k mismatch')
    require(rowspace_components(n,hx+[w<<n for w in hz])==1,'physical stabilizer space splits into coordinate blocks')
    words=[]
    for half,logical in (('X',m[3]),('Z',m[2])):
        i,w=min(enumerate(logical),key=lambda iw:(len(support(iw[1])),iw[0]));qs=support(w);verify_witness(n,m,half,qs)
        words.append(dict(half=half,basis='Gz' if half=='X' else 'Gx',zero_based_row=i,weight=len(qs),support=qs))
    result.update(stem=f'QMC_{n}_{case["k"]}_unknown',prime=case['prime'],group=group,all_actual_binary_columns_and_inverse_transposes_verified=True,
                  physical_stabilizer_rowspace_connected=True,published_exact=None,
                  individual_source_distance_status='ORIGINAL_FINITE_INSTANCE_NO_PUBLISHED_INDIVIDUAL_EXACT_ASSERTED_NOT_A_GLOBAL_OPEN_PROBLEM_CLAIM',
                  source_author_dataset_identity='NOT_ASSERTED_NO_UNLICENSED_MATRICES_COPIED',
                  independently_checked_uppers=words,independent_overall_upper=min(w['weight'] for w in words),
                  parameter_sha256=digest(case),certificate_sha256=digest(cert),scientific_status='FINITE_SL2_MARGULIS_CSS_AND_ACTUAL_BASIS_UPPERS_ONLY_NO_DISTANCE_PROOF')
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'));ap.add_argument('--cases',type=Path,default=Path(__file__).with_name('quantum_margulis_cases.json'))
    ap.add_argument('--certificates',type=Path,default=Path('optimization/experiments/GH-187/raw/certificates'));ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();results=[]
    for c in json.loads(args.cases.read_text()):
        stem=f'QMC_{c["n"]}_{c["k"]}_unknown';cert=json.loads((args.certificates/f'{stem}.json').read_text());n,m=read_code(args.dir,stem);results.append(certify(c,cert,n,m))
    text=json.dumps(results,indent=2)+'\n';args.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
