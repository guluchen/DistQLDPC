import sys,re,glob,os,collections,statistics as st
R={}
for f in glob.glob(sys.argv[1]):
    b=os.path.basename(f)[:-4]
    for l in open(f,errors='replace'):
        m=re.search(r'c DIAG \w cap \d+ \w+: cpu ([\d.]+) conflicts (\d+)',l)
        if m: R[b]=(float(m.group(1)),int(m.group(2)))
g=collections.defaultdict(list)
for b,(cpu,c) in sorted(R.items()):
    if b.endswith('_auto'):
        o=b[:-5]+'_off'
        if o in R:
            key=re.sub(r'_s\d+','',b[:-5]); g[key].append((c/R[o][1], cpu/R[o][0], b))
for k,v in sorted(g.items()):
    print(k, 'n=%d'%len(v), 'confl ratios', ' '.join('%.2f'%x[0] for x in v), 'median %.3f'%st.median(x[0] for x in v), '| cpu median %.3f'%st.median(x[1] for x in v))
