#!/usr/bin/env python3
"""Compare a candidate against the RECORDED main baseline and check answers while timing.
PI 2026-10-11: "把main需要的時間記下來就不用每次都重跑過" and "比速度的時候可以順便比答案".
Per case/mode with a recorded baseline: N candidate runs (default 3) + 1 drift-check run of the baseline binary; the candidate
median is compared with the recorded median (baselines/main_mac_reference.json). Drift: if the drift sample lies outside the
recorded [min, max] by more than --drift-tol (3%), the cell is marked DRIFT and must be re-run as a full AB/BA/AB comparison.
Cases without a recorded baseline (tier0, tier5) are run science-only (one candidate run).
Science: every run's solved d and every emitted lb/ub must be consistent with the stem's last field (d, {lb}to{ub}, ge{lb});
improvements over the stem bounds are reported (better_than_stem). Matrices are passed by resolved path
(data/matrices[/tierN]/<stem>) so binaries with or without the tier resolver behave the same. All runs use memlimit (2 GB)."""
import argparse, json, os, statistics, sys, time, hashlib, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import memlimit
def sha(p): return hashlib.sha256(open(p,'rb').read()).hexdigest()
def resolve(c):
    hits=sorted(glob.glob(f'data/matrices/{c}_Hx.txt')+glob.glob(f'data/matrices/tier*/{c}_Hx.txt'))
    if not hits: sys.exit(f'cannot find matrices for {c}')
    return hits[0][:-len('_Hx.txt')]
def run(b, c, m, lim, wd):
    t=time.perf_counter(); rc,out,err,peak=memlimit.run([b, f'-cpu-lim={lim}', '-'+m, resolve(c)], wd); w=time.perf_counter()-t
    L=out.splitlines(); res=[l for l in L if l.startswith('o ')]
    lbs=[int(l.split()[-1]) for l in L if l.startswith('c d_lb:') and l.split()[-1].isdigit()]
    ubs=[int(l.split()[-1]) for l in L if l.startswith('c d_ub:') and l.split()[-1].isdigit()]
    return dict(wall_s=w, rc=rc, result=res[-1] if res else None, lbs=lbs, ubs=ubs, peak_kb=peak)
def stem_bounds(c):
    p=c.split('_'); f=p[3] if len(p)>3 else ''
    if f.isdigit(): return int(f), int(f)
    if f.startswith('ge') and f[2:].isdigit(): return int(f[2:]), None
    if 'to' in f:
        a,b=f.split('to',1)
        if a.isdigit() and b.isdigit(): return int(a), int(b)
    return None, None
def science(c, x):
    lo,hi=stem_bounds(c); why=[]
    if x['rc'] not in (0,1): why.append(f"abnormal exit {x['rc']}")
    d=int(x['result'].split()[1]) if x['result'] else None
    if d is not None:
        if lo is not None and d<lo: why.append(f'solved d={d} < stem lower bound {lo}')
        if hi is not None and d>hi: why.append(f'solved d={d} > stem upper bound {hi}')
    for v in x['lbs']:
        if hi is not None and v>hi: why.append(f'lb {v} > stem upper bound {hi}')
    if d is not None:
        for v in x['lbs']:
            if v>d: why.append(f'lb {v} > own result {d}')
    for v in x['ubs']:
        if lo is not None and v<lo: why.append(f'ub {v} < stem lower bound {lo}')
    better={}
    if d is not None and (lo,hi)!=(d,d): better['solved']=d
    if x['lbs'] and lo is not None and max(x['lbs'])>lo: better['lb']=max(x['lbs'])
    if x['ubs'] and (hi is None or min(x['ubs'])<hi): better['ub']=min(x['ubs'])
    return (not why), why, better
ap=argparse.ArgumentParser(); ap.add_argument('--ref', required=True); ap.add_argument('--base', required=True); ap.add_argument('--cand', required=True)
ap.add_argument('--cases', nargs='+', required=True); ap.add_argument('--modes', nargs='+', default=['no-card','card-mto'])
ap.add_argument('--runs', type=int, default=3); ap.add_argument('--limit', type=int, default=1800); ap.add_argument('--watchdog', type=int, default=1815)
ap.add_argument('--drift-tol', type=float, default=0.03); ap.add_argument('--out', required=True); a=ap.parse_args()
ref=json.load(open(a.ref)); R={(r['case'],r['mode']):r for r in ref['rows']}
if sha(a.base)!=ref['binary_sha256']: sys.exit('baseline binary sha does not match the reference table')
os.makedirs(a.out, exist_ok=True); cells=[]
for c in a.cases:
    for m in a.modes:
        r=R.get((c,m))
        if r is None:
            x=run(a.cand,c,m,a.limit,a.watchdog); ok,why,better=science(c,x)
            cells.append(dict(case=c,mode=m,science_only=True,cand=[round(x['wall_s'],4)],result=x['result'],science_ok=ok,science_issues=why,better_than_stem=better))
            print(f"{c} {m}: science-only {x['wall_s']:.2f}s {x['result']} {'OK' if ok else 'SCIENCE-FAIL '+'; '.join(why)}{' better:'+str(better) if better else ''}", flush=True); continue
        d=run(a.base,c,m,a.limit,a.watchdog); cs=[run(a.cand,c,m,a.limit,a.watchdog) for _ in range(a.runs)]
        chk=[science(c,x) for x in cs+[d]]; ok=all(k[0] for k in chk); why=[w for k in chk for w in k[1]]
        better={k2:v for k in chk for k2,v in k[2].items()}
        lo,hi=r['min_s']*(1-a.drift_tol), r['max_s']*(1+a.drift_tol); drift=not (lo<=d['wall_s']<=hi)
        med=statistics.median(x['wall_s'] for x in cs); ratio=med/r['median_s']
        cells.append(dict(case=c,mode=m,ref_median=r['median_s'],ref_range=[r['min_s'],r['max_s']],drift_sample=round(d['wall_s'],4),drift=drift,
                          cand=[round(x['wall_s'],4) for x in cs],cand_median=round(med,4),ratio=round(ratio,4),
                          nonoverlap_regression=min(x['wall_s'] for x in cs)>r['max_s'],science_ok=ok,science_issues=why,better_than_stem=better))
        print(f"{c} {m}: ref {r['median_s']:.3f} cand {med:.3f} ratio {ratio:.3f} drift_sample {d['wall_s']:.3f}{' DRIFT' if drift else ''}{'' if ok else ' SCIENCE-FAIL '+'; '.join(why)}", flush=True)
json.dump(dict(ref=a.ref,base_sha=ref['binary_sha256'],cand=a.cand,cand_sha=sha(a.cand),cells=cells), open(os.path.join(a.out,'result.json'),'w'), indent=1)
