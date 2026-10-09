"""Verify retained resource-interrupted Tier 2 attempts without inventing a comparison."""
import hashlib
import json
from pathlib import Path
import re
import tarfile

root = Path(__file__).resolve().parent
hashes = {1:'487bfd7ff7049feb4a731ca351ede652866278edcb20736ae7ef421bb0734ffc',
          2:'4047422290bac9be4e3823028c12213804954ed68e6eeb21cba1b97cfb03f113'}
attempts = []
for number, expected in hashes.items():
    archive = root/f'tier2-attempt{number}.tar.gz'
    assert hashlib.sha256(archive.read_bytes()).hexdigest() == expected
    directory = root/f'raw/tier2-attempt{number}'
    if not directory.exists():
        with tarfile.open(archive) as tf:
            tf.extractall(directory, filter='data')
    results = directory/'results'
    decision = json.loads((results/'decision.json').read_text())
    samples = json.loads((results/'samples.json').read_text())
    capacity = json.loads((results/'capacity.json').read_text())
    commands = [(p,json.loads(p.read_text())) for p in results.glob('tier2-*.command.json')]
    aborted = [(p,c) for p,c in commands if c['resource_abort']]
    assert decision['decision']=='inconclusive' and decision['samples']==len(samples)
    assert len(aborted)==1 and not aborted[0][1]['external_timeout']
    assert aborted[0][1]['returncode']==-9
    assert any(c['idle_percent']<=50 for c in capacity)
    for row in samples:
        assert row['returncode']==0 and not row['watchdog']
        s=row['semantic']
        assert all(s[k]==8 for k in ['d','objective','lb','ub']) and not s['timeout'] and not s['unknown']
    # command.json -> stdout is not a one-suffix substitution.
    stdout=results/(aborted[0][0].name.removesuffix('.command.json')+'.stdout')
    text=stdout.read_text(encoding='utf-8')
    assert all(int(x)<=8 for x in re.findall(r'^c d_lb: (\d+)',text,re.M))
    assert all(int(x)>=8 for x in re.findall(r'^c d_ub: (\d+)',text,re.M))
    attempts.append(dict(attempt=number, archive_sha256=expected,
                         completed_samples=len(samples),samples=samples,
                         abort_label=aborted[0][0].name,
                         abort_elapsed_sec=aborted[0][1]['elapsed_sec'],
                         idle_min=min(c['idle_percent'] for c in capacity),
                         resource_checks=len(capacity),
                         half_idle_cpu_min=min(c['half_idle_cpus'] for c in capacity),
                         intentional_resource_kill=True,external_timeout=False))
assert [a['completed_samples'] for a in attempts]==[0,1]
receipt=dict(decision='INCONCLUSIVE',comparison_available=False,
             medians=None, speedup=None, attempts=attempts,
             reason='Both attempts stopped under the CPU capacity rule; no complete candidate or MTO run')
(root/'raw/tier2-independent-audit.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(receipt,indent=2))
