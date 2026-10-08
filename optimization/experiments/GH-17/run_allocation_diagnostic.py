"""Four bounded baseline-only calls; counters are not performance timings."""
import argparse
import json
import pathlib
import re
from runner_common import run,save,manifest,sha
from run_tier0 import semantic


def main():
    parser=argparse.ArgumentParser()
    for name in ["binary","data-root","out"]:parser.add_argument("--"+name,type=pathlib.Path,required=True)
    parser.add_argument("--run-assignment",required=True,help="Hub assignment recorded, not a CPU lease")
    parser.add_argument("--cygwin",action="store_true")
    args=parser.parse_args();out=args.out.resolve();out.mkdir(parents=True,exist_ok=False)
    binary=args.binary.resolve()
    summary=dict(state="INCONCLUSIVE",scientific="NOT_RUN",performance="NOT_MEASURED",assignment=args.run_assignment,
                 binary_sha256=sha(binary),instrumentation="Separate original-baseline counter-only snapshot")
    rows=[]
    try:
        for stem,distance in [("LP_34_20_2",2),("LP_136_32_4",4)]:
            for mode in ["no-card","card-mto"]:
                label=stem+"-"+mode
                rc,stdout,stderr=run([binary,"-v","-cpu-lim=120","-"+mode,args.data_root.resolve()/stem],
                                     binary.parent.parent,out,label,135,args.cygwin)
                assert rc==0 and semantic(stdout)==(distance,distance,distance,distance),(rc,stdout,stderr)
                counters=[json.loads(line[len("GH17_ALLOCATION "):]) for line in stderr.splitlines()
                          if line.startswith("GH17_ALLOCATION ")]
                if not counters:
                    raise RuntimeError("Missing diagnostic; no invented zero-count result")
                for counter in counters:
                    if counter["baseline_allocations"]<counter["predicted_reuse_allocations"]:
                        raise RuntimeError("Invalid allocation replay: "+repr(counter))
                rows.append(dict(case=stem,mode=mode,counters=counters))
        actual=sum(c["baseline_allocations"] for r in rows for c in r["counters"])
        predicted=sum(c["predicted_reuse_allocations"] for r in rows for c in r["counters"])
        summary.update(state="DIAGNOSTIC_COMPLETE",scientific="PASS",baseline_allocations=actual,
                       predicted_reuse_allocations=predicted,predicted_saved_allocations=actual-predicted,
                       mechanism_opportunity="PRESENT" if actual>predicted else "ABSENT_ON_DIAGNOSTIC_CASES",
                       reason="Counts only; whole-solve time share not established")
    except AssertionError as error:
        summary.update(state="REJECT",scientific="REJECT",reason=str(error));raise
    except Exception as error:
        summary.update(reason=repr(error));raise
    finally:
        save(out/"counters.json",rows);save(out/"summary.json",summary);manifest(out)


if __name__=="__main__":main()
