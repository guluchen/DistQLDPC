"""GH38 assigned Windows Tier0. Refuses execution until assignment URL is frozen.
Bounded file-backed supervisor reused from GH17, with separate outputs/source hashes.
No profile, allocation diagnostic or performance loop.
"""
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
import sys
import time
import traceback

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
ap=argparse.ArgumentParser()
ap.add_argument("--out",type=Path,required=True)
ap.add_argument("--run-assignment",required=True)
ap.add_argument("--candidate-sha",required=True)
args=ap.parse_args()
ASSIGNED_URL="HOST_SLOT_NOT_ASSIGNED"
PROBE02_AUDIT_SHA256="e78abbc71f26d3ed1fa973b0cbfce9cf908352745be125e6a442dc0bd5d9daaf"
assert ASSIGNED_URL!="HOST_SLOT_NOT_ASSIGNED", "No RUN_ASSIGNMENT: preparation only"
assert args.run_assignment==ASSIGNED_URL
out=args.out.resolve();assert out.parent==ROOT and out.name=="GH38-windows-tier0-01";out.mkdir(parents=True,exist_ok=False)
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(path,value):Path(path).write_text(json.dumps(value,indent=2),encoding="utf-8",newline="\n")
original_runtime=ROOT/"E004-windows-runtime/cygwin"
runtime=ROOT/"GH38-setup-probe-01/overlay"
prior02=ROOT/"GH38-setup-probe-02"
assert PROBE02_AUDIT_SHA256!="PROBE02_NOT_AUDITED", "Corrected compatibility audit not frozen"
assert sha(prior02/"INDEPENDENT-COMPATIBILITY-AUDIT.json")==PROBE02_AUDIT_SHA256
assert json.loads((prior02/"INDEPENDENT-COMPATIBILITY-AUDIT.json").read_text())["decision"]=="COMPATIBILITY_PASS"
package=ROOT/"E004-windows-tier2-02/E004-server-package"
immutable_base=package/"baseline"
candidate=ROOT/"GH38-CLANG"
helper=HERE/"windows_cpu_window.py"
# Pin every imported local support file to the named committed revision BEFORE
# executing it. CRLF checkout normalization is permitted; no content edits are.
head=subprocess.check_output(["git","-C",str(candidate),"rev-parse","HEAD"],text=True,timeout=20).strip()
assert head==args.candidate_sha, "Support HEAD differs from assignment"
assert HERE==candidate/"optimization/experiments/GH-38", "Unexpected support directory"
preimport_hashes={}
for name in ["windows_tier0.py","windows_cpu_window.py","runner_common.py","run_tier0.py","cygwin_test_stats_shim.cc","setup_worker.py","windows_codegen_probe.py","PACKAGE-CLOSURE.json","raw/setup-probe-01/runtime-before.json"]:
    path=HERE/name
    committed=subprocess.check_output(["git","-C",str(candidate),"show",head+":optimization/experiments/GH-38/"+name],timeout=20)
    actual=path.read_bytes()
    assert actual.replace(b"\r\n",b"\n")==committed.replace(b"\r\n",b"\n"), "Uncommitted support: "+name
    preimport_hashes[name]=sha(path)
assert sha(helper)=="ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2", "Reviewed helper differs"
save(out/"preimport-support.json",dict(candidate=head,assignment=args.run_assignment,hashes=preimport_hashes))
spec=importlib.util.spec_from_file_location("gh38_window",helper)
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
sys.path.insert(0,str(HERE))
import runner_common
import run_tier0
import windows_codegen_probe
k=module.k
k.QueryInformationJobObject.argtypes=[C.c_void_p,C.c_int,C.c_void_p,C.c_ulong,C.POINTER(C.c_ulong)]
k.QueryInformationJobObject.restype=C.c_int
window=None;current=None;resources=[];descendants=[];command_index=0;initial_identity=None;frozen_binaries={}
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
    command_index+=1;target=Path(target);target.mkdir(exist_ok=True,parents=True)
    argv=list(map(str,argv))
    if cygwin:argv=[argv[0]]+[runner_common.cygpath(v) for v in argv[1:]]
    window.previous=module.ticks();time.sleep(2.1);observe(label+"-preflight")
    command=dict(argv=argv,cwd=str(cwd),timeout_sec=timeout,assignment=args.run_assignment)
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

