"""Export exact E004 commits and adapt existing diagnostic/correctness harnesses."""
import hashlib
import io
import json
from pathlib import Path
import subprocess
import sys
import tarfile

ROOT = Path(__file__).resolve().parents[3]
BASE = '24572d6d09cce9a4a5faa58300a89e0feba9da6a'
QDIST = '7c4774fffc49856f48a22ae5f9063d00b2661aaa'
CAND = sys.argv[1]
OUT = Path(sys.argv[2]).resolve()
OLD = Path(sys.argv[3]).resolve()
OUT.mkdir(parents=True, exist_ok=False)

def git(*args):
    return subprocess.check_output(['git', '-c', 'core.autocrlf=false', '-C', str(ROOT), *args])

cases = ['LP_34_20_2', 'LP_136_32_4', 'BB_90_8_10', 'GB_144_12_8',
         'BB_108_8_10', 'LP_238_44_6', 'LP_340_56_8']
common = ['src', 'Makefile', 'LICENSE', 'NOTICE', 'MODIFICATIONS.md', 'README.md',
          'AGENTS.md', 'scripts/smoke_test.sh', 'docs/OPTIMIZATION_LOOP_POLICY.md',
          'docs/QDISTSAT_CROSS_REPO_CI.md']
common += [f'data/matrices/{case}_{suffix}.txt' for case in cases
           for suffix in ['Hx', 'Hz', 'Gx', 'Gz']]
assert git('diff', BASE, CAND, '--', 'src', 'data', 'NOTICE', 'MODIFICATIONS.md') == b''
for name, revision in [('baseline', BASE), ('candidate', CAND)]:
    target = OUT/name
    target.mkdir()
    with tarfile.open(fileobj=io.BytesIO(git('archive', revision, *common))) as archive:
        for member in archive:
            path = (target/member.name).resolve()
            assert path.is_relative_to(target)
            if member.isdir():
                path.mkdir(parents=True, exist_ok=True)
            elif member.isfile():
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(archive.extractfile(member).read())
                path.chmod(member.mode)
            else:
                raise ValueError(member.name)

# Reuse pinned QDistSAT blobs from the previously verified offline package.
old_manifest = json.loads((OLD/'manifest.json').read_text())
assert old_manifest['qdistsat'] == QDIST
for path in sorted((OLD/'qdistsat').rglob('*')):
    if path.is_file():
        relative = path.relative_to(OLD).as_posix()
        assert hashlib.sha256(path.read_bytes()).hexdigest() == old_manifest['files'][relative]
        destination = OUT/relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(path.read_bytes())

def write(relative, text):
    target = OUT/relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding='utf-8', newline='\n')

# Same CSS/WCNF/pilot/timeout checks as E003, excluding its unrelated XOR probe.
tier0 = (ROOT/'optimization/tests/tier0_xor_buffer.py').read_text()
tier0 = tier0.replace('H-004 production XOR buffer projection, exact CSS and result/timeout checks.',
                      'H-007 LTO: identical WCNF, exact CSS and result/timeout checks.')
tier0 = tier0.replace("'baseline','candidate','probe','qdistsat','out'",
                      "'baseline','candidate','qdistsat','out'")
start = tier0.index("    p=run([a.probe]")
end = tier0.index('    exports=[]', start)
tier0 = tier0[:start] + tier0[end:]
write('candidate/optimization/tests/tier0_lto.py', tier0)
write('candidate/optimization/tests/tier0.py', (ROOT/'optimization/tests/tier0.py').read_text())

# Keep resource limits, scientific comparisons, AB/BA/AB, medians and no-promotion
# behavior of the existing occupied-host driver; adapt only builds/test invocation.
driver = (ROOT/'optimization/server/idle_tier1.py').read_text().replace('E001', 'E004')
driver = driver.replace("['make', '-j2', 'CXX=g++']",
                        "['make', '-j1', 'CXX=g++', 'LTO='+('1' if version == 'candidate' else '0')]")
start = driver.index("        rc, _, _ = command(['g++'")
end = driver.index("        rc, _, _ = command([sys.executable", start)
driver = driver[:start] + driver[end:]
driver = driver.replace("'optimization/tests/tier0.py'", "'optimization/tests/tier0_lto.py'")
driver = driver.replace("'--probe',out/'probe',", '')
write('idle_tier1_lto.py', driver)

# Controlled follow-up keeps the original exclusive-host gate and Tier 1/2 plan.
controlled = (ROOT/'optimization/server/run.py').read_text().replace('E001', 'E004')
controlled = controlled.replace("['make','-j2','CXX=g++']",
                                "['make','-j1','CXX=g++','LTO='+('1' if version == 'candidate' else '0')]")
start = controlled.index("        command(['g++','-Isrc/solver'")
end = controlled.index("        command([sys.executable", start)
controlled = controlled[:start] + controlled[end:]
controlled = controlled.replace("'optimization/tests/tier0.py'", "'optimization/tests/tier0_lto.py'")
controlled = controlled.replace("'--probe',out/'probe',", '')
write('candidate/optimization/server/run.py', controlled)
write('PROPOSAL.md', (Path(__file__).parent/'PROPOSAL.md').read_text())
write('implementation.patch', git('diff', BASE, CAND).decode())
for script in ['idle_tier1_lto.py', 'candidate/optimization/server/run.py',
               'candidate/optimization/tests/tier0_lto.py']:
    compile((OUT/script).read_text(), script, 'exec')
manifest = {'experiment': 'E004', 'baseline': BASE, 'candidate': CAND, 'qdistsat': QDIST,
            'scope': 'One LTO concept; diagnostic Tier 1 cannot promote; no Tier 3',
            'files': {p.relative_to(OUT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                      for p in sorted(OUT.rglob('*')) if p.is_file()}}
write('manifest.json', json.dumps(manifest, indent=2)+'\n')
archive_path = OUT.with_suffix('.tar.gz')
assert not archive_path.exists()
with tarfile.open(archive_path, 'w:gz') as archive:
    archive.add(OUT, arcname=OUT.name)
print(json.dumps({'archive': str(archive_path), 'sha256': hashlib.sha256(archive_path.read_bytes()).hexdigest(),
                  'files': len(manifest['files']), 'candidate': CAND}, indent=2))
