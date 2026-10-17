import json,sys,re,os,collections
S=sys.argv[1]
jobs={j['id']:j for j in map(json.loads,open(S+'/corr/jobs.jsonl'))}
res={r['id']:r for r in map(json.loads,open(S+'/corr/results.jsonl'))}
def o(path):
    v=[l.split()[1] for l in open(path) if l.startswith('o ')]
    return int(v[-1]) if v else None
def dec(path):
    return re.findall(r'c frontier auto (\w): ([\d.]+) .*-> (on|off)',open(path).read())
def cf(path):
    return sum(int(x) for x in re.findall(r'check_fails (\d+)',open(path).read()))
bad=[];tier=collections.Counter();rnd=collections.Counter();decs=collections.Counter();maxw=0;rss=0
for jid,j in jobs.items():
    r=res[jid]; rss=max(rss,r['peak_rss_mb'])
    if r['status']!='done' or r['rc']!=0: bad.append((jid,r)); continue
    parts=jid.split('|')
    if parts[0].startswith('tier'):
        d=int(parts[1].split('_')[3]); v=o(j['out']); maxw=max(maxw,r['wall'])
        if v!=d or cf(j['err'])!=0: bad.append((jid,v,d))
        tier[parts[0]]+=1
        for h,c,m in dec(j['out']): decs[(parts[0],m)]+=1
    elif parts[2].startswith('auto'):
        cc=o(jobs[f'{parts[0]}|{parts[1]}|cc']['out']); v=o(j['out'])
        if v is None or v!=cc or cf(j['err'])!=0: bad.append((jid,v,cc))
        rnd[parts[0]]+=1
        for h,c,m in dec(j['out']): decs[('rand',m)]+=1
print('tier runs',dict(tier),'random auto runs',dict(rnd),'decisions',dict(decs),'max wall',maxw,'max rss MB',rss)
print('problems',len(bad)); [print(b) for b in bad]
