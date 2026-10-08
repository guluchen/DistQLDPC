"""GH50 engineering-only object/codegen gate; no solver execution.
Disabled until named assignment. Original GCC/O3 single source caching concept.
"""
import sys
sys.dont_write_bytecode=True
if not __debug__:raise RuntimeError("Python assertions disabled; unsupported supervisor invocation")
import argparse
import ctypes as C
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import time
import traceback

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
os.environ["PYTHONDONTWRITEBYTECODE"]="1"
if (HERE/"__pycache__").exists() or list(HERE.rglob("*.pyc")):
    raise RuntimeError("Support bytecode cache present before imports; no cached support execution")
ap=argparse.ArgumentParser()
ap.add_argument("--out",type=Path,required=True)
ap.add_argument("--run-assignment",required=True)
ap.add_argument("--candidate-sha",required=True)
args=ap.parse_args()
ASSIGNED_URL="https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6069956752"
assert ASSIGNED_URL!="HOST_SLOT_NOT_ASSIGNED", "No RUN_ASSIGNMENT: preparation only"
assert args.run_assignment==ASSIGNED_URL
out=args.out.resolve();assert out.parent==ROOT and out.name=="GH50-windows-codegen-01";out.mkdir(parents=True,exist_ok=False)
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(path,value):Path(path).write_text(json.dumps(value,indent=2),encoding="utf-8",newline="\n")
runtime=ROOT/"E004-windows-runtime/cygwin"
package=ROOT/"E004-windows-tier2-02/E004-server-package"
immutable_base=package/"baseline"
candidate=ROOT/"GH50-BINARY-VALUE"
helper=HERE/"windows_cpu_window.py"
# Pin every imported local support file to the named committed revision BEFORE
# executing it. CRLF checkout normalization is permitted; no content edits are.
head=subprocess.check_output(["git","-C",str(candidate),"rev-parse","HEAD"],text=True,timeout=20).strip()
assert head==args.candidate_sha, "Support HEAD differs from assignment"
assert HERE==candidate/"optimization/experiments/GH-50", "Unexpected support directory"
preimport_hashes={}
for name in ["windows_assigned_runner.py","windows_cpu_window.py","runner_common.py","codegen_parser.py","verify_runtime.py","RUNTIME-ORIGINAL-SHA256.json"]:
    path=HERE/name
    committed=subprocess.check_output(["git","-C",str(candidate),"show",head+":optimization/experiments/GH-50/"+name],timeout=20)
    actual=path.read_bytes()
    assert actual.replace(b"\r\n",b"\n")==committed.replace(b"\r\n",b"\n"), "Uncommitted support: "+name
    preimport_hashes[name]=sha(path)
assert sha(helper)=="ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2", "Reviewed helper differs"
assert sha(HERE/"RUNTIME-ORIGINAL-SHA256.json")=="9cc9c3db6dc0d72dbd90597058e165ee933affa6c9288a5abf7d804faed33db4", "Original runtime inventory changed"
save(out/"preimport-support.json",dict(candidate=head,assignment=args.run_assignment,hashes=preimport_hashes))
spec=importlib.util.spec_from_file_location("gh50_window",helper)
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
sys.path.insert(0,str(HERE))
import runner_common
import codegen_parser
k=module.k
k.QueryInformationJobObject.argtypes=[C.c_void_p,C.c_int,C.c_void_p,C.c_ulong,C.POINTER(C.c_ulong)]
k.QueryInformationJobObject.restype=C.c_int
window=None;current=None;resources=[];descendants=[];command_index=0;initial_identity=None;frozen_binaries={}
RUN_START=time.monotonic(); RUN_LIMIT=1200
summary=dict(status="INCONCLUSIVE",Tier0="NOT_RUN",diagnostic="NOT_RUN",performance="NOT_MEASURED",
             candidate=args.candidate_sha,assignment=args.run_assignment)

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
        if current.pid not in job_pids():
            raise RuntimeError("Live child not confirmed in owned Job; no unverified PID kill")
        result=subprocess.run(["taskkill","/PID",str(current.pid),"/T","/F"],
                              capture_output=True,text=True,timeout=10)
        records.append(dict(pid=current.pid,returncode=result.returncode,stdout=result.stdout,stderr=result.stderr))
        current.wait(timeout=10)
    # This NEW unnamed Job contains only this runner and its children, not other
    # users' jobs. Bounded cleanup handles any already-orphaned owned descendants.
    remaining=[pid for pid in job_pids() if pid!=os.getpid()]
    for pid in remaining:
        # A snapshotted PID can exit/recycle before taskkill. Recheck membership
        # in our unnamed Job immediately before issuing this bounded kill.
        if pid not in job_pids():continue
        result=subprocess.run(["taskkill","/PID",str(pid),"/T","/F"],capture_output=True,text=True,timeout=10)
        records.append(dict(pid=pid,returncode=result.returncode,stdout=result.stdout,stderr=result.stderr))
    deadline=time.monotonic()+5
    while time.monotonic()<deadline and [pid for pid in job_pids() if pid!=os.getpid()]:time.sleep(.1)
    still=[pid for pid in job_pids() if pid!=os.getpid()]
    save(out/("owned-cleanup-"+str(command_index)+".json"),dict(reason=reason,actions=records,
         remaining=still,confirmed=(not still)))
    if still:raise RuntimeError("Owned descendant cleanup unconfirmed: "+repr(still))

