#!/usr/bin/env python3
"""Record main's Mac baseline for cases missing from the reference table (PI 2026-10-12: "沒紀錄main的話也需要再跑一次並記錄").
Serial runs of the reference binary (sha must match the table), N runs per case/mode, 2 GB cap, matrices by resolved path.
Appends rows (tier from the directory) to the reference JSON; also stores bounds/result for answer checks."""
import argparse, json, os, sys, statistics, time, glob, hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import memlimit
ap=argparse.ArgumentParser(); ap.add_argument('--ref', required=True); ap.add_argument('--base', required=True)
ap.add_argument('--cases', nargs='+', required=True); ap.add_argument('--modes', nargs='+', default=['no-card','card-mto'])
ap.add_argument('--runs', type=int, default=3); ap.add_argument('--limit', type=int, required=True); ap.add_argument('--log', required=True); a=ap.parse_args()
ref=json.load(open(a.ref)); assert hashlib.sha256(open(a.base,'rb').read()).hexdigest()==ref['binary_sha256'], 'baseline sha mismatch'
have={(r['case'],r['mode']) for r in ref['rows']}
for c in a.cases:
    hit=sorted(glob.glob(f'data/matrices/tier*/{c}_Hx.txt'))[0]; path=hit[:-7]; tier=int(hit.split('/')[2][4:])
    for m in a.modes:
        if (c,m) in have: print('have',c,m); continue
        S=[]
        for i in range(a.runs):
            t=time.perf_counter(); rc,out,err,peak=memlimit.run([a.base,f'-cpu-lim={a.limit}','-'+m,path], a.limit+15); w=time.perf_counter()-t
            L=out.splitlines(); res=[l for l in L if l.startswith('o ')]
            S.append(dict(wall_s=round(w,4),rc=rc,result=res[-1] if res else None,
                          lbs=[int(l.split()[-1]) for l in L if l.startswith('c d_lb:') and l.split()[-1].isdigit()],
                          ubs=[int(l.split()[-1]) for l in L if l.startswith('c d_ub:') and l.split()[-1].isdigit()],peak_kb=peak))
            open(a.log,'a').write(json.dumps(dict(case=c,mode=m,rep=i,**S[-1]))+'\n')
        v=[s['wall_s'] for s in S]; solved=all(s['result'] for s in S)
        ref['rows'].append(dict(tier=tier,case=c,mode=m,n=len(v),median_s=round(statistics.median(v),4),min_s=min(v),max_s=max(v),
            solved=solved,limit_s=a.limit,result=S[0]['result'],final_lb=max((max(s['lbs']) for s in S if s['lbs']),default=None),
            final_ub=min((min(s['ubs']) for s in S if s['ubs']),default=None),sources=[f'record_main_mac.py {time.strftime("%Y-%m-%d")} serial, limit {a.limit}s']))
        json.dump(ref,open(a.ref,'w'),indent=1); print(c,m,v,S[0]['result'],flush=True)
