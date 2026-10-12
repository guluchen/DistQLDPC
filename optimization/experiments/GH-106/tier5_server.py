#!/usr/bin/env python3
"""Tier 5 on yfclab2 (PI 2026-10-12): main and candidate on every tier5 code x mode, ALL AT ONCE, one pinned physical core
per process (taskset), 2 GB cap (prlimit --as), wall limit 21600 s. Records timestamped bound events and checks every answer
against the stem (d / {lb}to{ub} / ge{lb}). Usage (in a DistQLDPC main checkout with data/matrices/tier5):
  tier5_server.py --bins main=PATH cand=PATH --cpus 0-63,128-... --out DIR [--limit 21600]"""
import argparse, glob, json, os, subprocess, threading, time, re
ap=argparse.ArgumentParser(); ap.add_argument('--bins', nargs='+', required=True); ap.add_argument('--cpus', required=True)
ap.add_argument('--out', required=True); ap.add_argument('--limit', type=int, default=21600); ap.add_argument('--modes', nargs='+', default=['no-card','card-mto'])
a=ap.parse_args(); os.makedirs(a.out, exist_ok=True)
bins=dict(b.split('=',1) for b in a.bins)
cpus=[]
for part in a.cpus.split(','):
    lo,_,hi=part.partition('-'); cpus+=list(range(int(lo),int(hi or lo)+1))
stems=sorted(os.path.basename(p)[:-7] for p in glob.glob('data/matrices/tier5/*_Hx.txt'))
jobs=[(v,s,m) for s in stems for m in a.modes for v in bins]
assert len(jobs)<=len(cpus), f'{len(jobs)} jobs > {len(cpus)} cpus'
def bounds(stem):
    f=stem.split('_')[3]
    if f.isdigit(): return int(f),int(f)
    if f.startswith('ge'): return int(f[2:]),None
    x,y=f.split('to'); return int(x),int(y)
res=[]; lock=threading.Lock()
def one(job,cpu):
    v,s,m=job; t0=time.time(); log=open(f'{a.out}/{s}.{m}.{v}.log','w',buffering=1)
    cmd=['taskset','-c',str(cpu),'prlimit','--as=2147483648','--',bins[v],f'-cpu-lim={a.limit}','-'+m,f'data/matrices/tier5/{s}']
    p=subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
    lbs=[];ubs=[];result=None
    for line in p.stdout:
        e=time.time()-t0; log.write(f'{e:9.1f}\t{line}')
        mm=re.match(r'c d_(lb|ub): (\d+)',line)
        if mm: (lbs if mm.group(1)=='lb' else ubs).append((round(e,1),int(mm.group(2))))
        if line.startswith('o '): result=(round(e,1),int(line.split()[1]))
    rc=p.wait(); lo,hi=bounds(s); bad=[]
    if result and (result[1]<lo or (hi is not None and result[1]>hi)): bad.append(f'solved {result[1]} outside stem [{lo},{hi}]')
    if hi is not None and any(x>hi for _,x in lbs): bad.append('lb above stem upper bound')
    if any(x<lo for _,x in ubs): bad.append('ub below stem lower bound')
    with lock:
        res.append(dict(bin=v,stem=s,mode=m,cpu=cpu,rc=rc,wall=round(time.time()-t0,1),result=result,
                        final_lb=max([x for _,x in lbs],default=None),final_ub=min([x for _,x in ubs],default=None),
                        lb_events=lbs,ub_events=ubs,science_ok=not bad,issues=bad))
        json.dump(dict(limit=a.limit,bins=bins,results=res),open(f'{a.out}/results.json','w'),indent=1)
ths=[threading.Thread(target=one,args=(j,c)) for j,c in zip(jobs,cpus)]
[t.start() for t in ths]; [t.join() for t in ths]
print('done',len(res),'runs; science problems:',sum(not r['science_ok'] for r in res))