def managed_run(argv,cwd,target,label,timeout,cygwin=False):
    global current,command_index
    if time.monotonic()-RUN_START>RUN_LIMIT:raise RuntimeError("Aggregate watchdog exceeded")
    command_index+=1;target=Path(target);target.mkdir(exist_ok=True,parents=True)
    argv=list(map(str,argv))
    if cygwin:argv=[argv[0]]+[runner_common.cygpath(v) for v in argv[1:]]
    window.previous=module.ticks();time.sleep(2.1);observe(label+"-preflight")
    command=dict(argv=argv,cwd=str(cwd),timeout_sec=timeout,assignment=args.run_assignment,observer_environment={k:os.environ.get(k) for k in ["GH50_REPORT","GH50_TRACE"]})
    reason=None;start=time.monotonic();last=start;sampled=False
    with (target/(label+".stdout")).open("wb") as stdout,(target/(label+".stderr")).open("wb") as stderr:
        try:
            # Only make's shell children get POSIX PATH. Direct native launch
            # keeps the Windows runtime DLL lookup PATH, including Cygwin/bin.
            child_env=dict(os.environ)
            if cygwin and Path(argv[0]).name.lower()=="make.exe":
                child_env["PATH"]=runner_common.cygpath(runtime/"bin")+":/usr/bin:/bin"
            command["path_kind"]="posix-make" if Path(argv[0]).name.lower()=="make.exe" else "native-DLL"
            current=subprocess.Popen(argv,cwd=cwd,stdout=stdout,stderr=stderr,env=child_env)
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
                if now-RUN_START>RUN_LIMIT:raise RuntimeError("Aggregate watchdog exceeded")
                if any((target/(label+suffix)).stat().st_size>64*1024*1024 for suffix in [".stdout",".stderr"]):raise RuntimeError("Bounded raw-output limit exceeded; streams preserved untruncated")
            if any((target/(label+suffix)).stat().st_size>64*1024*1024 for suffix in [".stdout",".stderr"]):
                raise RuntimeError("Final raw-output limit exceeded; streams preserved untruncated")
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

BASELINE="24572d6d09cce9a4a5faa58300a89e0feba9da6a"
PRODUCTION="b6bd31029bf7510ba2f3fc7e0fa1ea5a85357075"
protected_files={}
def freeze(path):
    path=Path(path);digest=sha(path)
    if str(path) in protected_files and protected_files[str(path)]!=digest:
        raise RuntimeError("Frozen file changed before later consumption: "+str(path))
    protected_files[str(path)]=digest

def checked(argv,cwd,target,label,timeout=120,cygwin=True):
    result=managed_run(argv,cwd,target,label,timeout,cygwin)
    if result[0]:raise RuntimeError("Engineering command failed "+label+": "+result[2][-2000:])
    return result

