"""Assigned GH36 Windows Tier0 only. No performance timings or auto queue.
Derived from executed GH22 supervisor SHA256 86587e2cb965ca688c7da01e053ea59c4b548519f76542a1fde083964ff4f723.

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
candidate=ROOT/"GH36-WITNESS"
support_head=subprocess.check_output(['git','-C',str(candidate),'rev-parse','HEAD'],text=True,timeout=10).strip()
assert support_head==args.support_sha,'Assigned support commit mismatch'
for support_name in ['windows_tier0.py','test_witness.cc','cygwin_test_stats_shim.cc']:
    support_path=HERE/support_name
    support_blob=subprocess.check_output(['git','-C',str(candidate),'show',support_head+':optimization/experiments/GH-36/'+support_name],timeout=10)
    assert support_path.read_bytes().replace(b'\r\n',b'\n')==support_blob.replace(b'\r\n',b'\n'),'Uncommitted support '+support_name
helper=ROOT/"DistQLDPC/optimization/experiments/E004/windows_cpu_window.py"
assert sha(helper)=='ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2','Reviewed helper changed before import'
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
summary=dict(status="INCONCLUSIVE",Tier0="NOT_RUN",diagnostic="NOT_RUN",performance="NOT_MEASURED",
             candidate="f8f379d",assignment=args.run_assignment)

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
        current.wait(timeout=10)
    # This NEW unnamed Job contains only this runner and its children, not other
    # users' jobs. Bounded cleanup handles any already-orphaned owned descendants.
    remaining=[pid for pid in job_pids() if pid!=os.getpid()]
    for pid in remaining:
        result=subprocess.run(["taskkill","/PID",str(pid),"/T","/F"],capture_output=True,text=True,timeout=10)
        records.append(dict(pid=pid,returncode=result.returncode,stdout=result.stdout,stderr=result.stderr))
    deadline=time.monotonic()+5
    while time.monotonic()<deadline and [pid for pid in job_pids() if pid!=os.getpid()]:time.sleep(.1)
    still=[pid for pid in job_pids() if pid!=os.getpid()]
    save(out/("owned-cleanup-"+str(command_index)+".json"),dict(reason=reason,actions=records,
         remaining=still,confirmed=(not still)))
    if still:raise RuntimeError("Owned descendant cleanup unconfirmed: "+repr(still))

def managed_run(argv,cwd,target,label,timeout,cygwin=False):
    timeout=min(timeout,work_deadline-time.monotonic())
    assert timeout>0,'Aggregate Tier0 budget exhausted'
    global current,command_index
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
                if now-start>timeout:raise subprocess.TimeoutExpired(argv,timeout)
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

BASE='24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CAND='f8f379d'
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
    unknown=bool(re.search(r'^s UNKNOWN\s*$',text,re.M))
    timed=bool(re.search(r'^c status: TIMEOUT\b',text,re.M))
    if timeout:
        assert rc==1 and unknown and timed,'SCIENCE timeout status/return'
        assert values['d'] is None and values['objective'] is None,'SCIENCE timeout reported optimum'
        assert not re.search(r'^o\b',text,re.M),'SCIENCE timeout objective'
    else:
        assert rc==0 and not unknown and not timed,'SCIENCE complete return/status'
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
work_deadline=time.monotonic()+2700
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
    runtime_pins={name:sha(runtime/'bin'/name) for name in ['g++.exe','make.exe','objdump.exe','bash.exe','cygwin1.dll','cygstdc++-6.dll','cyggcc_s-seh-1.dll','cygz.dll']}
    assert sha(helper)=='ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2', 'Reviewed helper changed'
    frozen={p.name:sha(p) for p in [Path(__file__),HERE/'test_witness.cc',HERE/'cygwin_test_stats_shim.cc',helper]}
    save(out/'preexecution.json',dict(assignment=args.run_assignment,production_candidate=CAND,record_head=head,baseline=BASE,
        support=frozen,input_hashes=inputs,source_hashes=source_hashes,
        runtime_hashes=runtime_pins,
        semantics='Makefile/smoke CRLF normalized for Cygwin shell; source otherwise Git-blob bytes; no bit-identical rebuild claim'))
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
    # Actual application helper fixture: candidate only, independent full Pauli oracle.
    fixture_source=out/'test_witness.cc'
    fixture_source.write_bytes((HERE/'test_witness.cc').read_bytes().replace(
        b'../../../src/core/distqldpc.cc',cygpath(sources['candidate']/'src/core/distqldpc.cc').encode()))
    probe=out/'candidate-witness-fixture.exe'
    objects=[sources['candidate']/'build'/(n+'.o') for n in ['SimpSolver','Solver','Options','System']]
    check_run([runtime/'bin/g++.exe','-Isrc/solver','-O2','-std=gnu++11',fixture_source,*objects,'-lz','-o',probe],
              'candidate-witness-build',sources['candidate'],120)
    check_run([probe],'candidate-witness-trace',sources['candidate'],30)
    trace=(out/'candidate-witness-trace.stdout').read_bytes()
    assert b'WITNESS_ORACLE_PASS cases=4368 plus_multirow' in trace,'SCIENCE incomplete witness oracle'
    assert not (out/'candidate-witness-trace.stderr').read_bytes(),'SCIENCE witness stderr'
    save(out/'binary-hashes.json',{v:sha(p) for v,p in binaries.items()})
    def span(rows):
        values={0}
        for row in rows:values|={x^row for x in values}
        return values
    for stem,n,hx,hz,gx,gz in [('css1',1,[0],[0],[1],[1]),('css4',4,[15],[15],[3,5],[3,5]),('css5',5,[3],[3],[12,24,28],[12,24,28]),('css-fallback',2,[0],[0],[3],[3])]:
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
            rc,text,error=check_run([binary,'-'+mode,'-cpu-lim=1',data_root/'LP_340_56_8'],'timeout-'+version+'-'+mode,sources[version],20,exact=8,timeout=True)
            assert not re.search(r'^o(?:\s|$)',text,re.M),'SCIENCE timeout objective fabricated'
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
    cases.extend([('pms-root-cap-offset',2,[[-1]],[[1],[2]]),
                  ('pms-root-cap-offset-plus-one',4,[[-1],[-2,-3]],[[1],[2],[3],[4]]),
                  ('pms-empty-soft-offset',3,[[-1,-2]],[[],[1],[2],[3]]),
                  ('pms-tight-positive-residual',6,[[-1,-2,-3,-4,-5,-6]],[[1],[2],[3],[4],[5],[6]])])
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
    tight_positive_residual=[]
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
            values=re.findall(r'optimal:\s*(\d+)',text)
            assert rc in (10,20) and values and all(int(v)==exact for v in values),'SCIENCE exact PMS mismatch '+stem+' '+version
            checked.append((rc,re.findall(r'^s\s+(.+)$',text,re.M),int(values[-1])))
        assert checked[0]==checked[1],'SCIENCE standalone result/exit semantics mismatch '+stem
        oracle.append(dict(stem=stem,variables=n,oracle=exact,scientific_results=checked,input_sha256=sha(wcnf)))
        save(out/'pms-oracle.json',oracle)
        feasible_assignments=[a for a in range(1<<n) if all(satisfies(c,a) for c in hard)]
        witness=min(feasible_assignments,key=lambda a:(sum(not satisfies(c,a) for c in soft),a))
        cap=sum(not satisfies(c,witness) for c in soft)
        assert cap==exact,'SCIENCE invalid test witness'
        provided_results=[]
        for version,binary in standalone.items():
            rc,text,error=check_run([binary,'-verb=1',wcnf,str(cap)],stem+'-'+version+'-provided',sources[version],20,allow_rc=True)
            optimal=re.findall(r'optimal:\s*(\d+)',text)
            statuses=re.findall(r'^s\s+(.*?)\s*$',text,re.M)
            assert rc in (10,20) and optimal and all(int(v)==exact for v in optimal),'SCIENCE provided-bound exact PMS mismatch'
            assert statuses==(['SATISFIABLE'] if rc==10 else ['UNSATISFIABLE']),'SCIENCE provided-bound status mismatch'
            initial=re.findall(r'^c initial UB:\s*(\d+)\s*$',text,re.M)
            accepted=cap if cap>0 else 2147483647 # Original Main CLI ignores zero.
            assert initial==[str(accepted)],'SCIENCE original cap CLI semantics changed'
            provided_results.append((rc,statuses,int(optimal[-1])))
            provided=re.findall(r'^c provided UB:\s*(\d+)\s*$',text,re.M)
            if cap>0 and provided and int(provided[0])>=2 and re.search(r'^c UB=1 fails,',text,re.M):
                tight_positive_residual.append(dict(stem=stem,version=version,verified_cost=cap,exact=exact,
                    strict_providedUB=int(provided[0]),observed_failed_initial_bound=1))
                save(out/'tight-positive-residual-coverage.json',tight_positive_residual)
            save(out/(stem+'-witness.json'),dict(assignment=witness,verified_weight=cap,oracle=exact,original_Main_accepted_initUB=accepted))
        assert provided_results[0]==provided_results[1],'SCIENCE provided-bound engine result mismatch'
        if stem=='pms-root-cap-offset':
            loose_witness=max(feasible_assignments,key=lambda a:sum(not satisfies(c,a) for c in soft))
            loose_cap=sum(not satisfies(c,loose_witness) for c in soft)
            assert loose_cap==2 and cap==1,'Fixed offset witness fixture changed'
            for version,binary in standalone.items():
                rc,text,error=check_run([binary,'-verb=1',wcnf,str(loose_cap)],stem+'-'+version+'-loose',sources[version],20,allow_rc=True)
                optimal=re.findall(r'optimal:\s*(\d+)',text)
                assert rc in (10,20) and optimal and all(int(v)==exact for v in optimal),'SCIENCE offset+1 exact PMS mismatch'
                p=re.findall(r'^c provided UB:\s*(\d+)\s*$',text,re.M)
                if p!=['2']:raise RuntimeError('TEST_COVERAGE: fixed offset+1 normalization not reached as expected')
                first=(out/(stem+'-'+version+'-provided.stdout')).read_text()
                if re.findall(r'^c provided UB:\s*(\d+)\s*$',first,re.M)!=['1']:
                    raise RuntimeError('TEST_COVERAGE: fixed offset normalization not reached as expected')
                save(out/(stem+'-'+version+'-offset-coverage.json'),dict(offset=1,strict_P=[1,2],verified_assignments=[witness,loose_witness],costs=[cap,loose_cap],oracle=exact))
    if set(row['version'] for row in tight_positive_residual)!={'baseline','candidate'}:
        raise RuntimeError('TEST_COVERAGE: tight positive residual cap after failed initial bound was not exercised')
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
            flags=['-Isrc/solver','-Wall','-Wno-parentheses','-O3','-g','-D__STDC_LIMIT_MACROS','-D__STDC_FORMAT_MACROS','-DNDEBUG']
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
    save(out/'standalone-test-hashes.json',{v:sha(p) for v,p in standalone.items()})
    for p in [Path(__file__),HERE/'test_witness.cc',HERE/'cygwin_test_stats_shim.cc',helper]:
        assert sha(p)==frozen[p.name], 'Support identity changed '+p.name
    for name,digest in runtime_pins.items():
        assert sha(runtime/'bin'/name)==digest, 'Runtime identity changed '+name
    for rel,digest in inputs.items():
        assert sha(package/rel)==digest, 'Input identity changed '+rel
    for version,hashes in source_hashes.items():
        for rel,digest in hashes.items():
            assert sha(sources[version]/rel)==digest, 'Exported source identity changed '+version+' '+rel
    frozen_binaries=json.loads((out/'binary-hashes.json').read_text())
    for version,binary in binaries.items():
        assert sha(binary)==frozen_binaries[version], 'Binary identity changed '+version
    save(out/'postexecution-identities.json',dict(support=True,runtime=True,inputs=True))
    summary.update(status='PREPARATORY_COMPLETE',Tier0='LOCAL_PASS',diagnostic='NOT_REQUESTED',performance='NOT_MEASURED')
except BaseException as error:
    summary['reason']=repr(error)
    if isinstance(error,AssertionError) and ('SCIENCE' in str(error) or 'TEST' in str(error)):
        summary.update(status='REJECTED',Tier0='REJECTED',scientific_rejected=True)
    print('STOP: '+repr(error),flush=True)
finally:
    if window is not None:
        try:
            for p in [Path(__file__),HERE/'test_witness.cc',HERE/'cygwin_test_stats_shim.cc',helper]:
                assert sha(p)==frozen[p.name], 'Support identity changed '+p.name
            for name,digest in runtime_pins.items():
                assert sha(runtime/'bin'/name)==digest, 'Runtime identity changed '+name
            for rel,digest in inputs.items():
                assert sha(package/rel)==digest, 'Input identity changed '+rel
            for version,hashes in source_hashes.items():
                for rel,digest in hashes.items():
                    assert sha(sources[version]/rel)==digest, 'Exported source identity changed '+version+' '+rel
            if (out/'binary-hashes.json').exists():
                frozen_binaries=json.loads((out/'binary-hashes.json').read_text())
                for version,binary in binaries.items():
                    assert sha(binary)==frozen_binaries[version], 'Binary identity changed '+version
        except Exception as error:
            summary.update(status='REJECTED' if summary.get('scientific_rejected') else 'INCONCLUSIVE',
                           Tier0='REJECTED' if summary.get('scientific_rejected') else 'INCONCLUSIVE',identity_failure=repr(error))
        try:
            clean_owned('final-cleanup');save(out/'job-pids-before-release.json',job_pids())
        except Exception as error:summary.update(status='REJECTED' if summary.get('scientific_rejected') else 'INCONCLUSIVE',cleanup_failure=repr(error))
        try:
            cleanup=window.close();save(out/'cleanup.json',cleanup);summary['cleanup']=cleanup
            assert all(cleanup.get(k) is True for k in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored']),'Resource restoration unconfirmed'
        except Exception as error:summary.update(status='REJECTED' if summary.get('scientific_rejected') else 'INCONCLUSIVE',cleanup_failure=repr(error))
    save(out/'summary.json',summary)
    save(out/'SHA256.json',{str(p.relative_to(out)):sha(p) for p in sorted(out.rglob('*')) if p.is_file() and p.name!='SHA256.json' and not any(part.endswith('-source') for part in p.parts)})
    print(json.dumps(summary,indent=2),flush=True)
sys.exit(0 if summary.get('status')=='PREPARATORY_COMPLETE' and not summary.get('cleanup_failure') else 1)
