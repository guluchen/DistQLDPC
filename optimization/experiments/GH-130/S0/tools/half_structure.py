import sys, os, glob, itertools, statistics as st
root = sys.argv[1]
def load(p):
    rows=[]
    for line in open(p):
        t=line.split()
        if not t: continue
        rows.append([i for i,v in enumerate(t) if v=='1'])
    n=len(open(p).readline().split())
    return rows,n
def rank(rows):
    piv={}
    r=0
    for row in rows:
        v=0
        for i in row: v|=1<<i
        while v:
            h=v.bit_length()-1
            if h in piv: v^=piv[h]
            else: piv[h]=v; r+=1; break
    return r
out=[]
for hx in sorted(glob.glob(os.path.join(root,'tier*','*_Hx.txt'))):
    stem=os.path.basename(hx)[:-7]; tier=os.path.basename(os.path.dirname(hx))
    for half,mat in (('X',hx[:-6]+'Hz.txt'),('Z',hx)):
        rows,n=load(mat)
        rows=[r for r in rows if r]
        m=len(rows)
        rw=[len(r) for r in rows]
        deg=[0]*n; inc=[[] for _ in range(n)]
        for j,r in enumerate(rows):
            for q in r: deg[q]+=1; inc[q].append(j)
        # pairwise overlaps among adjacent rows
        ov={}
        for q in range(n):
            for a,b in itertools.combinations(inc[q],2):
                ov[(a,b)]=ov.get((a,b),0)+1
        nb=[0]*m
        for (a,b) in ov: nb[a]+=1; nb[b]+=1
        ovs=list(ov.values())
        pairs=len(ovs); p2=sum(1 for v in ovs if v>=2)
        rk=rank(rows)
        # 2-paths per qubit through rows: candidates for 'fixing' a single flipped qubit
        cand=[sum(rw[j]-1 for j in inc[q]) for q in range(n)]
        out.append(dict(stem=stem,tier=tier,half=half,n=n,m=m,rank=rk,red=round((m-rk)/m,3),
            rw_min=min(rw),rw_mean=round(st.mean(rw),2),rw_max=max(rw),
            deg_min=min(deg),deg_mean=round(st.mean(deg),2),deg_max=max(deg),
            nb_mean=round(st.mean(nb),2),ov_mean=round(st.mean(ovs),3) if ovs else 0,ov_max=max(ovs) if ovs else 0,
            frac_ov2=round(p2/pairs,3) if pairs else 0,
            cyc4_per_row=round(sum(v*(v-1)//2 for v in ovs)/m,2),
            cand_mean=round(st.mean(cand),2)))
import json
json.dump(out,open(sys.argv[2],'w'),indent=0)
keys=['tier','stem','half','n','m','rank','red','rw_min','rw_mean','rw_max','deg_min','deg_mean','deg_max','nb_mean','ov_mean','ov_max','frac_ov2','cyc4_per_row','cand_mean']
print('\t'.join(keys))
for o in out: print('\t'.join(str(o[k]) for k in keys))
