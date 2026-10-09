#!/usr/bin/env python3
"""Resource-limited E001 diagnostics on an occupied Linux server; never promote."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import platform
import signal
import statistics
import subprocess
import sys
import time


class CapacityLost(RuntimeError):
    pass


def cpu_times():
    return {line.split()[0]: list(map(int, line.split()[1:9]))
            for line in Path('/proc/stat').read_text().splitlines()
            if line.startswith('cpu')}


def idle_percent(before, after, cpu='cpu'):
    delta = [b-a for a, b in zip(before[cpu], after[cpu])]
    total = sum(delta)
    if total <= 0:
        return None
    return 100 * delta[3] / total  # iowait/steal are conservatively unavailable


def capacity_ok(idle, cpus, allocated=1):
    return idle is not None and idle > 50 and allocated <= cpus * idle / 100 / 2


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--package', type=Path, required=True)
    ap.add_argument('--output', type=Path, required=True)
    ap.add_argument('--cpu', type=int, required=True)
    ap.add_argument('--sibling', type=int, required=True)
    ap.add_argument('--allow-core-contention', action='store_true',
                    help='Keep core contention as telemetry only for diagnostics; never promote')
    args = ap.parse_args()
    if platform.system() != 'Linux':
        ap.error('Linux /proc CPU accounting is required')
    allowed = sorted(os.sched_getaffinity(0))
    if args.cpu not in allowed or args.sibling not in allowed or args.cpu == args.sibling:
        ap.error('Choose a CPU and distinct SMT sibling from allowed affinity')
    actual_siblings = Path(f'/sys/devices/system/cpu/cpu{args.cpu}/topology/thread_siblings_list').read_text().strip()
    if actual_siblings != ','.join(map(str, sorted([args.cpu, args.sibling]))):
        ap.error('CPU pair does not match kernel SMT topology')
    os.sched_setaffinity(0, {args.cpu})  # children inherit this one-CPU ceiling
    pkg = args.package.resolve()
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    manifest = json.loads((pkg/'manifest.json').read_text())
    for path, expected in manifest['files'].items():
        if hashlib.sha256((pkg/path).read_bytes()).hexdigest() != expected:
            raise SystemExit('Package identity mismatch: '+path)
    spec = importlib.util.spec_from_file_location('e001', pkg/'candidate/optimization/server/run.py')
    runner = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(runner)
    env = dict(os.environ, OMP_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1', LC_ALL='C')
    cpus = os.cpu_count()
    telemetry, samples = [], []
    summary = {'decision':'inconclusive', 'reason':'Occupied-host diagnostics; no exclusive reservation',
               'tiers':{}, 'controlled_performance':False, 'samples':0}
    environment = {'uname':platform.uname()._asdict(), 'allowed_cpus':allowed,
                   'cpu':args.cpu, 'sibling':args.sibling, 'thread_siblings':actual_siblings,
                   'affinity':list(os.sched_getaffinity(0)), 'load_start':os.getloadavg(),
                   'resource_rule':'idle > 50%; allocated CPUs <= half idle capacity',
                   'allow_core_contention':args.allow_core_contention,
                   'manifest':manifest, 'driver_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    for path in ['/proc/cpuinfo', '/proc/meminfo', f'/sys/devices/system/cpu/cpu{args.cpu}/cpufreq/scaling_governor']:
        try:
            environment[path] = Path(path).read_text()
        except OSError:
            environment[path] = None
    (out/'environment.json').write_text(json.dumps(environment, indent=2))

    def save():
        (out/'decision.json').write_text(json.dumps(summary, indent=2))
        (out/'samples.json').write_text(json.dumps(samples, indent=2))
        (out/'capacity.json').write_text(json.dumps(telemetry, indent=2))

    def check(before, after, label, phase):
        idle = idle_percent(before, after)
        sibling = idle_percent(before, after, f'cpu{args.sibling}')
        selected = idle_percent(before, after, f'cpu{args.cpu}')
        row = {'label':label, 'phase':phase, 'time':time.time(), 'idle_percent':idle,
               'selected_cpu_idle_percent':selected, 'sibling_idle_percent':sibling,
               'half_idle_cpus':cpus * (idle or 0) / 200,
               'load':os.getloadavg()}
        contention = ((sibling is not None and sibling < 95)
                      or (phase == 'before' and selected is not None and selected < 95))
        row['core_contention_detected'] = contention
        telemetry.append(row)
        if not capacity_ok(idle, cpus) or (contention and not args.allow_core_contention):
            raise CapacityLost('Capacity/sibling guard failed: '+json.dumps(row))

    def command(cmd, cwd, label, watchdog):
        before = cpu_times()
        time.sleep(2)
        check(before, cpu_times(), label, 'before')
        command_record = {'argv':list(map(str, cmd)), 'cwd':str(cwd), 'watchdog_sec':watchdog}
        (out/(label+'.command.json')).write_text(json.dumps(command_record, indent=2))
        start = time.perf_counter()
        deadline = start + watchdog
        external_timeout = False
        resource_abort = None
        with (out/(label+'.stdout')).open('w') as so, (out/(label+'.stderr')).open('w') as se:
            proc = subprocess.Popen(list(map(str, cmd)), cwd=cwd, env=env,
                                    stdout=so, stderr=se, start_new_session=True)
            before = cpu_times()
            while True:
                remaining = deadline-time.perf_counter()
                if remaining <= 0:
                    external_timeout = True
                    os.killpg(proc.pid, signal.SIGKILL)
                    rc = proc.wait()
                    break
                try:
                    rc = proc.wait(timeout=min(2, remaining))
                    break
                except subprocess.TimeoutExpired:
                    after = cpu_times()
                    try:
                        check(before, after, label, 'during')
                    except CapacityLost as exc:
                        resource_abort = str(exc)
                        os.killpg(proc.pid, signal.SIGKILL)
                        rc = proc.wait()
                        break
                    before = after
        elapsed = time.perf_counter()-start
        command_record.update(returncode=rc, elapsed_sec=elapsed,
                              external_timeout=external_timeout, resource_abort=resource_abort)
        (out/(label+'.command.json')).write_text(json.dumps(command_record, indent=2))
        save()
        if resource_abort:
            raise CapacityLost(resource_abort)
        return rc, elapsed, external_timeout

    save()
    try:
        for version in ('baseline', 'candidate'):
            rc, _, _ = command(['make', '-j2', 'CXX=g++'], pkg/version, 'build-'+version, 900)
            if rc:
                raise RuntimeError('Build failed: '+version)
        candidate = pkg/'candidate'
        rc, _, _ = command(['g++','-Isrc/solver','-O2','-std=c++11','optimization/tests/logical_probe.cc',
                            'build/SimpSolver.o','build/Solver.o','build/Options.o','build/System.o',
                            '-lz','-o',out/'probe'], candidate, 'probe-build', 120)
        if rc:
            raise RuntimeError('Probe build failed')
        rc, _, _ = command([sys.executable,'optimization/tests/tier0.py',
                            '--baseline',pkg/'baseline/bin/distqldpc','--candidate',candidate/'bin/distqldpc',
                            '--probe',out/'probe','--qdistsat',pkg/'qdistsat','--out',out/'tier0'],
                            candidate, 'tier0', 900)
        if rc == 2:
            summary.update(decision='reject', reason='Tier 0 semantic mismatch; escalate')
            save()
            return 2
        if rc or json.loads((out/'tier0/summary.json').read_text())['status'] != 'PASS':
            raise RuntimeError('Tier 0 incomplete; no performance measurements')
        summary['tiers']['0'] = 'PASS'
        (out/'binary-identities.json').write_text(json.dumps({v:hashlib.sha256((pkg/v/'bin/distqldpc').read_bytes()).hexdigest()
                                                           for v in ('baseline','candidate')}, indent=2))
        for case in runner.CASES1:
            for mode in runner.MODES:
                reference = None
                for rep in range(3):
                    for version in (('baseline','candidate') if rep%2 == 0 else ('candidate','baseline')):
                        label = f'tier1-{case}-{mode}-{rep+1}-{version}'
                        cmd = [pkg/version/'bin/distqldpc','-v','-cpu-lim=180','-'+mode,pkg/'baseline/data/matrices'/case]
                        rc, elapsed, watchdog = command(cmd, pkg/version, label, 195)
                        semantic = runner.parse((out/(label+'.stdout')).read_text())
                        row = {'tier':1, 'case':case, 'mode':mode, 'repeat':rep+1, 'version':version,
                               'command':list(map(str,cmd)), 'elapsed_sec':elapsed, 'returncode':rc,
                               'watchdog':watchdog, 'semantic':semantic, 'load_after':os.getloadavg()}
                        samples.append(row)
                        summary['samples'] = len(samples)
                        save()
                        if not watchdog and (rc < 0 or rc not in (0,1)):
                            summary.update(decision='reject', reason='Unexpected solver crash: '+label)
                            save()
                            return 2
                        if semantic['d'] is not None and (semantic['objective'] != semantic['d'] or semantic['lb'] != semantic['d'] or semantic['ub'] != semantic['d']):
                            summary.update(decision='reject', reason='Malformed exact result: '+label)
                            save()
                            return 2
                        if watchdog or rc or semantic['d'] is None or semantic['timeout'] or semantic['unknown']:
                            raise RuntimeError('Incomplete diagnostic sample: '+label)
                        if reference is not None and semantic != reference:
                            summary.update(decision='reject', reason='Scientific result mismatch: '+label)
                            save()
                            return 2
                        reference = semantic
        numerical, reason, _ = runner.judge(samples, runner.CASES1)
        medians = []
        for case in runner.CASES1:
            for mode in runner.MODES:
                b = [r['elapsed_sec'] for r in samples if r['case']==case and r['mode']==mode and r['version']=='baseline']
                c = [r['elapsed_sec'] for r in samples if r['case']==case and r['mode']==mode and r['version']=='candidate']
                medians.append({'case':case,'mode':mode,'baseline_raw':b,'candidate_raw':c,
                                'baseline_median':statistics.median(b),'candidate_median':statistics.median(c),
                                'ratio':statistics.median(c)/statistics.median(b)})
        summary['tiers']['1'] = {'numerical_diagnostic':numerical, 'reason':reason, 'medians':medians}
        summary.update(reason='Tier 1 diagnostic samples complete; occupied host has no exclusive reservation. No promotion or Tier 2.')
        save()
        return 0
    except Exception as exc:
        summary.update(reason=str(exc))
        save()
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
