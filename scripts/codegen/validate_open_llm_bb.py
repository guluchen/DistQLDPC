#!/usr/bin/env python3
"""Independent columns, full logicals and basis-independent CSS components.

No constructor, author implementation or distance search imported.
GPL-3.0-or-later.
"""
import argparse
import hashlib
import json
from pathlib import Path
from validate_css import basis,read_code,validate


def columns(c):
    l,m=c['l'],c['m'];v=l*m
    if any(type(z)!=int or z<1 for z in (l,m)):raise ValueError('invalid lattice')
    if sorted(len(c[k]) for k in ('A','B'))!=[2,3]:raise ValueError('not a2+3 CSS support split')
    for key in ('A','B'):
        if len({(a%l,b%m) for a,b in c[key]})!=len(c[key]):raise ValueError('monomial collision')
    hx=[0]*v;hz=[0]*v
    for q in range(2*v):
        side,t=divmod(q,v);x,y=divmod(t,m)
        for a,b in c['A' if side==0 else 'B']:hx[((x-a)%l)*m+(y-b)%m]^=1<<q
        for a,b in c['B' if side==0 else 'A']:hz[((x+a)%l)*m+(y+b)%m]^=1<<q
    return hx,hz


def support(word):
    out=[]
    while word:
        b=word&-word;out.append(b.bit_length()-1);word^=b
    return out


def components(n,rows):
    parents=list(range(n))
    def root(q):
        while parents[q]!=q:parents[q]=parents[parents[q]];q=parents[q]
        return q
    for row in rows:
        s=support(row)
        for q in s[1:]:parents[root(q)]=root(s[0])
    result={}
    for q in range(n):result.setdefault(root(q),[]).append(q)
    return sorted(result.values(),key=lambda x:x[0])


def rref(rows):
    pivots=basis(rows)
    for p in sorted(pivots):
        for q in sorted(pivots):
            if q>p and (pivots[q]>>p)&1:pivots[q]^=pivots[p]
    return [pivots[p] for p in sorted(pivots)]


def stabilizer_components(n,hx,hz):
    # The finest physical partition under which BOTH stabilizer row spaces
    # split is the union of supports of their unique reduced bases.
    return components(n,rref(hx)+rref(hz))


def certify(c,n,m):
    hx,hz,gx,gz=m;l,mm=c['l'],c['m'];v=l*mm
    if n!=c['n'] or n!=2*v or (hx,hz)!=columns(c):raise ValueError('actual physical column incidence differs')
    result=validate(n,m)
    if result['k']!=c['k'] or c['k']!=4:raise ValueError('source dimensions mismatch')
    if any(bin(w).count('1')!=5 for w in hx+hz):raise ValueError('row weight not5')
    for rows in (hx,hz):
        if len(components(n,rows))!=1:raise ValueError('disconnected physical Tanner graph')
    factors=stabilizer_components(n,hx,hz)
    if len(factors)!=1:raise ValueError('stabilizer row space factors into disconnected components')
    dual=[(1-side)*v+((-x)%l)*mm+(-y)%mm for side in range(2) for x in range(l) for y in range(mm)]
    permute=lambda w,p:sum(1<<p[q] for q in support(w))
    if len(set(dual))!=n or any(dual[dual[q]]!=q for q in range(n)):raise ValueError('dual is not an involutive permutation')
    if {permute(w,dual) for w in hx}!=set(hz) or {permute(w,dual) for w in hz}!=set(hx):raise ValueError('actual duality fails')
    for axis in (0,1):
        p=[side*v+((x+(axis==0))%l)*mm+(y+(axis==1))%mm for side in range(2) for x in range(l) for y in range(mm)]
        if any({permute(w,p) for w in rows}!=set(rows) for rows in (hx,hz)):raise ValueError('translation fails')
    result.update(stem=f'BB_{n}_{c["k"]}_unknown',presentation_id=c['presentation_id'],class_id=c['class_id'],
                  row_weight=5,physical_degree_left_right=dict(Hx=[len(c['A']),len(c['B'])],Hz=[len(c['B']),len(c['A'])]),
                  physical_graphs_connected=True,stabilizer_rowspace_components=[len(s) for s in factors],
                  canonical_rref_sha256={k:hashlib.sha256(('\n'.join(format(w,'x') for w in rref(rows))+'\n').encode()).hexdigest() for k,rows in (('Hx',hx),('Hz',hz))},
                  dual_map_verified=True,translations_verified=2,published_lower=c['published_lower'],
                  published_endpoint=c['endpoint'],endpoint_supported=c['endpoint_supported'],source_class_exact=False)
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'))
    ap.add_argument('--cases',type=Path,default=Path(__file__).with_name('open_llm_bb_cases.json'));ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args();spec=json.loads(args.cases.read_text());source=json.loads(Path('optimization/experiments/GH-177/raw/selected-source-records.json').read_text())
    lookup={r['presentation_id']:r for r in source};results=[]
    for c in spec['cases']:
        r=lookup[c['presentation_id']];d=r['distance_class'];g=r['generators'];p=r['parameters']
        if (r['family']!='CSS' or not r['connectivity']['is_connected'] or d['is_exact'] or g['C_terms'] or g['D_terms']
                or r['provenance']['origin']['fixed_safety_net'] or not r['provenance']['origin']['model_attributed_observations_present']
                or [p['n'],p['k'],p['ell'],p['m']]!=[c['n'],c['k'],c['l'],c['m']]
                or g['A_terms']!=c['A'] or g['B_terms']!=c['B'] or d['lower']!=c['published_lower']
                or d['upper']!=c['endpoint'] or d['upper_is_supported']!=c['endpoint_supported']):raise ValueError('source numeric/provenance identity mismatch')
        n,m=read_code(args.dir,f'BB_{c["n"]}_{c["k"]}_unknown');results.append(certify(c,n,m))
    text=json.dumps(results,indent=2)+'\n';args.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
