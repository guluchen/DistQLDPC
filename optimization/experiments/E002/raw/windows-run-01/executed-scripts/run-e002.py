import hashlib, io, json, os, runpy, shutil, subprocess, sys, tarfile
from pathlib import Path

taskdir=Path(__file__).resolve().parent.parent
repo=taskdir/'DistQLDPC'
pkg=taskdir/'E002-windows-package'
out=repo/'optimization/experiments/E002/raw/windows-run-01'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def git(source,*args):
    return subprocess.check_output(['git','-c','core.autocrlf=false','-c','core.eol=lf','-C',str(source),*args])
pkg.mkdir(exist_ok=False)
identities={}
for name,source,ref in [('baseline',repo,'24572d6d09cce9a4a5faa58300a89e0feba9da6a'),
                        ('candidate',repo,'014d826'),('qdistsat',taskdir/'QDistSAT','7c4774fffc49856f48a22ae5f9063d00b2661aaa')]:
    identities[name]=git(source,'rev-parse',ref).decode().strip()
    archive=git(source,'archive','--format=tar',identities[name])
    target=pkg/name;target.mkdir()
    with tarfile.open(fileobj=io.BytesIO(archive)) as tf:
        for member in tf.getmembers():
            p=(target/member.name).resolve()
            assert p.is_relative_to(target)
            if member.isdir():p.mkdir(parents=True,exist_ok=True)
            elif member.isfile():
                p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(tf.extractfile(member).read())
            else:raise RuntimeError('Unexpected archive type')
files={str(p.relative_to(pkg)).replace('\\','/'):sha(p) for p in sorted(pkg.rglob('*')) if p.is_file()}
(pkg/'manifest.json').write_text(json.dumps(dict(experiment='E002',revisions=identities,files=files),indent=2),encoding='utf8')
out.mkdir(parents=True,exist_ok=False)
old=taskdir/'E001-linux-package/baseline'
expected=json.loads((repo/'optimization/experiments/E001/raw/windows-validation/environment.json').read_text())['binary_sha256']['baseline']
assert sha(old/'bin/distqldpc.exe')==expected
for version in ['baseline','candidate']:(pkg/version/'bin').mkdir()
shutil.copy2(old/'bin/distqldpc.exe',pkg/'baseline/bin/distqldpc.exe')
(pkg/'candidate/build').mkdir()
objects={}
for name in ['SimpSolver.o','Solver.o','Options.o','System.o']:
    objects[name]=sha(old/'build'/name)
    shutil.copy2(old/'build'/name,pkg/'candidate/build'/name)
for p in (pkg/'baseline/src/solver').rglob('*'):
    if p.is_file():assert p.read_bytes()==(pkg/'candidate'/p.relative_to(pkg/'baseline')).read_bytes()
(out/'build-inputs.json').write_text(json.dumps(dict(baseline_sha256=expected,engine_objects_sha256=objects,
    source_revisions=identities,solver_sources_unchanged=True,package_files=len(files)),indent=2),encoding='utf8')
os.environ['PATH']=str(taskdir/'windows-validation/cygwin/bin')+os.pathsep+os.environ['PATH']
os.environ.update(LC_ALL='C',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1')
with (out/'candidate-build.log').open('w',encoding='utf8') as f:
    p=subprocess.run([str(taskdir/'windows-validation/cygwin/bin/bash.exe'),'--noprofile','--norc',
        '/cygdrive/c/Users/User/Documents/Codex/2026-10-07/you-are-the-execution-agent-for/windows-validation/build-e002.sh'],stdout=f,stderr=subprocess.STDOUT,timeout=300)
if p.returncode:
    (out/'experiment-status.json').write_text(json.dumps(dict(decision='INCONCLUSIVE',reason='build failure; no timing')))
    raise SystemExit(p.returncode)
original_run=subprocess.run
def cygpath(value):
    text=str(value).replace('\\','/')
    return '/cygdrive/'+text[0].lower()+text[2:] if len(text)>2 and text[1]==':' else text
def adapted_run(args,*rest,**kw):
    first=str(taskdir/'windows-validation/cygwin/bin/bash.exe') if str(args[0])=='bash' else args[0]
    return original_run([first]+[cygpath(p) for p in args[1:]],*rest,**kw)
subprocess.run=adapted_run
os.chdir(pkg/'candidate')
sys.argv=[str(pkg/'candidate/optimization/tests/tier0_xor_prefix.py'),
    '--baseline',str(pkg/'baseline/bin/distqldpc.exe'),'--candidate',str(pkg/'candidate/bin/distqldpc.exe'),
    '--probe',str(taskdir/'windows-validation/e002-probe.exe'),'--qdistsat',str(pkg/'qdistsat'),'--out',str(out/'tier0')]
try:
    runpy.run_path(sys.argv[0],run_name='__main__')
except SystemExit as exc:
    (out/'experiment-status.json').write_text(json.dumps(dict(decision='REJECTED' if exc.code==2 else 'INCONCLUSIVE',reason='Tier 0 failed; no timings')))
    raise
finally:subprocess.run=original_run
sys.argv=[str(repo/'optimization/server/windows_diagnostic.py'),'--package',str(pkg),'--output',str(out)]
runpy.run_path(sys.argv[0],run_name='__main__')
