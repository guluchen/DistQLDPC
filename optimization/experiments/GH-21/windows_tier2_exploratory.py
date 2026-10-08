"""GH21 frozen O3/O2-only exploratory LP340 Tier2; no formal Tier1 promotion."""
import argparse, ctypes as C, hashlib, importlib.util, json, math, os
from pathlib import Path
import platform, re, shutil, statistics, subprocess, sys, time
from windows_cpu_window import Window, ticks, affinity, descendant_affinities, k

BASE='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CAND='e1aa9175c511b72dbb7305f5769b1e11f41bc05f'
ASSIGNED_URL='HOST_SLOT_NOT_ASSIGNED'
QDIST='7c4774fffc49856f48a22ae5f9063d00b2661aaa'
HASHES={'baseline':'22e398cc7558c2a04d5f24bd6db3030ce552c752622027fc2657eff7c1bd1815',
        'candidate':'f2964427f02a49359784305b00b24c082cd05f67c76e5659e9c8f5955e9e16c0'}
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
    if info.count>1024:
        raise RuntimeError('Owned-job PID inventory exceeds bounded buffer')
    return [int(p) for p in info.ids[:info.count] if p!=os.getpid()]

def scientific_updates(text,expected):
    specs={'lb':r'^c\s+d_lb:\s*(.*?)\s*$', 'ub':r'^c\s+d_ub:\s*(.*?)\s*$',
           'd':r'^c\s+d\s*:\s*(.*?)\s*$', 'objective':r'^o\s+(.*?)\s*$'}
    for key,pattern in specs.items():
        for item in re.findall(pattern,text,re.M):
            if item=='-' and key in ['lb','ub']:continue
            if item=='UNKNOWN' and key=='d':continue
            assert re.fullmatch(r'\d+',item),'Malformed scientific '+key+': '+item
            value=int(item)
            assert value<=expected if key=='lb' else value==expected if key=='d' else value>=expected,'Wrong scientific '+key

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--workspace',type=Path,required=True)
    ap.add_argument('--output',type=Path,required=True)
    ap.add_argument('--assignment',required=True,help='GitHub coordinator RUN_ASSIGNMENT comment URL')
    a=ap.parse_args(); root=a.workspace.resolve(); out=a.output.resolve()
    assert ASSIGNED_URL!='HOST_SLOT_NOT_ASSIGNED','No fresh RUN_ASSIGNMENT; preparation only'
    assert a.assignment==ASSIGNED_URL and platform.system()=='Windows'
    assert out.is_relative_to(root) and out!=root and not out.exists()
    tree=root/'GH21-O2';record=tree/'optimization/experiments/GH-21'
    local=record/'raw/windows-assigned-02'
    from audit_hosted import audit as audit_hosted
    from audit_tier0 import audit as audit_tier0
    audit_hosted(record/'raw/hosted-e1aa917');audit_tier0(local)
    from audit_tier1 import audit as audit_tier1
    audit_tier1(record/'raw/windows-tier1-01')
    hosted=json.loads((record/'raw/hosted-e1aa917/identity.json').read_text(encoding='utf-8'))
    assert hosted['candidate_sha']==CAND and hosted['baseline_sha']==BASE and hosted['qdistsat_sha']==QDIST
    head=subprocess.check_output(['git','-C',str(tree),'rev-parse','HEAD'],text=True,timeout=10).strip()
    assert not subprocess.check_output(['git','-C',str(tree),'diff',CAND,head,'--','src','Makefile'],timeout=10)
    paths=subprocess.check_output(['git','-C',str(tree),'ls-tree','-r','--name-only',head,'src'],text=True,timeout=10).splitlines()
    for rel in paths+['Makefile']:
        canonical=subprocess.check_output(['git','-C',str(tree),'show',head+':'+rel],timeout=10)
        assert (tree/rel).read_bytes().replace(bytes([13,10]),bytes([10]))==canonical.replace(bytes([13,10]),bytes([10])),rel
    reconciliation=json.loads((local/'identity.json').read_text(encoding='utf-8'))
    binary={'baseline':root/'E004-windows-tier2-02/E004-server-package/baseline/bin/distqldpc.exe',
            'candidate':tree/'bin/distqldpc.exe'}
    for v,p in binary.items():assert sha(p)==HASHES[v],v
    assert json.loads((local/'tier0/identity.json').read_text(encoding='utf-8'))['binaries']==HASHES
    pkg=root/'E004-windows-tier2-02/E004-server-package'
    manifest=json.loads((pkg/'manifest.json').read_text(encoding='utf-8'))
    assert manifest['baseline']==BASE and manifest['qdistsat']==QDIST
    for rel,digest in manifest['files'].items():assert sha(pkg/rel)==digest,rel
    # Immutable parser/input package only. Its LTO candidate binary is NEVER run.
    parser=pkg/'candidate/optimization/server/run.py'
    assert sha(parser)=='9674067528d0f3d7f1393d8732ae10b6a7289fbfd04e1d52f0832f7512e6dac5'
    spec=importlib.util.spec_from_file_location('gates',parser)
    gates=importlib.util.module_from_spec(spec);spec.loader.exec_module(gates)
    assert sha(record/'windows_cpu_window.py')=='ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2'
    cases=['LP_340_56_8']
    assert gates.CASES1==['BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6'] and gates.MODES==['no-card','card-mto']
    input_hashes={f'baseline/data/matrices/{case}_{suffix}.txt':manifest['files'][f'baseline/data/matrices/{case}_{suffix}.txt']
                  for case in gates.CASES1+cases for suffix in ['Hx','Hz','Gx','Gz']}
    assert len(input_hashes)==20
    limit=600;watchdog_limit=615
    runtime=root/'E004-windows-runtime/cygwin/bin'
    assert sha(runtime.parent/'etc/setup/installed.db')==reconciliation['runtime_manifest_sha256']
    os.environ['PATH']=str(runtime)+os.pathsep+os.environ['PATH']
    os.environ.update(LC_ALL='C',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1')
    out.mkdir(exist_ok=False,parents=True)
    save=lambda n,v:(out/n).write_text(json.dumps(v,indent=2),encoding='utf8',newline='\n')
    shutil.copy2(Path(__file__),out/'executed-driver.py')
    samples=[];resources=[];window=None;process=None
    result={'decision':'INCONCLUSIVE','tier0':'PASS','tier1':'INCONCLUSIVE','tier2':'pending','tier3':'NOT_RUN',
            'exploratory_exception':True,
            'tier1_promoted':False,
            'reason':'User-authorized one-tier exploratory exception; Tier1 INCONCLUSIVE, Windows diagnostic only'}
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
              'tier0_identity':reconciliation,'record_head':head,'manifest':manifest,'input_sha256':input_hashes,
              'platform':platform.uname()._asdict(),'python':sys.version,'invocation':sys.argv,
              'affinity':window.selection,'exclusive_reservation':False,
              'tier':2,'exploratory_exception':True,'tier1_promoted':False,
              'compiler':subprocess.check_output([str(runtime/'g++.exe'),'--version'],text=True,timeout=10),
              'power_scheme':subprocess.check_output(['powercfg','/GETACTIVESCHEME'],timeout=10).decode(errors='replace')})
        for case in cases:
            expected=int(case.rsplit('_',1)[1])
            for mode in gates.MODES:
                reference=None
                for repeat in range(1,4):
                    for version in (['baseline','candidate'] if repeat%2 else ['candidate','baseline']):
                        label=f'{case}-{mode}-{repeat}-{version}'
                        if owned_pids(window):raise RuntimeError('Previous owned worker still active')
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
                        stdout=(out/(label+'.stdout')).read_text(encoding='utf-8')
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
                        scientific_updates(stdout,expected)
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
        result.update(tier2=f'{len(samples)} scientifically correct solves')
        if numeric=='reject':result.update(decision='REJECT',reason='Repeated nonoverlapping per-case diagnostic regression')
        result.update(numeric_filter=numeric,numeric_reason=reason,medians=details,
                      correctness='Expected distance/objective/LB/UB identical in all runs')
    except AssertionError as e:
        result.update(decision='REJECT',reason=str(e),stopped=True,
                      scientific_reject=True,scientific_reject_reason=str(e))
    except Exception as e:
        result.update(reason=repr(e),stopped=True)
    finally:
        # Retain an honest result even if cleanup, restoration or final hashes fail.
        if window is not None:
            try:
                if owned_pids(window):stop_owned('exception')
                save('remaining-owned.json',owned_pids(window))
            except Exception as error:result.update(cleanup_invalid=True,cleanup_failure=repr(error))
            try:
                cleanup=window.close();save('cleanup.json',cleanup)
                if not all(cleanup.get(k) is True for k in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored']):
                    result.update(cleanup_invalid=True,restoration_failure='Not all restoration booleans true')
            except Exception as error:result.update(cleanup_invalid=True,restoration_failure=repr(error))
        else:result.update(cleanup_invalid=True,restoration_failure='Resource window was not established')
        try:
            for v,p in binary.items():assert sha(p)==HASHES[v],'Binary changed '+v
            assert sha(record/'windows_cpu_window.py')=='ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2'
            assert sha(parser)=='9674067528d0f3d7f1393d8732ae10b6a7289fbfd04e1d52f0832f7512e6dac5'
            assert sha(runtime.parent/'etc/setup/installed.db')==reconciliation['runtime_manifest_sha256'],'Runtime manifest changed'
            for rel,digest in input_hashes.items():assert sha(pkg/rel)==digest,'Input matrix changed '+rel
        except Exception as error:result.update(identity_invalid=True,identity_failure=repr(error))
        result['valid_run']=('medians' in result and len(samples)==12 and not result.get('cleanup_invalid')
                             and not result.get('identity_invalid') and not result.get('stopped'))
        if result.get('cleanup_invalid') or result.get('identity_invalid'):
            result.update(filter_invalid=True)
            if not result.get('scientific_reject'):
                result.update(decision='INCONCLUSIVE',reason='Cleanup/restoration or frozen identity unconfirmed; filter invalid')
        save('result.json',result)
        save('SHA256.json',{p.relative_to(out).as_posix():sha(p) for p in out.rglob('*')
                           if p.is_file() and p.name!='SHA256.json'})
    print(json.dumps(result,indent=2),flush=True)
    return 0 if result['valid_run'] else 1

if __name__=='__main__':sys.exit(main())
