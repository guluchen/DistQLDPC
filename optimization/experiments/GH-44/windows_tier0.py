"""UNASSIGNED GH44 Windows Tier0/ISA provenance. No performance timings or auto queue.
Derived from actual GH22 Tier0 driver SHA256 86587e2cb965ca688c7da01e053ea59c4b548519f76542a1fde083964ff4f723.
Restoration/identity finalization strengthened following reviewed GH20 Tier1.

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
for support_name in ['windows_tier0.py','cpu_isa_gate.cc','abi_probe.cc','cygwin_test_stats_shim.cc','runtime-original.json']:
    support_blob=subprocess.check_output(['git','-C',str(candidate),'show',support_head+':optimization/experiments/GH-44/'+support_name],timeout=10)
    assert (HERE/support_name).read_bytes()==support_blob,'Uncommitted support '+support_name
helper=ROOT/"DistQLDPC/optimization/experiments/E004/windows_cpu_window.py"
assert sha(helper)=='ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2','Reviewed helper changed'
spec=importlib.util.spec_from_file_location("gh17_window",helper)
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
def cygpath(v):
    v=str(v).replace("\\","/")
    if v.startswith("-dump-wcnf="):return "-dump-wcnf="+cygpath(v[len("-dump-wcnf="):])
    return "/cygdrive/"+v[0].lower()+v[2:] if len(v)>2 and v[1]==":" else v

k=module.k
k.QueryInformationJobObject.argtypes=[C.c_void_p,C.c_int,C.c_void_p,C.c_ulong,C.POINTER(C.c_ulong)]
k.QueryInformationJobObject.restype=C.c_int
window=None;current=None;resources=[];descendants=[];command_index=0
RUN_START=time.monotonic()
RUN_LIMIT=2700 # 45-minute aggregate watchdog; no autonomous retries.
identities={}; binaries={}
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
                if label.startswith('abi-run-') and 'loaded_modules' not in command:
                    live=loaded_modules(current.pid)
                    if {'cygwin1.dll','cygstdc++-6.dll','cygz.dll'}.issubset({Path(row['path']).name.lower() for row in live}):command['loaded_modules']=live
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

RUNTIME_DLLS={'cygwin1.dll':'959048d1407074097af021708d87bdf5ac1a8f107ff963c8950cd6dc8f21afaf',
    'cygstdc++-6.dll':'e8677526b0a6fef2a457d4d0e105571e1e350c7ad66c925bd00120cf91410443',
    'cyggcc_s-seh-1.dll':'af178c2cb5d4756ff5c2523433812c43f1ad91c6eea9c381caa5e8396bfdc134',
    'cygz.dll':'b3acfadb0f642c8e94d4b5cb4ee527d068f4b2001508af523444766949d67a80'}

BASE='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CAND='4a820ac5c1910d64930ed26a719af2f046a6a693'
def exported(commit,destination):
    data=subprocess.check_output(['git','-C',str(candidate),'archive',commit,'src','Makefile','scripts/smoke_test.sh'],timeout=20)
    destination.mkdir()
    (out/(destination.name+'.tar')).write_bytes(data)
    with tarfile.open(fileobj=io.BytesIO(data)) as archive:archive.extractall(destination,filter='data')
    for rel in ['Makefile','scripts/smoke_test.sh']:
        p=destination/rel;p.write_bytes(p.read_bytes().replace(b'\r\n',b'\n'))
    return {str(p.relative_to(destination)):sha(p) for p in destination.rglob('*') if p.is_file()}

def scientific(rc,text,exact,timeout=False):
    # Reject malformed fields, every interim bound/objective/d, not only final values.
    values={}
    specs={'lb':(r'^c\s+d_lb:\s*(.*?)\s*$',{'-'}),'ub':(r'^c\s+d_ub:\s*(.*?)\s*$',{'-'}),
           'd':(r'^c\s+d\s*:\s*(.*?)\s*$',{'UNKNOWN'}),'objective':(r'^o\s+(.*?)\s*$',set())}
    for key,(pattern,sentinels) in specs.items():
        raw=re.findall(pattern,text,re.M);nums=[]
        for item in raw:
            if item in sentinels:continue
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
    if timeout:
        assert rc==1 and unknown and timed,'SCIENCE timeout status/return'
        assert statuses==['UNKNOWN'] and len(comments)==1 and comments[0].startswith('TIMEOUT'),'SCIENCE changed timeout output semantics'
        assert values['d'] is None and values['objective'] is None,'SCIENCE timeout reported optimum'
        assert not re.search(r'^o\b',text,re.M),'SCIENCE timeout objective'
    else:
        assert rc==0 and not unknown and not timed,'SCIENCE complete return/status'
        assert not statuses and not comments,'SCIENCE unexpected completed status'
        assert all(value==exact for value in values.values()),'SCIENCE malformed/incomplete final '+repr(values)
    return dict(values,unknown=unknown,timeout=timed,returncode=rc)

def check_run(argv,label,cwd,limit=20,exact=None,timeout=False,allow_rc=False):
    result=managed_run(argv,cwd,out,label,limit,True)
    if exact is not None:science.append(dict(label=label,result=scientific(result[0],result[1],exact,timeout)));save(out/'science.json',science)
    elif not allow_rc:
        if 'trace' in label:
            if result[0]==2 and result[2].startswith('FAIL:'):
                raise RuntimeError('FIXTURE_ENGINEERING_REVIEW: actual fixture failed '+label+': '+result[2])
            assert result[0]==0,'SCIENCE actual fixture crash/non-oracle failure '+label+': '+result[2]
        if result[0]!=0:raise RuntimeError('BUILD/TEST command failed '+label+': '+result[2][-2000:])
    return result

def pe_properties(path):
    data=Path(path).read_bytes();offset=struct.unpack_from('<I',data,0x3c)[0]
    assert data[offset:offset+4]==b'PE\0\0'
    count=struct.unpack_from('<H',data,offset+6)[0];size=struct.unpack_from('<H',data,offset+20)[0]
    optional=offset+24;assert struct.unpack_from('<H',data,optional)[0]==0x20b
    manifest=None
    for index in range(count):
        row=optional+size+index*40
        if data[row:row+8].rstrip(b'\0')!=b'.rsrc':continue
        length,start=struct.unpack_from('<II',data,row+16);section=data[start:start+length]
        begin=section.find(b'<?xml');end=section.find(b'</assembly>',begin)
        if begin>=0 and end>begin:manifest=section[begin:end+len(b'</assembly>')]
    assert manifest is not None,'Original GNU default manifest missing'
    return dict(machine=struct.unpack_from('<H',data,offset+4)[0],
        dll_characteristics=struct.unpack_from('<H',data,optional+70)[0],
        subsystem=struct.unpack_from('<H',data,optional+68)[0],
        manifest_sha256=hashlib.sha256(manifest).hexdigest(),manifest_xml=manifest.decode())

def loaded_modules(pid):
    ps=C.WinDLL('psapi',use_last_error=True)
    k.OpenProcess.argtypes=[C.c_ulong,C.c_int,C.c_ulong];k.OpenProcess.restype=C.c_void_p
    ps.EnumProcessModulesEx.argtypes=[C.c_void_p,C.c_void_p,C.c_ulong,C.POINTER(C.c_ulong),C.c_ulong];ps.EnumProcessModulesEx.restype=C.c_int
    ps.GetModuleFileNameExW.argtypes=[C.c_void_p,C.c_void_p,C.c_wchar_p,C.c_ulong];ps.GetModuleFileNameExW.restype=C.c_ulong
    handle=k.OpenProcess(0x410,False,pid)
    if not handle:return []
    try:
        buf=(C.c_void_p*4096)();needed=C.c_ulong()
        if not ps.EnumProcessModulesEx(handle,buf,C.sizeof(buf),C.byref(needed),3):return []
        assert 0<needed.value<=C.sizeof(buf) and needed.value%C.sizeof(C.c_void_p)==0,'Truncated module inventory'
        rows=[]
        for ptr in buf[:needed.value//C.sizeof(C.c_void_p)]:
            name=C.create_unicode_buffer(32768)
            n=ps.GetModuleFileNameExW(handle,ptr,name,len(name))
            assert 0<n<len(name),'Truncated DLL path'
            p=Path(name.value).resolve()
            if p.name.lower().startswith('cyg'):
                assert p.is_relative_to(runtime),'Scientific DLL outside original runtime'
                rel=p.relative_to(runtime).as_posix()
                assert sha(p)==runtime_manifest[rel],'Scientific DLL replaced'
                rows.append(dict(path=str(p),sha256=sha(p)))
        return rows
    finally:k.CloseHandle(handle)

science=[]
try:
    assert out.parent==ROOT and out.is_relative_to(ROOT),'Output must be fresh direct workspace child'
    head=subprocess.check_output(['git','-C',str(candidate),'rev-parse','HEAD'],text=True,timeout=10).strip()
    assert head==support_head
    assert not subprocess.check_output(['git','-C',str(candidate),'diff',CAND,head,'--','src','Makefile'],timeout=10),'Pinned production changed'
    assert not subprocess.check_output(['git','-C',str(candidate),'diff',BASE,CAND,'--','src'],timeout=10),'Production source differs'
    manifest=json.loads((package/'manifest.json').read_text(encoding='utf8'));assert manifest['baseline']==BASE
    data_root=base/'data/matrices';inputs={}
    for stem in ['LP_34_20_2','LP_136_32_4','LP_340_56_8']:
        for suffix in ['Hx','Hz','Gx','Gz']:
            p=data_root/(stem+'_'+suffix+'.txt');rel=p.relative_to(package).as_posix()
            assert sha(p)==manifest['files'][rel],rel;inputs[rel]=sha(p);identities[str(p)]=sha(p)
    sources={v:out/(v+'-source') for v in ['baseline','candidate']}
    source_hashes={v:exported(commit,sources[v]) for v,commit in [('baseline',BASE),('candidate',CAND)]}
    for v,source in sources.items():
        for rel,digest in source_hashes[v].items():identities[str(source/rel)]=digest
        p=source/'data/matrices';p.mkdir(parents=True)
        for suffix in ['Hx','Hz','Gx','Gz']:shutil.copy2(data_root/('LP_34_20_2_'+suffix+'.txt'),p)
    runtime_manifest=json.loads((HERE/'runtime-original.json').read_text(encoding='utf8'))
    assert len(runtime_manifest)==10216,'Original runtime manifest scope'
    assert {p.relative_to(runtime).as_posix() for p in runtime.rglob('*') if p.is_file()}==set(runtime_manifest),'Original runtime file set changed'
    for rel,digest in runtime_manifest.items():
        p=runtime/rel;assert sha(p)==digest,'Original runtime changed '+rel;identities[str(p)]=digest
    support=[Path(__file__),HERE/'cpu_isa_gate.cc',HERE/'abi_probe.cc',HERE/'cygwin_test_stats_shim.cc',HERE/'runtime-original.json',helper]
    for p in support:identities[str(p)]=sha(p)
    save(out/'preexecution.json',dict(assignment=args.run_assignment,baseline=BASE,production_candidate=CAND,record_head=head,
        driver_sha256=sha(__file__),helper_sha256=sha(helper),support={p.name:sha(p) for p in support},source_hashes=source_hashes,
        input_hashes=inputs,identities=identities,aggregate_watchdog=RUN_LIMIT,exclusive_reservation=False,
        semantics='Only Make/smoke CRLF normalized symmetrically; original Git source bytes; no bit-identical rebuild claim'))
    shutil.copy2(Path(__file__),out/'executed-driver.py')
    os.environ['PATH']=str(runtime/'bin')+os.pathsep+os.environ['PATH']
    os.environ.update(LC_ALL='C',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1')
    assert not any(os.environ.get(key) for key in ['MAKEFLAGS','CXX','CXXFLAGS','LDFLAGS']),'Unrecorded build override'
    window=module.Window(True,0x8000);save(out/'window.json',window.selection)
    compiler=runtime/'bin/g++.exe'
    original_flags=['-Isrc/solver','-Wall','-Wno-parentheses','-O3','-g','-D__STDC_LIMIT_MACROS','-D__STDC_FORMAT_MACROS','-DNDEBUG']
    version_flags={'baseline':original_flags,'candidate':original_flags+['-march=x86-64-v3']}
    result=check_run([compiler,'--version'],'compiler-version',candidate);assert '14.4.0' in result[1],'Compiler version drift'
    gate=out/'portable-isa-gate.exe'
    check_run([compiler,*original_flags,HERE/'cpu_isa_gate.cc','-o',gate],'portable-isa-gate-build',sources['baseline'],60)
    rc,text,err=check_run([gate],'portable-isa-gate-run',sources['baseline'],10,allow_rc=True)
    if rc!=0:raise RuntimeError('ISA compatibility not established: '+text+err)
    gate_result=json.loads(text);assert gate_result['compatible'] is True,'ISA compatibility not established'
    save(out/'isa-gate.json',dict(cpu=window.selection['selected_cpu'],mask=window.mask,cpuid=gate_result))
    identities[str(gate)]=sha(gate)
    empty=out/'empty-target.cc';empty.write_text('int provenance_marker;\n',encoding='utf8')
    options={};optimizers={};macros={};abi={}
    for version,flags in version_flags.items():
        rc,options[version],err=check_run([compiler,*flags,'-Q','--help=target','-c',empty,'-o',out/(version+'-target.o')],version+'-target',sources[version],30)
        rc,optimizers[version],err=check_run([compiler,*flags,'-Q','--help=optimizers','-c',empty,'-o',out/(version+'-optimizer.o')],version+'-optimizers',sources[version],30)
        rc,macros[version],err=check_run([compiler,*flags,'-dM','-E','-x','c++',empty],version+'-macros',sources[version],30)
        check_run([compiler,*flags,'-###','-c',empty,'-o',out/(version+'-trace-only.o')],version+'-driver-trace',sources[version],30)
        assert re.search(r'-mtune=\s+generic\b',options[version]),'Unexpected original/default scheduling'
        assert re.search(r'-march=\s+'+('x86-64' if version=='baseline' else 'x86-64-v3')+r'\s',options[version]),'Unexpected ISA expansion'
        assert '#define __cplusplus 201703L' in macros[version],'Language default drift'
        probe=out/(version+'-abi-probe.exe')
        check_run([compiler,*flags,HERE/'abi_probe.cc','-lz','-o',probe],'abi-build-'+version,sources[version],60)
        rc,abi[version],err=check_run([probe],'abi-run-'+version,sources[version],10)
        live=json.loads((out/('abi-run-'+version+'.command.json')).read_text(encoding='utf8')).get('loaded_modules',[])
        assert {'cygwin1.dll','cygstdc++-6.dll','cygz.dll'}.issubset({Path(row['path']).name.lower() for row in live}),'Missing actual scientific linkage proof'
        identities[str(probe)]=sha(probe)
    assert abi['baseline']==abi['candidate'],'ABI/library probe mismatch'
    fp=lambda text:re.findall(r'^\s*(-ffp-contract=\S*|-f(?:fast-math|finite-math-only|unsafe-math-optimizations|rounding-math|signed-zeros|associative-math|reciprocal-math|excess-precision=\S*))\s+(.*?)\s*$',text,re.M)
    assert any(key.startswith('-ffp-contract=') for key,value in fp(optimizers['baseline'])),'FP contraction policy missing'
    assert fp(optimizers['baseline'])==fp(optimizers['candidate']),'FP policy differs'
    save(out/'target-provenance.json',dict(abi=abi,FPpolicy=fp(optimizers['baseline']),cpu=gate_result,original_generic_tuning=True,one_isa_change=True))
    for version,source in sources.items():
        check_run([runtime/'bin/make.exe','-j1','bin/distqldpc'],'build-'+version,source,300)
        binaries[version]=source/'bin/distqldpc.exe';identities[str(binaries[version])]=sha(binaries[version])
    save(out/'binary-hashes.json',{v:sha(p) for v,p in binaries.items()})
    props={v:pe_properties(p) for v,p in binaries.items()};assert props['baseline']==props['candidate'],'GNU PE security/default manifest changed'
    save(out/'production-pe.json',props)
    for version,source in sources.items():
        check_run([runtime/'bin/size.exe',binaries[version]],version+'-production-size',source,20)
        rc,symbols,err=check_run([runtime/'bin/nm.exe','-C',binaries[version]],version+'-production-symbols',source,30)
        assert 'gh44_' not in symbols,'Hook in production'
    def span(rows):
        values={0}
        for row in rows:values|={x^row for x in values}
        return values
    for stem,n,hx,hz,gx,gz in [('css1',1,[0],[0],[1],[1]),('css4',4,[15],[15],[3,5],[3,5]),('css5',5,[3],[3],[12,24,28],[12,24,28])]:
        exact=min((x|z).bit_count() for x,z in itertools.product(range(1<<n),repeat=2) if all((h&z).bit_count()%2==0 for h in hx) and all((h&x).bit_count()%2==0 for h in hz) and (x not in span(hx) or z not in span(hz)))
        for suffix,rows in zip(['Hx','Hz','Gx','Gz'],[hx,hz,gx,gz]):
            (out/(stem+'_'+suffix+'.txt')).write_text(''.join(' '.join(str((r>>i)&1) for i in range(n))+'\n' for r in rows),encoding='utf8')
        for mode in ['no-card','card-sinz','card-mto','card-both-force',None]:
            dumps=[]
            for version,binary in binaries.items():
                label=stem+'-'+(mode or 'default')+'-'+version
                check_run([binary,'-v','-cpu-lim=5',*(['-'+mode] if mode else []),out/stem],label,sources[version],20,exact=exact)
                wcnf=out/(label+'.wcnf')
                check_run([binary,*(['-'+mode] if mode else []),'-dump-only','-dump-wcnf='+str(wcnf),out/stem],label+'-dump',sources[version])
                dumps.append(wcnf.read_bytes())
            assert dumps[0]==dumps[1],'SCIENCE original WCNF changed'
            complete_traces=[(out/(stem+'-'+(mode or 'default')+'-'+version+'.stdout')).read_bytes() for version in sources]
            save(out/(stem+'-'+(mode or 'default')+'-trace-equality.json'),dict(identical=complete_traces[0]==complete_traces[1],diagnostic_only=True))
    for version,binary in binaries.items():
        check_run([runtime/'bin/bash.exe',sources[version]/'scripts/smoke_test.sh',binary],'smoke-'+version,sources[version],20)
        for mode in ['no-card','card-mto']:
            check_run([binary,'-'+mode,'-cpu-lim=1',data_root/'LP_340_56_8'],'timeout-'+version+'-'+mode,sources[version],20,exact=8,timeout=True)
    # Four fixed original-input production trace comparisons, not timings.
    for stem,exact in [('LP_34_20_2',2),('LP_136_32_4',4)]:
        for mode in ['no-card','card-mto']:
            traces=[]
            for version,binary in binaries.items():
                label='production-trace-'+stem+'-'+mode+'-'+version
                check_run([binary,'-v','-cpu-lim=120','-'+mode,data_root/stem],label,sources[version],135,exact=exact)
                traces.append((out/(label+'.stdout')).read_bytes())
            save(out/(stem+'-'+mode+'-trace-equality.json'),dict(identical=traces[0]==traces[1],diagnostic_only=True))
    # Test-only standalone Main link. No shim in production DistQLDPC.
    standalone={}
    for version,source in sources.items():
        binary=out/(version+'-standalone-test.exe');standalone[version]=binary
        objects=[source/'build'/(n+'.o') for n in ['SimpSolver','Solver','Options','System']]
        check_run([runtime/'bin/g++.exe',*version_flags[version],source/'src/solver/Main.cc',
            HERE/'cygwin_test_stats_shim.cc',*objects,'-lz','-o',binary],version+'-standalone-test-build',source,120)
    def satisfies(clause,assignment):
        return any(bool(assignment&(1<<(abs(lit)-1)))==(lit>0) for lit in clause)
    cases=[('pms-zero',2,[[-1,2]],[[1],[2]]),
        ('pms-conflict',2,[[-1,-2]],[[1],[2]]),
        ('pms-triangle',3,[[-1,-2],[-1,-3],[-2,-3]],[[1],[2],[3]]),
        ('pms-cycle',4,[[-1,-2],[-2,-3],[-3,-4],[-4,-1]],[[1],[2],[3],[4]])]
    import random
    rng=random.Random(20261008)
    for index in range(32):
        n=4+index%3;planted=rng.randrange(1<<n);hard=[]
        for j in range(4+index%9):
            variables=rng.sample(range(1,n+1),1+rng.randrange(3))
            clause=[v if rng.getrandbits(1) else -v for v in variables]
            if not satisfies(clause,planted):clause[0]=-clause[0]
            hard.append(clause)
        cases.append(('pms-seed-%02d'%index,n,hard,[[v] for v in range(1,n+1)]))
    oracle=[]
    for stem,n,hard,soft in cases:
        exact=min(sum(not satisfies(c,a) for c in soft) for a in range(1<<n)
                  if all(satisfies(c,a) for c in hard))
        top=len(soft)+1;wcnf=out/(stem+'.wcnf')
        wcnf.write_text('p wcnf %d %d %d\n'%(n,len(hard)+len(soft),top)+
            ''.join(str(weight)+' '+' '.join(map(str,c))+' 0\n'
                    for weight,clauses in [(top,hard),(1,soft)] for c in clauses),encoding='utf8')
        checked=[]
        for version,binary in standalone.items():
            rc,text,error=check_run([binary,'-verb=1',wcnf],stem+'-'+version,sources[version],20,allow_rc=True)
            values=re.findall(r'optimal:\s*([^,\r\n]*)',text)
            assert rc in (10,20) and values and all(re.fullmatch(r'\d+',v) and int(v)==exact for v in values),'SCIENCE exact PMS mismatch '+stem+' '+version
            statuses=re.findall(r'^s\s+(.*?)\s*$',text,re.M)
            assert statuses==(['SATISFIABLE'] if rc==10 else ['UNSATISFIABLE']),'SCIENCE standalone status/exit mismatch'
            checked.append((rc,statuses,int(values[-1])))
        assert checked[0]==checked[1],'SCIENCE standalone result/exit semantics mismatch '+stem
        oracle.append(dict(stem=stem,variables=n,oracle=exact,scientific_results=checked,input_sha256=sha(wcnf)))
        save(out/'pms-oracle.json',oracle)
    for binary in standalone.values():identities[str(binary)]=sha(binary)
    save(out/'standalone-test-hashes.json',{v:sha(p) for v,p in standalone.items()})
    for version,source in sources.items():
        original=(source/'src/solver/Solver.cc').read_bytes()
        for phase in ['pre-search','post-model']:
            if phase=='pre-search':
                assert original.count(b'emitTryUpdate(UB);')==1
                body=original.replace(b'emitTryUpdate(UB);',b'emitTryUpdate(UB); ::sleep(3);')
            else:
                begin=original.index(b'void Solver::noteBestSolution(')
                end=original.index(b'void Solver::printBestSolution()',begin)
                section=original[begin:end]
                assert section.count(b'emitBoundsUpdate();')==1
                section=section.replace(b'emitBoundsUpdate();',b'emitBoundsUpdate(); ::sleep(3);')
                body=original[:begin]+section+original[end:]
            tag=version+'-'+phase
            hooked=out/(tag+'-test-only-Solver.cc')
            hooked.write_bytes(b'#include <unistd.h>\n'+body)
            obj=out/(tag+'-test-only-Solver.o')
            flags=version_flags[version]
            check_run([runtime/'bin/g++.exe',*flags,'-c',hooked,'-o',obj],tag+'-hook-build',source,120)
            binary=out/(tag+'-test-only.exe')
            other=[source/'build'/(name+'.o') for name in ['SimpSolver','Options','System']]
            check_run([runtime/'bin/g++.exe',*flags,source/'src/core/distqldpc.cc',obj,*other,'-lz','-o',binary],tag+'-app-build',source,120)
            for mode in ['no-card','card-mto']:
                label=tag+'-timeout-'+mode
                rc,text,error=check_run([binary,'-v','-'+mode,'-cpu-lim=1',out/'css4'],label,source,20,exact=2,timeout=True)
                found=re.findall(r'^c\s+d_ub:\s*(\d+)\s*$',text,re.M)
                assert bool(found)==(phase=='post-model'),'SCIENCE forced model-tracking phase mismatch'
                assert not re.search(r'^o(?:\s|$)',text,re.M),'SCIENCE timeout objective fabricated'
            save(out/(tag+'-hook-hashes.json'),dict(source=sha(hooked),object=sha(obj),binary=sha(binary),production_engine_untouched=True))
            for retained in [hooked,obj,binary]:identities[str(retained)]=sha(retained)
    summary.update(Tier0='LOCAL_PASS',hosted='REQUIRED_SEPARATELY',Tier0_complete=False);save(out/'summary.json',summary)
    assert len(science)==50,'Test coverage incomplete'
    summary.update(status='PREPARATORY_COMPLETE',Tier0='LOCAL_PASS',diagnostic='NOT_RUN',performance='NOT_MEASURED')
except BaseException as error:
    summary['reason']=repr(error)
    if isinstance(error,AssertionError) and ('SCIENCE' in str(error) or 'TEST' in str(error)):
        summary.update(status='REJECTED',Tier0='REJECTED',scientific_rejected=True)
    print('STOP: '+repr(error),flush=True)
finally:
    if window is not None:
        try:
            clean_owned('final-cleanup');save(out/'job-pids-before-release.json',job_pids())
        except Exception as error:summary.update(cleanup_failure=repr(error),cleanup_invalid=True)
        finally:
            try:
                cleanup=window.close();save(out/'cleanup.json',cleanup);summary['cleanup']=cleanup
                if not all(cleanup.get(k) is True for k in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored']):summary['cleanup_invalid']=True
            except Exception as error:summary.update(restoration_failure=repr(error),cleanup_invalid=True)
    identity_errors=[]
    for path,digest in identities.items():
        try:
            if sha(path)!=digest:identity_errors.append(path+' changed')
        except Exception as error:identity_errors.append(path+': '+repr(error))
    if identity_errors:summary['identity_invalid']=identity_errors
    summary['valid_run']=bool(summary.get('status')=='PREPARATORY_COMPLETE' and window is not None and not summary.get('cleanup_invalid') and not summary.get('identity_invalid'))
    if not summary['valid_run'] and not summary.get('scientific_rejected'):summary['status']='INCONCLUSIVE'
    save(out/'summary.json',summary)
    try:
        save(out/'SHA256.json',{str(p.relative_to(out)):sha(p) for p in sorted(out.rglob('*')) if p.is_file() and p.name!='SHA256.json'})
    except Exception as error:
        summary.update(manifest_failure=repr(error),valid_run=False);save(out/'summary.json',summary)
    print(json.dumps(summary,indent=2),flush=True)
sys.exit(0 if summary['valid_run'] else 1)
