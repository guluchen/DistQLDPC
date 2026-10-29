#!/usr/bin/env python3
"""Independent recursive chain, path/fiber, actual pinned-check and GF2 audit."""
from collections import Counter,defaultdict
import argparse
import hashlib
import itertools
import json
import math
from pathlib import Path
from validate_css import basis,read_code,validate
from verify_css_witness import verify_witness


def require(b,msg):
    if not b:raise ValueError(msg)
def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def support(w):
    out=[]
    while w:b=w&-w;out.append(b.bit_length()-1);w^=b
    return out


def recursive_complex(factors):
    # Eq59-60, append one length2 complex at a time. No all-at-once bit-flip routine.
    h=factors[0];levels=[[(0,(i,)) for i in range(len(h))],[(1,(j,)) for j in range(len(h[0]))]]
    edges=[{(levels[0][i],levels[1][j]) for i,row in enumerate(h) for j,v in enumerate(row) if v}]
    for f,B in enumerate(factors[1:],1):
        oldL,oldE=levels,edges;D=len(oldL)-1;levels=[];edges=[]
        def append(obj,b,high):return obj[0]|((1<<f) if high else 0),obj[1]+(b,)
        for j in range(D+2):
            level=[]
            if j>0:level.extend(append(obj,b,True) for b in range(len(B[0])) for obj in oldL[j-1])
            if j<=D:level.extend(append(obj,b,False) for b in range(len(B)) for obj in oldL[j])
            levels.append(sorted(level))
        for j in range(1,D+2):
            e=set()
            if j<=D:e|={(append(lo,b,False),append(hi,b,False)) for b in range(len(B)) for lo,hi in oldE[j-1]}
            if j>=2:e|={(append(lo,b,True),append(hi,b,True)) for b in range(len(B[0])) for lo,hi in oldE[j-2]}
            e|={(append(obj,i,False),append(obj,k,True)) for obj in oldL[j-1] for i,row in enumerate(B) for k,v in enumerate(row) if v}
            edges.append(e)
    columns=[]
    for j,e in enumerate(edges):
        lower={b:i for i,b in enumerate(levels[j])};upper={b:i for i,b in enumerate(levels[j+1])};cols=[0]*len(upper)
        for lo,hi in e:cols[upper[hi]]^=1<<lower[lo]
        columns.append(cols)
    return levels,columns


def independent_flags(c):
    if c['construction']=='complete':return list(itertools.product(*(range(s) for s in c['levels']))),None,None,None
    factors=c['factors'];D=len(factors);levels,columns=recursive_complex(factors);index=[{b:i for i,b in enumerate(level)} for level in levels]
    edges=[[(i,j) for i,row in enumerate(h) for j,v in enumerate(row) if v] for h in factors]
    original=[]
    for chosen in itertools.product(*edges):
        for order in itertools.permutations(range(D)):
            mask=0;coords=[e[0] for e in chosen];path=[index[0][(mask,tuple(coords))]]
            for grade,f in enumerate(order,1):mask|=1<<f;coords[f]=chosen[f][1];path.append(index[grade][(mask,tuple(coords))])
            original.append(tuple(path))
    require(len(original)==len(set(original))==math.factorial(D)*math.prod(len(e) for e in edges),'original product-path multiplicity differs')
    # Complete missing-endpoint fibers by parity directly on flags; independent
    # of the constructor boundary degree correction.
    sizes=list(map(len,levels));flags=set(original)
    suffix=Counter(f[1:] for f in flags)
    for t,count in suffix.items():
        if count%2:flags.add((sizes[0],)+t)
    prefix=Counter(f[:-1] for f in flags)
    for t,count in prefix.items():
        if count%2:flags.add(t+(sizes[-1],))
    return sorted(flags),levels,columns,original


def check_relation(flags):
    require(flags and len(flags)==len(set(flags)),'flags must be distinct/nonempty')
    D=len(flags[0])-1;hist={}
    for omitted in range(D+1):
        counts=Counter(f[:omitted]+f[omitted+1:] for f in flags)
        require(all(v%2==0 for v in counts.values()),'odd D-pinned fiber')
        hist[str(omitted)]=dict(sorted(Counter(counts.values()).items()))
    return hist