try:
    baseline_sha="24572d6d09cce9a4a5faa58300a89e0feba9da6a"
    manifest=json.loads((package/"manifest.json").read_text(encoding="utf-8"))
    for relative,digest in manifest["files"].items():assert sha(package/relative)==digest,relative
    assert sha(immutable_base/"bin/distqldpc.exe")=="22e398cc7558c2a04d5f24bd6db3030ce552c752622027fc2657eff7c1bd1815"
    assert (runtime/"etc/setup/installed.db").read_bytes()==(ROOT/"DistQLDPC/optimization/experiments/E004/raw/windows-setup-2026-10-08/installed.db").read_bytes()
    head=subprocess.check_output(["git","-C",str(candidate),"rev-parse","HEAD"],text=True).strip()
    assert head==args.candidate_sha
    def git_data(ref,path):
        return subprocess.check_output(["git","-C",str(candidate),"show",ref+":"+path])
    assert subprocess.check_output(["git","-C",str(candidate),"rev-parse",head+":src"])==subprocess.check_output(["git","-C",str(candidate),"rev-parse",baseline_sha+":src"])
    paths=subprocess.check_output(["git","-C",str(candidate),"ls-tree","-r","--name-only",head,"src"],text=True).splitlines()
    for p in paths:
        assert (candidate/p).read_bytes().replace(b"\r\n",b"\n")==git_data(head,p).replace(b"\r\n",b"\n"),p
    original=git_data(baseline_sha,"Makefile")
    assert git_data(head,"Makefile")==git_data("79db804cf3d1fab8271a680ddb46a2b546808629","Makefile")
    assert (candidate/"Makefile").read_bytes().replace(b"\r\n",b"\n")==git_data(head,"Makefile")
    os.environ["PATH"]=str(runtime/"bin")+os.pathsep+os.environ["PATH"]
    os.environ.update(LC_ALL="C",OMP_NUM_THREADS="1",OPENBLAS_NUM_THREADS="1",MKL_NUM_THREADS="1")
    assert not any(os.environ.get(key) for key in ["CXXFLAGS","LDFLAGS","CXX","LINK_CXX","MAKEFLAGS","CPATH","CPLUS_INCLUDE_PATH","LIBRARY_PATH","GCC_EXEC_PREFIX"]), "Unexpected external build override"
    window=module.Window(True,0x8000)
    window.previous=module.ticks();time.sleep(2.1);observe("assignment-preflight")
    # Preserve immutable package. Copy for standalone TEST Main linking,
    # retaining verified O3 engine objects. Never compile in original package.
    base=out/"baseline-link-snapshot";shutil.copytree(immutable_base,base)
    for source in [base,candidate]:
        for rel in ["Makefile","scripts/smoke_test.sh"]:
            p=source/rel;p.write_bytes(p.read_bytes().replace(b"\r\n",b"\n"))
        # The original smoke script resolves LP34 relative to its own tree.
        destination=source/"data/matrices";destination.mkdir(parents=True,exist_ok=True)
        for suffix in ["Hx","Hz","Gx","Gz"]:
            reference=immutable_base/"data/matrices"/("LP_34_20_2_"+suffix+".txt")
            target=destination/reference.name
            if source==candidate and target.exists():
                raw=target.read_bytes();canonical=git_data(head,"data/matrices/"+reference.name)
                assert raw.replace(b"\r\n",b"\n")==canonical.replace(b"\r\n",b"\n"),reference.name
            if not target.exists():shutil.copy2(reference,target)
            assert target.read_bytes().replace(b"\r\n",b"\n")==reference.read_bytes().replace(b"\r\n",b"\n"),reference.name
    assert not (candidate/"build").exists() and not (candidate/"bin/distqldpc.exe").exists(), "Candidate must be clean"
    initial_identity=dict(candidate=head,baseline=baseline_sha,assignment=args.run_assignment,
         baseline_manifest_sha256=sha(package/"manifest.json"),baseline_binary_sha256=sha(immutable_base/"bin/distqldpc.exe"),
         runner_sha256=sha(__file__),helper_sha256=sha(helper),runtime_manifest_sha256=sha(runtime/"etc/setup/installed.db"),
         preimport_support_hashes=preimport_hashes,
         runtime_file_hashes={name:sha(runtime/"bin"/name) for name in ["g++.exe","make.exe","bash.exe","size.exe","cygwin1.dll","cygstdc++-6.dll"]},
         selection=window.selection,source_hashes={p:sha(candidate/p) for p in paths+["Makefile"]},
         support_hashes={p.name:sha(p) for p in list(HERE.glob("*.py"))+list(HERE.glob("*.cc"))},
         smoke_input_hashes={label:{p.name:sha(p) for p in (source/"data/matrices").glob("LP_34_20_2_*.txt")}
                             for label,source in [("baseline-copy",base),("candidate-checkout",candidate)]},
         object_hashes={str(p.relative_to(immutable_base)):sha(p) for p in (immutable_base/"build").glob("*.o")},
         input_hashes={p.name:sha(p) for stem in ["LP_34_20_2","LP_340_56_8"] for p in (immutable_base/"data/matrices").glob(stem+"_*.txt")})
    save(out/"identity.json",initial_identity)
    runner_common.run=managed_run;run_tier0.run=managed_run
    buildlogs=out/"build-logs";buildlogs.mkdir()
    def verify_overlay(label):
        result=managed_run([sys.executable,HERE/"setup_worker.py","verify-closure",
            "--runtime",original_runtime,"--overlay",runtime,
            "--manifest",HERE/"raw/setup-probe-01/runtime-before.json",
            "--closure",HERE/"PACKAGE-CLOSURE.json","--cache",ROOT/"GH38-setup-probe-01/archives",
            "--result",out/(label+".json")],candidate,buildlogs,label,300)
        assert result[0]==0,"Overlay verification worker failed: "+label
        return result
    verify_overlay("overlay-before")
    for label,compiler,version in [("original-GNU",runtime/"bin/g++.exe","14.4.0"),
                                   ("candidate-Clang",runtime/"bin/clang++.exe","22.1.8")]:
        result=managed_run([compiler,"--version"],candidate,buildlogs,label+"-version",20)
        assert result[0]==0 and version in result[1],"Compiler version drift"
    save(out/"compatibility-provenance.json",dict(actual_probe02_audit_sha256=PROBE02_AUDIT_SHA256,
        baseline="24572d6d09cce9a4a5faa58300a89e0feba9da6a",production="79db804cf3d1fab8271a680ddb46a2b546808629",
        concept="Clang22 O3 codegen with originalGNU14 linking",performance="NOT_MEASURED"))
    # Original make-all Main.cc cannot link on this Cygwin runtime: its
    # memUsedPeak declaration lacks an unsupported-platform definition.
    # The production target/default flags require no change or test shim.
    result=managed_run([runtime/"bin/make.exe","-j1","bin/distqldpc"],candidate,buildlogs,"candidate-default-build",300,True)
    if result[0]:raise RuntimeError("Candidate build failed: "+result[2][-3000:])
    production_pe={label:windows_codegen_probe.pe_properties(binary) for label,binary in
        [("baseline",immutable_base/"bin/distqldpc.exe"),("candidate",candidate/"bin/distqldpc.exe")]}
    assert production_pe["baseline"]==production_pe["candidate"],"Actual production GNU manifest/PE properties differ"
    save(out/"production-pe.json",production_pe)
    test_main={}
    for source,label,compiler in [(base,"baseline",runtime/"bin/g++.exe"),(candidate,"candidate",runtime/"bin/clang++.exe")]:
        binary=out/(label+"-test-only-main.exe");test_main[label]=binary
        flags=["-Isrc/solver","-Wall","-Wno-parentheses","-O3","-g",
               "-D__STDC_LIMIT_MACROS","-D__STDC_FORMAT_MACROS","-DNDEBUG"]
        main_object=out/(label+"-test-only-main.o");shim_object=out/(label+"-test-only-stats.o")
        acceptance=["-Wno-reserved-user-defined-literal"] if label=="candidate" else []
        result=managed_run([compiler,*acceptance,*flags,"-c",source/"src/solver/Main.cc","-o",main_object],
            source,buildlogs,label+"-test-main-compile",120,True)
        if result[0]:raise RuntimeError("Standalone TEST Main compile failed: "+result[2][-3000:])
        result=managed_run([runtime/"bin/g++.exe",*flags,"-c",HERE/"cygwin_test_stats_shim.cc","-o",shim_object],
            source,buildlogs,label+"-test-statistics-shim-compile",60,True)
        if result[0]:raise RuntimeError("Standalone TEST statistics shim compile failed: "+result[2][-3000:])
        engine=[source/"build"/name for name in ["SimpSolver.o","Solver.o","Options.o","System.o"]]
        result=managed_run([runtime/"bin/g++.exe",*flags,"-o",binary,main_object,*engine,shim_object,"-lz"],
            source,buildlogs,label+"-test-only-GNU-main-link",120,True)
        if result[0]:raise RuntimeError("Standalone TEST Main link failed: "+result[2][-3000:])
    save(out/"object-hashes.json",{str(p):sha(p) for p in (candidate/"build").glob("*.o")})
    frozen_binaries={str(p):sha(p) for p in [immutable_base/"bin/distqldpc.exe",candidate/"bin/distqldpc.exe",*test_main.values()]}
    save(out/"pretest-binary-hashes.json",frozen_binaries)
    for source,label in [(base,"baseline"),(candidate,"candidate")]:
        result=managed_run([runtime/"bin/size.exe",source/"bin/distqldpc.exe",test_main[label]],source,buildlogs,label+"-sections",20,True)
        assert result[0]==0
        result=managed_run([runtime/"bin/bash.exe",source/"scripts/smoke_test.sh",source/"bin/distqldpc.exe"],
                          source,buildlogs,label+"-original-smoke-script",35,True)
        if result[0]:raise RuntimeError("Original smoke script failed: "+result[2][-3000:])
    sys.argv=["run_tier0.py","--baseline-bin",str(immutable_base/"bin/distqldpc.exe"),
              "--candidate-bin",str(candidate/"bin/distqldpc.exe"),"--baseline-maxsat",str(test_main["baseline"]),
              "--candidate-maxsat",str(test_main["candidate"]),"--data-root",str(immutable_base/"data/matrices"),
              "--out",str(out/"tier0"),"--run-assignment",args.run_assignment,"--cygwin"]
    run_tier0.main();summary.update(Tier0="LOCAL_PASS",status="PREPARATORY_COMPLETE")
