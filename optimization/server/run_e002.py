#!/usr/bin/env python3
"""Offline E002 package runner. Linux dedicated host; no Tier 3 implementation."""
import argparse, hashlib, json, math, os, platform, re, shlex, signal
import statistics, subprocess, sys, time
from pathlib import Path

CASES1=['BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6']
MODES=['no-card','card-mto']

class ScientificMismatch(RuntimeError): pass

def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def parse(text):
    def last(pattern):
        matches=re.findall(pattern,text,re.M)
        return int(matches[-1]) if matches else None
    return {'d':last(r'^c\s+d\s*:\s*(\d+)\s*$'),
            'objective':last(r'^o\s+(-?\d+)\s*$'),
            'lb':last(r'^c\s+d_lb:\s*(\d+)\s*$'),
            'ub':last(r'^c\s+d_ub:\s*(\d+)\s*$'),
            'timeout':'c status: TIMEOUT' in text,'unknown':'s UNKNOWN' in text}

def judge(samples,cases):
    details=[]; modes={}
    for mode in MODES:
        median_ratios=[]; worst_ratios=[]; nonworse=True
        for case in cases:
            b=[r['elapsed_sec'] for r in samples if r['case']==case and r['mode']==mode and r['version']=='baseline']
            c=[r['elapsed_sec'] for r in samples if r['case']==case and r['mode']==mode and r['version']=='candidate']
            if len(b)!=3 or len(c)!=3:raise ValueError('incomplete samples')
            bm,cm=statistics.median(b),statistics.median(c)
            details.append({'case':case,'mode':mode,'baseline_raw':b,'candidate_raw':c,
                'baseline_median':bm,'candidate_median':cm,'median_ratio':cm/bm,
                'baseline_range_over_median':(max(b)-min(b))/bm,
                'baseline_min':min(b),'baseline_max':max(b),'candidate_min':min(c),'candidate_max':max(c)})
            if min(c)>max(b):return 'reject','confirmed per-case regression',details
            median_ratios.append(cm/bm);worst_ratios.append(max(c)/min(b));nonworse &= cm<=bm
        gm=lambda xs:math.exp(sum(math.log(x) for x in xs)/len(xs))
        modes[mode]={'median_geomean':gm(median_ratios),'range_envelope_geomean':gm(worst_ratios),'no_worse_medians':nonworse}
    passed=all(x['range_envelope_geomean']<1 and x['no_worse_medians'] for x in modes.values())
    return ('pass' if passed else 'inconclusive'),modes,details

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--package',type=Path,required=True)
    ap.add_argument('--output',type=Path,required=True,help='New empty results directory')
    ap.add_argument('--cpu',type=int,required=True)
    ap.add_argument('--exclusive-host',action='store_true',help='Operator attests exclusive reservation and stable host configuration')
    ap.add_argument('--reservation-note',required=True,help='Scheduler reservation or exclusive-host evidence')
    a=ap.parse_args()
    if platform.system()!='Linux' or not a.exclusive_host:
        ap.error('Requires dedicated Linux host with explicit exclusive reservation; shared timing is prohibited')
    if a.cpu not in os.sched_getaffinity(0):ap.error('CPU outside allowed affinity')
    os.sched_setaffinity(0,{a.cpu})
    pkg=a.package.resolve();out=a.output.resolve();out.mkdir(parents=True,exist_ok=False)
    manifest=json.loads((pkg/'manifest.json').read_text())
    for rel,sha in manifest['files'].items():
        if digest(pkg/rel)!=sha:raise SystemExit('Package identity mismatch: '+rel)
    env=dict(os.environ,OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1',LC_ALL='C')
    environment={'uname':platform.uname()._asdict(),'cpu':a.cpu,'reservation':a.reservation_note,'affinity':list(os.sched_getaffinity(0)),
                 'load_start':os.getloadavg(),'environment':{k:env[k] for k in ['OMP_NUM_THREADS','OPENBLAS_NUM_THREADS','MKL_NUM_THREADS','LC_ALL']},
                 'manifest':manifest,'performance_claim':'early filter only; never research-grade'}
    for path in ['/proc/cpuinfo','/proc/meminfo',f'/sys/devices/system/cpu/cpu{a.cpu}/cpufreq/scaling_governor',f'/sys/devices/system/cpu/cpu{a.cpu}/topology/thread_siblings_list']:
        try:environment[path]=Path(path).read_text()
        except OSError:environment[path]=None
    (out/'environment.json').write_text(json.dumps(environment,indent=2))
    def command(cmd,cwd,label,timeout=600):
        with (out/(label+'.log')).open('w') as f:
            f.write(shlex.join(map(str,cmd))+'\n');f.flush()
            p=subprocess.run(list(map(str,cmd)),cwd=cwd,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=timeout)
        if label=='tier0' and p.returncode==2:raise ScientificMismatch('Tier 0 correctness mismatch; escalate')
        if p.returncode:raise RuntimeError(label+' failed; no promotion')
    summary={'decision':'inconclusive','reason':'Tier 0 pending','tiers':{}}
    def save():
        (out/'decision.json').write_text(json.dumps(summary,indent=2))
        (out/'STATE.md').write_text('# E002 controlled run\n\nDecision: '+summary['decision']+'\n\nReason: '+str(summary['reason'])+'\n\nFull evidence: decision.json, samples.json and raw logs. Copy this run directory into optimization/experiments/E002/controlled/ and reconcile repository STATE/HYPOTHESES; never replace the earlier evidence.\n')
    save()
    samples=[]
    try:
        command(['g++','--version'],pkg,'compiler')
        for version in ['baseline','candidate']:
            command(['make','-j2','CXX=g++'],pkg/version,'build-'+version)
        candidate=pkg/'candidate';base=pkg/'baseline/bin/distqldpc';cand=candidate/'bin/distqldpc'
        command(['g++','-Isrc/solver','-O2','-std=gnu++11','optimization/tests/xor_prefix_probe.cc',
                 'build/SimpSolver.o','build/Solver.o','build/Options.o','build/System.o','-lz','-o',out/'probe'],candidate,'probe-build')
        command([sys.executable,'optimization/tests/tier0_xor_prefix.py','--baseline',base,'--candidate',cand,
                 '--probe',out/'probe','--qdistsat',pkg/'qdistsat','--out',out/'tier0'],candidate,'tier0')
        if json.loads((out/'tier0/summary.json').read_text())['status']!='PASS':raise RuntimeError('Tier 0 not PASS')
        summary['tiers']['0']='PASS';save()
        (out/'binary-identities.json').write_text(json.dumps({v:digest(pkg/v/'bin/distqldpc') for v in ['baseline','candidate']},indent=2))
        for tier,cases,limit in [(1,CASES1,180),(2,['LP_340_56_8'],600)]:
            current=[]
            for case in cases:
                for mode in MODES:
                    reference=None
                    for rep in range(3):
                        for version in (['baseline','candidate'] if rep%2==0 else ['candidate','baseline']):
                            label=f'tier{tier}-{case}-{mode}-{rep+1}-{version}'
                            cmd=[str(pkg/version/'bin/distqldpc'),'-v',f'-cpu-lim={limit}','-'+mode,str(pkg/'baseline/data/matrices'/case)]
                            start=time.perf_counter();watchdog=False
                            with (out/(label+'.stdout')).open('w') as so,(out/(label+'.stderr')).open('w') as se:
                                p=subprocess.Popen(cmd,cwd=pkg/version,env=env,stdout=so,stderr=se,start_new_session=True)
                                try:rc=p.wait(timeout=limit+15)
                                except subprocess.TimeoutExpired:
                                    watchdog=True;os.killpg(p.pid,signal.SIGKILL);rc=p.wait()
                            elapsed=time.perf_counter()-start
                            semantic=parse((out/(label+'.stdout')).read_text())
                            row={'tier':tier,'case':case,'mode':mode,'repeat':rep+1,'version':version,
                                 'command':cmd,'elapsed_sec':elapsed,'returncode':rc,'watchdog':watchdog,
                                 'semantic':semantic,'load_after':os.getloadavg()}
                            samples.append(row);current.append(row)
                            (out/'samples.json').write_text(json.dumps(samples,indent=2))
                            if semantic['d'] is not None and (semantic['objective']!=semantic['d'] or semantic['lb']!=semantic['d'] or semantic['ub']!=semantic['d']):
                                summary.update(decision='reject',reason='Scientific/result mismatch: malformed exact result');save();return 2
                            # Any sound partial run blocks promotion. Compare only completed
                            # solves as exact results; never reinterpret timeout as a distance.
                            if watchdog or rc!=0 or semantic['d'] is None or semantic['timeout'] or semantic['unknown']:
                                summary.update(decision='inconclusive',reason=f'Tier {tier} incomplete/timeout/failure: {label}');save();return 1
                            if reference is not None and semantic!=reference:
                                summary.update(decision='reject',reason=f'Scientific/result mismatch: {label}');save();return 2
                            reference=semantic
            decision,reason,medians=judge(current,cases)
            summary['tiers'][str(tier)]={'decision':decision,'reason':reason,'medians':medians};save()
            if decision!='pass':
                # A clearly vanished/reversed aggregate gain at Tier 2 is rejection.
                if tier==2 and isinstance(reason,dict) and any(r['median_geomean']>=1 for r in reason.values()):decision='reject'
                summary.update(decision=decision,reason=f'Tier {tier} did not pass; promotion stopped');save();return 1
        summary.update(decision='accept',reason='Tier 1 and Tier 2 filters passed; no Tier 3 run or research-grade claim; merge still requires hosted checks and review')
        save();return 0
    except ScientificMismatch as exc:
        summary.update(decision='reject',reason=str(exc));save();return 2
    except Exception as exc:
        summary.update(decision='inconclusive',reason=str(exc));save();raise

if __name__=='__main__':sys.exit(main())

