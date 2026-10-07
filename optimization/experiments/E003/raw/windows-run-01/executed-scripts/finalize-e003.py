import hashlib, io, json, math, shutil, statistics, subprocess, tarfile
from pathlib import Path

taskdir=Path(__file__).resolve().parent.parent
repo=taskdir/'DistQLDPC';record=repo/'optimization/experiments/E003'
raw=record/'raw/windows-run-01';pkg=taskdir/'E003-windows-package'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
git=lambda *args:subprocess.check_output(['git','-c','core.autocrlf=false','-C',str(repo),*args])
samples=json.loads((raw/'samples.json').read_text())
local=json.loads((raw/'result.json').read_text())
assert len(samples)==48 and local['tier0']=='PASS'
assert json.loads((raw/'tier0/summary.json').read_text())['status']=='PASS'
comparisons=[]
for case in ['BB_90_8_10','GB_144_12_8','BB_108_8_10','LP_238_44_6']:
    for mode in ['no-card','card-mto']:
        groups={}
        for version in ['baseline','candidate']:
            rows=[r for r in samples if r['case']==case and r['mode']==mode and r['version']==version]
            assert len(rows)==3
            expected=int(case.rsplit('_',1)[1])
            assert all(r['returncode']==0 and not r['watchdog'] and not r['semantic']['timeout'] and not r['semantic']['unknown'] and all(r['semantic'][k]==expected for k in ['d','objective','lb','ub']) for r in rows)
            groups[version]=[r['elapsed_sec'] for r in rows]
        b,c=groups['baseline'],groups['candidate']
        comparisons.append(dict(case=case,mode=mode,baseline_raw=b,candidate_raw=c,
            baseline_median=statistics.median(b),candidate_median=statistics.median(c),
            ratio=statistics.median(c)/statistics.median(b),baseline_min=min(b),baseline_max=max(b),
            candidate_min=min(c),candidate_max=max(c),disjoint_regression=min(c)>max(b)))
geomeans={m:math.prod(r['ratio'] for r in comparisons if r['mode']==m)**0.25 for m in ['no-card','card-mto']}
(raw/'all-medians.json').write_text(json.dumps(dict(comparisons=comparisons,mode_geomean_ratios=geomeans),indent=2)+'\n',encoding='utf8')
shutil.copy2(taskdir/'windows-validation/e003-driver.log',raw/'driver.log')
scripts=raw/'executed-scripts';scripts.mkdir(exist_ok=True)
for name in ['run-e003.py','build-e003.sh','finalize-e003.py']:
    shutil.copy2(taskdir/'windows-validation'/name,scripts/name)
shutil.copy2(repo/'optimization/server/windows_diagnostic.py',scripts/'windows_diagnostic.py')
baseline=git('rev-parse','24572d6').decode().strip()
code=git('rev-parse','02fc219').decode().strip()
runner_commit=git('rev-parse','HEAD').decode().strip()
assert git('show',code+':src/core/distqldpc.cc')==(pkg/'candidate/src/core/distqldpc.cc').read_bytes()
assert git('diff',baseline,code,'--','src/solver','data/matrices','MODIFICATIONS.md','NOTICE')==b''
(record/'implementation.patch').write_bytes(git('diff',baseline,code,'--','src/core/distqldpc.cc'))
package_name='E003-run-package'
members={rel:(pkg/rel).read_bytes() for rel in json.loads((pkg/'manifest.json').read_text())['files']}
members['server_run.py']=(repo/'optimization/server/run_e003.py').read_bytes().replace(b'\r\n',b'\n')
manifest=dict(experiment='E003',revisions=json.loads((pkg/'manifest.json').read_text())['revisions'],
    server_runner_commit=runner_commit,files={rel:hashlib.sha256(b).hexdigest() for rel,b in members.items()})
members['manifest.json']=(json.dumps(manifest,indent=2)+'\n').encode()
archive_path=taskdir/(package_name+'.tar.gz');assert not archive_path.exists()
with tarfile.open(archive_path,'w:gz') as tf:
    for rel,b in members.items():
        info=tarfile.TarInfo(package_name+'/'+rel);info.size=len(b);info.mode=0o644
        tf.addfile(info,io.BytesIO(b))
with tarfile.open(archive_path) as tf:
    for rel,expected in manifest['files'].items():
        assert hashlib.sha256(tf.extractfile(package_name+'/'+rel).read()).hexdigest()==expected
numeric=local['tier1']['numeric_filter'].upper()
result=dict(experiment='E003',hypothesis='H-004 reuse XOR gate clause buffer',baseline_commit=baseline,
    candidate_code_commit=code,candidate_snapshot=manifest['revisions']['candidate'],
    decision='INCONCLUSIVE',reason='Controlled performance pending; local numeric filter '+numeric,
    tier0_windows='PASS',hosted_PR_check='pending; no merge',tier1_controlled='not run',
    tier1_windows=dict(raw_samples=48,numeric_filter=numeric,medians='raw/windows-run-01/all-medians.json',
        mode_geomeans=geomeans),tier2='not reached',tier3='not run',scientific_semantics_changed=False,
    patch_sha256=sha(record/'implementation.patch'),binary_sha256=json.loads((raw/'environment.json').read_text())['binary_sha256'],
    package=dict(file=archive_path.name,sha256=sha(archive_path),files_verified=len(manifest['files']),runner_commit=runner_commit))
