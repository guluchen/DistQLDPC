#!/usr/bin/env python3
"""Independent polynomial COLUMN reconstruction and actual finite CSS checks.

No constructor imports. All weights refer to physical qubits, not lattice
sites. GPL-3.0-or-later; source mathematics1101.1962v2 Fig1/TableI/Eq8.
"""
import argparse
import hashlib
import json
from pathlib import Path
from validate_css import basis,read_code,validate
from verify_css_witness import verify_witness

# Derive from source Z corners by inversion about(1/2,1/2,1/2):
# f=1+x+y+z, g=1+xy+xz+yz. Source X=(g,f), Z=xyz*(bar f,bar g).
F=((0,0,0),(1,0,0),(0,1,0),(0,0,1))
G=((0,0,0),(1,1,0),(1,0,1),(0,1,1))


def support(w):
    out=[]
    while w:
        b=w&-w;out.append(b.bit_length()-1);w^=b
    return out


def reconstruct(L):
    N=2*L**3;out=[]
    for typ in ('X','Z'):
        rows=[0]*(L**3)
        for q in range(N):
            site,s=divmod(q,2);x,rem=divmod(site,L*L);y,z=divmod(rem,L)
            terms=(G if s==0 else F) if typ=='X' else (F if s==0 else G)
            # Input physical column contributes to translated check anchors.
            anchors=set()
            for dx,dy,dz in terms:
                a=((x-dx)%L,(y-dy)%L,(z-dz)%L) if typ=='X' else ((x+dx-1)%L,(y+dy-1)%L,(z+dz-1)%L)
                anchor=(a[0]*L+a[1])*L+a[2]
                if anchor in anchors:anchors.remove(anchor)
                else:anchors.add(anchor)
            for anchor in anchors:rows[anchor]|=1<<q
        out.append(rows)
    return tuple(out)


def dual_permutation(L):
    out=[]
    for x in range(L):
        for y in range(L):
            for z in range(L):
                for s in range(2):out.append(2*(((-x)%L*L+(-y)%L)*L+(-z)%L)+1-s)
    return out


def permute(w,p):return sum(1<<p[q] for q in support(w))


def components(n,rows):
    parents=list(range(n))
    def root(q):
        while parents[q]!=q:parents[q]=parents[parents[q]];q=parents[q]
        return q
    for w in rows:
        qs=support(w)
        for q in qs[1:]:parents[root(q)]=root(qs[0])
    return len({root(q) for q in range(n)})


def certify(c,n,m):
    L=c['L'];hx,hz,gx,gz=m
    if n!=2*L**3 or n!=c['n'] or (hx,hz)!=reconstruct(L):raise ValueError('source polynomial physical columns mismatch')
    r=validate(n,m)
    if r['k']!=c['k']:raise ValueError('actual finite rank differs from frozen k')
    if len(hx)!=L**3 or len(hz)!=L**3:raise ValueError('wrong number of translated checks')
    weights=[len(support(w)) for w in hx+hz]
    if L>=2 and set(weights)!={8}:raise ValueError('source check weight mismatch')
    column_weights=[sum((w>>q)&1 for w in rows) for rows in (hx,hz) for q in range(n)]
    if L>=2 and set(column_weights)!={4}:raise ValueError('source column weight mismatch')
    if components(n,hx+hz)!=1:raise ValueError('disconnected physical stabilizer incidence')
    p=dual_permutation(L)
    if sorted(p)!=list(range(n)) or any(p[p[q]]!=q for q in range(n)):raise ValueError('dual map not an involutory physical permutation')
    if {permute(w,p) for w in hx}!=set(hz) or {permute(w,p) for w in hz}!=set(hx):raise ValueError('actual XZ check map fails')
    # Check full logical extension after the same physical permutation.
    if len(basis(hz+[permute(w,p) for w in gz]))!=r['rank_Hz']+r['k'] or len(basis(hx+[permute(w,p) for w in gx]))!=r['rank_Hx']+r['k']:raise ValueError('dual logical quotient incomplete')
    words=[]
    for half,rows in (('X',gz),('Z',gx)):
        i,w=min(enumerate(rows),key=lambda iw:(len(support(iw[1])),iw[0]));qs=support(w);verify_witness(n,m,half,qs)
        words.append(dict(half=half,basis='Gz' if half=='X' else 'Gx',zero_based_row=i,weight=len(qs),support=qs))
    r.update(stem=f'HCC_{n}_{c["k"]}_unknown',L=L,source_code=1,physical_polynomial_columns_match=True,
             independently_checked_uppers=words,independent_overall_upper=min(w['weight'] for w in words),
             physical_dual_involution_sha256=hashlib.sha256(json.dumps(p,separators=(',',':')).encode()).hexdigest(),
             complete_logical_quotients_under_dual_map=True,check_weights=[min(weights),max(weights)],column_weights=[min(column_weights),max(column_weights)],
             parameter_sha256=hashlib.sha256(json.dumps(c,sort_keys=True,separators=(',',':')).encode()).hexdigest(),
             published_interval=[c['published_lower'],c['published_upper']],published_interval_is_new_independent_proof=False,
             scientific_status='CONSTRUCTION_LOGICALS_DUALITY_AND_ACTUAL_BASIS_UPPERS_ONLY')
    return r


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--dir',type=Path,default=Path('data/matrices/untiered'));ap.add_argument('--cases',type=Path,default=Path(__file__).with_name('haah_cubic_cases.json'));ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    result=[]
    for c in json.loads(args.cases.read_text()):
        n,m=read_code(args.dir,f'HCC_{c["n"]}_{c["k"]}_unknown');result.append(certify(c,n,m))
    text=json.dumps(result,indent=2)+'\n';args.out.write_text(text);print(text,end='')


if __name__=='__main__':main()
