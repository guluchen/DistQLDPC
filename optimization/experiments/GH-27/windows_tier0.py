"""Assigned GH27 Windows Tier0/counters. No performance timings or auto queue.
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
args=ap.parse_args()
ASSIGNED_URL="https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6065364988"
assert ASSIGNED_URL!="HOST_SLOT_NOT_ASSIGNED", "Preparation only: no host slot"
assert args.run_assignment==ASSIGNED_URL
out=args.out.resolve();out.mkdir(parents=True,exist_ok=False)
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(path,value):Path(path).write_text(json.dumps(value,indent=2),encoding="utf-8",newline="\n")
runtime=ROOT/"E004-windows-runtime/cygwin"
package=ROOT/"E004-windows-tier2-02/E004-server-package"
base=package/"baseline"
candidate=ROOT/"GH27-ENQUEUE"
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
             candidate="58fbae546e74c158c21070cd10106e94d6bd2b98",assignment=args.run_assignment)

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
CAND='58fbae546e74c158c21070cd10106e94d6bd2b98'
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
            assert result[0]==0,'SCIENCE production fixture failed '+label+': '+result[2]
        if result[0]!=0:raise RuntimeError('BUILD/TEST command failed '+label+': '+result[2][-2000:])
    return result

science=[]
try:
    assert out.is_relative_to(ROOT) and out.parent==ROOT,'Output must be fresh direct workspace child'
    head=subprocess.check_output(['git','-C',str(candidate),'rev-parse','HEAD'],text=True,timeout=10).strip()
    source_diff=subprocess.check_output(['git','-C',str(candidate),'diff',CAND,head,'--','src','Makefile'],timeout=10)
    assert not source_diff,'Pinned production source changed'
    manifest=json.loads((package/'manifest.json').read_text(encoding='utf8'))
    assert manifest['baseline']==BASE
    data_root=base/'data/matrices'
    inputs={}
    for stem in ['LP_34_20_2','LP_136_32_4','LP_340_56_8']:
        for suffix in ['Hx','Hz','Gx','Gz']:
            p=data_root/(stem+'_'+suffix+'.txt');rel=str(p.relative_to(package)).replace('\\','/')
            assert sha(p)==manifest['files'][rel],rel;inputs[rel]=sha(p)
    sources={v:out/(v+'-source') for v in ['baseline','candidate']}
    source_hashes={v:exported(commit,sources[v]) for v,commit in [('baseline',BASE),('candidate',CAND)]}
    for source in sources.values():
        destination=source/'data/matrices';destination.mkdir(parents=True)
        for suffix in ['Hx','Hz','Gx','Gz']:shutil.copy2(data_root/('LP_34_20_2_'+suffix+'.txt'),destination)
    diagnostic=out/'diagnostic-source';exported(BASE,diagnostic)
    solver=diagnostic/'src/solver/Solver.cc';core=diagnostic/'src/core/distqldpc.cc'
    s=solver.read_bytes();newline=b'\r\n' if b'\r\n' in s else b'\n'
    anchor=b'#include "Solver.h"';assert s.count(anchor)==1
    s=s.replace(anchor,anchor+newline+b'#define GH27_ENQUEUE_IMPLEMENTATION'+newline+b'#include "GH27EnqueueDiagnostic.h"',1)
    start=s.index(b'bool Solver::uncheckedEnqueueForLK(');end=s.index(b'CRef Solver::propagateForLK()',start)
    method=s[start:end]
    anchor=b'    assert(value(p) == l_Undef);';assert method.count(anchor)==1
    method=method.replace(anchor,anchor+newline+b'    gh27_enqueue_event(0);',1)
    anchor=b'if (auxiVar(v) && value(softLits[v]) == l_False) {// a soft clause is falsified';assert method.count(anchor)==1
    method=method.replace(anchor,anchor+newline+b'      gh27_enqueue_event(1);',1)
    anchor=b'return false;';assert method.count(anchor)==1
    method=method.replace(anchor,b'return (gh27_enqueue_event(2), false);',1)
    anchor=b'int iset = getLockedVarIsetForLK(v);';assert method.count(anchor)==1
    method=method.replace(anchor,b'gh27_enqueue_event(3);'+newline+b'\t'+anchor,1)
    solver.write_bytes(s[:start]+method+s[end:])
    s=core.read_bytes();newline=b'\r\n' if b'\r\n' in s else b'\n'
    anchor=b'#include "SimpSolver.h"';assert s.count(anchor)==1
    s=s.replace(anchor,anchor+newline+b'#include "GH27EnqueueDiagnostic.h"',1)
    anchor=b'        _exit(d >= 0 ? 0 : 1);';assert s.count(anchor)==1
    s=s.replace(anchor,b'        gh27_enqueue_dump();'+newline+anchor)
    core.write_bytes(s);shutil.copy2(HERE/'enqueue_diagnostic.h',diagnostic/'src/solver/GH27EnqueueDiagnostic.h')
    support=[Path(__file__),HERE/'test_enqueue_prefix.cc',HERE/'test_watch_tail.cc',HERE/'test_watch_tail_gc.cc',HERE/'enqueue_diagnostic.h',HERE/'cygwin_test_stats_shim.cc',helper]
    for p in support:identities[str(p)]=sha(p)
    for name,digest in RUNTIME_DLLS.items():
        p=runtime/'bin'/name;assert sha(p)==digest,name;identities[str(p)]=digest
    for name in ['g++.exe','make.exe','objdump.exe','nm.exe','size.exe','bash.exe']:
        p=runtime/'bin'/name;identities[str(p)]=sha(p)
    for rel,digest in inputs.items():identities[str(package/rel)]=digest
    for version,source in sources.items():
        for rel,digest in source_hashes[version].items():identities[str(source/rel)]=digest
        for p in (source/'src').rglob('*'):
            if p.is_file():assert b'gh27_enqueue_event' not in p.read_bytes() and b'gh27_enqueue_dump' not in p.read_bytes(),'Diagnostic hook in production source'
    for p in diagnostic.rglob('*'):
        if p.is_file():identities[str(p)]=sha(p)
    save(out/'preexecution.json',dict(assignment=args.run_assignment,production_candidate=CAND,record_head=head,baseline=BASE,
        support={p.name:sha(p) for p in support},input_hashes=inputs,source_hashes=source_hashes,
        diagnostic_source_hashes={str(p.relative_to(diagnostic)):sha(p) for p in diagnostic.rglob('*') if p.is_file()},
        identities=identities,aggregate_watchdog_sec=RUN_LIMIT,exclusive_reservation=False,
        semantics='Makefile/smoke CRLF normalized for Cygwin shell; source otherwise Git-blob bytes; no bit-identical rebuild claim'))
    shutil.copy2(Path(__file__),out/'executed-driver.py')
    os.environ['PATH']=str(runtime/'bin')+os.pathsep+os.environ['PATH']
    os.environ.update(LC_ALL='C',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1')
    assert not any(os.environ.get(key) for key in ['MAKEFLAGS','CXX','CXXFLAGS','LDFLAGS']), 'Unrecorded build override'
    window=module.Window(True,0x8000);save(out/'window.json',window.selection)
    window.previous=module.ticks();time.sleep(2.1);observe('assignment-preflight')
    check_run([runtime/'bin/g++.exe','--version'],'compiler',candidate)
    binaries={}
    for version,source in sources.items():
        check_run([runtime/'bin/make.exe','-j1','bin/distqldpc'],'build-'+version,source,300)
        binaries[version]=source/'bin/distqldpc.exe'
        release_objects=[source/'build'/(n+'.o') for n in ['Solver','Options','System']]
        debug_solver=out/(version+'-debug-Solver.o')
        check_run([runtime/'bin/g++.exe','-Isrc/solver','-O0','-g','-std=gnu++11','-D__STDC_LIMIT_MACROS','-D__STDC_FORMAT_MACROS','-c',source/'src/solver/Solver.cc','-o',debug_solver],version+'-debug-Solver-build',source,180)
        configurations=[('release',release_objects,'-O3'),('debug',[debug_solver,*release_objects[1:]],'-O0')]
        for configuration,objects,optimization in configurations:
            names=['test_enqueue_prefix.cc'] if configuration=='debug' else ['test_enqueue_prefix.cc','test_watch_tail.cc','test_watch_tail_gc.cc']
            for name in names:
                probe=out/(version+'-'+configuration+'-'+name+'.exe')
                check_run([runtime/'bin/g++.exe','-Isrc/solver',optimization,'-std=gnu++11',HERE/name,*objects,'-lz','-o',probe],version+'-'+configuration+'-'+name+'-build',source,120)
                check_run([probe],version+'-'+configuration+'-'+name+'-trace',source,30)
                identities[str(probe)]=sha(probe)
    for version,binary in binaries.items():identities[str(binary)]=sha(binary)
    save(out/'binary-hashes.json',{v:sha(p) for v,p in binaries.items()})
    for configuration,names in [('release',['test_enqueue_prefix.cc','test_watch_tail.cc','test_watch_tail_gc.cc']),('debug',['test_enqueue_prefix.cc'])]:
        for name in names:
            labels=[v+'-'+configuration+'-'+name+'-trace' for v in sources]
            traces=[(out/(label+'.stdout')).read_bytes() for label in labels]
            assert traces[0]==traces[1],'SCIENCE production method/propagation state mismatch '+name+' '+configuration
            expected=480 if name=='test_enqueue_prefix.cc' else 120
            assert len(re.findall(rb'^case=',traces[0],re.M))==expected,'SCIENCE incomplete fixture coverage'
            assert all((out/(label+'.stderr')).read_bytes()==b'' for label in labels),'SCIENCE fixture stderr'
    assembly=[]
    for version,source in sources.items():
        binary=binaries[version]
        rc,symbols,error=check_run([runtime/'bin/nm.exe','-C',binary],version+'-production-symbols',source,30)
        assert 'gh27_enqueue_' not in symbols,'SCIENCE diagnostic hook in production binary'
        for function in ['Minisat::Solver::propagateForLK()','Minisat::Solver::uncheckedEnqueueForLK(Minisat::Lit, unsigned int)','Minisat::Solver::handleSoftViolationForLK(int)']:
            label=version+'-assembly-'+str(len(assembly))
            rc,instructions,error=check_run([runtime/'bin/objdump.exe','-d','-C','--disassemble='+function,binary],label,source,30)
            if function.endswith('propagateForLK()'):assert len(instructions)>1000 and 'propagateForLK()>' in instructions,'Assembly extraction incomplete'
            assembly.append(dict(version=version,function=function,label=label,output_sha256=sha(out/(label+'.stdout'))))
        check_run([runtime/'bin/size.exe',binary],version+'-production-size',source,30)
    save(out/'assembly.json',assembly) # Actual code only; no automatic speedup inference.
    def span(rows):
        values={0}
        for row in rows:values|={x^row for x in values}
        return values
    for stem,n,hx,hz,gx,gz in [('css1',1,[0],[0],[1],[1]),('css4',4,[15],[15],[3,5],[3,5]),('css5',5,[3],[3],[12,24,28],[12,24,28])]:
        exact=min((x|z).bit_count() for x,z in itertools.product(range(1<<n),repeat=2) if all((h&z).bit_count()%2==0 for h in hx) and all((h&x).bit_count()%2==0 for h in hz) and (x not in span(hx) or z not in span(hz)))
        for suffix,rows in zip(['Hx','Hz','Gx','Gz'],[hx,hz,gx,gz]):
            (out/(stem+'_'+suffix+'.txt')).write_text(''.join(' '.join(str((r>>i)&1) for i in range(n))+'\n' for r in rows),encoding='utf8')
        for mode in ['no-card','card-mto']:
            dumps=[]
            for version,binary in binaries.items():
                label=stem+'-'+mode+'-'+version
                check_run([binary,'-v','-cpu-lim=5','-'+mode,out/stem],label,sources[version],20,exact=exact)
                wcnf=out/(label+'.wcnf')
                check_run([binary,'-'+mode,'-dump-only','-dump-wcnf='+str(wcnf),out/stem],label+'-dump',sources[version])
                dumps.append(wcnf.read_bytes())
            assert dumps[0]==dumps[1],'SCIENCE original WCNF changed'
    for version,binary in binaries.items():
        check_run([runtime/'bin/bash.exe',sources[version]/'scripts/smoke_test.sh',binary],'smoke-'+version,sources[version],20)
        for mode in ['no-card','card-mto']:
            check_run([binary,'-'+mode,'-cpu-lim=1',data_root/'LP_340_56_8'],'timeout-'+version+'-'+mode,sources[version],20,exact=8,timeout=True)
    # Test-only standalone Main link. No shim in production DistQLDPC.
    standalone={}
    for version,source in sources.items():
        binary=out/(version+'-standalone-test.exe');standalone[version]=binary
        objects=[source/'build'/(n+'.o') for n in ['SimpSolver','Solver','Options','System']]
        check_run([runtime/'bin/g++.exe','-Isrc/solver','-Wall','-Wno-parentheses','-O3','-g',
            '-D__STDC_LIMIT_MACROS','-D__STDC_FORMAT_MACROS','-DNDEBUG',source/'src/solver/Main.cc',
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
    summary.update(Tier0='LOCAL_PASS',hosted='REQUIRED_SEPARATELY',Tier0_complete=False);save(out/'summary.json',summary)
    check_run([runtime/'bin/make.exe','-j1','bin/distqldpc'],'diagnostic-build',diagnostic,300)
    diagnostic_binary=diagnostic/'bin/distqldpc.exe';identities[str(diagnostic_binary)]=sha(diagnostic_binary)
    save(out/'diagnostic-binary-hash.json',{'sha256':sha(diagnostic_binary),'baseline_only':True,'performance':'NOT_MEASURED'})
    opportunity=[]
    for stem,exact in [('LP_34_20_2',2),('LP_136_32_4',4)]:
        for mode in ['no-card','card-mto']:
            label='opportunity-'+stem+'-'+mode
            result=check_run([diagnostic/'bin/distqldpc.exe','-v','-cpu-lim=120','-'+mode,data_root/stem],label,diagnostic,135,exact=exact)
            matches=re.findall(r'^GH27_ENQUEUE (.+)$',result[2],re.M);assert len(matches)==1,'DIAGNOSTIC missing child counts'
            counts=json.loads(matches[0])
            assert set(counts)=={'entries','soft_false','unlocked_false','locked_false'}
            assert all(isinstance(v,int) and v>=0 for v in counts.values())
            assert counts['unlocked_false']+counts['locked_false']==counts['soft_false']<=counts['entries']
            opportunity.append(dict(stem=stem,mode=mode,counts=counts,scientific_expected=exact));save(out/'opportunity.json',opportunity)
    summary.update(status='PREPARATORY_COMPLETE',diagnostic='PASS',opportunity=opportunity,performance='NOT_MEASURED')
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
