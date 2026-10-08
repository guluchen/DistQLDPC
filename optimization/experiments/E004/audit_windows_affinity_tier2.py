"""Independent scientific/window audit of the twelve LP340 Tier2 samples."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import statistics


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('run', type=Path)
    ap.add_argument('--prior', type=Path, required=True)
    a = ap.parse_args()
    e, pkg = a.run/'evidence', a.prior/'E004-server-package'
    read = lambda p: json.loads(p.read_text(encoding='utf8'))
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    manifest = read(pkg/'manifest.json')
    for rel, expected in manifest['files'].items():
        assert sha(pkg/rel) == expected, rel
    identities = read(a.prior/'evidence/binary-hashes.json')
    assert identities == {'baseline': '22e398cc7558c2a04d5f24bd6db3030ce552c752622027fc2657eff7c1bd1815',
                          'candidate': 'b483fe59a90201f53c7ea4a87b95aa39740f738f1f418feec3a7b4b036f5e547'}
    for version, expected in identities.items():
        assert sha(pkg/version/'bin/distqldpc.exe') == expected
    assert read(a.prior/'evidence/tier0/summary.json')['status'] == 'PASS'
    env = read(e/'environment.json')
    assert env['manifest'] == manifest
    assert env['driver_sha256'] == sha(e/'executed-driver.py')
    setup = env['affinity']
    assert setup['mask'] == 1 << setup['selected_cpu']
    assert [setup['selected_cpu'], setup['sibling']] in setup['topology']
    assert not setup['exclusive_reservation'] and not setup['power_policy_changed']
    cleanup = read(e/'cleanup.json')
    assert cleanup == dict(job_limit_released=True, affinity_restored=True,
                           sleep_requirement_restored=True, final_mask=setup['original_affinity'])
    samples = read(e/'samples.json')
    assert len(samples) == 12, 'Incomplete round: no median or performance decision'
    resources = read(e/'resources.json')
    medians = []
    for mode in ['no-card', 'card-mto']:
        rows = [r for r in samples if r['mode'] == mode]
        assert [(r['repeat'], r['version']) for r in rows] == [(1,'baseline'),(1,'candidate'),(2,'candidate'),(2,'baseline'),(3,'baseline'),(3,'candidate')]
        for row in rows:
            assert row['case'] == 'LP_340_56_8' and row['returncode'] == 0
            assert not row['external_timeout'] and not row['resource_abort']
            assert row['command'][1:4] == ['-v', '-cpu-lim=600', '-'+mode]
            label = f"LP_340_56_8-{mode}-{row['repeat']}-{row['version']}"
            text = (e/(label+'.stdout')).read_text(encoding='utf8')
            patterns = {'d': r'^c\s+d\s*:\s*(\d+)\s*$', 'objective': r'^o\s+(-?\d+)\s*$',
                        'lb': r'^c\s+d_lb:\s*(\d+)\s*$', 'ub': r'^c\s+d_ub:\s*(\d+)\s*$'}
            for key, pattern in patterns.items():
                values = list(map(int, re.findall(pattern, text, re.M)))
                assert values and values[-1] == 8 and row['semantic'][key] == 8
                assert all(v <= 8 if key == 'lb' else v >= 8 for v in values)
            assert 's UNKNOWN' not in text and 'c status: TIMEOUT' not in text
            masks = read(e/(label+'.affinity.json'))
            assert masks and all(r['mask'] == setup['mask'] for r in masks)
            assert len({r['pid'] for r in masks}) >= 2
            preflight = [r for r in resources if r['label'] == label+'-preflight']
            assert preflight and preflight[-1]['eligible']
        raw = {v: [r['elapsed_sec'] for r in rows if r['version'] == v] for v in ['baseline','candidate']}
        b, c = [statistics.median(raw[v]) for v in ['baseline','candidate']]
        medians.append(dict(case='LP_340_56_8', mode=mode, raw=raw, baseline_median=b,
                            candidate_median=c, median_ratio=c/b,
                            range_envelope=max(raw['candidate'])/min(raw['baseline']),
                            nonoverlapping_regression=min(raw['candidate']) > max(raw['baseline'])))
    for r in resources:
        assert r['affinity'] == setup['mask']
        if r['eligible']:
            assert r['idle_percent'] > 50 and r['half_spare_logical_cpus'] >= 1
        else:
            assert r['label'].endswith('-preflight'), 'Active-window loss'
    if not setup['allow_contention']:
        assert all(setup['idle_by_cpu'][i] >= 95 for i in [setup['selected_cpu'],setup['sibling']])
        assert all(not r['core_contention_detected'] and r['sibling_idle'] >= 95 for r in resources if r['eligible'])
        assert all(r['selected_cpu_idle'] >= 95 for r in resources if r['eligible'] and r['label'].endswith('-preflight'))
    numeric = 'reject' if any(r['nonoverlapping_regression'] for r in medians) else ('pass' if all(r['range_envelope'] < 1 and r['median_ratio'] <= 1 for r in medians) else 'inconclusive')
    recorded = read(e/'result.json')
    assert recorded['medians'] == medians and recorded['numeric_filter'] == numeric
    result = dict(audit='PASS', correct_solves=12, binary_sha256=identities, medians=medians,
                  numeric_filter=numeric, strict_window_checks='not requested' if setup['allow_contention'] else 'PASS',
                  resource_checks=len(resources), min_observed_idle=min(r['idle_percent'] for r in resources),
                  preflight_wait_observations=sum(not r['eligible'] for r in resources),
                  active_contention_observations=sum(r['core_contention_detected'] for r in resources if not r['label'].endswith('-preflight')),
                  restoration='PASS', decision='INCONCLUSIVE',
                  reason='Windows repeat evidence; no automatic Tier3 or research acceptance')
    (e/'independent-audit.json').write_text(json.dumps(result, indent=2), encoding='utf8', newline='\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
