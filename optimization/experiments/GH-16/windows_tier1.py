"""H010 fixed-profile PGO Tier1 diagnostic; one assigned Windows runner only."""
import argparse, ctypes as C, hashlib, importlib.util, json, math, os
from pathlib import Path
import platform, re, shutil, statistics, subprocess, sys, time
from windows_cpu_window import Window, ticks, affinity, descendant_affinities, k

BASE='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CAND='467433133851f25a1ab76b662ca93250acf46d03'
QDIST='7c4774fffc49856f48a22ae5f9063d00b2661aaa'
HASHES={'baseline':'9574ed70921663b2ef5036a06980aed71a8278a5fa0270c25fa059448851ad5f',
        'candidate':'2c7896d35cf569e6f78ec25e2f9f2d5c148ee9196b99e0e21e802139695beb3b'}
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def cyg(p):
    s=str(p).replace('\\','/')
    return '/cygdrive/'+s[0].lower()+s[2:] if len(s)>2 and s[1]==':' else s

class JobPids(C.Structure):
    _fields_=[('assigned',C.c_ulong),('count',C.c_ulong),('ids',C.c_size_t*1024)]
k.QueryInformationJobObject.argtypes=[C.c_void_p,C.c_int,C.c_void_p,C.c_ulong,C.c_void_p]
def owned_pids(window):
    info=JobPids()
    if not k.QueryInformationJobObject(window.job,3,C.byref(info),C.sizeof(info),None):
        raise C.WinError(C.get_last_error())
    assert info.count<=1024
    return [int(p) for p in info.ids[:info.count] if p!=os.getpid()]

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--workspace',type=Path,required=True)
    ap.add_argument('--output',type=Path,required=True)
    ap.add_argument('--assignment',required=True,help='GitHub coordinator RUN_ASSIGNMENT comment URL')
    ap.add_argument('--tier',type=int,choices=[1,2],default=1)
    ap.add_argument('--tier1-evidence',type=Path)
    a=ap.parse_args(); root=a.workspace.resolve(); out=a.output.resolve()
    assert platform.system()=='Windows'
    tree=root/'GH16-PGO'; prep=root/'GH16-windows-preparation-04'
    local=root/'GH16-windows-tier0-followup-01'
    record=tree/'optimization/experiments/GH-16'
    hosted=json.loads((record/'raw/hosted-4674331/hosted-ci.json').read_text())
    assert hosted['candidate_sha']==CAND and hosted['baseline_sha']==BASE and hosted['qdistsat_sha']==QDIST
    assert len(hosted['workflow_runs'])==2 and all(r['conclusion']=='success' for r in hosted['workflow_runs'])
    assert json.loads((local/'summary.json').read_text())['local_tier0']=='PASS'
    reconciliation=json.loads((record/'raw/hosted-4674331/source-reconciliation.json').read_text())
    for rel,row in reconciliation.items():
        assert row['matches_executed'] and row['LF_content_identical']
        assert sha(tree/rel)==row['current_byte_hash'],rel
    actual_source=json.loads((local/'environment.json').read_text())['source_sha256']
    for rel,digest in actual_source.items():
        if rel.replace('\\','/')!='src/core/distqldpc.cc': assert sha(tree/rel)==digest,rel
    binary={v:prep/(v+'.exe') for v in HASHES}
    for v,p in binary.items(): assert sha(p)==HASHES[v],v
    profile=json.loads((prep/'profile-completeness.json').read_text())
    assert profile['status']=='PASS' and all(profile['counts'].values())
    for name,digest in profile['profiles'].items(): assert sha(tree/'pgo-data'/name)==digest,name
    pkg=root/'E004-windows-tier2-02/E004-server-package'
    manifest=json.loads((pkg/'manifest.json').read_text())
    assert manifest['baseline']==BASE and manifest['qdistsat']==QDIST
    for rel,digest in manifest['files'].items(): assert sha(pkg/rel)==digest,rel
    # Older package supplies immutable input and parser only; its LTO executables are never run.
    spec=importlib.util.spec_from_file_location('gates',pkg/'candidate/optimization/server/run.py')
    gates=importlib.util.module_from_spec(spec);spec.loader.exec_module(gates)
    previous=None
    if a.tier==2:
        assert a.tier1_evidence is not None
        previous=json.loads((a.tier1_evidence/'result.json').read_text())
        assert previous['correctness']=='Expected distance/objective/LB/UB identical in all runs'
        assert len(json.loads((a.tier1_evidence/'samples.json').read_text()))==48
        assert previous['decision']=='INCONCLUSIVE' and not previous.get('cleanup_invalid')
        assert all(v['median_geomean']<1 for v in previous['numeric_reason'].values())
        assert not any(r['nonoverlapping_regression'] for r in previous['medians'])
    cases=gates.CASES1 if a.tier==1 else ['LP_340_56_8']
    limit=180 if a.tier==1 else 600
    watchdog_limit=limit+15
    runtime=root/'E004-windows-runtime/cygwin/bin'
    os.environ['PATH']=str(runtime)+os.pathsep+os.environ['PATH']
    os.environ.update(LC_ALL='C',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1')
    out.mkdir(exist_ok=False,parents=True)
    save=lambda n,v:(out/n).write_text(json.dumps(v,indent=2),encoding='utf8',newline='\n')
    shutil.copy2(Path(__file__),out/'executed-driver.py')
    samples=[];resources=[];window=None;process=None
    result={'decision':'INCONCLUSIVE','tier0':'PASS','tier1':'pending' if a.tier==1 else 'INCONCLUSIVE (previous diagnostic)',
            'tier2':'NOT_RUN' if a.tier==1 else 'pending user-authorized exploratory exception','tier3':'NOT_RUN',
            'reason':'Windows diagnostic: no exclusive reservation; never research-grade evidence'}
    def observe(label):
        row=window.observe(label); resources.append(row);save('resources.json',resources)
        return row['eligible']
    def stop_owned(label):
        events=[];deadline=time.monotonic()+30
        while True:
            pids=owned_pids(window)
            if not pids:break
            if time.monotonic()>deadline:raise RuntimeError('Owned-job cleanup not established')
            for pid in pids:
                if pid not in owned_pids(window):continue
                p=subprocess.run(['taskkill','/PID',str(pid),'/T','/F'],capture_output=True,text=True,timeout=10)
                events.append({'pid':pid,'returncode':p.returncode,'stdout':p.stdout,'stderr':p.stderr})
            time.sleep(.1)
        if process is not None:process.wait(timeout=5)
        save(label+'.cleanup.json',{'events':events,'remaining_owned_pids':owned_pids(window)})
    save('result.json',result)
    try:
        window=Window(True,0x8000)
        save('environment.json',{'baseline_sha':BASE,'candidate_sha':CAND,'qdistsat_sha':QDIST,
              'assignment':a.assignment,'hosted':hosted,'binary_sha256':HASHES,
              'driver_sha256':sha(Path(__file__)),'window_helper_sha256':sha(record/'windows_cpu_window.py'),
              'parser_sha256':sha(pkg/'candidate/optimization/server/run.py'),
              'profiles':profile,'source_reconciliation':reconciliation,'manifest':manifest,
              'platform':platform.uname()._asdict(),'python':sys.version,'invocation':sys.argv,
              'affinity':window.selection,'exclusive_reservation':False,
              'tier':a.tier,'prior_tier1':previous,'exploratory_exception':a.tier==2,
              'compiler':subprocess.check_output([str(runtime/'g++.exe'),'--version'],text=True),
              'power_scheme':subprocess.check_output(['powercfg','/GETACTIVESCHEME']).decode(errors='replace')})
        for case in cases:
            expected=int(case.rsplit('_',1)[1])
            for mode in gates.MODES:
                reference=None
                for repeat in range(1,4):
                    for version in (['baseline','candidate'] if repeat%2 else ['candidate','baseline']):
                        label=f'{case}-{mode}-{repeat}-{version}'
                        assert not owned_pids(window),'Previous owned worker still active'
                        window.previous=ticks();time.sleep(2)
                        if not observe(label+'-preflight'):raise RuntimeError('Capacity guard before '+label)
                        cmd=[str(binary[version]),'-v',f'-cpu-lim={limit}','-'+mode,cyg(pkg/'baseline/data/matrices'/case)]
                        save(label+'.command.json',{'argv':cmd,'cwd':str(tree)})
                        print('START '+label,flush=True)
                        start=last=time.perf_counter();abort=watchdog=False;seen=[]
                        with (out/(label+'.stdout')).open('w',encoding='utf8') as so,(out/(label+'.stderr')).open('w',encoding='utf8') as se:
                            process=subprocess.Popen(cmd,cwd=tree,stdout=so,stderr=se)
                            if affinity(process._handle)!=window.mask:raise RuntimeError('Parent affinity mismatch')
                            while process.poll() is None:
                                try:process.wait(timeout=.25)
                                except subprocess.TimeoutExpired:
                                    current=descendant_affinities(process.pid);seen.extend(current)
                                    if not all(r['mask']==window.mask and r['priority_class']==0x8000 for r in current):
                                        raise RuntimeError('Owned worker affinity/priority mismatch')
                                    if time.perf_counter()-last>=2:
                                        abort=not observe(label);last=time.perf_counter()
                                    watchdog=time.perf_counter()-start>=watchdog_limit
                                    if abort or watchdog:stop_owned(label);break
                        elapsed=time.perf_counter()-start
                        save(label+'.affinity.json',seen)
                        if owned_pids(window):stop_owned(label+'-remaining')
                        stdout=(out/(label+'.stdout')).read_text()
                        semantic=gates.parse(stdout)
                        row={'case':case,'mode':mode,'version':version,'repeat':repeat,'elapsed_sec':elapsed,
                             'command':cmd,'cwd':str(tree),'returncode':process.returncode,
                             'resource_abort':abort,'external_timeout':watchdog,'semantic':semantic}
                        samples.append(row);save('samples.json',samples);print(label,elapsed,semantic,flush=True)
                        assert all(int(x)<=expected for x in re.findall(r'^c\s+d_lb:\s*(-?\d+)\s*$',stdout,re.M)),'Wrong interim lower bound '+label
                        assert all(int(x)>=expected for x in re.findall(r'^c\s+d_ub:\s*(-?\d+)\s*$',stdout,re.M)),'Wrong interim upper bound '+label
                        assert all(int(x)>=expected for x in re.findall(r'^o\s+(-?\d+)\s*$',stdout,re.M)),'Wrong interim objective '+label
                        assert all(int(x)==expected for x in re.findall(r'^c\s+d\s*:\s*(-?\d+)\s*$',stdout,re.M)),'Wrong interim distance '+label
                        assert semantic['lb'] is None or semantic['lb']<=expected,'Wrong lower bound '+label
                        assert semantic['ub'] is None or semantic['ub']>=expected,'Wrong upper bound '+label
                        assert semantic['objective'] is None or semantic['objective']>=expected,'Wrong objective '+label
                        if abort or watchdog:raise RuntimeError('Interrupted '+label)
                        assert process.returncode in [0,1],'Crash '+label
                        if process.returncode==0:
                            assert all(semantic[k]==expected for k in ['d','objective','lb','ub']),'Wrong complete result '+label
                            assert not semantic['timeout'] and not semantic['unknown'],'Wrong output semantics '+label
                        else:
                            assert semantic['timeout'] and semantic['unknown'] and semantic['d'] is None and semantic['objective'] is None,'Malformed incomplete output '+label
                            raise RuntimeError('Incomplete/timeout '+label)
                        assert reference is None or semantic==reference,'Semantic mismatch '+label
                        reference=semantic
        numeric,reason,_=gates.judge(samples,cases)
        details=[]
        for case in cases:
            for mode in gates.MODES:
                values={v:[s['elapsed_sec'] for s in samples if s['case']==case and s['mode']==mode and s['version']==v] for v in HASHES}
                b,c=(statistics.median(values[v]) for v in HASHES)
                details.append({'case':case,'mode':mode,'raw':values,'baseline_median':b,'candidate_median':c,
                    'ratio':c/b,'range_envelope':max(values['candidate'])/min(values['baseline']),
                    'nonoverlapping_regression':min(values['candidate'])>max(values['baseline'])})
        result.update({f'tier{a.tier}':f'{len(samples)} scientifically correct solves'})
        result.update(numeric_filter=numeric,numeric_reason=reason,medians=details,
                      correctness='Expected distance/objective/LB/UB identical in all runs')
    except AssertionError as e:
        result.update(decision='REJECTED',reason=str(e),stopped=True)
    except Exception as e:
        result.update(reason=repr(e),stopped=True)
    finally:
        try:
            if window is not None:
                if owned_pids(window):stop_owned('exception')
                save('remaining-owned.json',owned_pids(window))
        finally:
            if window is not None:
                cleanup=window.close();save('cleanup.json',cleanup)
                if not all(cleanup.get(k) is True for k in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored']):
                    result.update(decision='INCONCLUSIVE',reason='Resource restoration not established; no valid performance filter',cleanup_invalid=True)
            for v,p in binary.items():assert sha(p)==HASHES[v],'Binary changed '+v
            for name,digest in profile['profiles'].items():assert sha(tree/'pgo-data'/name)==digest,'Profile changed '+name
            save('result.json',result)
    print(json.dumps(result,indent=2),flush=True)
    return 0 if 'medians' in result else 1

if __name__=='__main__':sys.exit(main())
