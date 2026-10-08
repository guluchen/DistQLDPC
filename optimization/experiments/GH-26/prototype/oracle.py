"""GH26 independent truth-table oracle. DO NOT RUN without host assignment.

Checks a standalone test-only C++ kernel, not production DistQLDPC Tier0.
No SAT/MaxSAT engine is used as the reference. Fixed seed and fixed budget;
no retries or increasing budget to seek positive results.
"""
import argparse
import copy
import hashlib
import itertools
import json
import random
import subprocess
from pathlib import Path


def holds(p, values):
    return values[p // 2] != (p & 1)


def completions(case):
    out = []
    for values in itertools.product((0, 1), repeat=case['n']):
        if any(b >= 0 and values[i] != b for i, b in enumerate(case['base'])):
            continue
        if all(any(holds(p, values) for p in clause) for clause in case['hard']):
            out.append(values)
    return out


def cost(soft, values):
    return sum(not holds(p, values) for p in soft)


def protocol(case):
    rows = [f"{case['n']} {len(case['hard'])} {len(case['soft'])} {len(case['cores'])}",
            ' '.join(map(str, case['base']))]
    rows += [f"{len(c)} " + ' '.join(map(str, c)) for c in case['hard']]
    rows += [' '.join(map(str, case['soft']))]
    rows += [f"{c['weight']} {len(c['members'])} " + ' '.join(map(str, c['members']))
             for c in case['cores']]
    return '\n'.join(rows) + '\n'


def make(n, hard, cores, *, soft=None, base=None, name='', expected=None):
    return dict(n=n, hard=hard, cores=cores, soft=list(range(0, 2*n, 2)) if soft is None else soft,
                base=[-1]*n if base is None else base, name=name, expected=expected)


def fixtures():
    # Clique of pairwise incompatible positive softs has optimum2, while one
    # existing two-member weight1 core alone gives1. Both branches must cover.
    basic=make(3, [[1,3], [1,5], [3,5]], [dict(members=[0,2],weight=1)],
               name='pair-coverage',expected=True)
    missing=make(3, [[1,3], [1,5]], [dict(members=[0,2],weight=1)],
                 name='one-uncovered-branch',expected=False)
    cases=[basic, missing,
           make(2, [[1,3]], [dict(members=[0,2],weight=1)],
                name='unlock-not-extra',expected=False),
           make(3, [[1,3],[0],[1,5]], [dict(members=[0,2],weight=1)],
                name='one-hard-infeasible-branch',expected=True),
           make(3, [[1,3],[1,5],[3,5],[0],[2]], [dict(members=[0,2],weight=1)],
                name='both-hard-infeasible-branches',expected=True),
           make(4, [[1,3],[1,5],[3,5]], [dict(members=[0,2],weight=1)],
                base=[-1,-1,-1,0],name='base-false-offset',expected=True),
           make(2, [], [],name='no-certified-core',expected=False),
           make(3, [[1,3],[1,5],[3,5]],
                [dict(members=[0,2,4],weight=2)],name='no-weight1-core',expected=False)]
    # Sign substitution is an exact variable bijection, including base facts.
    for mask in range(1,8):
        case=copy.deepcopy(basic)
        case['name']=f'pair-coverage-signmask-{mask}'
        flip=lambda p: p ^ ((mask >> (p//2)) & 1)
        case['hard']=[[flip(p) for p in c] for c in case['hard']]
        case['soft']=[flip(p) for p in case['soft']]
        for c in case['cores']: c['members']=[flip(p) for p in c['members']]
        cases.append(case)
    # Independent weight2 passive unlocking and one selected weight1 pair.
    hard=[[1,3],[5,7],[5,9],[7,9],[0,5],[0,7],[2,5],[2,7],[1,9],[3,9]]
    cases.append(make(5,hard,[dict(members=[0,2],weight=1),
                             dict(members=[4,6,8],weight=2)],
                      name='weight2-unlocking',expected=None))
    return cases


def generated_cases():
    rng=random.Random(2609)
    for index in range(512):
        n=4
        soft=[2*v+rng.randrange(2) for v in range(n)]
        hard=[]
        for _ in range(rng.randrange(2,10)):
            vs=rng.sample(range(n),rng.choice((2,3)))
            hard.append([2*v+rng.randrange(2) for v in vs])
        base=[rng.choice((-1,-1,-1,0,1)) for _ in range(n)]
        case=make(n,hard,[],soft=soft,base=base,name=f'fixed-seed-{index}')
        models=completions(case)
        if models:
            free=[soft[v] for v in range(n) if base[v]<0]
            for begin in range(0,len(free),2):
                members=free[begin:begin+2]
                weight=min(cost(members,m) for m in models)
                if weight>0: case['cores'].append(dict(members=members,weight=weight))
        yield case


def declined_inputs():
    common=make(3,[[1,3],[1,5],[3,5]],[],name='')
    variants=[('overlap',[dict(members=[0,2],weight=1),dict(members=[2,4],weight=1)]),
              ('duplicate-member',[dict(members=[0,0],weight=1)]),
              ('nonobjective-sign',[dict(members=[1,2],weight=1)]),
              ('zero-weight',[dict(members=[0,2],weight=0)]),
              ('oversized-weight',[dict(members=[0,2],weight=3)])]
    for name,cores in variants:
        case=copy.deepcopy(common)
        case.update(name='decline-'+name,cores=cores,expected=False,decline=True)
        yield case
    case=copy.deepcopy(common)
    case.update(name='decline-baseassigned-member',cores=[dict(members=[0,2],weight=1)],
                base=[1,-1,-1],expected=False,decline=True)
    yield case


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--driver',required=True)
    parser.add_argument('--output',required=True)
    args=parser.parse_args()
    cases=fixtures()+list(generated_cases())+list(declined_inputs())
    payload=''.join(protocol(c) for c in cases)
    completed=subprocess.run([args.driver],input=payload,text=True,capture_output=True,
                             check=True,timeout=60)
    lines=completed.stdout.splitlines()
    if len(lines)!=len(cases): raise AssertionError('driver result count mismatch')
    records=[]
    for case,line in zip(cases,lines):
        models=completions(case)
        # Validate OLD certificates independently before testing strengthening.
        if not case.get('decline'):
            for core in case['cores']:
                if any(cost(core['members'],m)<core['weight'] for m in models):
                    raise AssertionError('invalid fixture old core: '+case['name'])
        result=list(map(int,line.split()))
        if len(result)!=6: raise AssertionError('invalid driver protocol')
        strengthened=bool(result[0])
        basefalse=sum(b>=0 and b==(p&1) for p in case['soft'] for b in [case['base'][p//2]])
        bound=basefalse+sum(c['weight'] for c in case['cores'])+int(strengthened)
        exact=min((cost(case['soft'],m) for m in models),default=None)
        if not case.get('decline') and exact is not None and bound>exact:
            raise AssertionError(f"scientific kernel LB mismatch {case['name']}: {bound}>{exact}")
        if case['expected'] is not None and strengthened!=case['expected']:
            raise AssertionError('targeted behavior mismatch: '+case['name'])
        records.append(dict(case=case,result=result,lb=None if case.get('decline') else bound,
                            exact=exact,feasible=len(models)))
    report=dict(status='MODEL_ORACLE_PASS',production_tier0='NOT_RUN',
                driver_sha256=hashlib.sha256(Path(args.driver).read_bytes()).hexdigest(),
                stdin_sha256=hashlib.sha256(payload.encode()).hexdigest(),
                cases=len(records),strengthened=sum(bool(r['result'][0]) for r in records),
                records=records,stdout=completed.stdout,stderr=completed.stderr)
    Path(args.output).write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')


if __name__=='__main__':
    main()
