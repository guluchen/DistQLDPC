#!/usr/bin/env python3
"""H-002 production XOR-clause projection, exact CSS and result/timeout checks."""
import argparse, importlib.util, itertools, json, re, subprocess, sys
from pathlib import Path


def main():
    ap = argparse.ArgumentParser()
    for name in ['baseline','candidate','probe','qdistsat','out']:
        ap.add_argument('--'+name,type=Path,required=True)
    a=ap.parse_args()
    for name in ['baseline','candidate','probe','qdistsat','out']:
        setattr(a,name,getattr(a,name).resolve())
    root=Path(__file__).resolve().parents[2]
    a.out.mkdir(parents=True,exist_ok=True)
    checks=[]
    def run(cmd,label,timeout=60):
        p=subprocess.run(list(map(str,cmd)),cwd=root,text=True,capture_output=True,timeout=timeout)
        for suffix,text in [('stdout',p.stdout),('stderr',p.stderr)]:
            (a.out/(label+'.'+suffix)).write_text(text,encoding='utf8')
        (a.out/(label+'.command.json')).write_text(json.dumps(dict(argv=list(map(str,cmd)),cwd=str(root),returncode=p.returncode),indent=2),encoding='utf8')
        return p
    p=run([a.probe],'production-xor-probe')
    assert p.returncode==0,'XOR clause/projection probe failed: '+p.stdout+p.stderr
    checks.append(json.loads(p.stdout))
    structure=[]
    for case in ['LP_136_32_4','BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6','LP_340_56_8']:
        p=run([a.probe,root/'data/matrices'/case],'structure-'+case)
        assert p.returncode==0,p.stdout+p.stderr
        counts=json.loads(p.stdout.splitlines()[-1])
        assert counts['shared_gates']<=counts['uncached_gates']
        structure.append(dict(case=case,**counts))
    (a.out/'structure.json').write_text(json.dumps(structure,indent=2),encoding='utf8')
    spec=importlib.util.spec_from_file_location('css_helpers',root/'optimization/tests/tier0.py')
    helper=importlib.util.module_from_spec(spec);spec.loader.exec_module(helper)
    for stem,n,hx,hz,gx,gz in [('css4',4,[15],[15],[3,5],[3,5]),('css5',5,[3],[3],[12,24,28],[12,24,28])]:
        span=lambda rows:{v for v in range(1<<n) if helper.rank(rows+[v])==helper.rank(rows)}
        sx,sz=span(hx),span(hz)
        weights=[]
        for x,z in itertools.product(range(1<<n),repeat=2):
            feasible=not helper.nonzero(hx,z) and not helper.nonzero(hz,x) and (x not in sx or z not in sz)
            encoded=not helper.nonzero(hx,z) and not helper.nonzero(hz,x) and (helper.nonzero(gx,x) or helper.nonzero(gz,z))
            assert feasible==encoded
            if feasible:weights.append((x|z).bit_count())
        distance=min(weights)
        for name,rows in zip(['Hx','Hz','Gx','Gz'],[hx,hz,gx,gz]):helper.write(a.out/f'{stem}_{name}.txt',rows,n)
        for version in ['baseline','candidate']:
            for mode in ['default','no-card','card-mto']:
                p=run([getattr(a,version),'-cpu-lim=5']+([] if mode=='default' else ['-'+mode])+[a.out/stem],f'{stem}-{version}-{mode}')
                assert p.returncode==0 and re.search(r'^c d  : '+str(distance)+r'$',p.stdout,re.M),p.stdout+p.stderr
        checks.append(dict(fixture=stem,oracle_distance=distance,status='PASS'))
    for version in ['baseline','candidate']:
        p=run(['bash',root/'scripts/smoke_test.sh',getattr(a,version)],'smoke-'+version)
        assert p.returncode==0,p.stdout+p.stderr
    spec=importlib.util.spec_from_file_location('pilot',a.qdistsat/'benchmarks/compare_distqldpc_binaries.py')
    pilot=importlib.util.module_from_spec(spec);sys.modules['pilot']=pilot;spec.loader.exec_module(pilot)
    original_run=subprocess.run
    rows=[]
    for stem in ['LP_136_32_4','BB_108_8_10']:
        for mode,flag in pilot.CONFIGS:
            results=[]
            for version in ['baseline','candidate']:
                label='pilot-'+stem+'-'+mode+'-'+version
                def captured(*args,**kw):
                    p=original_run(*args,**kw)
                    (a.out/(label+'.stdout')).write_text(p.stdout or '',encoding='utf8')
                    (a.out/(label+'.stderr')).write_text(p.stderr or '',encoding='utf8')
                    return p
                subprocess.run=captured
                try:r=pilot.run_one(getattr(a,version),pilot.matrix_prefix(a.qdistsat/'data',stem),stem,mode,flag,45)
                finally:subprocess.run=original_run
                results.append(r)
            expected=int(stem.rsplit('_',1)[1])
            assert results[0].semantic_result==results[1].semantic_result,'pilot scientific mismatch: '+stem+' '+mode
            assert all(r.returncode==0 and not r.timed_out and r.d==expected and r.objective==expected and r.d_lb==expected and r.d_ub==expected for r in results),'pilot incomplete/malformed/wrong distance'
            rows.append(dict(stem=stem,mode=mode,same_semantics=True,runs=[vars(r) for r in results]))
            (a.out/'cross-repo.json').write_text(json.dumps(rows,indent=2),encoding='utf8')
    for version in ['baseline','candidate']:
        for mode in ['default','no-card','card-mto']:
            p=run([getattr(a,version),'-cpu-lim=1']+([] if mode=='default' else ['-'+mode])+['BB_108_8_10'],'timeout-'+version+'-'+mode,timeout=20)
            assert p.returncode==1 and 'c status: TIMEOUT' in p.stdout and 's UNKNOWN' in p.stdout,p.stdout+p.stderr
            assert not re.search(r'^o |^c d  : \d',p.stdout,re.M)
            assert all(int(v)<=10 for v in re.findall(r'^c d_lb: (\d+)',p.stdout,re.M))
            assert all(int(v)>=10 for v in re.findall(r'^c d_ub: (\d+)',p.stdout,re.M))
    checks.append(dict(smoke_cross_repo_timeouts='PASS'))
    (a.out/'summary.json').write_text(json.dumps(dict(status='PASS',checks=checks,timing='diagnostic only'),indent=2),encoding='utf8')
    print(json.dumps(checks),flush=True)


if __name__=='__main__':
    try:main()
    except AssertionError as exc:
        print('REJECT / correctness escalation: '+str(exc),file=sys.stderr)
        sys.exit(2)
