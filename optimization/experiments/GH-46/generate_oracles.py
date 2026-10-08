"""Generate only small test WCNFs with exhaustive assignment oracles; no solver.

Run under the assigned Tier0 Job, not during another agent's CPU allocation.
These are new test inputs, not changes to benchmark matrices or ground truth.
"""
import argparse
import hashlib
import itertools
import json
from pathlib import Path
import random

def literal(lit,mask):
    value=bool(mask & (1<<(abs(lit)-1)))
    return value if lit>0 else not value

def oracle(n,hard,soft):
    feasible=[]
    for mask in range(1<<n):
        if all(any(literal(x,mask) for x in c) for c in hard):
            feasible.append((sum(not any(literal(x,mask) for x in c) for c in soft),mask))
    if not feasible:
        raise ValueError("Fixture unexpectedly hard-UNSAT")
    return min(feasible)

def main():
    ap=argparse.ArgumentParser();ap.add_argument("--out",type=Path,required=True)
    args=ap.parse_args();args.out.mkdir(parents=True,exist_ok=False)
    records=[]
    for family,n in enumerate((8,10,12)):
        for variant in range(4):
            rng=random.Random(4600+100*family+variant)
            if family==0:
                hard=[(-(i+1),-((i+1)%n+1)) for i in range(n)]
                hard += [tuple(-x for x in rng.sample(range(1,n+1),3)) for _ in range(4)]
            else:
                hard=[]
                for _ in range(15 if family==1 else 30):
                    vs=rng.sample(range(1,n+1),3)
                    # At least one negative literal: all-false is an independent
                    # feasibility witness, without encoding a benchmark answer.
                    hard.append(tuple(-v if j==0 or rng.getrandbits(1) else v for j,v in enumerate(vs)))
            soft=[(v,) for v in range(1,n+1)]
            if variant&1:
                soft += [(-v,) for v in range(1,n//3+1)]
            optimum,witness=oracle(n,hard,soft)
            top=len(soft)+1
            text=f"p wcnf {n} {len(hard)+len(soft)} {top}\n"
            text += "".join(f"{top} "+" ".join(map(str,c))+" 0\n" for c in hard)
            text += "".join("1 "+" ".join(map(str,c))+" 0\n" for c in soft)
            name=f"family{family}-variant{variant}.wcnf"
            data=text.encode();(args.out/name).write_bytes(data)
            records.append({"file":name,"variables":n,"hard":len(hard),"soft":len(soft),
                            "optimum":optimum,"witness_mask":witness,
                            "sha256":hashlib.sha256(data).hexdigest()})
    (args.out/"ORACLES.json").write_text(json.dumps(records,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"fixtures":len(records),"solver_executed":False}))

if __name__=="__main__":main()
