"""Assigned GH17 Windows Tier0/counters. No performance timings or auto queue.

Reuses the reviewed temporary one-CPU Windows Job/capacity helper. Replaces
runner_common.run with file-backed bounded supervision; no communicate() pipe
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
import subprocess
import sys
import time

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
ap=argparse.ArgumentParser();ap.add_argument("--out",type=Path,required=True)
ap.add_argument("--run-assignment",required=True)
args=ap.parse_args()
assert args.run_assignment=="https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6062543626"
out=args.out.resolve();out.mkdir(parents=True,exist_ok=False)
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(path,value):Path(path).write_text(json.dumps(value,indent=2),encoding="utf-8",newline="\n")
runtime=ROOT/"E004-windows-runtime/cygwin"
package=ROOT/"E004-windows-tier2-02/E004-server-package"
base=package/"baseline"
candidate=ROOT/"GH17-SCRATCH"
helper=ROOT/"DistQLDPC/optimization/experiments/E004/windows_cpu_window.py"
spec=importlib.util.spec_from_file_location("gh17_window",helper)
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
sys.path.insert(0,str(HERE))
import runner_common
import run_tier0
import run_allocation_diagnostic

k=module.k
k.QueryInformationJobObject.argtypes=[C.c_void_p,C.c_int,C.c_void_p,C.c_ulong,C.POINTER(C.c_ulong)]
k.QueryInformationJobObject.restype=C.c_int
window=None;current=None;resources=[];descendants=[];command_index=0
summary=dict(status="INCONCLUSIVE",Tier0="NOT_RUN",diagnostic="NOT_RUN",performance="NOT_MEASURED",
             candidate="191de6849357574c830e14992a7afe9615dad320",assignment=args.run_assignment)

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
    global current,command_index
    command_index+=1;target=Path(target);target.mkdir(exist_ok=True,parents=True)
    argv=list(map(str,argv))
    if cygwin:argv=[argv[0]]+[runner_common.cygpath(v) for v in argv[1:]]
    window.previous=module.ticks();time.sleep(2.1);observe(label+"-preflight")
    command=dict(argv=argv,cwd=str(cwd),timeout_sec=timeout,assignment=args.run_assignment)
    reason=None;start=time.monotonic();last=start;sampled=False
    with (target/(label+".stdout")).open("wb") as stdout,(target/(label+".stderr")).open("wb") as stderr:
        try:
            current=subprocess.Popen(argv,cwd=cwd,stdout=stdout,stderr=stderr)
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
    manifest=json.loads((package/"manifest.json").read_text(encoding="utf-8"))
    for relative,digest in manifest["files"].items():assert sha(package/relative)==digest,relative
    assert sha(base/"bin/distqldpc.exe")=="22e398cc7558c2a04d5f24bd6db3030ce552c752622027fc2657eff7c1bd1815"
    assert (runtime/"etc/setup/installed.db").read_bytes()==(ROOT/"DistQLDPC/optimization/experiments/E004/raw/windows-setup-2026-10-08/installed.db").read_bytes()
    head=subprocess.check_output(["git","-C",str(candidate),"rev-parse","HEAD"],text=True).strip()
    assert head==summary["candidate"],head
    for relative in ["src/solver/Solver.cc","src/solver/Solver.h","src/core/distqldpc.cc"]:
        git_bytes=subprocess.check_output(["git","-C",str(candidate),"show",head+":"+relative])
        assert (candidate/relative).read_bytes().replace(b"\r\n",b"\n")==git_bytes.replace(b"\r\n",b"\n"),relative
    # Working-tree normalization agrees with the Git LF Makefile; engine source
    # bytes remain untouched. It prevents shell CRLF commands on Cygwin.
    for relative in ["Makefile","scripts/smoke_test.sh"]:
        p=candidate/relative;p.write_bytes(p.read_bytes().replace(b"\r\n",b"\n"))
    os.environ["PATH"]=str(runtime/"bin")+os.pathsep+os.environ["PATH"]
    os.environ.update(LC_ALL="C",OMP_NUM_THREADS="1",OPENBLAS_NUM_THREADS="1",MKL_NUM_THREADS="1")
    window=module.Window(True,0x8000)
    window.previous=module.ticks();time.sleep(2.1);observe("assignment-preflight")
    save(out/"identity.json",dict(candidate=head,baseline=manifest["baseline"],assignment=args.run_assignment,
         baseline_manifest_sha256=sha(package/"manifest.json"),baseline_binary_sha256=sha(base/"bin/distqldpc.exe"),
         runner_sha256=sha(__file__),helper_sha256=sha(helper),test_source_sha256=sha(HERE/"test_core_scratch.cc"),
         runtime_manifest_sha256=sha(runtime/"etc/setup/installed.db"),
         selection=window.selection,source_hashes={r:sha(candidate/r) for r in ["src/solver/Solver.cc","src/solver/Solver.h","src/core/distqldpc.cc","Makefile"]},
         support_hashes={p.name:sha(p) for p in HERE.glob("*.py")},
         object_hashes={str(p.relative_to(base)):sha(p) for p in (base/"build").glob("*.o")},
         input_hashes={p.name:sha(p) for stem in ["LP_34_20_2","LP_136_32_4","LP_340_56_8"] for p in (base/"data/matrices").glob(stem+"_*.txt")}))
    runner_common.run=managed_run;run_tier0.run=managed_run;run_allocation_diagnostic.run=managed_run
    buildlogs=out/"build";buildlogs.mkdir()
    result=managed_run([runtime/"bin/g++.exe","--version"],candidate,buildlogs,"compiler",20)
    assert result[0]==0 and "14.4" in result[1],result
    result=managed_run([runtime/"bin/make.exe","-j1","bin/distqldpc"],candidate,buildlogs,"candidate-build",300,True)
    if result[0]:raise RuntimeError("Candidate build failed: "+result[2][-3000:])
    for version,source,define in [("baseline",base,["-DGH17_BASELINE"]),("candidate",candidate,[])]:
        objects=[source/"build"/(name+".o") for name in ["SimpSolver","Solver","Options","System"]]
        argv=[runtime/"bin/g++.exe","-Isrc/solver","-O2","-std=gnu++11"]+define+[HERE/"test_core_scratch.cc"]+objects+["-lz","-o",out/(version+"-probe.exe")]
        result=managed_run(argv,source,buildlogs,version+"-probe-build",120,True)
        if result[0]:raise RuntimeError("Probe build failed: "+result[2][-3000:])
    sys.argv=["run_tier0.py","--baseline-bin",str(base/"bin/distqldpc.exe"),"--candidate-bin",str(candidate/"bin/distqldpc.exe"),
              "--baseline-probe",str(out/"baseline-probe.exe"),"--candidate-probe",str(out/"candidate-probe.exe"),
              "--data-root",str(base/"data/matrices"),"--out",str(out/"tier0"),"--run-assignment",args.run_assignment,"--cygwin"]
    run_tier0.main();summary["Tier0"]="LOCAL_PASS"
    result=managed_run([sys.executable,HERE/"prepare_diagnostic.py","--source",base,"--out",out/"diagnostic-baseline"],
                       candidate,buildlogs,"diagnostic-prepare",30)
    if result[0]:raise RuntimeError("Diagnostic preparation failed: "+result[2])
    diagnostic=out/"diagnostic-baseline"
    for relative in ["Makefile","scripts/smoke_test.sh"]:
        p=diagnostic/relative;p.write_bytes(p.read_bytes().replace(b"\r\n",b"\n"))
    result=managed_run([runtime/"bin/make.exe","-j1","bin/distqldpc"],diagnostic,buildlogs,"diagnostic-build",300,True)
    if result[0]:raise RuntimeError("Diagnostic build failed: "+result[2][-3000:])
    sys.argv=["run_allocation_diagnostic.py","--binary",str(diagnostic/"bin/distqldpc.exe"),"--data-root",str(base/"data/matrices"),
              "--out",str(out/"allocation"),"--run-assignment",args.run_assignment,"--cygwin"]
    run_allocation_diagnostic.main()
    result=json.loads((out/"allocation/summary.json").read_text(encoding="utf-8"))
    summary.update(status="PREPARATORY_COMPLETE",diagnostic=result)
except BaseException as error:
    summary["reason"]=repr(error)
    if isinstance(error,AssertionError):summary.update(status="REJECT",Tier0="REJECT")
    if (out/"tier0/summary.json").exists():summary["Tier0_report"]=json.loads((out/"tier0/summary.json").read_text(encoding="utf-8"))
    print("STOP: "+repr(error),flush=True)
finally:
    if window is not None:
        try:
            clean_owned("final-cleanup")
            save(out/"job-pids-before-release.json",job_pids())
            summary["cleanup"]=window.close()
        except Exception as error:summary["cleanup_failure"]=repr(error)
    save(out/"summary.json",summary)
    # Exclude fresh diagnostic build/source from the raw manifest to avoid
    # disguising it as the production candidate; identify separately below.
    if (out/"diagnostic-baseline/src/solver/Solver.cc").exists():
        save(out/"diagnostic-source-identity.json",{str(p.relative_to(out/"diagnostic-baseline")):sha(p) for p in
             [out/"diagnostic-baseline/src/solver/Solver.cc",out/"diagnostic-baseline/src/solver/GH17AllocationDiagnostic.h",out/"diagnostic-baseline/bin/distqldpc.exe"] if p.exists()})
    save(out/"SHA256.json",{str(p.relative_to(out)):sha(p) for p in sorted(out.rglob("*"))
         if p.is_file() and "diagnostic-baseline" not in p.parts and p.name!="SHA256.json"})
    print(json.dumps(summary,indent=2),flush=True)
