import sys,glob,collections,os
def load(p): return [[int(x) for x in l.split()] for l in open(p) if l.strip() and l.strip()[0] in "01"]
for hx in sorted(glob.glob('gh-stabov/data/matrices/tier[1-5]/*_Hx.txt')):
    stem=os.path.basename(hx)[:-7]; p=hx[:-7]
    out=[]
    for H in ('Hx','Hz'):
        S=[frozenset(j for j,v in enumerate(r) if v) for r in load(p+'_'+H+'.txt') if any(r)]
        d=collections.Counter()
        for i,s in enumerate(S):
            c4=sum((lambda o: o*(o-1)//2)(len(s&t)) for k,t in enumerate(S) if k!=i)
            d[(len(s),c4)]+=1
        out.append(H+' '+' '.join('w%d:c%d x%d'%(w,c,n) for (w,c),n in sorted(d.items())))
    print(stem,' | '.join(out))
