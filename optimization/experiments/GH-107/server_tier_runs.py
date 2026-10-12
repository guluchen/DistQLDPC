#!/usr/bin/env python3
"""yfclab2 tier runs (PI 2026-10-12): run one or more binaries on tier cases, N reps per case/mode, as a pool over pinned
physical cores (taskset), each process capped at 4 GB (prlimit --as, server rule), per-tier wall limits
(tier0 600 s, tier1-3 1800 s, tier4 5000 s on the server, tier5 21600 s). Records wall time, result and timestamped bounds, and checks
answers against the stem (d / {lb}to{ub} / ge{lb}). Run inside a DistQLDPC checkout with data/matrices/tierN.
Usage: server_tier_runs.py --bins main=PATH [cand=PATH] --tiers 0 1 2 3 4 --reps 3 --cpus 0-59,64-123 --out DIR"""
import argparse, glob, json, os, queue, re, subprocess, threading, time
LIM={0:600,1:1800,2:1800,3:1800,4:5000,5:21600}  # tier4 5000 s on yfclab2 (PI 2026-10-12)
ap=argparse.ArgumentParser(); ap.add_argument('--bins',nargs='+',required=True); ap.add_argument('--tiers',nargs='+',type=int,required=True)
ap.add_argument('--reps',type=int,default=3); ap.add_argument('--cpus',required=True); ap.add_argument('--out',required=True)
ap.add_argument('--modes',nargs='+',default=['no-card','card-mto']); a=ap.parse_args(); os.makedirs(a.out,exist_ok=True)
bins=dict(b.split('=',1) for b in a.bins); cpus=[]
for part in a.cpus.split(','):
    lo,_,hi=part.partition('-'); cpus+=list(range(int(lo),int(hi or lo)+1))
def bounds(stem):
    f=stem.split('_')[3]
    if f.isdigit(): return int(f),int(f)
    if f.startswith('ge'): return int(f[2:]),None
    x,y=f.split('to'); return int(x),int(y)
jobs=[]
for t in a.tiers:
    for p in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt')):
        s=os.path.basename(p)[:-7]
        for m in a.modes:
            for r in range(a.reps):
                for v in bins: jobs.append((t,s,m,r,v))
# longest first so the pool finishes early
jobs.sort(key=lambda j:-LIM[j[0]])
Q=queue.Queue(); [Q.put(j) for j in jobs]; res=[]; lock=threading.Lock()
def worker(cpu):
    while True:
        try: t,s,m,r,v=Q.get_nowait()
        except queue.Empty: return
        lim=LIM[t]; t0=time.time(); lbs=[];ubs=[];result=None
        p=subprocess.Popen(['taskset','-c',str(cpu),'prlimit','--as=4294967296','--',bins[v],f'-cpu-lim={lim}','-'+m,f'data/matrices/tier{t}/{s}'],
                           stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
        with open(f'{a.out}/{s}.{m}.{v}.r{r}.log','w') as log:
            for line in p.stdout:
                e=time.time()-t0; log.write(f'{e:9.1f}\t{line}')
                mm=re.match(r'c d_(lb|ub): (\d+)',line)
                if mm: (lbs if mm.group(1)=='lb' else ubs).append((round(e,1),int(mm.group(2))))
                if line.startswith('o '): result=int(line.split()[1])
        rc=p.wait(); w=time.time()-t0; lo,hi=bounds(s); bad=[]
        if result is not None and (result<lo or (hi is not None and result>hi)): bad.append(f'solved {result} outside stem [{lo},{hi}]')
        if hi is not None and any(x>hi for _,x in lbs): bad.append('lb above stem upper bound')
        if any(x<lo for _,x in ubs): bad.append('ub below stem lower bound')
        with lock:
            res.append(dict(tier=t,stem=s,mode=m,rep=r,bin=v,cpu=cpu,rc=rc,wall_s=round(w,2),limit_s=lim,result=result,
                            final_lb=max([x for _,x in lbs],default=None),final_ub=min([x for _,x in ubs],default=None),
                            science_ok=not bad,issues=bad))
            json.dump(dict(bins=bins,host='yfclab2',results=res),open(f'{a.out}/results.json','w'),indent=1)
ths=[threading.Thread(target=worker,args=(c,)) for c in cpus[:len(jobs)]]
[t.start() for t in ths]; [t.join() for t in ths]
print('done',len(res),'runs; science problems',sum(not r['science_ok'] for r in res),'; timeouts',sum(r['result'] is None for r in res))
