import re,sys,json
S=sys.argv[1]
res={json.loads(l)['id']:json.loads(l)['wall'] for l in open(S+'/lk/results.jsonl')}
def parse(c,arm):
    log=open(f'{S}/lk/{c}.{arm}.log').read().splitlines(); err=open(f'{S}/lk/{c}.{arm}.err').read().splitlines()
    fr=[l for l in err if l.startswith('c FRONTIER')]
    probes=[];cur={}
    for l in log:
        m=re.match(r'c nbLK: (\d+), nbSuccLK: (\d+).*nbLKup: (\d+)',l)
        if m: cur['lk'],cur['slk'],cur['lkup']=map(int,m.groups())
        m=re.search(r'hardConflicts: (\d+)',l)
        if m: cur['hard']=int(m.group(1))
        m=re.match(r'c CSS interleave: (\w) half cap (\d+) lb \d+ (\w+) -> (\w+)',l)
        if m: cur['tag']=f'{m.group(1)} cap {m.group(2)} {m.group(3)} -> {m.group(4)}'; probes.append(cur); cur={}
    for p,f in zip(probes,fr):
        p['conf']=int(re.search(r'conflicts (\d+)',f).group(1))
    return probes
print('| code | probe class | arm | conflicts | lookahead calls / conflict | lookahead propagations / conflict | hard-conflict share | wall s (run) |')
print('|---|---|---|---:|---:|---:|---:|---:|')
for c in ('BB_144_14_14','LP_442_68_10','GB_144_12_12','TN_108_2_12','TN_200_10_10'):
    for arm in ('off','on'):
        P=parse(c,arm)
        groups={'NONE (refutation) + final optimize proof':[p for p in P if p['tag'].endswith('NONE') or 'optimize' in p['tag']],'FOUND':[p for p in P if p['tag'].endswith('FOUND') or p['tag'].endswith(tuple('0123456789'))  and 'feasibility' in p['tag']]}
        for g,ps in groups.items():
            if not ps: continue
            C=sum(p.get('conf',0) for p in ps); L=sum(p.get('lk',0) for p in ps); U=sum(p.get('lkup',0) for p in ps); H=sum(p.get('hard',0) for p in ps)
            print(f'| {c} | {g} | {arm} | {C} | {L/max(C,1):.2f} | {U/max(C,1):.0f} | {H/max(C,1):.3f} | {res[c+"|"+arm]:.1f} |')