except BaseException as error:
    summary["reason"]=repr(error)
    summary["traceback"]=traceback.format_exc()
    # Assertions before scientific execution are provenance/harness failures,
    # not fabricated scientific disagreements.
    if (out/"tier0/summary.json").exists():
        summary["Tier0_report"]=json.loads((out/"tier0/summary.json").read_text(encoding="utf-8"))
        if summary["Tier0_report"]["Tier0"]=="REJECT":summary.update(status="REJECT",Tier0="REJECT")
    print("STOP: "+repr(error),flush=True)
finally:
    if window is not None:
        try:
            clean_owned("final-cleanup")
            if initial_identity is not None and "verify_overlay" in globals():
                result=verify_overlay("overlay-after")
                assert result[0]==0,"Overlay immutable verification failed"
            save(out/"job-pids-before-release.json",job_pids())
        except Exception as error:summary["cleanup_failure"]=repr(error)
        # Always attempt restoration, including when owned cleanup fails.
        try:
            summary["cleanup"]=window.close()
            required=["job_limit_released","affinity_restored","sleep_requirement_restored","priority_restored"]
            if not all(summary["cleanup"].get(k) is True for k in required):
                summary["restoration_failure"]="Not all Job/affinity/priority/sleep restoration checks succeeded"
        except Exception as error:summary["restoration_failure"]=repr(error)
    try:
        if initial_identity is not None:
            for name,digest in preimport_hashes.items():assert sha(HERE/name)==digest, "Imported support changed "+name
            for rel,digest in initial_identity["source_hashes"].items():assert sha(candidate/rel)==digest, "Source changed "+rel
            for name,digest in initial_identity["support_hashes"].items():assert sha(HERE/name)==digest, "Support changed "+name
            for name,digest in initial_identity["input_hashes"].items():assert sha(immutable_base/"data/matrices"/name)==digest, "Input changed "+name
            assert sha(helper)==initial_identity["helper_sha256"], "Helper changed"
            assert sha(runtime/"etc/setup/installed.db")==initial_identity["runtime_manifest_sha256"], "Runtime manifest changed"
            for name,digest in initial_identity["runtime_file_hashes"].items():assert sha(runtime/"bin"/name)==digest, "Runtime file changed "+name
            for rel,digest in manifest["files"].items():assert sha(package/rel)==digest, "Immutable package changed "+rel
        for path,digest in frozen_binaries.items():assert sha(path)==digest, "Binary changed "+path
        assert sha(prior02/"INDEPENDENT-COMPATIBILITY-AUDIT.json")==PROBE02_AUDIT_SHA256,"Compatibility audit changed"
    except Exception as error:summary["identity_failure"]=repr(error)
    success=(summary["status"]=="PREPARATORY_COMPLETE" and summary["Tier0"]=="LOCAL_PASS"
             and "cleanup_failure" not in summary and "restoration_failure" not in summary and "identity_failure" not in summary
             and window is not None)
    summary["valid_run"]=success
    if not success and summary["status"]!="REJECT":summary["status"]="INCONCLUSIVE"
    save(out/"summary.json",summary)
    save(out/"SHA256.json",{str(p.relative_to(out)):sha(p) for p in sorted(out.rglob("*"))
         if p.is_file() and "baseline-link-snapshot" not in p.parts and p.name!="SHA256.json"})
    print(json.dumps(summary,indent=2),flush=True)
if not summary["valid_run"]:sys.exit(1)
