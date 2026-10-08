"""Prepared GH36 48-solve Windows Tier1 filter; NOT ASSIGNED, no auto queue.
Derived from actually executed GH27 Tier1 and successful GH36 Tier0 supervisor;
uses GH36 exact science checker, immutable successful production and preparation
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
out=args.out.resolve();assert out.parent==ROOT and not out.exists(),'Fresh direct workspace child required';out.mkdir()
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(path,value):Path(path).write_text(json.dumps(value,indent=2),encoding="utf-8",newline="\n")
runtime=ROOT/"E004-windows-runtime/cygwin"
package=ROOT/"E004-windows-tier2-02/E004-server-package"
base=package/"baseline"
candidate=ROOT/"GH36-WITNESS"
support_head=subprocess.check_output(['git','-C',str(candidate),'rev-parse','HEAD'],text=True,timeout=10).strip()
assert support_head==args.support_sha,'Assigned support commit mismatch'
support_blob=subprocess.check_output(['git','-C',str(candidate),'show',support_head+':optimization/experiments/GH-36/windows_tier1.py'],timeout=10)
assert Path(__file__).read_bytes().replace(b'\r\n',b'\n')==support_blob.replace(b'\r\n',b'\n'),'Uncommitted Tier1 driver'
helper=ROOT/"DistQLDPC/optimization/experiments/E004/windows_cpu_window.py"
assert sha(helper)=='ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2','Reviewed helper changed'
PREIMPORT={Path(sys.executable):'ef8f51028ac5329641985112f8efb1c2d4c47c86b8011ddf7e6fae21e2b4e5a1',
           Path(sys.executable).parent/'python313.dll':'3a7a6170ea840bf2a2a76d05b687b946fcdc8d0cfedfe159012b38f1e8959a7c',
           helper:'ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2'}
for p,digest in PREIMPORT.items():assert sha(p)==digest,'Preimport identity changed: '+str(p)
spec=importlib.util.spec_from_file_location("gh36_window",helper)
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
identities={str(p):digest for p,digest in PREIMPORT.items()}
summary=dict(status="INCONCLUSIVE",Tier0="NOT_RUN",diagnostic="NOT_RUN",performance="NOT_MEASURED",
             candidate="f8f379ddb7d7cc4a0f8dc1d62f670b2e97bd22a1",assignment=args.run_assignment)

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
CAND='f8f379ddb7d7cc4a0f8dc1d62f670b2e97bd22a1'
HASHES={'baseline':'96a3dba9d76d1af06f5d4f5422874287d53d6c4d071b37e1cc88c2e7a42d2d3f','candidate':'983d51be5fa12a71a630b16aef02fa0b1d57fcc92d8520154af06974d005d55a'}
CASES=['BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6']
MODES=['no-card','card-mto']
prep=ROOT/'GH36-windows-tier0-01'
record=candidate/'optimization/experiments/GH-36'
binaries={v:prep/(v+'-source')/'bin/distqldpc.exe' for v in HASHES}
samples=[];inputs={}
summary.update(status='INCONCLUSIVE',decision='INCONCLUSIVE',Tier0='PASS',Tier1='NOT_RUN',Tier2='NOT_RUN',Tier3='NOT_RUN',performance='PENDING_ASSIGNED_DIAGNOSTIC',reason='No exclusive OS reservation; report numeric filter separately')
try:
    preparation_pins={"summary.json":"25e8e940ccf2b908b1919111a71f8e79475e84b48bd671c2430be63c5219f5db","preexecution.json":"9e5e0fcb59e8beb3be22b4aadcbca30db57ed35278ae5a9a778ae00a7a41bbe3","binary-hashes.json":"7cac0007d7fa499ac07e4aadc44e6777de89324840024506bbf93ad91bd08eb9","SHA256.json":"97188a7019ccdb83646d28557496453822b9d1d2ef3873e60947487d71d17198","postexecution-identities.json":"efdc4697ae022db9021dadc51c2e75e58b1c50cae5834be81bccff68e27a0e7d","owned-cleanup-223.json":"4e5d4b35983ca591f30bd0247ffaa8723342e59b41f3a1890e328fab35c388fa"}
    for name,digest in preparation_pins.items():
        p=prep/name;assert sha(p)==digest,'Production preparation changed: '+name;identities[str(p)]=digest
    original=json.loads((prep/'preexecution.json').read_text(encoding='utf8'))
    assert original['production_candidate']=='f8f379d' and original['baseline']==BASE
    assert original['record_head']=='247bc11d4191e36466f2203f0236da102d27ff0d'
    tier0=json.loads((prep/'summary.json').read_text(encoding='utf8'))
    assert tier0['Tier0']=='LOCAL_PASS' and tier0['status']=='PREPARATORY_COMPLETE' and tier0['diagnostic']=='NOT_REQUESTED'
    assert not any(tier0.get(k) for k in ['identity_failure','cleanup_failure','scientific_rejected'])
    assert all(tier0['cleanup'].get(k) is True for k in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored'])
    assert tier0['cleanup']['final_mask']==65535 and tier0['cleanup']['final_priority_class']==32
    cleanup=json.loads((prep/'owned-cleanup-223.json').read_text(encoding='utf8'))
    assert cleanup['confirmed'] is True and cleanup['remaining']==[]
    assert json.loads((prep/'postexecution-identities.json').read_text())==dict(support=True,runtime=True,inputs=True)
    raw_manifest=json.loads((prep/'SHA256.json').read_text(encoding='utf8'))
    assert len(raw_manifest)==820
    for name,digest in raw_manifest.items():
        p=(prep/name).resolve();assert p.is_relative_to(prep.resolve()),'Unsafe raw manifest path'
        assert sha(p)==digest,'Tier0 raw identity changed: '+name;identities[str(p)]=digest
    for version,hashes in original['source_hashes'].items():
        for name,digest in hashes.items():
            p=prep/(version+'-source')/name
            assert sha(p)==digest,'Frozen original export changed: '+version+' '+name;identities[str(p)]=digest
        # Authenticate actual git archive export, which honors core.autocrlf.
        commit=BASE if version=='baseline' else CAND
        exported=subprocess.check_output(['git','-C',str(candidate),'archive',commit,'src','Makefile','scripts/smoke_test.sh'],timeout=20)
        assert exported==(prep/(version+'-source.tar')).read_bytes(),'Original source archive differs from actual pinned Git export'
        with tarfile.open(prep/(version+'-source.tar'),'r') as archive:
            members={m.name:m for m in archive.getmembers() if m.isfile()}
            for name in hashes:
                rel=name.replace('\\','/');blob=archive.extractfile(members[rel]).read()
                commit=BASE if version=='baseline' else CAND
                actual=subprocess.check_output(['git','-C',str(candidate),'show',commit+':'+rel],timeout=10)
                assert actual.replace(b'\r\n',b'\n')==blob.replace(b'\r\n',b'\n'),'Original source archive differs from normalized pinned Git blob: '+version+' '+rel
                build=(prep/(version+'-source')/name).read_bytes()
                assert build==blob.replace(b'\r\n',b'\n') if rel in ['Makefile','scripts/smoke_test.sh'] else build==blob,'Build export normalization mismatch'
    for name,digest in original['support'].items():
        p=helper if name=='windows_cpu_window.py' else record/name
        assert sha(p)==digest,'Original support changed: '+name;identities[str(p)]=digest
    for name,digest in original['runtime_hashes'].items():
        p=runtime/'bin'/name;assert sha(p)==digest,'Original runtime changed: '+name;identities[str(p)]=digest
    for rel,digest in original['input_hashes'].items():
        p=package/rel;assert sha(p)==digest,'Original input changed: '+rel;identities[str(p)]=digest
    hosted_dir=record/'raw/hosted-247bc11'
    hosted_pins={"AUDIT.json":"a62dbb231047a1887f3ccf528c4300facff830653642cab77efcf6b317f1e460","identity.json":"1096341c9dbaf5dd262b8a07c76eb2150617b9b9a8bcb732e8ebd9ec9e85fae3","result.json":"8b80a8d72c0b52bf38bb0e097e97b75b242b69f48977bf8c53d9e7922f7e27c2","artifact.zip":"dcf00f22b1e9d38fae41ac431769d1c206cc8fc9aa526ad8355db5797293354d"}
    for name,digest in hosted_pins.items():
        p=hosted_dir/name;assert sha(p)==digest,'Hosted evidence changed: '+name;identities[str(p)]=digest
    audit=json.loads((hosted_dir/'AUDIT.json').read_text())
    assert audit['status']=='PASS' and audit['production']==CAND and audit['source_tree_byte_equal'] is True and audit['correct_final_solves']==8
    hosted=json.loads((hosted_dir/'identity.json').read_text())
    assert hosted['candidate']=='247bc11d4191e36466f2203f0236da102d27ff0d' and hosted['production']=='f8f379d' and hosted['baseline']==BASE
    assert sha(hosted_dir/'artifact.zip')==hosted['zip_sha256']
    hosted_result=json.loads((hosted_dir/'result.json').read_text())
    assert hosted_result['scientific_semantics_match'] is True and len(hosted_result['rows'])==4
    for row in hosted_result['rows']:
        assert row['same_semantics'] is True
        exact=int(row['stem'].rsplit('_',1)[1])
        for version in ['baseline','candidate']:
            r=row[version];assert r['returncode']==0 and not r['timed_out']
            assert all(r[k]==exact for k in ['d_lb','d_ub','d','objective'])
    for name in ['windows_tier1.py','TIER1_PRERECORD.md','tier1-input-sha256.json']:
        p=record/name;blob=subprocess.check_output(['git','-C',str(candidate),'show',support_head+':optimization/experiments/GH-36/'+name],timeout=10)
        assert p.read_bytes().replace(b'\r\n',b'\n')==blob.replace(b'\r\n',b'\n'),'Uncommitted Tier1 support '+name
        identities[str(p)]=sha(p)
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
    spec=importlib.util.spec_from_file_location('gh36_numeric_filter',parser);gates=importlib.util.module_from_spec(spec);spec.loader.exec_module(gates)
    assert gates.CASES1==CASES and gates.MODES==MODES
    save(out/'preexecution.json',dict(baseline=BASE,candidate=CAND,record_head=head,assignment=args.run_assignment,
        driver_sha256=sha(__file__),helper_sha256=sha(helper),parser_sha256=sha(parser),binary_hashes=HASHES,input_hashes=inputs,
        production_preparation_sha256=sha(prep/'preexecution.json'),production_summary_sha256=sha(prep/'summary.json'),original_preparation_pins=preparation_pins,identities=identities,
        hosted_pins=hosted_pins,
        driver_provenance='Executed GH20 Tier1 and corrected GH36 Tier0 bounded Job supervisor/science checker; GH16 AB/BA/AB and E004 immutable numeric filter',
        gh16_reviewed_driver_sha256='5f4064eb7d9ce8fe7bc82dfe3862d1431d7f2d946dced3c1d27976bdf0052c21',
        polling_sec=.05,sampling_sec=2,exclusive_reservation=False,internal_limit=180,watchdog=195,aggregate_watchdog=RUN_LIMIT))
    shutil.copy2(Path(__file__),out/'executed-driver.py')
    os.environ['PATH']=str(runtime/'bin')+os.pathsep+os.environ['PATH']
    os.environ.update(LC_ALL='C',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1')
    window=module.Window(True,0x8000);save(out/'window.json',window.selection)
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
                    assert rc in [0,1],'SCIENCE crash '+label
                    if rc==1:
                        scientific(rc,text,expected,incomplete=True)
                        # Genuine UNKNOWN/timeout is engineering INCONCLUSIVE, no optimum/performance claim.
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
                if not all(cleanup.get(k) is True for k in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored']) or cleanup['final_mask']!=window.original_mask or cleanup['final_priority_class']!=window.original_priority:summary['cleanup_invalid']=True
            except Exception as error:summary.update(restoration_failure=repr(error),cleanup_invalid=True)
    identity_errors=[]
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