def pinned_checks(flags,t):
    # Intersect independently materialized one-pin incidence masks.
    singles=defaultdict(int)
    for q,f in enumerate(flags):
        for level,p in enumerate(f):singles[level,p]|=1<<q
    rows=[];labels=[];all_flags=(1<<len(flags))-1
    for T in itertools.combinations(range(len(flags[0])),t):
        keys=sorted({tuple(f[j] for j in T) for f in flags})
        for pins in keys:
            w=all_flags
            for j,p in zip(T,pins):w&=singles[j,p]
            labels.append(dict(type=list(T),pins=list(pins)));rows.append(w)
    return rows,labels


def isolation_check(flags,qs,pins):
    """Construct an odd pinned-check overlap for any support below2^(pins+1)."""
    require(qs and len(qs)==len(set(qs)) and max(qs)<len(flags) and min(qs)>=0,'bad unit support')
    require(len(qs)<1<<(pins+1),'isolation bound precondition')
    active=list(qs);selected={}
    while len(active)>1:
        chosen=None
        for j in range(len(flags[0])):
            if j in selected:continue
            groups=defaultdict(list)
            for q in active:groups[flags[q][j]].append(q)
            if len(groups)>1:
                p,small=min(groups.items(),key=lambda kv:(len(kv[1]),kv[0]));chosen=(j,p,small);break
        require(chosen is not None,'distinct flags not separated');j,p,active=chosen;selected[j]=p
        require(len(selected)<=pins,'support-isolation proof bound failed')
    q=active[0]
    for j in range(len(flags[0])):
        if len(selected)==pins:break
        selected.setdefault(j,flags[q][j])
    T=sorted(selected);values=[selected[j] for j in T];intersection=[q for q in qs if all(flags[q][j]==p for j,p in zip(T,values))]
    require(len(intersection)==1,'not an odd-check certificate')
    return dict(type=T,pins=values,intersection=intersection)


def physical_components(n,hx,hz):
    p=basis(hx+[r<<n for r in hz])
    for a in sorted(p):
        for b in p:
            if b>a and (p[b]>>a)&1:p[b]^=p[a]
    parent=list(range(n))
    def root(q):
        while parent[q]!=q:parent[q]=parent[parent[q]];q=parent[q]
        return q
    for w in p.values():
        qs={q%n for q in support(w)}
        if qs:
            first=next(iter(qs))
            for q in qs:parent[root(q)]=root(first)
    return len({root(q) for q in range(n)})


