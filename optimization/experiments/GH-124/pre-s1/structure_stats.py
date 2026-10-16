import sys,glob,os
def load(p):
    rows=[]
    for line in open(p):
        line=line.strip()
        if not line or line.startswith('#'): continue
        rows.append([int(x) for x in line.split()])
    return rows
def st(H):
    if not H: return None
    n=len(H[0]); rw=[sum(r) for r in H]; deg=[sum(H[r][c] for r in range(len(H))) for c in range(n)]
    return dict(rows=len(H),n=n,maxrw=max(rw),meanrw=sum(rw)/len(rw),mindeg=min(deg),maxdeg=max(deg),meandeg=sum(deg)/n)
for d in sys.argv[1:]:
    for hx in sorted(glob.glob(d+'/*_Hx.txt')):
        pre=hx[:-7]; name=os.path.basename(pre)
        Hx=load(hx); Hz=load(pre+'_Hz.txt')
        a=st(Hz); b=st(Hx)   # X half uses Hz, Z half uses Hx
        n=a['n'] if a else b['n']
        def f(s): return "rows%4d maxrw%3d meanrw%6.2f deg[%d..%d] mean%5.2f dens%.4f" % (s['rows'],s['maxrw'],s['meanrw'],s['mindeg'],s['maxdeg'],s['meandeg'],s['meanrw']/s['n'])
        print("%-28s n=%5d | Hz %s | Hx %s" % (name,n,f(a),f(b)))
