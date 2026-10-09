import hashlib,io,json,math,shutil,statistics,subprocess,tarfile
from pathlib import Path

taskdir=Path(__file__).resolve().parent.parent
repo=taskdir/'DistQLDPC';record=repo/'optimization/experiments/E002'
raw=record/'raw/windows-run-01';pkg=taskdir/'E002-windows-package'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
git=lambda *args:subprocess.check_output(['git','-c','core.autocrlf=false','-C',str(repo),*args])
samples=json.loads((raw/'samples.json').read_text(encoding='utf8'))
assert len(samples)==48
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
shutil.copy2(taskdir/'windows-validation/e002-driver.log',raw/'driver.log')
scripts=raw/'executed-scripts';scripts.mkdir(exist_ok=True)
for name in ['run-e002.py','build-e002.sh','finalize-e002.py']:
    shutil.copy2(taskdir/'windows-validation'/name,scripts/name)
shutil.copy2(repo/'optimization/server/windows_diagnostic.py',scripts/'windows_diagnostic.py')
baseline=git('rev-parse','24572d6').decode().strip()
code=git('rev-parse','80a6eba').decode().strip()
runner_commit=git('rev-parse','HEAD').decode().strip()
assert git('show',code+':src/core/distqldpc.cc')==(pkg/'candidate/src/core/distqldpc.cc').read_bytes()
assert git('diff',baseline,code,'--','src/solver','data/matrices','MODIFICATIONS.md','NOTICE')==b''
patch=git('diff',baseline,code,'--','src/core/distqldpc.cc')
(record/'implementation.patch').write_bytes(patch)
# Offline archive excludes all Windows build artifacts; exact source bytes only.
package_name='E002-run-package'
members={}
for rel in json.loads((pkg/'manifest.json').read_text())['files']:
    members[rel]=(pkg/rel).read_bytes()
members['server_run.py']=(repo/'optimization/server/run_e002.py').read_bytes().replace(b'\r\n',b'\n')
manifest=dict(experiment='E002',revisions=json.loads((pkg/'manifest.json').read_text())['revisions'],
    server_runner_commit=runner_commit,files={rel:hashlib.sha256(b).hexdigest() for rel,b in members.items()})
members['manifest.json']=(json.dumps(manifest,indent=2)+'\n').encode()
archive_path=taskdir/(package_name+'.tar.gz')
assert not archive_path.exists()
with tarfile.open(archive_path,'w:gz') as tf:
    for rel,b in members.items():
        info=tarfile.TarInfo(package_name+'/'+rel);info.size=len(b);info.mode=0o644
        tf.addfile(info,io.BytesIO(b))
with tarfile.open(archive_path) as tf:
    for rel,expected in manifest['files'].items():
        assert hashlib.sha256(tf.extractfile(package_name+'/'+rel).read()).hexdigest()==expected
result=dict(experiment='E002',hypothesis='H-002 exact XOR-prefix sharing',baseline_commit=baseline,
    candidate_code_commit=code,candidate_snapshot=manifest['revisions']['candidate'],
    decision='INCONCLUSIVE',reason='Controlled run pending; local Windows numerical filter REJECT',
    tier0_windows='PASS',hosted_PR_check='pending; no merge',tier1_controlled='not run',
    tier1_windows=dict(raw_samples=48,numeric_filter='REJECT',medians='raw/windows-run-01/all-medians.json',
        reason='Disjoint regressions: GB in OFF/MTO and BB_108 OFF',mode_geomeans=geomeans),
    tier2='not reached',tier3='not run',scientific_semantics_changed=False,
    patch_sha256=sha(record/'implementation.patch'),binary_sha256=json.loads((raw/'environment.json').read_text())['binary_sha256'],
    package=dict(file=archive_path.name,sha256=sha(archive_path),files_verified=len(manifest['files']),runner_commit=runner_commit))
