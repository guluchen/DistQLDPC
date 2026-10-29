"""Re-compare ident.py logs with the two halves ub-pre lines sorted within each contiguous block (main itself prints
them in a timing-dependent order). usage: ident_mod.py DIR..."""
import glob,re,sys
MASK=[re.compile(r"cpu[ =]?\d+\.\d+s?"),re.compile(r"\d+\.\d+ ?s\b"),re.compile(r"\d+\.\d+s\)"),re.compile(r"detect_cpu=\d+\.\d+s"),re.compile(r"time\s*:?\s*\d+\.\d+"),re.compile(r"(CPU time|Real time|Wall)[^\n]*",re.I)]
def norm(t):
    out=[]
    for l in t.splitlines():
        for m in MASK: l=m.sub("<T>",l)
        out.append(l)
    res=[];blk=[]
    for l in out:
        if l.startswith("c ub-pre "): blk.append(l); continue
        res+=sorted(blk); blk=[]; res.append(l)
    return res+sorted(blk)
for d in sys.argv[1:]:
    same=diff=0
    for f in sorted(glob.glob(d+"/*.main.out")):
        b=f[:-9]
        m=norm(open(b+".main.out").read())+norm(open(b+".main.err").read())
        c=norm(open(b+".cand.out").read())+norm(open(b+".cand.err").read())
        if m==c: same+=1
        else: diff+=1; print("DIFF",b)
    print(d,"identical modulo ub-pre half order:",same,"different:",diff)
