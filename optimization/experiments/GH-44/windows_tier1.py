"""Prepared GH44 48-solve Windows Tier1 filter; NOT ASSIGNED, no auto queue.
Derived from executed GH20 Tier1 and successful GH44 corrected Tier0 supervisor;
uses GH44 exact science checker, immutable successful production and preparation
pins, and a three-hour aggregate watchdog. No compile or diagnosis in this driver.

Reuses the reviewed temporary one-CPU Windows Job/capacity helper. Uses
file-backed bounded supervision; no communicate() pipe
drain can hang. QueryInformationJobObject proves owned descendant cleanup.
"""
import argparse
import ctypes as C
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import struct
import tarfile
import io
import itertools
import re
import shutil
import subprocess
import sys
import time

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
ap=argparse.ArgumentParser();ap.add_argument("--out",type=Path,required=True)
ap.add_argument("--run-assignment",required=True)
ap.add_argument("--support-sha",required=True)
args=ap.parse_args()
ASSIGNED_URL="HOST_SLOT_NOT_ASSIGNED"
assert ASSIGNED_URL!="HOST_SLOT_NOT_ASSIGNED", "Preparation only: no host slot"
assert args.run_assignment==ASSIGNED_URL
out=args.out.resolve();out.mkdir(parents=True,exist_ok=False)
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(path,value):Path(path).write_text(json.dumps(value,indent=2),encoding="utf-8",newline="\n")
runtime=ROOT/"E004-windows-runtime/cygwin"
package=ROOT/"E004-windows-tier2-02/E004-server-package"
base=package/"baseline"
candidate=ROOT/"GH44-ISA"
support_head=subprocess.check_output(['git','-C',str(candidate),'rev-parse','HEAD'],text=True,timeout=10).strip()
assert support_head==args.support_sha,'Assigned support commit mismatch'
support_blob=subprocess.check_output(['git','-C',str(candidate),'show',support_head+':optimization/experiments/GH-40/windows_tier1.py'],timeout=10)
assert Path(__file__).read_bytes()==support_blob,'Uncommitted Tier1 driver'
helper=ROOT/"DistQLDPC/optimization/experiments/E004/windows_cpu_window.py"
assert sha(helper)=='ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2','Reviewed helper changed'
spec=importlib.util.spec_from_file_location("gh44_window",helper)
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
def cygpath(v):
    v=str(v).replace("\\","/")
    if v.startswith("-dump-wcnf="):return "-dump-wcnf="+cygpath(v[len("-dump-wcnf="):])
    return "/cygdrive/"+v[0].lower()+v[2:] if len(v)>2 and v[1]==":" else v

k=module.k
k.QueryInformationJobObject.argtypes=[C.c_void_p,C.c_int,C.c_void_p,C.c_ulong,C.POINTER(C.c_ulong)]
k.QueryInformationJobObject.restype=C.c_int
window=None;current=None;resources=[];descendants=[];command_index=0
RUN_START=time.monotonic(); RUN_LIMIT=10800 # Three-hour aggregate cap; no retries.
identities={}
summary=dict(status="INCONCLUSIVE",Tier0="NOT_RUN",diagnostic="NOT_RUN",performance="NOT_MEASURED",
             candidate="4a820ac5c1910d64930ed26a719af2f046a6a693",assignment=args.run_assignment)

def job_pids():
    buf=C.create_string_buffer(65536);returned=C.c_ulong()
    if not k.QueryInformationJobObject(window.job,3,buf,C.sizeof(buf),C.byref(returned)):
        raise C.WinError(C.get_last_error())
    assigned,count=struct.unpack_from("<II",buf)
    assert assigned==count and 8+8*count<=C.sizeof(buf),(assigned,count)
    return list(struct.unpack_from("<"+"Q"*count,buf,8))

def observe(label):
    row=window.observe(label);resources.append(row);save(out/"resources.json",resources)
    if not row["eligible"]:raise RuntimeError("Spare-capacity guard: "+label)
    return row

