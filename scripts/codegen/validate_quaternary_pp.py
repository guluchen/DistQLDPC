#!/usr/bin/env python3
"""Independent GF4 polynomial/tuple-group and physical column reconstruction.

No generator or logical-builder imports. Field values encode 1,x,x+1.
"""
import argparse
from collections import Counter
import hashlib
import itertools
import json
import math
from pathlib import Path
from validate_css import basis,contains,dot,equal_space,read_code,validate


def field_mul(a,b):
    out=0
    while b:
        if b&1:out^=a
        a<<=1
        if a&4:a^=7  # x^2+x+1
        b>>=1
    return out


def trace(a):return a ^ field_mul(a,a)


def tuple_group(moduli):
    if not moduli or any(m<1 for m in moduli):raise ValueError('invalid product group')
    return [tuple(reversed(x)) for x in itertools.product(*(range(m) for m in reversed(moduli)))]


def plus(a,b,moduli):return tuple((x+y)%m for x,y,m in zip(a,b,moduli))


def negate(a,moduli):return tuple((-x)%m for x,m in zip(a,moduli))


def facts(c):return {k:c[k] for k in ('C','E','group_moduli','row_choices','source_witness_Z')}


def source_binding(c):
    if hashlib.sha256(json.dumps(facts(c),sort_keys=True,separators=(',',':')).encode()).hexdigest()!=c['parameter_projection_sha256']:
        raise ValueError('stale mathematical source projection')
    p=math.prod(c['group_moduli'])
    if c['n']!=16*p or c['k']!=4*p or len(c['C'])!=3 or len(c['E'])!=3 or len(c['row_choices'])!=3:raise ValueError('source dimensions')
    if any(len(row)!=8 or any(x not in (0,1,2,3) for x in row) for row in c['C']):raise ValueError('invalid field array')
    if any(len(row)!=8 or any(x<0 or x>=p for x in row) for row in c['E']):raise ValueError('invalid exponent array')
    if any(len(pair)!=2 or len(set(pair))!=2 or any(x not in (0,1,2) for x in pair) for pair in c['row_choices']):raise ValueError('singular row presentation')


def weighted_commutation(c):
    """Compute Hx Hz^dagger in GF4[G], without binary expansion."""
    moduli=c['group_moduli'];group=tuple_group(moduli)
    for i in range(3):
        for j in range(3):
            coeff={}
            for ell in range(8):
                other=(ell+4)%8
                label=plus(group[c['E'][i][ell]],group[c['E'][j][other]],moduli)
                value=field_mul(c['C'][i][ell],c['C'][j][other])
                coeff[label]=coeff.get(label,0)^value
            if any(coeff.values()):raise ValueError('GF4-weighted group-algebra commutator nonzero')


def reconstruct(c):
    moduli=c['group_moduli'];group=tuple_group(moduli);p=len(group);index={g:i for i,g in enumerate(group)}
    out=[]
    for half in (0,1):
        rows=[0]*(6*p)
        for ell in range(8):
            source=(ell+4)%8 if half else ell
            for b,beta in enumerate((2,3)):
                for h in group:
                    q=(2*ell+b)*p+index[h]
                    for i in range(3):
                        e=group[c['E'][i][source]]
                        if half:e=negate(e,moduli)
                        root=plus(h,e,moduli)  # invert rowg -> colg-e
                        # Self-dual trace extracts the component: no rho table.
                        value=field_mul(c['C'][i][source],beta)
                        bits=[trace(field_mul(x,value)) for x in (2,3)]
                        variants=(bits[0],bits[1],bits[0]^bits[1])
                        for a,t in enumerate(c['row_choices'][i]):
                            if variants[t]:rows[(2*i+a)*p+index[root]]|=1<<q
        out.append(rows)
    return out


def permute(word,mapping):
    out=0
    while word:
        t=word&-word;out|=1<<mapping[t.bit_length()-1];word^=t
    return out


