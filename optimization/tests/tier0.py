#!/usr/bin/env python3
"""H-001 production-helper algebra, exhaustive CSS and integration checks."""
import argparse, hashlib, importlib.util, itertools, json, os, random, re
import subprocess, sys
from pathlib import Path


def rank(rows):
    pivots = {}
    for x in rows:
        while x:
            p = x.bit_length()
            if p in pivots: x ^= pivots[p]
            else:
                pivots[p] = x
                break
    return len(pivots)


def read(path):
    return [sum(int(x) << i for i, x in enumerate(line.split()))
            for line in path.read_text().splitlines() if line.strip() and not line.startswith('#')]


def write(path, rows, n):
    path.write_text(''.join(' '.join(str((r >> i) & 1) for i in range(n))+'\n' for r in rows))


def reference(rows):
    out = rows[:]
    for i in range(len(out)):
        choices = [( (out[i]^r).bit_count(), j) for j,r in enumerate(out) if i != j]
        if choices:
            weight,j = min(choices)
            if weight < out[i].bit_count(): out[i] ^= out[j]
    return out


def nonzero(rows, x):
    return any((r & x).bit_count() % 2 for r in rows)


def main():
    ap=argparse.ArgumentParser()
    for name in ['baseline','candidate','probe','qdistsat','out']:
        ap.add_argument('--'+name, type=Path, required=True)
    a=ap.parse_args()
    for name in ['baseline','candidate','probe','qdistsat','out']:
        setattr(a,name,getattr(a,name).resolve())
    a.out.mkdir(parents=True, exist_ok=True)
    root=Path(__file__).resolve().parents[2]
    checks=[]; measurements=[]; counter=0
    def run(cmd, label, cwd=root, timeout=60):
        p=subprocess.run([str(x) for x in cmd],cwd=cwd,text=True,capture_output=True,timeout=timeout)
        (a.out/(label+'.stdout')).write_text(p.stdout)
        (a.out/(label+'.stderr')).write_text(p.stderr)
        (a.out/(label+'.command.json')).write_text(json.dumps({'argv':list(map(str,cmd)),'cwd':str(cwd),'returncode':p.returncode},indent=2))
        return p
    def transform(rows,n,label):
        nonlocal counter
        path=a.out/'probe-input.txt';write(path,rows,n)
        p=run([a.probe,path], 'probe-last')
        assert p.returncode==0, p.stderr
        after=[sum(int(x)<<i for i,x in enumerate(line.split())) for line in p.stdout.splitlines()]
        assert after==reference(rows), label
        assert rank(rows)==rank(after)==rank(rows+after),label
        assert len(after)==len(rows)
        assert all(b.bit_count()<=r.bit_count() for r,b in zip(rows,after))
        if n<=6:
            assert all(nonzero(rows,x)==nonzero(after,x) for x in range(1<<n)),label
        counter+=1
        measurements.append({'label':label,'before':[r.bit_count() for r in rows],
                             'after':[r.bit_count() for r in after], 'probe_diagnostic':p.stderr.strip()})
        return after
    # Exhaust ALL ordered pairs and triples at n=3, including zero/dependent rows,
    # ties and sequential-update counterexamples; plus reproducible larger samples.
    for k in [1,2,3]:
        for rows in itertools.product(range(8),repeat=k): transform(list(rows),3,'exhaustive')
    rng=random.Random(1)
    for i in range(80):
        n=rng.randrange(1,33);k=rng.randrange(1,12)
        transform([rng.getrandbits(n) for _ in range(k)],n,'random-'+str(i))
    cases=['LP_136_32_4','BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6','LP_340_56_8']
    for stem in cases:
        matrices={s:read(root/'data/matrices'/f'{stem}_{s}.txt') for s in ['Hx','Hz','Gx','Gz']}
        n=len(next(l for l in (root/'data/matrices'/f'{stem}_Hx.txt').read_text().splitlines() if l.strip() and not l.startswith('#')).split())
        gx=transform(matrices['Gx'],n,stem+' Gx');gz=transform(matrices['Gz'],n,stem+' Gz')
        for before,after,stabilizers in [(matrices['Gx'],gx,matrices['Hz']),(matrices['Gz'],gz,matrices['Hx'])]:
            assert rank(stabilizers+before)==rank(stabilizers+after)
        pairing=lambda x,z:[sum(((r&s).bit_count()%2)<<j for j,s in enumerate(z)) for r in x]
        assert rank(pairing(gx,gz))==rank(pairing(matrices['Gx'],matrices['Gz']))==len(gx)
        assert all((h&g).bit_count()%2==0 for h in matrices['Hx'] for g in gx)
        assert all((h&g).bit_count()%2==0 for h in matrices['Hz'] for g in gz)
    checks.append({'algebra_instances':counter,'status':'PASS'})
    (a.out/'structure.json').write_text(json.dumps(measurements,indent=2))
    fixtures=[('css4',4,[15],[15],[3,5],[3,5]),('css5',5,[3],[3],[12,24,28],[12,24,28])]
    for stem,n,hx,hz,gx,gz in fixtures:
        # Independent stabilizer-membership oracle, exhaustive all 4^n Paulis.
        span=lambda rows:{v for v in range(1<<n) if rank(rows+[v])==rank(rows)}
        sx,sz=span(hx),span(hz)
        tx,tz=transform(gx,n,stem+' Gx'),transform(gz,n,stem+' Gz')
        weights=[]
        for x,z in itertools.product(range(1<<n),repeat=2):
            feasible=not nonzero(hx,z) and not nonzero(hz,x) and (x not in sx or z not in sz)
            encoded=not nonzero(hx,z) and not nonzero(hz,x) and (nonzero(gx,x) or nonzero(gz,z))
            changed=not nonzero(hx,z) and not nonzero(hz,x) and (nonzero(tx,x) or nonzero(tz,z))
            assert feasible==encoded==changed,(stem,x,z)
            if feasible:weights.append((x|z).bit_count())
        expected=min(weights)
        for name,rows in zip(['Hx','Hz','Gx','Gz'],[hx,hz,gx,gz]):write(a.out/f'{stem}_{name}.txt',rows,n)
        for version in ['baseline','candidate']:
            for mode in ['default','no-card','card-mto']:
                cmd=[getattr(a,version),'-cpu-lim=5']+([] if mode=='default' else ['-'+mode])+[a.out/stem]
                p=run(cmd,f'{stem}-{version}-{mode}')
                assert p.returncode==0 and re.search(r'^c d  : '+str(expected)+r'$',p.stdout,re.M),p.stdout
        checks.append({'fixture':stem,'oracle_distance':expected,'status':'PASS'})
    for version in ['baseline','candidate']:
        p=run(['bash',root/'scripts/smoke_test.sh',getattr(a,version)],'smoke-'+version)
        assert p.returncode==0,p.stdout+p.stderr
    # Existing QDistSAT functions, unchanged parser and semantic tuple. Preserve raw
    # logs externally because upstream report omits stdout/stderr. Stop at FIRST mismatch.
    spec=importlib.util.spec_from_file_location('pilot',a.qdistsat/'benchmarks/compare_distqldpc_binaries.py')
    pilot=importlib.util.module_from_spec(spec);sys.modules['pilot']=pilot;spec.loader.exec_module(pilot)
    original_run=subprocess.run
    pilot_rows=[]
    for stem in ['LP_136_32_4','BB_108_8_10']:
        for mode,flag in pilot.CONFIGS:
            runs=[]
            for version in ['baseline','candidate']:
                label='pilot-'+stem+'-'+mode+'-'+version
                def captured(*args,**kwargs):
                    p=original_run(*args,**kwargs)
                    (a.out/(label+'.stdout')).write_text(p.stdout or '')
                    (a.out/(label+'.stderr')).write_text(p.stderr or '')
                    return p
                subprocess.run=captured
                try:r=pilot.run_one(getattr(a,version),pilot.matrix_prefix(a.qdistsat/'data',stem),stem,mode,flag,45)
                finally:subprocess.run=original_run
                runs.append(r)
            same=runs[0].semantic_result==runs[1].semantic_result and runs[0].returncode==runs[1].returncode
            pilot_rows.append({'stem':stem,'mode':mode,'same_semantics':same,'runs':[vars(r) for r in runs]})
            (a.out/'cross-repo.json').write_text(json.dumps(pilot_rows,indent=2))
            assert same,'SEMANTIC MISMATCH: '+stem+' '+mode
            assert all(r.d is not None and r.returncode==0 and not r.timed_out for r in runs),'pilot incomplete'
    # One-second parent timeout: bounds may differ with search, but must contain
    # certified pilot distance 10; UNKNOWN must not be presented as an exact solve.
    for version in ['baseline','candidate']:
        for mode in ['default','no-card','card-mto']:
            cmd=[getattr(a,version),'-cpu-lim=1']+([] if mode=='default' else ['-'+mode])+['BB_108_8_10']
            p=run(cmd,'timeout-'+version+'-'+mode,timeout=20)
            assert p.returncode==1 and 'c status: TIMEOUT' in p.stdout and 's UNKNOWN' in p.stdout,p.stdout
            assert not re.search(r'^o |^c d  : \d',p.stdout,re.M)
            lbs=[int(x) for x in re.findall(r'^c d_lb: (\d+)',p.stdout,re.M)]
            ubs=[int(x) for x in re.findall(r'^c d_ub: (\d+)',p.stdout,re.M)]
            assert all(v<=10 for v in lbs) and all(v>=10 for v in ubs),p.stdout
    checks.append({'smoke_cross_repo_timeouts':'PASS'})
    (a.out/'summary.json').write_text(json.dumps({'status':'PASS','checks':checks,'timing':'diagnostic only; no performance conclusion'},indent=2))
    print(json.dumps(checks))

if __name__=='__main__':
    try: main()
    except AssertionError as exc:
        print('REJECT / correctness escalation: '+str(exc), file=sys.stderr)
        sys.exit(2)
