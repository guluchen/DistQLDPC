import sys,glob,os,collections
def load(p):
    rows=[]
    for line in open(p):
        line=line.strip()
        if not line or line[0] in '#c%': continue
        t=line.replace(',',' ').split()
        if len(t)==1 and len(t[0])>1 and set(t[0])<=set('01'): t=list(t[0])
        rows.append([int(x) for x in t])
    return rows
for d in sorted(glob.glob(sys.argv[1]+'/tier*')):
    for hx in sorted(glob.glob(d+'/*_Hx.txt')):
        stem=os.path.basename(hx)[:-7]
        out=[os.path.basename(d),stem]
        for H in ('Hx','Hz'):
            M=load(d+'/'+stem+'_'+H+'.txt')
            M=[r for r in M if any(r)]
            rw=collections.Counter(sum(r) for r in M)
            n=len(M[0]); cw=collections.Counter(sum(M[i][j] for i in range(len(M))) for j in range(n))
            # 4-cycles per row: pairs of rows sharing >=2 cols
            S=[set(j for j,v in enumerate(r) if v) for r in M]
            c4=0
            for i in range(len(S)):
                for k in range(i+1,len(S)):
                    s=len(S[i]&S[k]); c4+=s*(s-1)//2
            out.append('%s rw%s cw%s c4/row%.2f'%(H,dict(rw),dict(cw),2*c4/len(S)))
        print(' | '.join(out))