def connected(n,rows):
    incident=[[] for _ in range(n)]
    for i,r in enumerate(rows):
        while r:
            t=r&-r;incident[t.bit_length()-1].append(i);r^=t
    vertices={0};checks=set();queue=[0]
    for q in queue:
        for i in incident[q]:
            if i in checks:continue
            checks.add(i);r=rows[i]
            while r:
                t=r&-r;v=t.bit_length()-1;r^=t
                if v not in vertices:vertices.add(v);queue.append(v)
    if len(vertices)!=n or len(checks)!=len(rows):raise ValueError('disconnected half/zero check')


def witness(n,m,half,support):
    if not support or len(set(support))!=len(support) or min(support)<0 or max(support)>=n:raise ValueError('bad support')
    parity,stab,det=(m[0],m[1],m[3]) if half=='Z' else (m[1],m[0],m[2])
    w=sum(1<<q for q in support)
    if any(dot(w,r) for r in parity) or contains(basis(stab),w) or not any(dot(w,g) for g in det):raise ValueError('invalid nontrivial physical logical')


def certify(c,n,m):
    source_binding(c);weighted_commutation(c)
    if reconstruct(c)!=m[:2]:raise ValueError('independent physical columns differ')
    r=validate(n,m)
    if r['n']!=c['n'] or r['k']!=c['k']:raise ValueError('actual source dimension mismatch')
    p=math.prod(c['group_moduli']);group=tuple_group(c['group_moduli']);index={g:i for i,g in enumerate(group)}
    reflection=[((q//p+8)%16)*p+index[negate(group[q%p],c['group_moduli'])] for q in range(n)]
    if any(reflection[reflection[q]]!=q or reflection[q]==q for q in range(n)):raise ValueError('reflection not fixed-point-free involution')
    if not equal_space([permute(w,reflection) for w in m[0]],m[1]) or not equal_space([permute(w,reflection) for w in m[1]],m[0]):raise ValueError('reflection does not exchange CSS checks')
    translations=[]
    for axis,order in enumerate(c['group_moduli']):
        unit=tuple(1 if i==axis else 0 for i in range(len(c['group_moduli'])))
        mapping=[(q//p)*p+index[plus(group[q%p],unit,c['group_moduli'])] for q in range(n)]
        if any(not equal_space([permute(w,mapping) for w in rows],rows) for rows in m[:2]):raise ValueError('group translation is not a CSS symmetry')
        translations.append(dict(axis=axis,order=order,both_check_spaces_preserved=True))
    witnesses=[]
    for half,support in (('Z',c['source_witness_Z']),('X',[reflection[q] for q in c['source_witness_Z']])):
        witness(n,m,half,support)
        if len(support)!=c['d']:raise ValueError('source logical word differs from exact claim')
        witnesses.append(dict(half=half,weight=len(support),support=support,source='source numeric witness and independently checked reflection'))
    for rows in m[:2]:connected(n,rows)
    weights=lambda rows:dict(sorted(Counter(bin(w).count('1') for w in rows).items()))
    r.update(stem=f'PP_{n}_{r["k"]}_unknown',source_id=c['source_id'],group_moduli=c['group_moduli'],
        source_projection_sha256=c['parameter_projection_sha256'],check_weights_X=weights(m[0]),check_weights_Z=weights(m[1]),
        connected_both_halves=True,weighted_group_algebra_commutation=True,group_translations=translations,reflection='GF2-verified check-exchanging involution',
        witnesses=witnesses,distance_status='GF2_UPPER_ONLY; published exact lower proof not executed/imported')
    return r


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'));ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();records=[]
    for c in json.loads(Path(__file__).with_name('quaternary_pp_cases.json').read_text()):
        n,m=read_code(a.dir,f'PP_{c["n"]}_{c["k"]}_unknown');records.append(certify(c,n,m))
    text=json.dumps(records,indent=2)+'\n';a.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