try:
    manifest=json.loads((package/"manifest.json").read_text())
    assert manifest["baseline"]==BASELINE
    for relative,digest in manifest["files"].items():assert sha(package/relative)==digest,relative
    installed=runtime/"etc/setup/installed.db"
    freeze(installed)
    assert installed.read_bytes()==(ROOT/"DistQLDPC/optimization/experiments/E004/raw/windows-setup-2026-10-08/installed.db").read_bytes()
    assert not subprocess.check_output(["git","-C",str(candidate),"diff",PRODUCTION,head,"--","src","Makefile"],timeout=20)
    assert subprocess.check_output(["git","-C",str(candidate),"show",head+":Makefile"],timeout=20)==subprocess.check_output(["git","-C",str(candidate),"show",BASELINE+":Makefile"],timeout=20)
    for name in preimport_hashes:freeze(HERE/name)
    freeze(sys.executable)
    blocked=['CC','CXX','CPP','CFLAGS','CXXFLAGS','CPPFLAGS','LDFLAGS','MAKEFLAGS','GNUMAKEFLAGS','MAKEFILES','MFLAGS','MAKEOVERRIDES',
             'CPATH','C_INCLUDE_PATH','CPLUS_INCLUDE_PATH','OBJC_INCLUDE_PATH',
             'GCC_EXEC_PREFIX','COMPILER_PATH','LIBRARY_PATH','GCC_COMPARE_DEBUG',
             'GCC_COMPARE_DEBUG_SECOND','LD_PRELOAD','LD_LIBRARY_PATH','LD_AUDIT','CYGWIN']
    present=[name for name in blocked if name in os.environ]
    assert not present, "External build/runtime override names: "+repr(present)
    assert not (candidate/"build").exists(),"Candidate must be clean"
    os.environ["PATH"]=str(runtime/"bin")+os.pathsep+os.environ["PATH"]
    window=module.Window(True,0x8000)
    save(out/"identity.json",dict(baseline=BASELINE,production=PRODUCTION,support=head,
         assignment=args.run_assignment,preimport=preimport_hashes,selection=window.selection,
         solver_executed=False,known_baseline_anomaly="GH46 family1-variant1 preserved/unresolved"))
    logs=out/"build-logs"
    checked([sys.executable,"-B",HERE/"verify_runtime.py","--runtime",runtime,"--manifest",HERE/"RUNTIME-ORIGINAL-SHA256.json",
             "--out",out/"runtime-before.json"],candidate,logs,"original-runtime-before",300,False)
    compiler=checked([runtime/"bin/g++.exe","--version"],candidate,logs,"compiler",30)
    assert "14.4" in compiler[1],"Frozen compiler version changed"
    base=out/"baseline-source";base.mkdir()
    names=subprocess.check_output(["git","-C",str(candidate),"ls-tree","-r","--name-only",BASELINE,"--","src","Makefile"],text=True,timeout=20).splitlines()
    for name in names:
        target=base/name;target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(subprocess.check_output(["git","-C",str(candidate),"show",BASELINE+":"+name],timeout=20))
    sources={"baseline":base,"candidate":candidate};objects={};disassemblies={}
    for label,source in sources.items():
        revision=BASELINE if label=="baseline" else PRODUCTION
        for name in names:
            expected=subprocess.check_output(["git","-C",str(candidate),"show",revision+":"+name],timeout=20)
            path=source/name
            assert path.read_bytes().replace(b"\r\n",b"\n")==expected.replace(b"\r\n",b"\n"),"Source blob differs "+name
            if name=="Makefile":path.write_bytes(expected.replace(b"\r\n",b"\n"))
            freeze(path)
        checked([runtime/"bin/make.exe","-j1","build/Solver.o"],source,logs,label+"-original-O3-Solver-object",300)
        obj=source/"build/Solver.o";freeze(obj);objects[label]=obj
        retained=out/(label+"-actual-Solver.o");shutil.copyfile(obj,retained)
        assert sha(retained)==sha(obj),"Retained actual object differs";freeze(retained)
        checked([runtime/"bin/nm.exe","--defined-only",obj],source,logs,label+"-defined-symbols",30)
        result=checked([runtime/"bin/objdump.exe","-dr","--disassemble="+codegen_parser.SYMBOL,obj],source,logs,label+"-actual-ForLK-disassembly",30)
        disassemblies[label]=codegen_parser.parse(result[1])
    report=codegen_parser.compare(disassemblies["baseline"],disassemblies["candidate"])
    save(out/"codegen-comparison.json",report)
    checked([sys.executable,"-B",HERE/"verify_runtime.py","--runtime",runtime,"--manifest",HERE/"RUNTIME-ORIGINAL-SHA256.json",
             "--out",out/"runtime-after.json"],candidate,logs,"original-runtime-after",300,False)
    summary.update(status="ENGINEERING_COMPLETE",mechanism=report["status"],science="NOT_TESTED",performance="NOT_MEASURED",protected_identity_count=len(protected_files))

except BaseException as error:
    summary["reason"]=repr(error);summary["traceback"]=traceback.format_exc()
    print("STOP: "+repr(error),flush=True)
finally:
    if window is not None:
        try:
            clean_owned("final-cleanup");save(out/"job-pids-before-release.json",job_pids())
        except Exception as error:summary["cleanup_failure"]=repr(error)
        try:
            summary["cleanup"]=window.close()
            required=["job_limit_released","affinity_restored","sleep_requirement_restored","priority_restored"]
            if not all(summary["cleanup"].get(k) is True for k in required):summary["restoration_failure"]="Not all restorations succeeded"
        except Exception as error:summary["restoration_failure"]=repr(error)
    try:
        if (HERE/"__pycache__").exists() or list(HERE.rglob("*.pyc")):
            raise RuntimeError("Support cache appeared during frozen run")
        summary["support_cache_absent_after"]=True
        for name,digest in protected_files.items():assert sha(name)==digest,"Frozen identity changed "+name
        if "manifest" in globals():
            for relative,digest in manifest["files"].items():assert sha(package/relative)==digest,"Immutable package changed "+relative
    except Exception as error:summary["identity_failure"]=repr(error)
    success=summary["status"]=="ENGINEERING_COMPLETE" and window is not None and not any(k in summary for k in ["cleanup_failure","restoration_failure","identity_failure"])
    summary["valid_run"]=success
    if not success:summary["status"]="INCONCLUSIVE"
    save(out/"protected-identities.json",protected_files);save(out/"summary.json",summary)
    save(out/"SHA256.json",{str(p.relative_to(out)):sha(p) for p in sorted(out.rglob("*"))
         if p.is_file() and p.suffix!=".exe" and p.name!="SHA256.json"})
    print(json.dumps(summary,indent=2),flush=True)
if not summary["valid_run"]:sys.exit(1)