def clean_owned(reason):
    records=[]
    if current is not None and current.poll() is None:
        result=subprocess.run(["taskkill","/PID",str(current.pid),"/T","/F"],
                              capture_output=True,text=True,timeout=10)
        records.append(dict(pid=current.pid,returncode=result.returncode,stdout=result.stdout,stderr=result.stderr))
        save(out/("cleanup-actions-"+str(command_index)+".json"),records)
        current.wait(timeout=10)
    # This NEW unnamed Job contains only this runner and its children, not other
    # users' jobs. Bounded cleanup handles any already-orphaned owned descendants.
    remaining=[pid for pid in job_pids() if pid!=os.getpid()]
    for pid in remaining:
        if pid not in job_pids():continue
        result=subprocess.run(["taskkill","/PID",str(pid),"/T","/F"],capture_output=True,text=True,timeout=10)
        records.append(dict(pid=pid,returncode=result.returncode,stdout=result.stdout,stderr=result.stderr))
        save(out/("cleanup-actions-"+str(command_index)+".json"),records)
    deadline=time.monotonic()+5
    while time.monotonic()<deadline and [pid for pid in job_pids() if pid!=os.getpid()]:time.sleep(.1)
    still=[pid for pid in job_pids() if pid!=os.getpid()]
    save(out/("owned-cleanup-"+str(command_index)+".json"),dict(reason=reason,actions=records,
         remaining=still,confirmed=(not still)))
    if still:raise RuntimeError("Owned descendant cleanup unconfirmed: "+repr(still))

def managed_run(argv,cwd,target,label,timeout,cygwin=False):
    global current,command_index
    assert time.monotonic()-RUN_START<RUN_LIMIT,'Aggregate watchdog expired'
    assert job_pids()==[os.getpid()],'Owned workers still active'
    for p,digest in identities.items():
        if p in runtime_identity_paths and p not in critical_runtime_paths:continue
        assert sha(p)==digest,'Identity changed before command: '+p
    for p,digest in inputs.items():assert sha(p)==digest,'Input changed before command: '+p
    command_index+=1;target=Path(target);target.mkdir(exist_ok=True,parents=True)
    argv=list(map(str,argv))
    if cygwin:argv=[argv[0]]+[cygpath(v) for v in argv[1:]]
    window.previous=module.ticks();time.sleep(2.1);observe(label+"-preflight")
    command=dict(argv=argv,cwd=str(cwd),timeout_sec=timeout,assignment=args.run_assignment)
    reason=None;start=time.monotonic();last=start;sampled=False
    with (target/(label+".stdout")).open("wb") as stdout,(target/(label+".stderr")).open("wb") as stderr:
        try:
            env=dict(os.environ)
            if cygwin and Path(argv[0]).name.lower()=='make.exe':env['PATH']=cygpath(runtime/'bin')+':/usr/bin:/bin'
            current=subprocess.Popen(argv,cwd=cwd,stdout=stdout,stderr=stderr,env=env)
            # Verify actual owned descendants when present; Job limits also
            # enforce children too short-lived to capture in a sample.
            while current.poll() is None:
                time.sleep(.05)
                now=time.monotonic()
                if not sampled or now-last>=2:
                    seen=module.descendant_affinities(current.pid)
                    descendants.append(dict(label=label,time=time.time(),records=seen))
                    save(out/"descendants.json",descendants)
                    assert all(r["mask"]==window.mask and r["priority_class"]==0x8000 for r in seen),seen
                    sampled=True
                if now-last>=2:
                    observe(label);last=now
                if now-start>timeout or now-RUN_START>RUN_LIMIT:raise subprocess.TimeoutExpired(argv,timeout)
            command["returncode"]=current.returncode
            command["elapsed_sec"]=time.monotonic()-start
            deadline=time.monotonic()+2
            while time.monotonic()<deadline and [pid for pid in job_pids() if pid!=os.getpid()]:time.sleep(.1)
            active=[pid for pid in job_pids() if pid!=os.getpid()]
            command["owned_descendants_remaining"]=active
            if active:raise RuntimeError("Unexpected owned descendant after command: "+repr(active))
        except BaseException as error:
            reason=repr(error);command["abort"]=reason
            try:clean_owned(reason)
            except Exception as cleanup_error:command["cleanup_failure"]=repr(cleanup_error)
            raise
        finally:
            save(target/(label+".command.json"),command)
    text=(target/(label+".stdout")).read_text(encoding="utf-8",errors="replace")
    error=(target/(label+".stderr")).read_text(encoding="utf-8",errors="replace")
    print(label+": rc="+str(current.returncode),flush=True)
    return current.returncode,text,error