(record/'result.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
report=f'''# E003 / H-004: reuse XOR gate clause buffer

**Decision: INCONCLUSIVE. Local Windows numeric filter: {numeric}.**

One general engineering change: xor2 replaces four temporary std::vectors and
four copies into fresh solver vecs with a single local vec, cleared/refilled
between the original four clauses. Clause signs/order/weights/variable IDs
unchanged; no prefix sharing or logical-basis shortening. Baseline {baseline};
candidate {code}; exact diff: implementation.patch. Isolated branch
experiment/h004-xor-clause-buffer; no merge or promotion.
Embedded MaxCDCL, matrices, attribution, scientific and result semantics unchanged.
DistQLDPC remains a downstream application/engine combination, not upstream MaxCDCL.

## Tier 0

Build PASS with identical GCC 14.4 original application Makefile flags and
verified unchanged engine objects/baseline executable. 584 production XOR
chains with signed/repeated operands, all 16 base assignments and auxiliary
extensions PASS. Six byte-identical exported WCNFs (including LP_340; export
only, no Tier 2 timing). Exhaustive CSS fixtures d=2/d=1, default/OFF/MTO,
smoke, unchanged pinned QDistSAT pilot OFF/MTO, six forced one-second timeouts
PASS. All 48 timing solves have identical certified expected distances,
objective, lower/upper bounds. Hosted cross-repo PR check remains pending;
local pilot does not replace it. No correctness anomaly.

## Tier 1 Windows diagnostics

Serial AB/BA/AB, 3/version/case/mode, verbose raw logs, 180s internal limit,
195s watchdog. No discarded sample, timeout or failure. Full wall includes
input/encoding/preprocessing/search/startup. Interactive Windows/Cygwin,
unreserved and unpinned, balanced power; no portable/research-grade timing claim.
Preregistered unchanged numeric judge in PROPOSAL.md; original controlled-host
gate unfulfilled, so no Tier 2/3.

| Case | Mode | Baseline median (s) | Candidate median (s) | Candidate/base |
|---|---|---:|---:|---:|
'''
for r in comparisons:
    report+=f"| {r['case']} | {r['mode']} | {r['baseline_median']:.4f} | {r['candidate_median']:.4f} | {r['ratio']:.4f} |\n"
report+=f'\nEqual-weight median-ratio geomeans: OFF {geomeans["no-card"]:.5f}; MTO {geomeans["card-mto"]:.5f}.\n'
report+='All individual samples and ranges: raw/windows-run-01/all-medians.json.\n'
for r in comparisons:
    if r['disjoint_regression']:
        report+=f"Disjoint local regression: {r['case']} {r['mode']}, baseline {r['baseline_min']:.4f}–{r['baseline_max']:.4f}, candidate {r['candidate_min']:.4f}–{r['candidate_max']:.4f} s.\n"
report+='''
## Learning / next action

Reducing short-lived allocations preserves the exact CNF in this experiment.
Whole-solve timings cannot isolate encoding cost; do not claim that allocation
was a hot spot or infer hardware-independent gain. If the numeric gate overlaps,
the next useful measurement is a construction-versus-search profile on the
baseline, or a controlled reproduction, before extending this idea. Do not stack
another change here. H-003 initial verified witness remains a separate untested
candidate, requiring a witness and bound-semantics review. E001/E002 retained.

## Exact dedicated-server reproduction

Offline source-only package: pinned baseline/candidate/QDistSAT, data, licenses,
runner and hash manifest; no Windows binaries. Linux exclusive reserved physical
CPU/sibling, stable governor/power, g++, make, zlib headers, Python >=3.10.
Replace CPU/reservation with real values; new empty output directory. Runner
builds both, repeats Tier 0/1 and allows LP_340 Tier 2 only on controlled Tier 1
PASS (3/version/mode, 600s/615s). No Tier 3. Worst internal budgets Tier 1
144 min, conditional Tier 2 120 min; expected Tier 1 minutes, overhead extra.

```sh
tar -xzf E003-run-package.tar.gz
cd E003-run-package
python3 server_run.py --package . --output ../E003-controlled-results --cpu 2 --exclusive-host --reservation-note 'actual exclusive reservation ID'
```
'''
report+=f'\nArchive SHA-256 `{sha(archive_path)}`; {len(manifest["files"])} payload hashes verified. Retain all controlled outputs; never overwrite this run.\n'
(record/'README.md').write_text(report,encoding='utf8')
(record/'.gitattributes').write_text('implementation.patch -text\n',encoding='utf8')
(raw/'.gitattributes').write_text('* -text\n',encoding='utf8')
evidence={str(p.relative_to(raw)).replace('\\','/'):sha(p) for p in sorted(raw.rglob('*')) if p.is_file() and p.name!='evidence-manifest.json'}
(raw/'evidence-manifest.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf8')
print(json.dumps(dict(tier0='PASS',local_tier1=numeric,controlled='INCONCLUSIVE',raw_runs=48,
    package_sha256=sha(archive_path),package_files=len(manifest['files']),evidence_files=len(evidence),medians=comparisons),indent=2))
