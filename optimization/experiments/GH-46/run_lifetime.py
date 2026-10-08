"""Bounded actual-path fixtures. The assigned supervisor supplies every process.

No solver runs on import. This is not a timing driver.
"""
import json
from pathlib import Path
import re
import run_tier0

def standalone(result,exact):
    rc,text,_=result
    values=re.findall(r"optimal:\s*([^,\r\n]*)",text)
    assert values and all(re.fullmatch(r"\d+",x.strip()) for x in values),"SCIENCE malformed/missing optimum"
    assert all(int(x.strip())==exact for x in values),"SCIENCE wrong oracle optimum"
    statuses=[x.strip() for x in re.findall(r"^s\s+(.*?)\s*$",text,re.M)]
    assert rc in (10,20) and statuses==[{10:"SATISFIABLE",20:"UNSATISFIABLE"}[rc]],"SCIENCE return/status semantics"
    return rc,statuses,[int(x.strip()) for x in values]

def counters(error,require_complete=True):
    latest={}; previous={}
    for line in error.splitlines():
        if not line.startswith("GH46_ALLOCATION "):continue
        row=json.loads(line[len("GH46_ALLOCATION "):])
        assert row.get("failed") is False,"COUNTER observer failed"
        assert isinstance(row.get("complete"),bool),"COUNTER completion marker"
        for key in ["solver_id","calls","populated_calls","actual_growths","predicted_reuse_growths",
                    "actual_requested_bytes","predicted_requested_bytes","pushes","peak_size","peak_capacity",
                    "predicted_capacity","element_bytes","entries","ub_transitions","resets","uip_resets"]:
            assert type(row.get(key)) is int and row[key]>=0,"COUNTER malformed "+key
        sid=row["solver_id"]
        if sid in previous:
            for key in ["calls","actual_growths","predicted_reuse_growths","pushes"]:
                assert row[key]>=previous[sid][key],"COUNTER nonmonotone cumulative rows"
        previous[sid]=row;latest[sid]=row
    if require_complete:
        assert latest and all(row["complete"] for row in latest.values()),"COUNTER no genuine complete final report"
    return latest

def state(error):
    lines=[]
    for line in error.splitlines():
        if line.startswith(("GH46_STATE ","GH46_RESET ","GH46_BUFFER_ENTRY ")):
            if line.startswith("GH46_BUFFER_ENTRY "):
                assert re.fullmatch(r'GH46_BUFFER_ENTRY call=\d+ size=0',line),"SCIENCE scratch not logically empty on entry"
            lines.append(line)
        elif line.startswith("GH46_ALLOCATION "):continue
        elif line.strip():raise RuntimeError("Unexpected observer stderr: "+line[:200])
    return lines

def run(execute,sources,observer_main,production_main,observer_app,oracles,tier0,out):
    rows=json.loads((oracles/"ORACLES.json").read_text())
    report={"status":"INCONCLUSIVE","fixtures":[],"science":"NOT_RUN","lifetime":"NOT_RUN"}
    sufficient=False
    for row in rows:
        results={};trace={};count={}
        for variant in ("baseline","candidate"):
            original=execute([production_main[variant],"-verb=1",oracles/row["file"]],
                             variant+"-original-"+row["file"],sources[variant],20)
            result=execute([observer_main[variant],"-verb=1",oracles/row["file"]],
                           variant+"-observer-"+row["file"],sources[variant],20)
            results[variant]=standalone(result,row["optimum"])
            assert results[variant]==standalone(original,row["optimum"]),"SCIENCE observer changed standalone semantics"
            trace[variant]=state(result[2]);count[variant]=counters(result[2],False)
        assert results["baseline"]==results["candidate"],"SCIENCE actual source result/status differs"
        assert trace["baseline"]==trace["candidate"],"SCIENCE lookahead relevant state/rollback differs"
        assert count["baseline"].keys()==count["candidate"].keys(),"COUNTER solver lifetime differs"
        for sid,b in count["baseline"].items():
            c=count["candidate"][sid]
            assert b["complete"] and c["complete"],"COUNTER fixture report incomplete"
            assert b["calls"]==c["calls"] and b["pushes"]==c["pushes"],"COUNTER actual logical sequence differs"
            assert b["predicted_reuse_growths"]==c["actual_growths"],"COUNTER actual reuse growth count disagrees with simulation"
            assert b["predicted_requested_bytes"]==c["actual_requested_bytes"],"COUNTER actual reuse request bytes disagree"
            assert b["predicted_capacity"]==c["peak_capacity"],"COUNTER actual reuse capacity disagrees"
            meaningful_calls=set()
            for line in trace["baseline"]:
                m=re.fullmatch(r'GH46_RESET call=(\d+) core=-?\d+ selected=1 uip=(\d+) size=(\d+) .*',line)
                if m and (int(m[2])==1 or int(m[3])>=2):meaningful_calls.add(int(m[1]))
            if b["calls"]>=2 and b["populated_calls"]>=2 and b["ub_transitions"]>=1 and b["resets"]>=2 and len(meaningful_calls)>=2:
                sufficient=True
        report["fixtures"].append(dict(input=row,results=results,counters=count,state_rows=len(trace["baseline"])))
    # Actual application CLI supplies mode selection; original Main retains BOTH.
    for stem,exact in [("css1",1),("css4",2),("css5",1)]:
        for mode in ("no-card","card-both","card-sinz","card-mto","card-both-force"):
            traces=[]
            for variant in ("baseline","candidate"):
                result=execute([observer_app[variant],"-v","-"+mode,"-cpu-lim=5",tier0/stem],
                               variant+"-css-state-"+stem+"-"+mode,sources[variant],20)
                assert result[0]==0 and run_tier0.semantic(result[1])==(exact,exact,exact,exact),"SCIENCE instrumented CSS oracle"
                run_tier0.assert_all_bounds(result[1],exact);run_tier0.assert_status(result[1])
                traces.append(state(result[2]))
            assert traces[0]==traces[1],"SCIENCE actual CSS mode lookahead relevant state differs"
            report["fixtures"].append(dict(css=stem,mode=mode,state_rows=len(traces[0]),oracle=exact))
    report.update(science="PASS",coverage_sufficient=sufficient)
    if not sufficient:
        (out/"lifetime-report.json").write_text(json.dumps(report,indent=2)+"\n")
        raise RuntimeError("COVERAGE_GAP: bounded fixtures did not exercise repeated populated lookahead across UB changes")
    report.update(status="PASS",lifetime="PASS")
    (out/"lifetime-report.json").write_text(json.dumps(report,indent=2)+"\n")
    return report