def scientific(rc,text,exact,timeout=False,incomplete=False):
    # Reject malformed fields, every interim bound/objective/d, not only final values.
    values={}
    specs={'lb':(r'^c\s+d_lb:\s*(.*?)\s*$',{'-'}),'ub':(r'^c\s+d_ub:\s*(.*?)\s*$',{'-'}),
           'd':(r'^c\s+d\s*:\s*(.*?)\s*$',{'UNKNOWN'}),'objective':(r'^o(?:\s+(.*?))?\s*$',set())}
    for key,(pattern,sentinels) in specs.items():
        raw=re.findall(pattern,text,re.M);nums=[]
        for item in raw:
            if item in sentinels:continue
            assert item is not None,'SCIENCE missing objective'
            assert re.fullmatch(r'\d+',item),'SCIENCE malformed '+key+': '+item
            value=int(item);nums.append(value)
            assert value<=exact if key=='lb' else value==exact if key=='d' else value>=exact,'SCIENCE wrong interim '+key
        values[key]=int(raw[-1]) if raw and re.fullmatch(r'\d+',raw[-1]) else None
    for value in re.findall(r'^c\s+trying d:\s*(.*?)\s*$',text,re.M):
        assert re.fullmatch(r'\d+',value),'SCIENCE malformed trying distance'
    statuses=re.findall(r'^s\s+(.*?)\s*$',text,re.M)
    comments=re.findall(r'^c status:\s*(.*?)\s*$',text,re.M)
    unknown=bool(re.search(r'^s UNKNOWN\s*$',text,re.M))
    timed=bool(re.search(r'^c status: TIMEOUT\b',text,re.M))
    if timeout or incomplete:
        assert rc==1 and unknown,'SCIENCE incomplete status/return'
        assert statuses==['UNKNOWN'] and len(comments)==1,'SCIENCE changed incomplete output semantics'
        assert comments[0]=='UNKNOWN' or comments[0].startswith('TIMEOUT'),'SCIENCE malformed incomplete status'
        if timeout:assert timed,'SCIENCE requested timeout status missing'
        assert values['d'] is None and values['objective'] is None,'SCIENCE incomplete solve reported optimum'
        assert not re.search(r'^o\b',text,re.M),'SCIENCE incomplete objective'
    else:
        assert rc==0 and not unknown and not timed,'SCIENCE complete return/status'
        assert not statuses and not comments,'SCIENCE unexpected completed status'
        assert all(value==exact for value in values.values()),'SCIENCE malformed/incomplete final '+repr(values)
    return dict(values,unknown=unknown,timeout=timed,returncode=rc)

