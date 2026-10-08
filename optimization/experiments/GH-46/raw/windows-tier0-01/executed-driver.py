"""GH46 assigned Windows Tier0. Refuses execution until assignment URL is frozen.
Bounded file-backed supervisor reused from GH17, with separate outputs/source hashes.
Separate targeted allocation diagnostic only after correctness; no performance loop.
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
ASSIGNED_URL="https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6069534252"
assert ASSIGNED_URL!="HOST_SLOT_NOT_ASSIGNED", "No RUN_ASSIGNMENT: preparation only"
assert args.run_assignment==ASSIGNED_URL
out=args.out.resolve();assert out.parent==ROOT and out.name=="GH46-windows-tier0-01";out.mkdir(parents=True,exist_ok=False)
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(path,value):Path(path).write_text(json.dumps(value,indent=2),encoding="utf-8",newline="\n")
runtime=ROOT/"E004-windows-runtime/cygwin"
package=ROOT/"E004-windows-tier2-02/E004-server-package"
immutable_base=package/"baseline"
candidate=ROOT/"GH46-LOOKAHEAD-SCRATCH"
helper=HERE/"windows_cpu_window.py"
# Pin every imported local support file to the named committed revision BEFORE
# executing it. CRLF checkout normalization is permitted; no content edits are.
head=subprocess.check_output(["git","-C",str(candidate),"rev-parse","HEAD"],text=True,timeout=20).strip()
assert head==args.candidate_sha, "Support HEAD differs from assignment"
assert HERE==candidate/"optimization/experiments/GH-46", "Unexpected support directory"
preimport_hashes={}
for name in ["windows_assigned_runner.py","windows_cpu_window.py","runner_common.py","run_tier0.py","run_lifetime.py","cygwin_test_stats_shim.cc","prepare_observer.py","allocation_diagnostic.h","state_observer.h","generate_oracles.py","test_allocation_prediction.cc","verify_runtime.py","RUNTIME-ORIGINAL-SHA256.json"]:
    path=HERE/name
    committed=subprocess.check_output(["git","-C",str(candidate),"show",head+":optimization/experiments/GH-46/"+name],timeout=20)
    actual=path.read_bytes()
    assert actual.replace(b"\r\n",b"\n")==committed.replace(b"\r\n",b"\n"), "Uncommitted support: "+name
    preimport_hashes[name]=sha(path)
assert sha(helper)=="ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2", "Reviewed helper differs"
assert sha(HERE/"RUNTIME-ORIGINAL-SHA256.json")=="9cc9c3db6dc0d72dbd90597058e165ee933affa6c9288a5abf7d804faed33db4", "Original runtime inventory changed"
save(out/"preimport-support.json",dict(candidate=head,assignment=args.run_assignment,hashes=preimport_hashes))
spec=importlib.util.spec_from_file_location("gh46_window",helper)
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
sys.path.insert(0,str(HERE))
import runner_common
import run_tier0
import run_lifetime
k=module.k
k.QueryInformationJobObject.argtypes=[C.c_void_p,C.c_int,C.c_void_p,C.c_ulong,C.POINTER(C.c_ulong)]
k.QueryInformationJobObject.restype=C.c_int
window=None;current=None;resources=[];descendants=[];command_index=0;initial_identity=None;frozen_binaries={}
RUN_START=time.monotonic(); RUN_LIMIT=3600
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
    command=dict(argv=argv,cwd=str(cwd),timeout_sec=timeout,assignment=args.run_assignment,observer_environment={k:os.environ.get(k) for k in ["GH46_REPORT","GH46_TRACE"]})
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
PRODUCTION="51509debe2e09a44bc3accdaf1b1857a6c30e53f"
protected_files={}
consumed_links=[]
def freeze(path):
    path=Path(path);digest=sha(path)
    if str(path) in protected_files and protected_files[str(path)]!=digest:
        raise RuntimeError("Frozen file changed before a later consumption: "+str(path))
    protected_files[str(path)]=digest

def checked(argv,cwd,target,label,timeout=120,cygwin=True):
    result=managed_run(argv,cwd,target,label,timeout,cygwin)
    if result[0]:raise RuntimeError("Engineering command failed "+label+": "+result[2][-2000:])
    return result

FLAGS=["-Isrc/solver","-Wall","-Wno-parentheses","-O3","-g",
       "-D","__STDC_LIMIT_MACROS","-D","__STDC_FORMAT_MACROS","-DNDEBUG"]
ENGINE_NAMES=["SimpSolver","Solver","Options","System"]
def build_app(source,label,logs):
    objects=[source/"build"/(name+".o") for name in ENGINE_NAMES]
    checked([runtime/"bin/make.exe","-j1",*["build/"+name+".o" for name in ENGINE_NAMES]],
            source,logs,label+"-compile-engine-objects",300)
    for p in objects:freeze(p)
    before={str(p):sha(p) for p in objects}
    checked([runtime/"bin/make.exe","-j1","bin/distqldpc"],source,logs,label+"-application-link",300)
    after={str(p):sha(p) for p in objects}
    if before!=after:raise RuntimeError("Consumed application objects changed during link "+label)
    consumed_links.append(dict(label=label,kind="original-Makefile-application-link",before=before,after=after))
    save(out/"consumed-links.json",consumed_links)
    binary=source/"bin/distqldpc.exe";freeze(binary)
    return binary

def build_main(source,label,logs):
    binary=out/(label+"-test-only-main.exe")
    objects=[source/"build"/(name+".o") for name in ENGINE_NAMES]
    for p in objects:
        if str(p) not in protected_files or sha(p)!=protected_files[str(p)]:
            raise RuntimeError("Unpinned/changed consumed Main object: "+str(p))
    before={str(p):sha(p) for p in objects}
    checked([runtime/"bin/g++.exe",*FLAGS,source/"src/solver/Main.cc",HERE/"cygwin_test_stats_shim.cc",
             *objects,"-lz","-o",binary],source,logs,label+"-test-main-link")
    after={str(p):sha(p) for p in objects}
    if before!=after:raise RuntimeError("Consumed Main objects changed during link "+label)
    consumed_links.append(dict(label=label,kind="identical-test-only-statistic-shim-Main-link",before=before,after=after))
    save(out/"consumed-links.json",consumed_links)
    freeze(binary)
    return binary

try:
    manifest=json.loads((package/"manifest.json").read_text())
    assert manifest["baseline"]==BASELINE
    for relative,digest in manifest["files"].items():assert sha(package/relative)==digest,relative
    assert sha(immutable_base/"bin/distqldpc.exe")=="22e398cc7558c2a04d5f24bd6db3030ce552c752622027fc2657eff7c1bd1815"
    installed=runtime/"etc/setup/installed.db"
    assert installed.read_bytes()==(ROOT/"DistQLDPC/optimization/experiments/E004/raw/windows-setup-2026-10-08/installed.db").read_bytes()
    assert not subprocess.check_output(["git","-C",str(candidate),"diff",PRODUCTION,head,"--","src","Makefile"],timeout=20)
    assert subprocess.check_output(["git","-C",str(candidate),"show",head+":Makefile"],timeout=20)==subprocess.check_output(["git","-C",str(candidate),"show",BASELINE+":Makefile"],timeout=20)
    paths=subprocess.check_output(["git","-C",str(candidate),"ls-tree","-r","--name-only",head,"src","Makefile"],text=True,timeout=20).splitlines()
    for name in paths:
        committed=subprocess.check_output(["git","-C",str(candidate),"show",head+":"+name],timeout=20)
        assert (candidate/name).read_bytes().replace(b"\r\n",b"\n")==committed.replace(b"\r\n",b"\n"),name
    for name in [*paths,"scripts/smoke_test.sh"]:freeze(candidate/name)
    for name in preimport_hashes:freeze(HERE/name)
    freeze(helper);freeze(installed);freeze(sys.executable)
    for name in ["g++.exe","make.exe","bash.exe","size.exe","nm.exe","cygwin1.dll","cygstdc++-6.dll",
                 "cyggcc_s-seh-1.dll","cygz.dll","cygiconv-2.dll","cygintl-8.dll"]:freeze(runtime/"bin"/name)
    for stem in ["LP_34_20_2","LP_136_32_4","LP_340_56_8"]:
        for suffix in ["Hx","Hz","Gx","Gz"]:freeze(immutable_base/"data/matrices"/(stem+"_"+suffix+".txt"))
    assert not any(os.environ.get(key) for key in ["CXXFLAGS","LDFLAGS","CXX","MAKEFLAGS","CPATH","CPLUS_INCLUDE_PATH","LIBRARY_PATH","GCC_EXEC_PREFIX","GH46_TRACE","GH46_REPORT"]),"External build/observer override"
    os.environ["PATH"]=str(runtime/"bin")+os.pathsep+os.environ["PATH"]
    os.environ.update(LC_ALL="C",OMP_NUM_THREADS="1",OPENBLAS_NUM_THREADS="1",MKL_NUM_THREADS="1")
    window=module.Window(True,0x8000)
    window.previous=module.ticks();time.sleep(2.1);observe("assignment-preflight")
    initial_identity=dict(baseline=BASELINE,production=PRODUCTION,support=head,
                          assignment=args.run_assignment,preimport=preimport_hashes,
                          selection=window.selection,protected_files=dict(protected_files),
                          original_package_binary=sha(immutable_base/"bin/distqldpc.exe"),
                          support_cache_absent=True,python_executable=sys.executable,python_version=sys.version,
                          aggregate_watchdog_seconds=RUN_LIMIT,exclusive_reservation=False)
    save(out/"identity.json",initial_identity);shutil.copyfile(__file__,out/"executed-driver.py")
    # Fresh original source build, preserving the immutable package and its executable.
    base=out/"baseline-source";base.mkdir()
    for name in ["src","scripts"]:shutil.copytree(immutable_base/name,base/name)
    shutil.copyfile(immutable_base/"Makefile",base/"Makefile")
    for source in [base,candidate]:
        for name in ["Makefile","scripts/smoke_test.sh"]:
            p=source/name;p.write_bytes(p.read_bytes().replace(b"\r\n",b"\n"))
            if source==candidate:protected_files[str(p)]=sha(p) # explicitly allowed canonical LF shell normalization only
        dest=source/"data/matrices";dest.mkdir(exist_ok=True,parents=True)
        for suffix in ["Hx","Hz","Gx","Gz"]:
            reference=immutable_base/"data/matrices"/("LP_34_20_2_"+suffix+".txt")
            target=dest/reference.name
            if target.exists():
                assert target.read_bytes().replace(b"\r\n",b"\n")==reference.read_bytes().replace(b"\r\n",b"\n")
            else:shutil.copyfile(reference,target)
            freeze(target)
    assert not (candidate/"build").exists() and not (candidate/"bin/distqldpc.exe").exists(),"Candidate must be clean"
    for p in (base/"src").rglob("*"):
        if p.is_file():freeze(p)
    for name in ["Makefile","scripts/smoke_test.sh"]:freeze(base/name)
    logs=out/"build-logs";logs.mkdir()
    checked([sys.executable,"-B",HERE/"verify_runtime.py","--runtime",runtime,"--manifest",HERE/"RUNTIME-ORIGINAL-SHA256.json",
             "--out",out/"runtime-before.json"],candidate,logs,"original-runtime-before",300,False)
    compiler=checked([runtime/"bin/g++.exe","--version"],candidate,logs,"compiler",20,False)
    assert "14.4" in compiler[1],"Frozen compiler version changed"
    sources={"baseline":base,"candidate":candidate};apps={};mains={}
    for label,source in sources.items():
        apps[label]=build_app(source,label+"-production",logs)
        for p in (source/"src").rglob("*"):
            if p.is_file():freeze(p)
        mains[label]=build_main(source,label,logs)
        symbols=checked([runtime/"bin/nm.exe","-C",apps[label]],source,logs,label+"-production-symbols",30)
        assert "gh46_" not in symbols[1] and "GH46" not in symbols[1],"Diagnostic support in production binary"
        checked([runtime/"bin/bash.exe",source/"scripts/smoke_test.sh",apps[label]],source,logs,label+"-original-smoke",35)
    save(out/"production-binary-hashes.json",{label:sha(p) for label,p in apps.items()})
    runner_common.run=managed_run;run_tier0.run=managed_run
    sys.argv=["run_tier0.py","--baseline-bin",str(apps["baseline"]),"--candidate-bin",str(apps["candidate"]),
              "--baseline-maxsat",str(mains["baseline"]),"--candidate-maxsat",str(mains["candidate"]),
              "--data-root",str(immutable_base/"data/matrices"),"--out",str(out/"tier0"),
              "--run-assignment",args.run_assignment,"--cygwin"]
    run_tier0.main();summary["production_checks"]="LOCAL_PASS"
    # Separate test snapshots: no observer edit enters the checkout/production binary.
    observed={};observed_mains={};observed_apps={}
    for label,source in sources.items():
        snapshot=out/(label+"-observer-source")
        checked([sys.executable,"-B",HERE/"prepare_observer.py","--source",source,"--out",snapshot,"--variant",label,"--trace"],candidate,logs,label+"-prepare-observer",30,False)
        observed[label]=snapshot
        for p in snapshot.rglob("*"):
            if p.is_file():freeze(p)
        observed_apps[label]=build_app(snapshot,label+"-observer",logs)
        observed_mains[label]=build_main(snapshot,label+"-observer",logs)
    prediction=out/"allocation-prediction.exe"
    checked([runtime/"bin/g++.exe",*FLAGS,HERE/"test_allocation_prediction.cc","-o",prediction],observed["baseline"],logs,"prediction-build",120)
    freeze(prediction)
    checked([prediction],observed["baseline"],logs,"prediction-check",30)
    oracle_dir=out/"oracles"
    checked([sys.executable,"-B",HERE/"generate_oracles.py","--out",oracle_dir],candidate,logs,"generate-oracles",30,False)
    for p in oracle_dir.iterdir():freeze(p)
    os.environ.update(GH46_TRACE="1",GH46_REPORT="1")
    def fixture_execute(argv,label,cwd,timeout):
        return managed_run(argv,cwd,out/"lifetime",label,timeout,True)
    try:
        run_lifetime.run(fixture_execute,sources,observed_mains,mains,observed_apps,oracle_dir,out/"tier0",out)
    finally:
        os.environ.pop("GH46_TRACE",None);os.environ.pop("GH46_REPORT",None)
    summary["Tier0"]="LOCAL_PASS"
    # Only four bounded ORIGINAL-baseline diagnostics, after all correctness checks.
    diag=out/"baseline-diagnostic-source"
    checked([sys.executable,"-B",HERE/"prepare_observer.py","--source",base,"--out",diag,"--variant","baseline"],candidate,logs,"prepare-allocation-diagnostic",30,False)
    for p in diag.rglob("*"):
        if p.is_file():freeze(p)
    diag_bin=build_app(diag,"baseline-allocation-diagnostic",logs)
    os.environ["GH46_REPORT"]="1";allocation=[]
    try:
        for stem,exact in [("LP_34_20_2",2),("LP_136_32_4",4)]:
            for mode in ["no-card","card-mto"]:
                result=managed_run([diag_bin,"-"+mode,"-cpu-lim=110",immutable_base/"data/matrices"/stem],diag,out/"allocation",stem+"-"+mode,120,True)
                run_tier0.assert_all_bounds(result[1],exact)
                if result[0]==0:
                    assert run_tier0.semantic(result[1])==(exact,exact,exact,exact),"SCIENCE wrong diagnostic result"
                    run_tier0.assert_status(result[1])
                else:
                    assert result[0]==1,"SCIENCE diagnostic crash/exit"
                    run_tier0.assert_status(result[1],True)
                    assert run_tier0.semantic(result[1])[:2]==(None,None),"SCIENCE timeout reports completed distance"
                counts=run_lifetime.counters(result[2],False)
                allocation.append(dict(case=stem,mode=mode,returncode=result[0],counters=counts,
                                       complete=bool(counts) and all(c["complete"] for c in counts.values())))
                save(out/"allocation/COUNTERS.json",allocation)
    finally:os.environ.pop("GH46_REPORT",None)
    checked([sys.executable,"-B",HERE/"verify_runtime.py","--runtime",runtime,"--manifest",HERE/"RUNTIME-ORIGINAL-SHA256.json",
             "--out",out/"runtime-after.json"],candidate,logs,"original-runtime-after",300,False)
    summary.update(status="PREPARATORY_COMPLETE",diagnostic="COMPLETE" if all(x["complete"] for x in allocation) else "INCOMPLETE_PREFIX_ONLY",
                   performance="NOT_MEASURED",protected_identity_count=len(protected_files))
except BaseException as error:
    summary["reason"]=repr(error);summary["traceback"]=traceback.format_exc()
    if isinstance(error,run_tier0.ScienceMismatch) or isinstance(error,AssertionError) and "SCIENCE" in str(error):summary.update(status="REJECT",Tier0="REJECT")
    if (out/"tier0/summary.json").exists():
        summary["production_report"]=json.loads((out/"tier0/summary.json").read_text())
        if summary["production_report"]["Tier0"]=="REJECT":summary.update(status="REJECT",Tier0="REJECT")
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
    success=summary["status"]=="PREPARATORY_COMPLETE" and summary["Tier0"]=="LOCAL_PASS" and window is not None and not any(k in summary for k in ["cleanup_failure","restoration_failure","identity_failure"])
    summary["valid_run"]=success
    if not success and summary["status"]!="REJECT":summary["status"]="INCONCLUSIVE"
    save(out/"protected-identities.json",protected_files);save(out/"summary.json",summary)
    save(out/"SHA256.json",{str(p.relative_to(out)):sha(p) for p in sorted(out.rglob("*"))
         if p.is_file() and p.suffix not in [".exe",".o"] and p.name!="SHA256.json"})
    print(json.dumps(summary,indent=2),flush=True)
if not summary["valid_run"]:sys.exit(1)
