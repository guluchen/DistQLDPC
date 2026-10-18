import re,glob,os,sys,collections
d0=sys.argv[1]
pat=re.compile(r'c FRONTIER (\w) cap (\d+) (\w+): conflicts (\d+) decisions (\d+) frontier_picks (\d+)')
def parse(f):
    res=collections.OrderedDict()
    for l in open(f):
        m=pat.match(l)
        if m:
            h,cap,kind,c,dd,p=m.groups(); res[(h,int(cap),kind)]=(int(c),int(dd),int(p))
    return res
rows=[]
for sub in ('cnt','t3'):
  for f in sorted(glob.glob(os.path.join(d0,sub,'*.off.log.err'))):
    b=os.path.basename(f); code,mode=b.split('.')[:2]
    g=f.replace('.off.','.on.')
    if not os.path.exists(g): continue
    d=int(code.split('_')[3])
    A=parse(f);B=parse(g)
    agg=collections.defaultdict(lambda:[0,0])
    for k in A:
        if k in B:
            h,cap,kind=k
            cls='refute' if (kind=='feasibility' and cap<d) else ('found?' if kind=='feasibility' else 'optimize')
            agg[cls][0]+=A[k][0]; agg[cls][1]+=B[k][0]
    s=f"{code:16s} {mode:9s}"
    for cls in ('refute','found?','optimize'):
        a,bq=agg[cls]
        s+=f" {cls}: {a:>9d}->{bq:>9d} ({bq/a if a else float('nan'):.2f})"
    print(s)
