"""Prepared E006 Linux Tier0/Tier1 runner; requires externally validated lease.

Syntax checked locally, not executed on Linux. No Tier2/3 or automatic retry.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import statistics
import subprocess
import sys
import time

BASE = '24572d6d09cce9a4a5faa58300a89e0feba9da6a'
CAND = 'c91b19bbf29a28a6e808c8ef2c328cb9cef784e8'
CASES = ['BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6']
MODES = ['no-card','card-mto']


def main():
    ap = argparse.ArgumentParser()
    for name in ['baseline','candidate','out','fixtures']:
        ap.add_argument('--'+name, required=True, type=Path)
    ap.add_argument('--cpu', required=True, type=int)
    ap.add_argument('--sibling', required=True, type=int)
    ap.add_argument('--reservation-note', required=True)
    a = ap.parse_args()
    assert os.uname().sysname == 'Linux' and os.geteuid() != 0
    assert os.sched_getaffinity(0) == {a.cpu}, 'Must launch inside validated single-CPU lease'
    assert a.cpu != a.sibling
    topology = Path(f'/sys/devices/system/cpu/cpu{a.cpu}/topology/thread_siblings_list').read_text().strip()
    members = set()
    for part in topology.split(','):
        lo, _, hi = part.partition('-')
        members.update(range(int(lo), int(hi or lo)+1))
    assert a.sibling in members
    a.out.mkdir(parents=True, exist_ok=False)
    env = dict(os.environ, LC_ALL='C', OMP_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1')
    def save(name, value):
        (a.out/name).write_text(json.dumps(value, indent=2))
    def command(cmd, cwd, label):
        p = subprocess.run(list(map(str,cmd)), cwd=cwd, env=env, capture_output=True, text=True, timeout=600)
        (a.out/(label+'.stdout')).write_text(p.stdout)
        (a.out/(label+'.stderr')).write_text(p.stderr)
        save(label+'.command.json', dict(argv=list(map(str,cmd)), cwd=str(cwd), returncode=p.returncode))
        assert p.returncode == 0, label
        return p.stdout
    for version, tree, commit in [('baseline',a.baseline,BASE),('candidate',a.candidate,CAND)]:
        assert subprocess.check_output(['git','-C',str(tree),'rev-parse','HEAD'],text=True).strip() == commit
        assert not subprocess.check_output(['git','-C',str(tree),'status','--porcelain'],text=True).strip()
        command(['make','clean'], tree, 'clean-'+version)
        command(['make','-j1','CXX=g++'], tree, 'build-'+version)
    save('environment.json', dict(baseline=BASE,candidate=CAND,reservation=a.reservation_note,
        cpu=a.cpu,sibling=a.sibling,topology=topology,uname=list(os.uname()),
        compiler=command(['g++','--version'],a.candidate,'compiler'),
        binaries={v:hashlib.sha256((p/'bin/distqldpc').read_bytes()).hexdigest()
                  for v,p in [('baseline',a.baseline),('candidate',a.candidate)]}))
    probe = a.out.resolve()/'bdd-probe'
    command(['g++','-Isrc/solver','-O2','-std=gnu++11','tests/bdd_bound_probe.cc',
             'build/SimpSolver.o','build/Solver.o','build/Options.o','build/System.o','-lz','-o',probe],
            a.candidate,'probe-build')
    assert 'BDD_PROBE_PASS' in command([probe],a.candidate,'probe')
    def parse(output):
        patterns = dict(d=r'^c\s+d\s*:\s*(\d+)\s*$', objective=r'^o\s+(-?\d+)\s*$',
                        lb=r'^c\s+d_lb:\s*(\d+)\s*$', ub=r'^c\s+d_ub:\s*(\d+)\s*$')
        result = {}
        for k,p in patterns.items():
            values = re.findall(p, output, re.M)
            result[k] = int(values[-1]) if values else None
        result.update(timeout='c status: TIMEOUT' in output, unknown='s UNKNOWN' in output)
        return result
    trees = dict(baseline=a.baseline,candidate=a.candidate)
    for version, tree in trees.items():
        command(['bash','scripts/smoke_test.sh'],tree,'smoke-'+version)
        for mode in MODES:
            for stem,expected in [('css1',1),('css4',2),('css5',1),('LP_136_32_4',4),('BB_108_8_10',10)]:
                input_root = a.fixtures if stem.startswith('css') else a.baseline/'data/matrices'
                label = f'tier0-{stem}-{mode}-{version}'
                s = parse(command([tree.resolve()/'bin/distqldpc','-cpu-lim=60','-'+mode,(input_root/stem).resolve()],tree,label))
                assert all(s[k] == expected for k in ['d','objective','lb','ub']) and not s['timeout'] and not s['unknown'], label
            label = f'timeout-{mode}-{version}'
            cmd = [str(tree.resolve()/'bin/distqldpc'),'-cpu-lim=1','-'+mode,str((a.baseline/'data/matrices/BB_108_8_10').resolve())]
            p = subprocess.run(cmd,cwd=tree,env=env,capture_output=True,text=True,timeout=16)
            (a.out/(label+'.stdout')).write_text(p.stdout)
            (a.out/(label+'.stderr')).write_text(p.stderr)
            save(label+'.command.json',dict(argv=cmd,cwd=str(tree),returncode=p.returncode))
            s = parse(p.stdout)
            assert p.returncode in [0,1]
            assert s['lb'] is None or s['lb'] <= 10
            assert s['ub'] is None or s['ub'] >= 10
            assert s['objective'] is None or s['objective'] >= 10
            if p.returncode == 1:
                assert s['d'] is None and s['timeout'] and s['unknown']
            else:
                assert all(s[k] == 10 for k in ['d','objective','lb','ub']) and not s['timeout'] and not s['unknown']
    save('tier0.json',dict(status='PASS',note='Production BDD probe, smoke, CSS and exact pilot checks; hosted checks already pinned in record'))
    def ticks():
        result = {}
        for line in Path('/proc/stat').read_text().splitlines():
            cols = line.split()
            if cols and re.fullmatch(r'cpu\d*',cols[0]):
                values = list(map(int,cols[1:9])) # guest already included in user/nice
                result[cols[0]] = (sum(values), values[3])
        return result
    resources, samples = [], []
    def observe(label, before, preflight=False):
        after = ticks()
        idle = lambda k: 100*(after[k][1]-before[k][1])/(after[k][0]-before[k][0])
        global_idle, sib, selected = idle('cpu'), idle('cpu'+str(a.sibling)), idle('cpu'+str(a.cpu))
        eligible = global_idle > 50 and (os.cpu_count()*global_idle/200) >= 1 and sib >= 95 and (not preflight or selected >= 95)
        resources.append(dict(label=label,global_idle=global_idle,sibling_idle=sib,selected_idle=selected,eligible=eligible))
        save('resources.json',resources)
        return eligible, after
    decision = dict(decision='INCONCLUSIVE',tier0='PASS',tier1='pending',tier2='not run',tier3='not run')
    try:
        for case in CASES:
            expected = int(case.rsplit('_',1)[1])
            for mode in MODES:
                for rep in range(1,4):
                    for version in (['baseline','candidate'] if rep%2 else ['candidate','baseline']):
                        label = f'{case}-{mode}-{rep}-{version}'
                        before=ticks();time.sleep(2)
                        ok,before=observe(label+'-preflight',before,True)
                        if not ok: raise RuntimeError('Preflight window loss: '+label)
                        cmd=[str(trees[version].resolve()/'bin/distqldpc'),'-v','-cpu-lim=180','-'+mode,str((a.baseline/'data/matrices'/case).resolve())]
                        start=time.perf_counter();last=start;abort=False
                        with (a.out/(label+'.stdout')).open('w') as so,(a.out/(label+'.stderr')).open('w') as se:
                            p=subprocess.Popen(cmd,cwd=trees[version],env=env,stdout=so,stderr=se,start_new_session=True)
                            try:
                                while p.poll() is None:
                                    time.sleep(.25)
                                    if time.perf_counter()-last >= 2:
                                        ok,before=observe(label,before);last=time.perf_counter()
                                        abort=not ok
                                    if abort or time.perf_counter()-start >= 195:
                                        os.killpg(p.pid,signal.SIGKILL);p.wait();abort=True;break
                            finally:
                                if p.poll() is None: os.killpg(p.pid,signal.SIGKILL);p.wait()
                        s=parse((a.out/(label+'.stdout')).read_text())
                        samples.append(dict(case=case,mode=mode,repeat=rep,version=version,elapsed_sec=time.perf_counter()-start,semantic=s,returncode=p.returncode,abort=abort,command=cmd))
                        save('samples.json',samples)
                        assert s['lb'] is None or s['lb']<=expected
                        assert s['ub'] is None or s['ub']>=expected
                        assert s['objective'] is None or s['objective']>=expected
                        if abort: raise RuntimeError('Resource loss/watchdog: '+label)
                        assert p.returncode in [0,1], 'Crash: '+label
                        if s['d'] is not None: assert all(s[k]==expected for k in ['d','objective','lb','ub']) and not s['timeout'] and not s['unknown'], label
                        if p.returncode or s['d'] is None or s['timeout'] or s['unknown']: raise RuntimeError('Incomplete: '+label)
        medians=[]
        for case in CASES:
            for mode in MODES:
                raw={v:[r['elapsed_sec'] for r in samples if r['case']==case and r['mode']==mode and r['version']==v] for v in trees}
                b,c=(statistics.median(raw[v]) for v in ['baseline','candidate'])
                medians.append(dict(case=case,mode=mode,raw=raw,baseline_median=b,candidate_median=c,ratio=c/b,range_envelope=max(raw['candidate'])/min(raw['baseline'])))
        decision.update(tier1='48 correct solves',medians=medians,reason='Audit controlled provenance and preregistered gates; no automatic higher tier')
    except AssertionError as error:
        decision.update(decision='REJECTED',reason=str(error))
    except Exception as error:
        decision.update(reason=repr(error))
    finally:
        save('decision.json',decision)
    print(json.dumps(decision,indent=2))


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        # Tier0/setup errors occur before the performance block; never continue.
        if '--out' in sys.argv:
            output = Path(sys.argv[sys.argv.index('--out')+1])
            if output.is_dir():
                (output/'decision.json').write_text(json.dumps(dict(
                    decision='REJECTED' if isinstance(error,AssertionError) else 'INCONCLUSIVE',
                    reason=repr(error), tier1='not started', tier2='not run', tier3='not run'),indent=2))
        raise
