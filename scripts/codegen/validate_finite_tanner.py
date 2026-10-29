#!/usr/bin/env python3
"""Independent inverse-permutation/column-pullback reconstruction of QT lifts.

No generator, external constructor or logical-builder imports.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
from validate_css import basis,dot,read_code,validate


def reverse(p):
    return tuple(p.index(i) for i in range(len(p)))


def product(a,b):
    # Inverse permutation coordinates: (a*b)^-1 = a^-1 after b^-1.
    return tuple(a[b[i]] for i in range(len(a)))


def inverse_cycles(text,degree):
    if re.fullmatch(r'(\((?:\d+(?:,\d+)*)?\))+',text) is None:raise ValueError('cycle syntax')
    result=list(range(degree));used=set()
    for block in text.split(')')[:-1]:
        vals=[int(t)-1 for t in block.lstrip('(').split(',') if t]
        if len(set(vals))!=len(vals) or any(t<0 or t>=degree or t in used for t in vals):raise ValueError('non-disjoint cycles')
        used.update(vals)
        for i,t in enumerate(vals):result[vals[(i+1)%len(vals)]]=t
    return tuple(result)


def independent_group(c):
    degree=max(map(int,re.findall(r'\d+',','.join(c['A']+c['B']))),default=1)
    a=[inverse_cycles(t,degree) for t in c['A']];b=[inverse_cycles(t,degree) for t in c['B']]
    queue=[tuple(range(degree))];known=set(queue)
    for g in queue:
        for s in a+b:
            h=product(s,g)
            if h not in known:
                known.add(h);queue.append(h)
                if len(queue)>c['group_order']:raise ValueError('source order exceeded')
    group=sorted(known,key=reverse)
    if len(group)!=c['group_order']:raise ValueError('wrong group order')
    return group,a,b


def source_binding(c):
    r=c['source_reconstruction']
    digest=hashlib.sha256(json.dumps(r,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    if digest!=c['source_parameter_projection_sha256']:raise ValueError('source projection digest')
    if r['A_elements'].split(';')!=c['A'] or r['B_elements'].split(';')!=c['B'] or r['group_order']!=c['group_order']:raise ValueError('source group data mismatch')
    for side in ('A','B'):
        if c['pi_'+side]!=r['H1_perm_'+side] or sorted(c['pi_'+side])!=list(range(1,len(c[side])+1)):raise ValueError('source permutation mismatch')
        for kind in ('H','G'):
            if [list(x) for x in zip(*c[kind+'_'+side])]!=r[kind+'0_'+side]:raise ValueError('source local matrix mismatch')
            if r[kind+'1_'+side]!=[r[kind+'0_'+side][j-1] for j in c['pi_'+side]]:raise ValueError('source local permuted matrix mismatch')
        h,g=c['H_'+side],c['G_'+side];length=len(c[side])
        if any(len(row)!=length or any(v not in (0,1) for v in row) for row in h+g):raise ValueError('nonbinary/ragged local code')
        bit=lambda rows:[sum(v<<i for i,v in enumerate(row)) for row in rows]
        if len(basis(bit(h)))!=len(h) or len(basis(bit(g)))!=len(g) or len(h)+len(g)!=length:raise ValueError('local ranks do not define full duals')
        if any(dot(x,z) for x in bit(h) for z in bit(g)):raise ValueError('local duality')


def reconstruct(c):
    group,a,b=independent_group(c);p=len(group);index={g:i for i,g in enumerate(group)};nb=len(b)
    ha,ga,hb,gb=[c[k] for k in ('H_A','G_A','H_B','G_B')]
    perm=lambda rows,pi:[[row[j-1] for j in pi] for row in rows]
    h1a,g1a=perm(ha,c['pi_A']),perm(ga,c['pi_A']);h1b,g1b=perm(hb,c['pi_B']),perm(gb,c['pi_B'])
    sizes=[len(ha)*len(gb)*p,len(h1a)*len(g1b)*p,len(ga)*len(h1b)*p,len(g1a)*len(hb)*p]
    blocks=[[0]*n for n in sizes]
    # For a physical column h, the slice roots are h, a^-1*h*b, h*b,
    # a^-1*h. This reverses the row-to-column construction completely.
    for i in range(len(a)):
        for j in range(nb):
            for t,h in enumerate(group):
                roots=[h,product(product(reverse(a[i]),h),b[j]),product(h,b[j]),product(reverse(a[i]),h)]
                q=(i*nb+j)*p+t
                for rows,ra,rb,g in zip(blocks,(ha,h1a,ga,g1a),(gb,g1b,h1b,hb),roots):
                    for u in range(len(ra)):
                        if not ra[u][i]:continue
                        for v in range(len(rb)):
                            if rb[v][j]:rows[(u*len(rb)+v)*p+index[g]]|=1<<q
    return blocks[0]+blocks[1],blocks[2]+blocks[3]


def connected(n,rows):
    adjacency=[[] for _ in range(n)]
    for k,r in enumerate(rows):
        while r:
            t=r&-r;adjacency[t.bit_length()-1].append(k);r^=t
    seen_q={0};seen_r=set();todo=[0]
    for q in todo:
        for k in adjacency[q]:
            if k in seen_r:continue
            seen_r.add(k);r=rows[k]
            while r:
                t=r&-r;v=t.bit_length()-1;r^=t
                if v not in seen_q:seen_q.add(v);todo.append(v)
    if len(seen_q)!=n or len(seen_r)!=len(rows):raise ValueError('disconnected/zero-row Tanner half')


def certify(c,n,m):
    source_binding(c);x,z=reconstruct(c)
    if m[0]!=x or m[1]!=z or n!=c['n']:raise ValueError('independent pullback does not match matrix')
    r=validate(n,m)
    if r['k']!=c['k']:raise ValueError('actual k differs from source')
    group,_,_=independent_group(c)
    if all(product(a,b)==product(b,a) for a in group for b in group):raise ValueError('selected group expected nonabelian')
    for rows in (x,z):connected(n,rows)
    weights=lambda rows:dict(sorted(Counter(bin(r).count('1') for r in rows).items()))
    r.update(stem=f'TN_{n}_{r["k"]}_unknown',group_order=len(group),nonabelian=True,connected_both_halves=True,
        check_weights_X=weights(x),check_weights_Z=weights(z),source_projection_sha256=c['source_parameter_projection_sha256'],
        published_half_uppers=c['published_half_uppers'],distance_status='PUBLISHED_RANDOMIZED_UPPER_ESTIMATES_ONLY; no distance search here')
    return r


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'));ap.add_argument('--out',type=Path,required=True);a=ap.parse_args()
    records=[]
    for c in json.loads(Path(__file__).with_name('finite_tanner_cases.json').read_text()):
        n,m=read_code(a.dir,f'TN_{c["n"]}_{c["k"]}_unknown');records.append(certify(c,n,m))
    text=json.dumps(records,indent=2)+'\n';a.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