BASE='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CAND='4a820ac5c1910d64930ed26a719af2f046a6a693'
HASHES={'baseline':'5d21d6c0c8daf117470e0dd353086f5a27bf5751f2a8ddb35136f2ac779325a8','candidate':'42ebb16923087a68472cb5b821f470fd5f08be565033a82acf2d67765b78168e'}
CASES=['BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6']
MODES=['no-card','card-mto']
prep=ROOT/'GH44-windows-tier0-01'
record=candidate/'optimization/experiments/GH-40'
binaries={v:prep/(v+'-source')/'bin/distqldpc.exe' for v in HASHES}
samples=[];inputs={}
summary.update(status='INCONCLUSIVE',decision='INCONCLUSIVE',Tier0='PASS',Tier1='NOT_RUN',Tier2='NOT_RUN',Tier3='NOT_RUN',performance='PENDING_ASSIGNED_DIAGNOSTIC',reason='No exclusive OS reservation; report numeric filter separately')
try:
    window=module.Window(True,0x8000);save(out/'window.json',window.selection)
    window.previous=module.ticks();time.sleep(2.1);observe('assigned-preflight')
    preparation_pins={'summary.json': '65ca8ab4414480264f2f3542a8d93cd0766e2efc1be8425da90c954fab3c3d27', 'preexecution.json': '088d72695126e8d82366fcd955222582f6def234010b8d384f9a618a16db0cec', 'binary-hashes.json': '6ecb4dc684282f3f00bdf4c672a7c5577ecae6351e27b30fac0b71433f1c148a', 'SHA256.json': 'd842d514869b09508f5724d91553035aa2b579b4be38af0bec0c3cd956a2042e', 'AUDIT.json': 'bb04c997f344d944d51526a53147dd1d397292f13543f17564cae2de886f0f87', 'POST-EXIT.json': '90756e28499e2b330c802b911eb510af884db01a6743ac9e94849110e50b7691', 'runtime-post-file-set.json': 'e50e817e192255e378a834cc3fca40295b0393be9f2970dd3c2734533cf911c5'}
    for name,digest in preparation_pins.items():
        p=prep/name;assert sha(p)==digest,'Production preparation changed: '+name;identities[str(p)]=digest
    original_manifest=json.loads((prep/'SHA256.json').read_text(encoding='utf8'))
    for rel,digest in original_manifest.items():
        p=prep/rel;assert sha(p)==digest,'Successful Tier0 raw changed: '+rel;identities[str(p)]=digest
    runtime_manifest=json.loads((record/'runtime-original.json').read_text(encoding='utf8'))
    runtime_identity_paths={str(runtime/p) for p in runtime_manifest}
    critical_runtime_paths=set(json.loads((prep/'preexecution.json').read_text(encoding='utf8'))['critical_runtime_paths'])
    frozen_runtime_file_set={p.relative_to(runtime).as_posix() for p in runtime.rglob('*') if p.is_file()}
    assert frozen_runtime_file_set==set(runtime_manifest),'Runtime file-set drift before timing'
    for p,digest in runtime_manifest.items():assert sha(runtime/p)==digest,'Runtime drift before timing: '+p;identities[str(runtime/p)]=digest
    original=json.loads((prep/'preexecution.json').read_text(encoding='utf8'))
    assert original['production_candidate']==CAND and original['baseline']==BASE
    assert original['record_head']=='09f32016f6da1d6218f534b0c3f8ae16d1b52614'
    for path,digest in original['identities'].items():
        assert sha(path)==digest,'Original Tier0 identity changed: '+path
        identities[path]=digest
    for p in [Path(__file__),record/'raw/hosted-09f3201/audit.json']:
        identities[str(p)]=sha(p)
    tier0=json.loads((prep/'summary.json').read_text(encoding='utf8'))
    assert tier0['Tier0']=='LOCAL_PASS' and tier0['diagnostic']=='NOT_RUN' and tier0['valid_run'] is True
    assert all(tier0['cleanup'].get(k) is True for k in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored'])
    assert sha(record/"raw/hosted-09f3201/audit.json")=='cf433a481c939d53c4a3d0e834a86b9c055d5667853a82e08a235c73b1e7c305'
    hosted=json.loads((record/'raw/hosted-09f3201/audit.json').read_text(encoding='utf8'))
    assert hosted['status']=='PASS' and len(hosted['source_files'])==32 and hosted['production']==CAND and hosted['baseline']==BASE and hosted['gate']['compatible'] is True
    head=subprocess.check_output(['git','-C',str(candidate),'rev-parse','HEAD'],text=True,timeout=10).strip()
    assert head==support_head,'Assigned support HEAD changed'
    assert not subprocess.check_output(['git','-C',str(candidate),'diff',CAND,head,'--','src','Makefile'],timeout=10)
    manifest=json.loads((package/'manifest.json').read_text(encoding='utf8'))
    assert manifest['baseline']==BASE and manifest['qdistsat']=='7c4774fffc49856f48a22ae5f9063d00b2661aaa'
    for version,binary in binaries.items():
        assert sha(binary)==HASHES[version],version;identities[str(binary)]=HASHES[version]
    input_map=record/'tier1-input-sha256.json'
    assert sha(input_map)=='a4d6e78c6d75eb9a6e101e9de3ec68a95fad534821f90c704cc84523297f701a'
    identities[str(input_map)]=sha(input_map)
    frozen_inputs=json.loads(input_map.read_text(encoding='utf8'))
    for case in CASES:
        for suffix in ['Hx','Hz','Gx','Gz']:
            p=base/'data/matrices'/(case+'_'+suffix+'.txt');rel=str(p.relative_to(package)).replace('\\','/')
            assert sha(p)==manifest['files'][rel]==frozen_inputs[p.name],rel;inputs[str(p)]=sha(p)
    parser=package/'candidate/optimization/server/run.py'
    relative=str(parser.relative_to(package)).replace('\\','/');assert sha(parser)==manifest['files'][relative]=='9674067528d0f3d7f1393d8732ae10b6a7289fbfd04e1d52f0832f7512e6dac5'
    identities[str(parser)]=sha(parser)
    spec=importlib.util.spec_from_file_location('gh44_numeric_filter',parser);gates=importlib.util.module_from_spec(spec);spec.loader.exec_module(gates)
    assert gates.CASES1==CASES and gates.MODES==MODES
    save(out/'preexecution.json',dict(baseline=BASE,candidate=CAND,record_head=head,assignment=args.run_assignment,
        driver_sha256=sha(__file__),helper_sha256=sha(helper),parser_sha256=sha(parser),binary_hashes=HASHES,input_hashes=inputs,
        production_preparation_sha256=sha(prep/'preexecution.json'),production_summary_sha256=sha(prep/'summary.json'),original_preparation_pins=preparation_pins,identities=identities,
        hosted_audit_sha256=sha(record/'raw/hosted-09f3201/audit.json'),
        driver_provenance='Executed GH27 standard Tier1 and corrected GH44 Tier0 bounded Job supervisor/science checker; GH16 AB/BA/AB and E004 immutable numeric filter',
        gh16_reviewed_driver_sha256='5f4064eb7d9ce8fe7bc82dfe3862d1431d7f2d946dced3c1d27976bdf0052c21',
        polling_sec=.05,sampling_sec=2,exclusive_reservation=False,internal_limit=180,watchdog=195,aggregate_watchdog=RUN_LIMIT))
    shutil.copy2(Path(__file__),out/'executed-driver.py')
    os.environ['PATH']=str(runtime/'bin')+os.pathsep+os.environ['PATH']
    os.environ.update(LC_ALL='C',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1')

    gate_binary=prep/'portable-isa-gate.exe'
    assert sha(gate_binary)==original_manifest['portable-isa-gate.exe']
    identities[str(gate_binary)]=sha(gate_binary)
    rc,text,error=managed_run([gate_binary],candidate,out,'fresh-selected-core-isa-gate',20,True)
    if rc!=0 or error:raise RuntimeError('Fresh selected-core ISA gate did not complete: '+repr((rc,error)))
    gate=json.loads(text)
    if not gate.get('compatible') or gate.get('xcr0',0)&6!=6:raise RuntimeError('Selected CPU lacks required v3/OS state')
    save(out/'isa-gate.json',dict(cpu=window.selection['selected_cpu'],mask=window.mask,cpuid=gate))
    for case in CASES:
        expected=int(case.rsplit('_',1)[1])
        for mode in MODES:
            reference=None
            for repeat in range(1,4):
                for version in (['baseline','candidate'] if repeat%2 else ['candidate','baseline']):
                    label=f'{case}-{mode}-{repeat}-{version}'
                    assert job_pids()==[os.getpid()],'Owned worker still active'
                    print('START '+label,flush=True)
                    rc,text,error=managed_run([binaries[version],'-v','-cpu-lim=180','-'+mode,base/'data/matrices'/case],candidate,out,label,195,True)
                    command=json.loads((out/(label+'.command.json')).read_text(encoding='utf8'))
                    semantic=gates.parse(text)
                    row=dict(case=case,mode=mode,repeat=repeat,version=version,elapsed_sec=command['elapsed_sec'],returncode=rc,
                        command=command['argv'],semantic=semantic,resource_abort=False,external_timeout=False)
                    samples.append(row);save(out/'samples.json',samples)
                    assert not error,'SCIENCE scientific stderr regression '+label
                    assert rc in [0,1],'SCIENCE crash '+label
                    if rc==1:
                        scientific(rc,text,expected,incomplete=True)
                        raise RuntimeError('Genuine incomplete solve blocks timing filter: '+label)
                    scientific(rc,text,expected)
                    assert reference is None or semantic==reference,'SCIENCE semantic mismatch '+label
                    reference=semantic
    assert len(samples)==48
    numeric,reason,details=gates.judge(samples,CASES)
    import statistics
    complete=[]
    for case in CASES:
        for mode in MODES:
            values={v:[r['elapsed_sec'] for r in samples if r['case']==case and r['mode']==mode and r['version']==v] for v in HASHES}
            b,c=(statistics.median(values[v]) for v in HASHES)
            complete.append(dict(case=case,mode=mode,raw=values,baseline_median=b,candidate_median=c,ratio=c/b,
                range_envelope=max(values['candidate'])/min(values['baseline']),nonoverlapping_regression=min(values['candidate'])>max(values['baseline'])))
    summary.update(status='FILTER_COMPLETE',Tier1='48 scientifically correct solves',performance='WINDOWS_DIAGNOSTIC',
        numeric_filter=numeric,numeric_reason=reason,medians=complete,legacy_filter_details=details,
        correctness='Expected distance/objective/LB/UB identical in all runs',reason='Numeric direction/variability reported; controlled confirmation pending')
except BaseException as error:
    summary['reason']=repr(error)
    if isinstance(error,AssertionError) and 'SCIENCE' in str(error):summary.update(status='REJECTED',decision='REJECTED',Tier1='REJECTED_SCIENCE')
    print('STOP: '+repr(error),flush=True)
finally:
    if window is not None:
        try:
            clean_owned('final-cleanup');save(out/'job-pids-before-release.json',job_pids())
        except Exception as error:summary.update(cleanup_failure=repr(error),cleanup_invalid=True)
        finally:
            # Restoration is attempted independently of child-cleanup success.
            # Preserve any scientific rejection as a separate, durable finding.
            try:
                cleanup=window.close();save(out/'cleanup.json',cleanup);summary['cleanup']=cleanup
                if not all(cleanup.get(k) is True for k in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored']):summary['cleanup_invalid']=True
            except Exception as error:summary.update(restoration_failure=repr(error),cleanup_invalid=True)
    identity_errors=[]
    if 'frozen_runtime_file_set' in globals():
        try:
            actual={p.relative_to(runtime).as_posix() for p in runtime.rglob('*') if p.is_file()}
            confirmation=dict(pre_count=len(frozen_runtime_file_set),post_count=len(actual),identical=actual==frozen_runtime_file_set,added=sorted(actual-frozen_runtime_file_set),removed=sorted(frozen_runtime_file_set-actual))
            save(out/'runtime-post-file-set.json',confirmation)
            if not confirmation['identical']:identity_errors.append('Runtime post file-set drift')
        except Exception as error:identity_errors.append('Runtime file-set postcheck failed: '+repr(error))

    for path,digest in identities.items():
        try:
            if sha(path)!=digest:identity_errors.append(path+' identity changed')
        except Exception as error:identity_errors.append(path+': '+repr(error))
    for version,binary in binaries.items():
        try:
            if sha(binary)!=HASHES[version]:identity_errors.append(version+' binary changed')
        except Exception as error:identity_errors.append(version+': '+repr(error))
    for p,digest in inputs.items():
        try:
            if sha(Path(p))!=digest:identity_errors.append(p+' input changed')
        except Exception as error:identity_errors.append(p+': '+repr(error))
    if identity_errors:summary['identity_invalid']=identity_errors
    summary['valid_run']=bool(summary.get('status')=='FILTER_COMPLETE' and len(samples)==48 and not summary.get('cleanup_invalid') and not summary.get('identity_invalid'))
    if not summary['valid_run'] and summary.get('decision')!='REJECTED':summary.update(status='INCONCLUSIVE',decision='INCONCLUSIVE')
    save(out/'result.json',summary)
    try:save(out/'SHA256.json',{str(p.relative_to(out)):sha(p) for p in sorted(out.rglob('*')) if p.is_file() and p.name!='SHA256.json'})
    except Exception as error:
        summary.update(manifest_failure=repr(error),valid_run=False)
        save(out/'result.json',summary)
    print(json.dumps(summary,indent=2),flush=True)
sys.exit(0 if summary['valid_run'] else 1)
