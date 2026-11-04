import sys,os
cores=[int(c) for c in sys.argv[1].split(',')]
B=os.path.expanduser('~/mac-agent-20261009/frozen/server-gh218-diag3/distqldpc')
T5='data/matrices/tier5'
jobs=[]  # (weight, name, env, args)
for md in ('no-card','card-mto'):
    for s in range(5):
        for probe,lb,w in (('Z17',17,140),('X17',17,80),('Z16',9,55),('X16',9,25)):
            if md=='no-card' and s==0: continue
            jobs.append((w,f'g1/TN216_{probe}_{md}_s{s}_v1.log',f'DQ_DIAG=1|DQ_OV_VARIANT=1|DQ_DIAG_PROBE={probe[0]}:{probe[1:]}:{lb}',f'-{md} -seed={s} -frontier-stats -cpu-lim=21600 {T5}/TN_216_4_18'))
for md in ('no-card','card-mto'):
    for s in range(5):
        arms=['v1']
        if md=='card-mto' and s>=3: arms+=['auto','off']
        if md=='no-card' and s>=1: arms+=['auto','off']
        if md=='card-mto' and s==0: arms=[]
        for a in arms:
            env='DQ_DIAG=1|DQ_DIAG_PROBE=X:16:9'+('|DQ_OV_VARIANT=1' if a=='v1' else '')
            extra=' -stab-overlap=off' if a=='off' else ''
            jobs.append((150 if a=='off' else 65,f'g1/TN180_X16_{md}_s{s}_{a}.log',env,f'-{md} -seed={s}{extra} -frontier-stats -cpu-lim=21600 {T5}/TN_180_2_17'))
jobs.sort(key=lambda j:-j[0])
load={c:0 for c in cores}; q={c:[] for c in cores}
for w,n,e,a in jobs:
    c=min(cores,key=lambda c:load[c]); load[c]+=w; q[c].append(f'{c} {n} {B} {e} {a}')
for c in cores:
    open(f'jg1_{c}.txt','w').write('\n'.join(q[c])+'\n')
print(len(jobs),'jobs; max load',max(load.values()),'min')
