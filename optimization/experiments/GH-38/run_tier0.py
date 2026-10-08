"""GH38 correctness checks. Requires an external assigned resource wrapper.
Original Main finite optima allow rc10/SAT or rc20/UNSAT after its failed bound
proof; preserve original rc/status relationship rather than inventing mismatch.
"""
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


def assert_all_bounds(text,oracle):
    """Validate every emitted scientific update, not only its final value."""
    specs={'lb':(r'^c\s+d_lb:\s*(.*?)\s*$',{'-'}),
           'ub':(r'^c\s+d_ub:\s*(.*?)\s*$',{'-'}),
           'd':(r'^c\s+d\s*:\s*(.*?)\s*$',{'UNKNOWN'}),
           'objective':(r'^o(?:\s+(.*?))?\s*$',set())}
    for key,(pattern,sentinels) in specs.items():
        for item in re.findall(pattern,text,re.M):
            if item in sentinels:continue
            assert re.fullmatch(r'\d+',item),('malformed scientific field',key,item)
            value=int(item)
            assert (value<=oracle if key=='lb' else value==oracle if key=='d' else value>=oracle),('unsound scientific field',key,value,oracle)


def main():
    parser=argparse.ArgumentParser()
    for name in ["baseline-bin","candidate-bin","baseline-maxsat","candidate-maxsat","data-root","out"]:
        parser.add_argument("--"+name,type=pathlib.Path,required=True)
    parser.add_argument("--run-assignment",required=True,help="Record hub15 assignment; not a lease or attestation")
    parser.add_argument("--cygwin",action="store_true")
    args=parser.parse_args()
    out=args.out.resolve();out.mkdir(exist_ok=False,parents=True)
    versions={"baseline":args.baseline_bin.resolve(),"candidate":args.candidate_bin.resolve()}
    maxsat_versions={"baseline":args.baseline_maxsat.resolve(),"candidate":args.candidate_maxsat.resolve()}
    summary=dict(decision="INCONCLUSIVE",Tier0="NOT_RUN",performance="NOT_MEASURED",
                 assignment=args.run_assignment,hosted_cross_repo="REQUIRED_PENDING")
    save(out/"identity.json",dict(assignment=args.run_assignment,binaries={k:sha(v) for k,v in versions.items()},
                                maxsat_binaries={k:sha(v) for k,v in maxsat_versions.items()}))
    def execute(command,label,cwd,timeout=20):
        return run(command,cwd,out,label,timeout,args.cygwin)
    try:
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
                    assert_all_bounds(result[1],exact)
                    wcnf=out/(label+".wcnf")
                    result=execute([binary,"-"+mode,"-dump-only","-dump-wcnf="+str(wcnf),out/stem],label+"-dump",binary.parent.parent)
                    assert result[0]==0,result
                    dumps.append(wcnf.read_bytes())
                assert dumps[0]==dumps[1],"Initial CNF changed"
            checks.append(dict(fixture=stem,oracle_distance=exact,initial_CNF_identical=True))
        # Independent exhaustive oracle for tiny supported unweighted PMS.
        # Main.cc's standalone result format uses "optimal:", not DistQLDPC's o line.
        pms=[("pms-zero",2,[[-1,2]],[[1],[2]]),
             ("pms-conflict",2,[[-1,-2]],[[1],[2]]),
             ("pms-triangle",3,[[-1,-2],[-1,-3],[-2,-3]],[[1],[2],[3]]),
             ("pms-cycle",4,[[-1,-2],[-2,-3],[-3,-4],[-4,-1]],[[1],[2],[3],[4]])]
        def satisfied(clause,assignment):
            return any(bool(assignment & (1 << (abs(lit)-1))) == (lit>0) for lit in clause)
        for stem,n,hard,soft in pms:
            exact=min(sum(not satisfied(c,a) for c in soft) for a in range(1<<n)
                      if all(satisfied(c,a) for c in hard))
            top=len(soft)+1;wcnf=out/(stem+".wcnf")
            wcnf.write_text("p wcnf %d %d %d\n"%(n,len(hard)+len(soft),top)+
                "".join(str(weight)+" "+" ".join(map(str,c))+" 0\n"
                        for weight,clauses in [(top,hard),(1,soft)] for c in clauses),encoding="utf-8")
            scientific=[]
            for version,binary in maxsat_versions.items():
                result=execute([binary,"-verb=1",wcnf],stem+"-"+version,binary.parent.parent)
                # Solver.cc emits comma-delimited optimal fields. Inspect every
                # occurrence, including malformed/negative values, not a numeric subset.
                raw_values=re.findall(r"optimal:\s*([^,\r\n]*)",result[1])
                assert raw_values and all(re.fullmatch(r'\d+',v.strip()) for v in raw_values),result
                values=[int(v.strip()) for v in raw_values]
                status=[v.strip() for v in re.findall(r"^s\s+(.+)$",result[1],re.M)]
                expected_status={10:'SATISFIABLE',20:'UNSATISFIABLE'}
                assert result[0] in expected_status and status==[expected_status[result[0]]],result
                # Finite optimum alone does not force original Main rc10:
                # its final failed-bound proof can report rc20/UNSATISFIABLE.
                assert all(v==exact for v in values),result
                scientific.append((result[0],status,values))
            assert scientific[0]==scientific[1],"Standalone result/exit semantics differ"
            checks.append(dict(fixture=stem,oracle_cost=exact,standalone_semantics_identical=True))
        # Existing integration help/smoke case plus a stable long-instance timeout.
        for version,binary in versions.items():
            result=execute([binary,"--help"],"help-"+version,binary.parent.parent)
            assert result[0]==0 and "Usage:" in result[1],result
            for mode in ["no-card","card-mto"]:
                result=execute([binary,"-"+mode,"-cpu-lim=20",args.data_root.resolve()/"LP_34_20_2"],
                               "smoke-"+version+"-"+mode,binary.parent.parent,35)
                assert result[0]==0 and semantic(result[1])==(2,2,2,2),result
                assert_all_bounds(result[1],2)
                result=execute([binary,"-"+mode,"-cpu-lim=1",args.data_root.resolve()/"LP_340_56_8"],
                               "timeout-"+version+"-"+mode,binary.parent.parent)
                assert result[0]==1 and "s UNKNOWN" in result[1] and "c status: TIMEOUT" in result[1],result
                assert semantic(result[1])[:2]==(None,None),result
                assert_all_bounds(result[1],8)
                assert all(int(v)<=8 for v in re.findall(r"^c\s+d_lb:\s*(\d+)",result[1],re.M)),result
                assert all(int(v)>=8 for v in re.findall(r"^c\s+d_ub:\s*(\d+)",result[1],re.M)),result
        summary.update(Tier0="LOCAL_PASS",checks=checks,reason="CSS oracle, CNF, smoke, timeout and standalone MaxSAT oracle checks")
    except subprocess.TimeoutExpired as error:
        summary.update(Tier0="INCONCLUSIVE",reason="External watchdog interruption; no scientific mismatch established: "+str(error))
        raise
    except AssertionError as error:
        summary.update(decision="REJECT",Tier0="REJECT",reason=str(error))
        raise
    except Exception as error:
        summary.update(reason=repr(error))
        raise
    finally:
        save(out/"summary.json",summary);manifest(out)


if __name__=="__main__":main()
