"""Prepare a NEW test-only snapshot; never build or execute anything.

Only pinned baseline or GH46 production source is accepted. Original files outside
the enumerated observer edits are copied unchanged. Production checkout is untouched.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

BASELINE="24572d6d09cce9a4a5faa58300a89e0feba9da6a"
CANDIDATE="51509debe2e09a44bc3accdaf1b1857a6c30e53f"
FILES=("src/solver/Solver.cc","src/solver/Solver.h","src/solver/mtl/Vec.h","src/solver/Main.cc")

def replace_once(data,old,new):
    if data.count(old)!=1:
        raise ValueError(f"Expected exactly one observer fragment: {old!r}")
    return data.replace(old,new,1)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--source",type=Path,required=True)
    ap.add_argument("--out",type=Path,required=True)
    ap.add_argument("--variant",choices=("baseline","candidate"),required=True)
    ap.add_argument("--trace",action="store_true",help="Also prepare relevant state observer for correctness fixtures")
    args=ap.parse_args()
    source=args.source.resolve(); out=args.out.resolve()
    if out.exists() or source==out or source in out.parents or out in source.parents:
        raise ValueError("Destination must be new and outside the source")
    revision=BASELINE if args.variant=="baseline" else CANDIDATE
    original={}
    for name in FILES:
        expected=subprocess.check_output(["git","show",revision+":"+name],cwd=Path(__file__).parents[3])
        actual=(source/name).read_bytes()
        if actual.replace(b"\r\n",b"\n")!=expected.replace(b"\r\n",b"\n"):
            raise ValueError("Pinned source mismatch: "+name)
        original[name]=actual
    # No overwrite, source mutation, alternate allocator or semantic code changes.
    out.mkdir()
    shutil.copytree(source/"src",out/"src")
    shutil.copyfile(source/"Makefile",out/"Makefile")
    modified={}
    for name,data in original.items():
        modified[name]=data.replace(b"\r\n",b"\n")
    cc=modified[FILES[0]]; hh=modified[FILES[1]]; vv=modified[FILES[2]]; mm=modified[FILES[3]]
    hh=replace_once(hh,b"protected:\n",b"protected:\n    GH46AllocationCounts gh46_allocation_counts; // test-only observer\n")
    hh=replace_once(hh,b"    uint64_t getLastOptimalCost() const { return lastOptimalCost; }",
                    b"    uint64_t getLastOptimalCost() const { return lastOptimalCost; }\n"
                    b"    void gh46_report_counts() const { gh46_allocation_counts.dump(true); } // test-only final report")
    mm=replace_once(mm,b"        exit(ret == l_True ? 10 : ret == l_False ? 20 : 0);",
                    b"        S.gh46_report_counts(); // test-only: original NDEBUG exit skips destructors\n"
                    b"        exit(ret == l_True ? 10 : ret == l_False ? 20 : 0);")
    vv=replace_once(vv,b'#include "mtl/XAlloc.h"',b'#include "mtl/XAlloc.h"\n#include "../GH46AllocationDiagnostic.h"')
    vv=replace_once(vv,b"new (&data[sz]) T(); sz++;",b"new (&data[sz]) T(); sz++; gh46_observe_push(this,sz,sizeof(T));")
    vv=replace_once(vv,b"if (sz == cap) capacity(sz+1); data[sz++] = elem;",
                    b"if (sz == cap) capacity(sz+1); data[sz++] = elem; gh46_observe_push(this,sz,sizeof(T));")
    # push_ is not used by the selected vector in the pinned source. Observe it
    # nevertheless so a later support coverage assertion cannot silently miss it.
    vv=replace_once(vv,b"assert(sz < cap); data[sz++] = elem;",b"assert(sz < cap); data[sz++] = elem; gh46_observe_push(this,sz,sizeof(T));")
    vv=replace_once(vv,b"    int add = imax(",b"    int gh46_oldcap=cap;\n    int add = imax(")
    vv=replace_once(vv,b"        throw OutOfMemoryException();\n }",b"        throw OutOfMemoryException();\n    gh46_observe_growth(this,gh46_oldcap,cap,sizeof(T));\n }")
    marker=b"  vec<Lit> out_learnt;" if args.variant=="baseline" else b"  out_learnt.clear();\n#ifdef printTestedVar"
    replacement=(marker+b"\n  GH46AllocationScope gh46_alloc(gh46_allocation_counts,&out_learnt);") if args.variant=="baseline" else b"  out_learnt.clear();\n  GH46AllocationScope gh46_alloc(gh46_allocation_counts,&out_learnt);\n#ifdef printTestedVar"
    cc=replace_once(cc,marker,replacement)
    if args.trace:
        hh=replace_once(hh,b"protected:\n",b"protected:\n    friend struct GH46TraceSnapshot;\n    friend struct GH46TraceScope;\n")
        cc=replace_once(cc,b'#include "Solver.h"',b'#include "Solver.h"\n#include "GH46StateObserver.h"')
        # Restrict instrumentation to the actual selected function and its actual
        # explanation helper, preserving all algorithmic statements and ordering.
        start=cc.index(b"bool Solver::lookahead() {")
        end=cc.index(b"\nvoid Solver::addHardClausesForSoftClauses",start)
        body=cc[start:end]
        # Stop precisely at this function's closing brace, before any next code.
        # Baseline's commented braces make lexical brace scanning unsuitable.
        # Its final original return/end marker is unique inside this function.
        final=b"  return true;\n}\n"
        finish=body.index(final)+len(final)
        body=body[:finish]
        body=replace_once(body,b"bool Solver::lookahead() {",b"bool Solver::lookahead() {\n  GH46TraceScope gh46_trace(*this);")
        body=replace_once(body,b"  int nbIsets=0;",b"  int nbIsets=0;\n  gh46_trace.substantive=true;")
        body=replace_once(body,b"  GH46AllocationScope gh46_alloc(gh46_allocation_counts,&out_learnt);",
                          b"  GH46AllocationScope gh46_alloc(gh46_allocation_counts,&out_learnt);\n"
                          b"  GH46TraceSnapshot::buffer_entry(*this,out_learnt);")
        import re
        body=re.sub(rb"(?m)^(\s*)return false;",rb"\1gh46_trace.result=false; return false;",body)
        cc=cc[:start]+body+cc[start+finish:]
        helper_start=cc.index(b"void Solver::lookbackResetTrail(")
        helper_end=cc.index(b"\nvoid Solver::bumpConflVars()",helper_start)
        helper_body=cc[helper_start:helper_end]
        helper_body=replace_once(helper_body,b"  int pathC=0;",b"  bool gh46_uip=false;\n  CRef gh46_initial_confl=confl;\n  int pathC=0;")
        helper_body=replace_once(helper_body,b"out_learnt[0] = ~p;",b"out_learnt[0] = ~p; gh46_uip=true;")
        helper_body=replace_once(helper_body,b"      seen[var(out_learnt[i])] = 0;\n}",b"      seen[var(out_learnt[i])] = 0;\n  GH46TraceSnapshot::reset(*this,out_learnt,gh46_uip,nbIsets,gh46_initial_confl,falseVar,last);\n}")
        cc=cc[:helper_start]+helper_body+cc[helper_end:]
    for name,data in zip(FILES,(cc,hh,vv,mm)):
        (out/name).write_bytes(data)
    helper=Path(__file__).with_name("allocation_diagnostic.h")
    shutil.copyfile(helper,out/"src/solver/GH46AllocationDiagnostic.h")
    if args.trace:
        shutil.copyfile(Path(__file__).with_name("state_observer.h"),out/"src/solver/GH46StateObserver.h")
    all_hashes={str(p.relative_to(out)):hashlib.sha256(p.read_bytes()).hexdigest()
                for p in sorted(out.rglob("*")) if p.is_file()}
    report={"variant":args.variant,"trace_enabled_support":args.trace,"source_revision":revision,
            "input_hashes":{n:hashlib.sha256(d).hexdigest() for n,d in original.items()},
            "observer_sha256":hashlib.sha256(helper.read_bytes()).hexdigest(),
            "snapshot_hashes":all_hashes,"production_mutated":False,
            "built_or_run":False}
    (out/"GH46-observer-identity.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"destination":str(out),"variant":args.variant,"built_or_run":False}))

if __name__=="__main__": main()