(record/'result.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
report=f'''# E002 / H-002 — exact XOR-prefix sharing

**Decision: INCONCLUSIVE for controlled performance; Windows numerical Tier 1 REJECT.**

This is a new engineering experiment, not another E001 repeat. The existing
Brain candidate name was recovered from HYPOTHESES.md; detailed original Brain
prose was unavailable. PROPOSAL.md records the chosen concrete scope explicitly.
E001's logical row-XOR change is absent. Baseline: {baseline}.
Candidate code: {code}; exact application diff in implementation.patch.
Only exact signed, ordered XOR pairs within one MaxCDCL application encoding
share a defined auxiliary literal. Matrices, objective, bounds, timeout/results,
embedded engine and attribution unchanged. Dump-only/other backends default
to uncached encoding. Candidate isolated on experiment/h002-xor-prefix.

## Tier 0

Windows application build PASS with identical GCC 14.4 original Makefile flags;
baseline executable and unchanged engine objects verified and reused. Production
XOR-clause probe: 584 signed/repeated chain cases, each with all 16 original
assignments and all auxiliary extensions; exactly one correct extension. Checks
duplicate reuse, ordered keys and fresh per-solver cache lifetime. Small exact
CSS oracle d=2/d=1 in BOTH/OFF/MTO; smoke; pinned QDistSAT pilot OFF/MTO; six
one-second timeout checks PASS. No crash, wrong distance/bound or semantic mismatch.
All 48 measured solves return certified expected distance/objective/lower/upper
bounds. Local pilot is not a hosted PR check; that check remains pending.

## Tier 1 local diagnostics

Windows/Cygwin interactive desktop, no reservation/pinned CPU/fixed power policy.
Same four cases and OFF/MTO modes, 3 runs/version, serial AB/BA/AB; verbose raw
logs, 180 s internal timeout / 195 s watchdog. Full wall includes construction
and solving. No timing timeout/failure/sample discarded. Results are local,
not machine-independent or controlled dedicated-server performance evidence.

| Case | Mode | Baseline median (s) | Candidate median (s) | Candidate/base |
|---|---|---:|---:|---:|
'''
for r in comparisons:
    report+=f"| {r['case']} | {r['mode']} | {r['baseline_median']:.4f} | {r['candidate_median']:.4f} | {r['ratio']:.4f} |\n"
report+=f'\nEqual-weight median-ratio geomeans: OFF {geomeans["no-card"]:.5f}; MTO {geomeans["card-mto"]:.5f}.\n'
report+='The local filter rejects; averages do not hide these disjoint regressions:\n'
for r in comparisons:
    if r['disjoint_regression']:
        report+=f"- {r['case']} {r['mode']}: baseline {r['baseline_min']:.4f}–{r['baseline_max']:.4f} s, candidate {r['candidate_min']:.4f}–{r['candidate_max']:.4f} s.\n"
report+='''
## Learning / next action

Sharing reduced generated XOR gates on every inspected case before elimination:
LP_136 1400->1328, BB_90 654->630, GB 1283->1277, BB_108 790->775,
LP_238 2630->2552, LP_340 4320->4125. This did not guarantee faster solving.
Do not infer which search/propagation mechanism caused regression; it was not
isolated. H-002 is unpromoted, and no Tier 2/3 or merge occurred. Keep the failed
local filter. Next iteration should read E001 and E002 history; no replacement
hypothesis is selected here. Controlled reproduction is available if needed.

## Reproducible dedicated-server package

Requires exclusive reserved Linux host, g++, make, Python >=3.10, zlib headers.
Reserve a physical CPU and its sibling, fix governor/power and stop other jobs.
The package contains pinned source/data/harness and exact identity manifest;
it excludes Windows binaries/objects and preserves licenses. Replace CPU 2 and
reservation note below with real reservation values. Use a new output directory.
The runner re-enters Tier 0, runs Tier 1, and only on a controlled Tier 1 PASS
allows LP_340 Tier 2 (3/version/mode, 600 s / 615 s watchdog); no Tier 3 code.
Worst internal timing budgets: Tier 1 144 min, Tier 2 120 min; overhead extra.

```sh
'''
report+=f"printf '%s  %s\\n' {sha(archive_path)} E002-run-package.tar.gz | sha256sum --check\n"
report+="tar -xzf E002-run-package.tar.gz\ncd E002-run-package\npython3 server_run.py --package . --output ../E002-controlled-results --cpu 2 --exclusive-host --reservation-note 'actual exclusive reservation ID'\n```\n"
report+=f'\nPackage SHA-256: `{sha(archive_path)}`; {len(manifest["files"])} payload hashes verified.\n'
report+='Retain complete controlled outputs before reconciling the decision; never replace the Windows data.\n'
(record/'README.md').write_text(report,encoding='utf8')
(record/'.gitattributes').write_text('implementation.patch -text\n',encoding='utf8')
(raw/'.gitattributes').write_text('* -text\n',encoding='utf8')
evidence={str(p.relative_to(raw)).replace('\\','/'):sha(p) for p in sorted(raw.rglob('*')) if p.is_file() and p.name!='evidence-manifest.json'}
(raw/'evidence-manifest.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf8')
print(json.dumps(dict(tier0='PASS',local_tier1='REJECT',controlled='INCONCLUSIVE',raw_runs=48,
    package_sha256=sha(archive_path),package_files=len(manifest['files']),evidence_files=len(evidence)),indent=2))
