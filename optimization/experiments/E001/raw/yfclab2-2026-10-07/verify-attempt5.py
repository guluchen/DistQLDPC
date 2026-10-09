import hashlib, json, math, pathlib, re, statistics

root = pathlib.Path('optimization/experiments/E001/raw/yfclab2-2026-10-07')
r = root / 'attempt5' / 'results-attempt5'
d = json.loads((r/'decision.json').read_text(encoding='utf-8'))
s = json.loads((r/'samples.json').read_text(encoding='utf-8'))
t = json.loads((r/'capacity.json').read_text(encoding='utf-8'))
expected = {'BB_90_8_10':10,'GB_144_12_8':8,'BB_108_8_10':10,'LP_238_44_6':6}
assert d['tiers']['0'] == 'PASS' and len(s) == 48
assert not d['controlled_performance']
for x in s:
    value = expected[x['case']]
    assert x['semantic'] == dict(d=value, objective=value, lb=value, ub=value, timeout=False, unknown=False)
    assert x['returncode'] == 0 and not x['watchdog']
    label = f"tier1-{x['case']}-{x['mode']}-{x['repeat']}-{x['version']}"
    cmd = json.loads((r/(label+'.command.json')).read_text(encoding='utf-8'))
    assert cmd['resource_abort'] is None and not cmd['external_timeout']
    assert cmd['elapsed_sec'] == x['elapsed_sec']
for cell in d['tiers']['1']['medians']:
    for version in ('baseline','candidate'):
        raw = [x['elapsed_sec'] for x in s if x['case']==cell['case'] and x['mode']==cell['mode'] and x['version']==version]
        assert len(raw)==3 and raw==cell[version+'_raw']
        assert statistics.median(raw)==cell[version+'_median']
assert min(x['idle_percent'] for x in t)>50
assert min(x['half_idle_cpus'] for x in t)>=1
counters={}
for version in ('baseline','candidate'):
    counters[version]=[]
    for rep in range(1,4):
        log=(r/f'tier1-GB_144_12_8-no-card-{rep}-{version}.stdout').read_text(encoding='utf-8')
        found=re.findall(r'LRB phase 1: conflicts (\d+), phase (\d+), starts (\d+), UP (\d+)',log)
        assert found
        counters[version].append(dict(zip(['conflicts','phase','starts','UP'],map(int,found[-1]))))
receipt=dict(scientific_results='PASS', sample_count=len(s), distances=expected,
    tier0='PASS', tier2='NOT RUN', tier3='NOT RUN', allocated_cpus=1,
    capacity_checks=len(t), global_idle_min_percent=min(x['idle_percent'] for x in t),
    global_idle_max_percent=max(x['idle_percent'] for x in t),
    half_idle_cpu_budget_min=min(x['half_idle_cpus'] for x in t),
    contention_checks=sum(x['core_contention_detected'] for x in t),
    medians=d['tiers']['1']['medians'], GB_no_card_final_LRB_phase1_counters=counters,
    median_geomean_diagnostic={m:math.exp(sum(math.log(x['ratio']) for x in d['tiers']['1']['medians'] if x['mode']==m)/4) for m in ('no-card','card-mto')},
    numerical_diagnostic=d['tiers']['1']['numerical_diagnostic'], decision='INCONCLUSIVE',
    reason='Occupied-host timings; no controlled promotion',
    archive_sha256={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in root.glob('results-attempt[45].tar.gz')})
(root/'attempt5-verification.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps(receipt,indent=2))
