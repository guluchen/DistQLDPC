import sys,glob,collections,os
def load(p): return [[int(x) for x in l.split()] for l in open(p) if l.strip() and l.strip()[0] in "01"]
for stem in sys.argv[1:]:
    p=glob.glob('gh-stabov/data/matrices/tier*/'+stem+'_Hx.txt')[0][:-7]
    out=[]
    for H in ('Hx','Hz'):
        S=[frozenset(j for j,v in enumerate(r) if v) for r in load(p+'_'+H+'.txt') if any(r)]
        d=collections.Counter()
        for i,s in enumerate(S):
            ov=collections.Counter(len(s&t) for k,t in enumerate(S) if k!=i and len(s&t)>=2)
            d[(len(s),tuple(sorted(ov.items())))]+=1
        out.append(H+' '+' '.join('w%d:%s x%d'%(w,dict(o),n) for (w,o),n in sorted(d.items())))
    print(stem,' | '.join(out))
