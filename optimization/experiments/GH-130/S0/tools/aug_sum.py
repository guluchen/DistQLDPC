import json,sys,re,statistics,collections
S=sys.argv[1]
jobs={j['id']:j for j in map(json.loads,open(S+'/augrun/jobs.jsonl'))}
res={r['id']:r for r in map(json.loads,open(S+'/augrun/results.jsonl'))}
D=collections.defaultdict(lambda: collections.defaultdict(list)); bad=[]
for jid,j in jobs.items():
    c,v,arm,seed=jid.split('|'); r=res[jid]
    o=[l.split()[1] for l in open(j['out']) if l.startswith('o ')]
    if not o or int(o[-1])!=int(c.split('_')[3]): bad.append(jid)
    conf=sum(int(x) for x in re.findall(r'conflicts (\d+)',open(j['err']).read()))
    D[(c,v)][arm].append((r['wall'],conf))
print('| code | parity rows | C4/row (X/Z) | off: median wall s / conflicts | on: median wall s / conflicts | on/off wall | on/off conflicts |')
print('|---|---|---|---|---|---:|---:|')
for (c,v),A in D.items():
    mw=lambda a: statistics.median(x[0] for x in A[a]); mc=lambda a: statistics.median(x[1] for x in A[a])
    print(f'| {c} | {v} | | {mw("off"):.1f} / {mc("off"):.0f} | {mw("on"):.1f} / {mc("on"):.0f} | {mw("on")/mw("off"):.3f} | {mc("on")/mc("off"):.3f} |')
print('wrong answers:',bad)
