"""Generate a narrow guarded follow-up from the hash-pinned E004 diagnostic driver."""
import hashlib
import json
from pathlib import Path
import sys

root = Path(__file__).resolve().parent
package = Path(sys.argv[1]).resolve()
manifest = json.loads((root/'package-manifest.json').read_text(encoding='utf-8'))
source = package/'idle_tier1_lto.py'
assert hashlib.sha256(source.read_bytes()).hexdigest() == manifest['files']['idle_tier1_lto.py']
driver = source.read_text(encoding='utf-8')
driver = driver.replace('Resource-limited E004 diagnostics', 'User-requested E004 Tier 2 diagnostics')
anchor = "    ap.add_argument('--cpu', type=int, required=True)"
assert driver.count(anchor) == 1
driver = driver.replace(anchor,
    "    ap.add_argument('--prior-results', type=Path, required=True)\n"
    "    ap.add_argument('--user-requested-tier2', action='store_true', required=True)\n"+anchor)
start = driver.index('        for version in (\'baseline\', \'candidate\'):\n')
end = driver.index('        for case in runner.CASES1:', start)
reuse = '''        prior = args.prior_results.resolve()
        prior_decision = json.loads((prior/'decision.json').read_text())
        identities = json.loads((prior/'build-identities.json').read_text())
        if prior_decision['tiers'].get('0') != 'PASS':
            raise RuntimeError('Prior Tier 0 is not PASS')
        if identities['baseline'] != manifest['baseline'] or identities['candidate'] != manifest['candidate']:
            raise RuntimeError('Prior source identities differ from package')
        expected_hashes = {'baseline':'055e973e88cc0bb47dfeea236799b02c05d8f2d19b7a50a049125f9057223c0f',
                           'candidate':'9923009bb57c1f5ce5c5bfdede9af1b490f944e94f0a1731e0a85da5f0af9cca'}
        for version, expected in expected_hashes.items():
            actual = hashlib.sha256((pkg/version/'bin/distqldpc').read_bytes()).hexdigest()
            if actual != expected or identities['binaries'][version]['sha256'] != expected:
                raise RuntimeError('Reused binary mismatch: '+version)
        summary['tiers']['0'] = 'PASS (reused matching source/binary identities)'
        summary['tiers']['1'] = {'numerical_diagnostic':'inconclusive', 'source':str(prior)}
        summary['scope'] = 'User-requested diagnostic Tier 2; Tier 1 remains INCONCLUSIVE; no Tier 3'
        (out/'prior-validation.json').write_text(json.dumps({'prior_decision':prior_decision,
            'binary_identities':identities,'expected_hashes':expected_hashes},indent=2))
        save()
'''
driver = driver[:start]+reuse+driver[end:]
driver = driver.replace('runner.CASES1', "['LP_340_56_8']")
driver = driver.replace("f'tier1-", "f'tier2-")
driver = driver.replace("'-cpu-lim=180'", "'-cpu-lim=600'")
driver = driver.replace('label, 195)', 'label, 615)')
driver = driver.replace("{'tier':1,", "{'tier':2,")
driver = driver.replace("summary['tiers']['1'] = {'numerical_diagnostic':numerical", "summary['tiers']['2'] = {'numerical_diagnostic':numerical")
driver = driver.replace('Tier 1 diagnostic samples complete;', 'User-requested Tier 2 diagnostic samples complete;')
driver = driver.replace('No promotion or Tier 2.', 'Tier 1 unchanged; no promotion or Tier 3.')
anchor = "                        if reference is not None and semantic != reference:"
assert driver.count(anchor) == 1
checks = '''                        if semantic['d'] is not None and semantic['d'] != 8:
                            summary.update(decision='reject', reason='Wrong LP_340 distance: '+label)
                            save()
                            return 2
'''
driver = driver.replace(anchor, checks+anchor)
anchor = "                        if watchdog or rc or semantic['d'] is None or semantic['timeout'] or semantic['unknown']:"
assert driver.count(anchor) == 1
bound_check = '''                        if (semantic['lb'] is not None and semantic['lb'] > 8) or (semantic['ub'] is not None and semantic['ub'] < 8):
                            summary.update(decision='reject', reason='Wrong LP_340 bound: '+label)
                            save()
                            return 2
'''
driver = driver.replace(anchor, bound_check+anchor)
compile(driver, 'idle_tier2_lto.py', 'exec')
target = root/'idle_tier2_lto.py'
assert not target.exists()
target.write_text(driver, encoding='utf-8', newline='\n')
print(json.dumps({'driver':str(target), 'sha256':hashlib.sha256(target.read_bytes()).hexdigest()},indent=2))
