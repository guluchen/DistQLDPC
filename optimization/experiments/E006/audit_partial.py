"""Independent read-only audit of E006 partial strict Windows Tier1 evidence."""
import argparse
import hashlib
import json
import re
import statistics
from pathlib import Path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('run', type=Path)
    ap.add_argument('--prior', required=True, type=Path)
    ap.add_argument('--candidate', required=True, type=Path)
    a = ap.parse_args()
    e = a.run/'evidence'
    read = lambda p: json.loads(p.read_text(encoding='utf8'))
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    env = read(e/'environment.json')
    setup = env['affinity']
    pkg = a.prior/'E004-server-package'
    for rel, want in env['manifest']['files'].items():
        assert sha(pkg/rel) == want, rel
    assert env['manifest']['baseline'].startswith('24572d6')
    assert env['candidate_sha'] == 'c91b19bbf29a28a6e808c8ef2c328cb9cef784e8'
    for rel, want in env['tier0_validation']['source_hashes'].items():
        assert sha(a.candidate/rel) == want, rel
    for version, path in [('baseline', pkg/'baseline'), ('candidate', a.candidate)]:
        assert sha(path/'bin/distqldpc.exe') == env['binary_sha256'][version]
    assert sha(e/'executed-driver.py') == env['driver_sha256']
    assert all(r['conclusion'] == 'success' for r in env['hosted_ci']['workflow_runs'])
    assert read(a.prior/'evidence/tier0/summary.json')['status'] == 'PASS'
    assert setup['mask'] == 1 << setup['selected_cpu']
    assert [setup['selected_cpu'], setup['sibling']] in setup['topology']
    assert all(setup['idle_by_cpu'][i] >= 95 for i in [setup['selected_cpu'], setup['sibling']])
    assert not setup['allow_contention'] and not setup['exclusive_reservation']
    assert setup['priority_class'] == 32768
    cleanup = read(e/'cleanup.json')
    assert cleanup == dict(job_limit_released=True, affinity_restored=True,
        sleep_requirement_restored=True, final_mask=65535, priority_restored=True,
        final_priority_class=32)
    resources = read(e/'resources.json')
    assert all(r['idle_percent'] > 50 and r['half_spare_logical_cpus'] >= 1 for r in resources)
    assert all(r['affinity'] == setup['mask'] for r in resources)
    active_bad = [r for r in resources if not r['eligible'] and not r['label'].endswith('-preflight')]
    assert len(active_bad) == 1 and active_bad[0]['core_contention_detected']
    assert active_bad[0]['sibling_idle'] < 95
    samples = read(e/'samples.json')
    completed = []
    patterns = dict(d=r'^c\s+d\s*:\s*(\d+)\s*$', objective=r'^o\s+(-?\d+)\s*$',
                    lb=r'^c\s+d_lb:\s*(\d+)\s*$', ub=r'^c\s+d_ub:\s*(\d+)\s*$')
    for i, row in enumerate(samples):
        label = f"{row['case']}-{row['mode']}-{row['repeat']}-{row['version']}"
        expected = int(row['case'].rsplit('_', 1)[1])
        assert row['command'][1:4] == ['-v', '-cpu-lim=180', '-'+row['mode']]
        assert Path(row['command'][0]).resolve() == (pkg/'baseline/bin/distqldpc.exe' if row['version']=='baseline' else a.candidate/'bin/distqldpc.exe').resolve()
        assert Path(row['cwd']).resolve() == (pkg/'baseline' if row['version']=='baseline' else a.candidate).resolve()
        assert row['command'][4].endswith('/baseline/data/matrices/'+row['case'])
        observed = read(e/(label+'.affinity.json'))
        assert observed and len({r['pid'] for r in observed}) >= 2
        assert all(r['mask'] == setup['mask'] and r['priority_class'] == 32768 for r in observed)
        pre = [r for r in resources if r['label'] == label+'-preflight']
        assert pre and pre[-1]['eligible'] and pre[-1]['selected_cpu_idle'] >= 95 and pre[-1]['sibling_idle'] >= 95
        active = [r for r in resources if r['label'] == label]
        output = (e/(label+'.stdout')).read_text(encoding='utf8')
        for key, pattern in patterns.items():
            values = list(map(int, re.findall(pattern, output, re.M)))
            assert all(v <= expected if key=='lb' else v >= expected for v in values)
            assert row['semantic'][key] == (values[-1] if values else None)
        if row['resource_abort']:
            assert i == len(samples)-1 and active_bad[0]['label'] == label
            assert read(e/(label+'.kill.json'))['returncode'] == 0
            assert not row['external_timeout']
            continue
        assert all(r['eligible'] and r['sibling_idle'] >= 95 for r in active)
        assert row['returncode'] == 0 and not row['external_timeout']
        assert all(row['semantic'][k] == expected for k in patterns)
        assert 's UNKNOWN' not in output and 'c status: TIMEOUT' not in output
        completed.append(row)
    assert len(completed) == 31 and len(samples) == 32
    medians = []
    for case in ['BB_90_8_10', 'GB_144_12_8', 'BB_108_8_10', 'LP_238_44_6']:
        for mode in ['no-card', 'card-mto']:
            rows = [r for r in completed if r['case']==case and r['mode']==mode]
            if len(rows) != 6:
                continue
            assert [(r['repeat'],r['version']) for r in rows] == [(1,'baseline'),(1,'candidate'),(2,'candidate'),(2,'baseline'),(3,'baseline'),(3,'candidate')]
            raw = {v:[r['elapsed_sec'] for r in rows if r['version']==v] for v in ['baseline','candidate']}
            b, c = (statistics.median(raw[v]) for v in ['baseline','candidate'])
            medians.append(dict(case=case, mode=mode, raw=raw, baseline_median=b,
                candidate_median=c, ratio=c/b, improvement_percent=100*(1-c/b),
                range_envelope=max(raw['candidate'])/min(raw['baseline'])))
    result = dict(audit='PASS', decision='INCONCLUSIVE', completed_correct=31, attempted=32,
        tier1_complete=False, partial_medians=medians, active_window_loss=active_bad,
        min_observed_global_idle=min(r['idle_percent'] for r in resources),
        active_checks=sum(not r['label'].endswith('-preflight') for r in resources),
        cleanup='PASS', identities='PASS', affinity_priority='PASS',
        reason='One candidate deliberately stopped on sibling idle below95%; incomplete four-case filter; no aggregate or promotion')
    (e/'independent-partial-audit.json').write_text(json.dumps(result,indent=2),encoding='utf8',newline='\n')
    print(json.dumps(result,indent=2))


if __name__ == '__main__':
    main()
