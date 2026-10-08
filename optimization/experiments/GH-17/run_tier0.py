"""GH17 correctness checks. Requires an external assigned resource wrapper."""
import argparse
import itertools
import pathlib
import re
import subprocess
from runner_common import run,save,manifest,sha


def semantic(text):
    patterns=[r"^c\s+d\s*:\s*(\d+)\s*$",r"^o\s+(-?\d+)\s*$",
              r"^c\s+d_lb:\s*(\d+)\s*$",r"^c\s+d_ub:\s*(\d+)\s*$"]
    return tuple(int(values[-1]) if values else None
                 for values in (re.findall(pattern,text,re.M) for pattern in patterns))


def span(rows):
    values={0}
    for row in rows: values |= {value^row for value in values}
    return values


def main():
    parser=argparse.ArgumentParser()
    for name in ["baseline-bin","candidate-bin","baseline-probe","candidate-probe","data-root","out"]:
        parser.add_argument("--"+name,type=pathlib.Path,required=True)
    parser.add_argument("--run-assignment",required=True,help="Record hub15 assignment; not a lease or attestation")
    parser.add_argument("--cygwin",action="store_true")
    args=parser.parse_args()
    out=args.out.resolve();out.mkdir(exist_ok=False,parents=True)
    versions={"baseline":args.baseline_bin.resolve(),"candidate":args.candidate_bin.resolve()}
    summary=dict(decision="INCONCLUSIVE",Tier0="NOT_RUN",performance="NOT_MEASURED",
                 assignment=args.run_assignment,hosted_cross_repo="REQUIRED_PENDING")
    save(out/"identity.json",dict(assignment=args.run_assignment,binaries={k:sha(v) for k,v in versions.items()},
                                probes={"baseline":sha(args.baseline_probe),"candidate":sha(args.candidate_probe)}))
    def execute(command,label,cwd,timeout=20):
        return run(command,cwd,out,label,timeout,args.cygwin)
    try:
        traces=[]
        for version,probe in [("baseline",args.baseline_probe),("candidate",args.candidate_probe)]:
            result=execute([probe.resolve()],"core-trace-"+version,probe.resolve().parent,120)
            assert result[0]==0,result
            traces.append((out/("core-trace-"+version+".stdout")).read_bytes())
        assert traces[0]==traces[1],"Production core-state traces differ"
        fixtures=[("css1",1,[0],[0],[1],[1]),("css4",4,[15],[15],[3,5],[3,5]),
                  ("css5",5,[3],[3],[12,24,28],[12,24,28])]
        checks=[]
        for stem,n,hx,hz,gx,gz in fixtures:
            exact=min((x|z).bit_count() for x,z in itertools.product(range(1<<n),repeat=2)
                      if all((h&z).bit_count()%2==0 for h in hx)
                      and all((h&x).bit_count()%2==0 for h in hz)
                      and (x not in span(hx) or z not in span(hz)))
            for suffix,rows in zip(["Hx","Hz","Gx","Gz"],[hx,hz,gx,gz]):
                (out/(stem+"_"+suffix+".txt")).write_text(
                    "".join(" ".join(str((row>>i)&1) for i in range(n))+"\n" for row in rows),encoding="utf-8")
            for mode in ["no-card","card-mto"]:
                dumps=[]
                for version,binary in versions.items():
                    label=stem+"-"+mode+"-"+version
                    result=execute([binary,"-v","-cpu-lim=5","-"+mode,out/stem],label,binary.parent.parent)
                    assert result[0]==0 and semantic(result[1])==(exact,exact,exact,exact),result
                    wcnf=out/(label+".wcnf")
                    result=execute([binary,"-dump-only","-dump-wcnf="+str(wcnf),out/stem],label+"-dump",binary.parent.parent)
                    assert result[0]==0,result
                    dumps.append(wcnf.read_bytes())
                assert dumps[0]==dumps[1],"Initial CNF changed"
            checks.append(dict(fixture=stem,oracle_distance=exact,initial_CNF_identical=True))
        # Existing integration help/smoke case plus a stable long-instance timeout.
        for version,binary in versions.items():
            result=execute([binary,"--help"],"help-"+version,binary.parent.parent)
            assert result[0]==0 and "Usage:" in result[1],result
            for mode in ["no-card","card-mto"]:
                result=execute([binary,"-"+mode,"-cpu-lim=20",args.data_root.resolve()/"LP_34_20_2"],
                               "smoke-"+version+"-"+mode,binary.parent.parent,35)
                assert result[0]==0 and semantic(result[1])==(2,2,2,2),result
                result=execute([binary,"-"+mode,"-cpu-lim=1",args.data_root.resolve()/"LP_340_56_8"],
                               "timeout-"+version+"-"+mode,binary.parent.parent)
                assert result[0]==1 and "s UNKNOWN" in result[1] and "c status: TIMEOUT" in result[1],result
                assert semantic(result[1])[:2]==(None,None),result
                assert all(int(v)<=8 for v in re.findall(r"^c\s+d_lb:\s*(\d+)",result[1],re.M)),result
                assert all(int(v)>=8 for v in re.findall(r"^c\s+d_ub:\s*(\d+)",result[1],re.M)),result
        summary.update(Tier0="LOCAL_PASS",checks=checks,reason="Core-state equivalence, CSS oracle, CNF, smoke and timeout checks")
    except (AssertionError,subprocess.TimeoutExpired) as error:
        summary.update(decision="REJECT",Tier0="REJECT",reason=str(error))
        raise
    except Exception as error:
        summary.update(reason=repr(error))
        raise
    finally:
        save(out/"summary.json",summary);manifest(out)


if __name__=="__main__":main()
