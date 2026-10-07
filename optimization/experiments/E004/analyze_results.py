"""Independent verification of retained E004 results; not a performance promotion."""
import hashlib
import json
import math
from pathlib import Path
import re
import statistics

ROOT = Path(__file__).resolve().parent
RESULTS = ROOT/'raw/server/results'
samples = json.loads((RESULTS/'samples.json').read_text())
decision = json.loads((RESULTS/'decision.json').read_text())
capacity = json.loads((RESULTS/'capacity.json').read_text())
expected = {'BB_90_8_10':10, 'GB_144_12_8':8, 'BB_108_8_10':10, 'LP_238_44_6':6}
assert len(samples) == 48 and decision['tiers']['0'] == 'PASS'
for row in samples:
    assert row['returncode'] == 0 and not row['watchdog']
    result = row['semantic']
    assert all(result[key] == expected[row['case']] for key in ['d','objective','lb','ub'])
    assert not result['timeout'] and not result['unknown']
assert all(row['idle_percent'] > 50 and row['half_idle_cpus'] >= 1 for row in capacity)

details, modes, search = [], {}, []
for mode in ['no-card', 'card-mto']:
    ratios, envelopes = [], []
    for case in expected:
        groups = {v:[r for r in samples if r['case']==case and r['mode']==mode
                     and r['version']==v] for v in ['baseline','candidate']}
        assert all(len(g)==3 for g in groups.values())
        b = [r['elapsed_sec'] for r in groups['baseline']]
        c = [r['elapsed_sec'] for r in groups['candidate']]
        bm, cm = statistics.median(b), statistics.median(c)
        ratios.append(cm/bm); envelopes.append(max(c)/min(b))
        detail = dict(case=case, mode=mode, baseline_raw=b, candidate_raw=c,
                      baseline_median=bm, candidate_median=cm, ratio=cm/bm)
        recorded = next(r for r in decision['tiers']['1']['medians']
                        if r['case']==case and r['mode']==mode)
        assert all(detail[k]==recorded[k] for k in detail)
        details.append(detail)
        counters = []
        for version in ['baseline','candidate']:
            for rep in range(1,4):
                text = (RESULTS/f'tier1-{case}-{mode}-{rep}-{version}.stdout').read_text(encoding='utf-8')
                counters.append(re.findall(r'^c (?:LRB phase .*|initCost:.*|nbLK:.*)$', text, re.M))
        assert counters[0] and all(c==counters[0] for c in counters), (case,mode)
        search.append(dict(case=case, mode=mode, identical_recorded_lines=counters[0]))
    gm = lambda xs: math.exp(sum(math.log(x) for x in xs)/len(xs))
    modes[mode] = dict(median_geomean=gm(ratios), range_envelope_geomean=gm(envelopes))
receipt = dict(scientific_results='PASS: all 48 distances/objectives/bounds match',
               global_idle_min=min(x['idle_percent'] for x in capacity),
               global_idle_max=max(x['idle_percent'] for x in capacity),
               half_idle_cpu_min=min(x['half_idle_cpus'] for x in capacity),
               resource_checks=len(capacity),
               contention_checks=sum(x['core_contention_detected'] for x in capacity),
               medians=details, modes=modes, recorded_search_counters=search,
               search_limitation='Named phase/final counters only; not proof of identical execution',
               decision='INCONCLUSIVE: occupied host and numerical gate did not pass',
               raw_archive_sha256=hashlib.sha256((ROOT/'raw/server-results.tar.gz').read_bytes()).hexdigest())
(ROOT/'raw/independent-audit.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps({k:v for k,v in receipt.items() if k not in ['medians','recorded_search_counters']},indent=2))
