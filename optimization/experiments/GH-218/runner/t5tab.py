import sys,re,glob,os
rows=[]
for f in sorted(glob.glob(sys.argv[1])):
    b=os.path.basename(f)[:-4]; L=open(f,errors='replace').read()
    done='# rc' in L
    m=re.search(r'TIME ([\d.]+) ([\d.]+) (\d+)',L); wall=float(m.group(1)) if m else None
    d=re.findall(r'c d  : (\S+)',L); d=d[-1] if d else '-'
    lb=re.findall(r'c d_lb: (\d+)',L); lb=lb[-1] if lb else '-'
    pil=' '.join('%s:%s(%s)'%(x[0],x[2],x[1]) for x in re.findall(r'OVERLAP-PILOT (\w) cap \d+: .* median ([\d.]+) -> (\w+)',L))
    probes=' '.join('%s%s:%.2fM'%(x[0],x[1],int(x[2])/1e6) for x in re.findall(r'FRONTIER (\w) cap (\d+) \w+: conflicts (\d+)',L) if int(x[1])>=12)
    print('%-38s %-4s d=%-3s lb=%-3s wall=%-8s %s | %s'%(b,'done' if done else 'run',d,lb,'%.0f'%wall if wall else '-',pil,probes))