def certify(c,cert,n,matrices):
    require(cert['case']==c and cert['parameter_sha256']==digest(c),'case/certificate identity mismatch')
    flags,levels,columns,original=independent_flags(c)
    require(flags==[tuple(f) for f in cert['flags']] and n==len(flags)==c['n'],'independent complete flag relation differs')
    require(cert['D']==len(flags[0])-1 and min(c['x'],c['z'])>0 and c['x']+c['z']<=cert['D'],'pin dimension/type condition')
    if levels is not None:
        require([[m,list(t)] for level in levels for m,t in level]==[b for level in cert['tensor_bases'] for b in level],'recursive tensor bases differ')
        require([len(b) for b in levels]==[len(b) for b in cert['tensor_bases']],'graded basis partition differs')
        require(columns==cert['original_boundary_columns'],'recursive Eq59/60 boundaries differ')
        for j in range(len(columns)-1):
            for col in columns[j+1]:
                product=0
                for row in support(col):product^=columns[j][row]
                require(product==0,'original boundary composition nonzero')
        sizes=list(map(len,levels));completed=[r[:] for r in columns];added=[None,None]
        odd=[i for i,col in enumerate(columns[0]) if len(support(col))%2]
        if odd:
            added[0]=sizes[0];sizes[0]+=1
            for i in odd:completed[0][i]|=1<<added[0]
        # Sum columns gives precisely the odd-row parity completion.
        parity=0
        for w in columns[-1]:parity^=w
        if parity:added[1]=sizes[-1];sizes[-1]+=1;completed[-1].append(parity)
        require(cert['levels']==sizes and cert['endpoint_added_pins']==added and cert['completed_boundary_columns']==completed,'endpoint parity completion differs')
        for j in range(len(completed)-1):
            for col in completed[j+1]:
                product=0
                for row in support(col):product^=completed[j][row]
                require(product==0,'completed boundary composition nonzero')
    else:require(c['levels']==[2,2,2,2,2,2,4] and (c['x'],c['z'],c['published_exact'])==(2,4,8),'source TableVI anchor facts differ')
    histogram=check_relation(flags);require(max(int(v) for h in histogram.values() for v in h)>2,'selected relation is thin manifold-only control')
    hx,hz,gx,gz=matrices
    for kind,t,rows in [('X',c['x'],hx),('Z',c['z'],hz)]:
        expected,labels=pinned_checks(flags,t)
        require(labels==cert['check_labels_'+kind] and rows==expected,'actual complete pinned-check matrix differs: '+kind)
        lookup={(tuple(a['type']),tuple(a['pins'])):i for i,a in enumerate(labels)}
        columns_actual=[0]*n
        for i,w in enumerate(rows):
            for q in support(w):columns_actual[q]|=1<<i
        for q,f in enumerate(flags):
            col=sum(1<<lookup[(T,tuple(f[j] for j in T))] for T in itertools.combinations(range(len(f)),t))
            require(col==columns_actual[q],'physical pinned-check column differs')
    result=validate(n,matrices);require(result['k']==c['k']==cert['k'] and (result['rank_Hx'],result['rank_Hz'])==(cert['rank_Hx'],cert['rank_Hz']),'actual/source dimension mismatch')
    require(physical_components(n,hx,hz)==1,'hidden typed physical product partition')
    uppers=[]
    for half,kind,rows in [('X','Gz',gz),('Z','Gx',gx)]:
        i,w=min(enumerate(rows),key=lambda p:len(support(p[1])));qs=support(w);verify_witness(n,matrices,half,qs);uppers.append(dict(half=half,basis=kind,zero_based_row=i,weight=len(qs),support=qs))
    lower=dict(X=1<<(c['z']+1),Z=1<<(c['x']+1));require(all(w['weight']>=lower[w['half']] for w in uppers),'actual word contradicts pin-kernel theorem')
    if c['published_exact'] is not None:
        qs=[q for q,f in enumerate(flags) if all(f[j]==0 for j in [2,3,4,5]) and all(f[j] in [0,1] for j in [0,1,6])]
        verify_witness(n,matrices,'Z',qs);require(len(qs)==8,'source anchor explicit word weight');uppers.append(dict(half='Z',basis='explicit Cartesian logical',zero_based_row=None,weight=8,support=qs))
    return dict(stem=f'PIN_{n}_{result["k"]}_unknown',**result,parameter_sha256=digest(c),certificate_sha256=digest(cert),pin_relation_even_fiber_histograms=histogram,
        recursive_boundary_and_independent_full_flag_paths=True,all_actual_pinned_checks_and_columns=True,typed_physical_rowspace_connected=True,
        independently_checked_uppers=uppers,independent_overall_upper=min(w['weight'] for w in uppers),pin_kernel_lower=lower,independent_overall_lower=min(lower.values()),published_exact=c['published_exact'])


def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--matrices',type=Path,default=Path('data/matrices/untiered'));ap.add_argument('--cases',type=Path,default=Path('scripts/codegen/pin_relation_cases.json'));ap.add_argument('--certificates',type=Path,default=Path('optimization/experiments/GH-189/raw/certificates'));ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();results=[]
    for c in json.loads(a.cases.read_text()):
        if c['k']<=0:continue
        stem=f'PIN_{c["n"]}_{c["k"]}_unknown';n,m=read_code(a.matrices,stem);cert=json.loads((a.certificates/f'{stem}.json').read_text());results.append(certify(c,cert,n,m));print(stem,'PASS',flush=True)
    a.out.write_text(json.dumps(results,indent=2)+'\n')


if __name__=='__main__':main()
