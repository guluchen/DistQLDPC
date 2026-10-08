"""GH26 test-only model oracle. Preparation is disabled until assigned.
One compiler translation unit, one CPU Job, <=240s workload budget. No Solver.
"""
import argparse
import ctypes as C
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
TREE = HERE.parents[2]
ASSIGNED_URL = 'https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6064900438'
MODEL_COMMIT = '8438131b07901a9182e3212aed18b027b1773650'
BASE = '24572d6d09cce9a4a5faa58300a89e0feba9da6a'
HELPER_SHA = 'ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2'
SOURCE = {
    'snapshot_fla.h': '3d8ae9138586c3ae6a25ece1fc9ed9db8e2a89444bd0d62420ee8c5354ab81bc',
    'driver.cc': 'd40233f15151bff8395510730a29f8b4105019e5afbc07a9c84865541d777cf8',
    'oracle.py': 'dab67bbeda3cd867279f9be0e0831c28784a4f6ffc48ab5245bc8a4f3c511141',
}
RUNTIME = {
    'bin/g++.exe': '86bec0e6bef5057ab9065082633d430db5bc443a74489452798818cb0e0c0bd3',
    'lib/gcc/x86_64-pc-cygwin/14/cc1plus.exe': '1cb2aea35d1e643f9903b96fa45132ea5e26e4642202318d24c0cbfe9c88bf72',
    'lib/gcc/x86_64-pc-cygwin/14/collect2.exe': '7469996e903a87ace9c326299c479a3af9fd6a65dac60b0e4966310c217b1af5',
    'bin/as.exe': 'c314b4bfd253cdc2acb9955d1599acb6ca8cf6314730165f7c8c3bbeadc9f7aa',
    'bin/ld.exe': 'f6b6e5e8f2148173e814cce5bd662c984b8886ebe5e2f9c4bc37236a7dea242e',
    'bin/cygwin1.dll': '959048d1407074097af021708d87bdf5ac1a8f107ff963c8950cd6dc8f21afaf',
    'bin/cygstdc++-6.dll': 'e8677526b0a6fef2a457d4d0e105571e1e350c7ad66c925bd00120cf91410443',
    'bin/cyggcc_s-seh-1.dll': 'af178c2cb5d4756ff5c2523433812c43f1ad91c6eea9c381caa5e8396bfdc134',
    'bin/cygz.dll': 'b3acfadb0f642c8e94d4b5cb4ee527d068f4b2001508af523444766949d67a80',
    'bin/cygzstd-1.dll': '1cca310acda0c743af8c8b776c453e51975a7822c19d293fde5544c5252ff141',
    'bin/cygisl-23.dll': '0d3ba41e07bfed4222e8ef4159a960bc3e12cce8e254d57d5bd30b2d35604d3b',
    'bin/cyggmp-10.dll': '44a89e8405b4707d120dd0fbf8b6421d300204e216abdaffdddc4c4a434c6b477',
    'bin/cygmpc-3.dll': 'a29697e606da2c9ae52468f3fc582b7df689e6773549c4936f1e12329ee1dd34',
    'bin/cygmpfr-6.dll': '9f81066227df4993522f37c75d6b796482426230be9d87bf02c8afd888086e01',
    'bin/cygiconv-2.dll': 'ddb34b3a5538495775c4e1333acf0d5f5b1cf228e38f3b4a7e6438cfc5290e9c',
    'bin/cygintl-8.dll': 'f0f89113cdac2b710cf6ff295120b8718a709b020165235f3554e5ed5c6fc75a',
}
PYTHON_SHA = 'ef8f51028ac5329641985112f8efb1c2d4c47c86b8011ddf7e6fae21e2b4e5a1'
PYTHON_DLL_SHA = '3a7a6170ea840bf2a2a76d05b687b946fcdc8d0cfedfe159012b38f1e8959a7c'
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
ap = argparse.ArgumentParser()
ap.add_argument('--out', type=Path, required=True)
ap.add_argument('--run-assignment', required=True)
args = ap.parse_args()
assert ASSIGNED_URL != 'HOST_SLOT_NOT_ASSIGNED', 'Preparation only: no assigned host slot'
assert args.run_assignment == ASSIGNED_URL
out = args.out.resolve()
assert out.parent == ROOT and not out.exists(), 'Fresh direct workspace child required'
out.mkdir()
def save(p, v):
    Path(p).write_text(json.dumps(v, indent=2)+'\n', encoding='utf-8', newline='\n')

runtime = ROOT/'E004-windows-runtime/cygwin'
helper = ROOT/'DistQLDPC/optimization/experiments/E004/windows_cpu_window.py'
pins = {HERE/'prototype'/name: value for name, value in SOURCE.items()}
pins.update({runtime/name: value for name, value in RUNTIME.items()})
pins.update({helper: HELPER_SHA, Path(sys.executable): PYTHON_SHA,
             Path(sys.executable).parent/'python313.dll': PYTHON_DLL_SHA})
pins[Path(__file__).resolve()] = sha(__file__)
def identities():
    actual = {str(p): sha(p) for p in pins}
    assert all(actual[str(p)] == expected for p, expected in pins.items()), 'Pinned file identity changed'
    return actual

window = None
current = None
resources = []
descendants = []
index = 0
deadline = time.monotonic()+240
summary = dict(status='INCONCLUSIVE', model='NOT_RUN', production_tier0='NOT_RUN',
               performance='NOT_MEASURED', assignment=args.run_assignment, model_commit=MODEL_COMMIT)
def job_pids():
    buf = C.create_string_buffer(65536)
    returned = C.c_ulong()
    if not module.k.QueryInformationJobObject(window.job, 3, buf, C.sizeof(buf), C.byref(returned)):
        raise C.WinError(C.get_last_error())
    assigned, count = struct.unpack_from('<II', buf)
    assert assigned == count and 8+8*count <= C.sizeof(buf)
    return list(struct.unpack_from('<'+'Q'*count, buf, 8))

def clean_owned():
    actions = []
    # Recheck membership immediately before each PID action; never enumerate other jobs.
    for pid in [p for p in job_pids() if p != os.getpid()]:
        if pid not in job_pids():
            continue
        with (out/('cleanup-'+str(pid)+'.stdout')).open('wb') as so, (out/('cleanup-'+str(pid)+'.stderr')).open('wb') as se:
            r = subprocess.run(['taskkill', '/PID', str(pid), '/T', '/F'], stdout=so, stderr=se, timeout=10)
        actions.append(dict(pid=pid, returncode=r.returncode))
    end = time.monotonic()+5
    while time.monotonic()<end and [p for p in job_pids() if p != os.getpid()]:
        time.sleep(.1)
    remaining = [p for p in job_pids() if p != os.getpid()]
    save(out/('cleanup-'+str(index)+'.json'), dict(actions=actions, remaining=remaining))
    assert not remaining, 'Owned descendants remain'

def observe(label):
    r = window.observe(label)
    resources.append(r)
    save(out/'resources.json', resources)
    assert r['eligible'], 'Capacity guard failed: '+label

def cygpath(p):
    v = str(p).replace('\\', '/')
    return '/cygdrive/'+v[0].lower()+v[2:] if len(v)>2 and v[1]==':' else v

def managed(argv, label, limit):
    global current, index
    index += 1
    window.previous = module.ticks()
    time.sleep(2.1)
    observe(label+'-preflight')
    limit = min(limit, deadline-time.monotonic())
    assert limit > 0, 'Total workload budget exhausted'
    command = dict(argv=list(map(str, argv)), cwd=str(out), timeout_sec=limit)
    start = time.monotonic()
    last = start
    with (out/(label+'.stdout')).open('wb') as so, (out/(label+'.stderr')).open('wb') as se:
        try:
            current = subprocess.Popen(command['argv'], cwd=out, stdout=so, stderr=se)
            while current.poll() is None:
                time.sleep(.05)
                now = time.monotonic()
                if now-last >= 2:
                    seen = module.descendant_affinities(current.pid)
                    descendants.append(dict(label=label, records=seen))
                    save(out/'descendants.json', descendants)
                    assert all(r['mask']==window.mask and r['priority_class']==0x8000 for r in seen)
                    observe(label)
                    last = now
                if now-start > limit:
                    raise subprocess.TimeoutExpired(argv, limit)
            command['returncode'] = current.returncode
            clean_owned()
            assert current.returncode == 0, 'Command failed: '+label
        except BaseException as error:
            command['error'] = repr(error)
            clean_owned()
            raise
        finally:
            save(out/(label+'.command.json'), command)

try:
    before = identities()
    assert not subprocess.check_output(['git', '-C', str(TREE), 'diff', BASE, 'HEAD', '--', 'src', 'Makefile'], timeout=10)
    assert not subprocess.check_output(['git', '-C', str(TREE), 'diff', '--', 'src', 'Makefile'], timeout=10)
    source = out/'prototype'
    source.mkdir()
    blobs = {}
    for name in SOURCE:
        data = subprocess.check_output(['git', '-C', str(TREE), 'show', MODEL_COMMIT+':optimization/experiments/GH-26/prototype/'+name], timeout=10)
        # Git LF and checkout CRLF are recorded separately; executable copies use pinned checkout bytes.
        blobs[name] = hashlib.sha256(data).hexdigest()
        assert data.replace(b'\r\n', b'\n') == (HERE/'prototype'/name).read_bytes().replace(b'\r\n', b'\n')
        shutil.copyfile(HERE/'prototype'/name, source/name)
        pins[source/name] = SOURCE[name]
    shutil.copyfile(__file__, out/'executed-runner.py')
    shutil.copyfile(helper, out/'executed-window.py')
    pins[out/'executed-runner.py'] = pins[Path(__file__).resolve()]
    pins[out/'executed-window.py'] = HELPER_SHA
    save(out/'preexecution.json', dict(pins=before, git_blob_hashes=blobs, assignment=args.run_assignment,
         compile='single translation unit, no make or parallel workers', oracle_cases=534,
         oracle_outer_timeout_sec=60, workload_budget_sec=240))
    assert not any(os.environ.get(n) for n in ['CXX','CXXFLAGS','LDFLAGS','MAKEFLAGS'])
    os.environ['PATH'] = str(runtime/'bin')+os.pathsep+os.environ['PATH']
    os.environ.update(LC_ALL='C', OMP_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1')
    spec = importlib.util.spec_from_file_location('gh26_window', helper)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.k.QueryInformationJobObject.argtypes = [C.c_void_p,C.c_int,C.c_void_p,C.c_ulong,C.POINTER(C.c_ulong)]
    module.k.QueryInformationJobObject.restype = C.c_int
    window = module.Window(True, 0x8000)
    save(out/'window.json', window.selection)
    managed([runtime/'bin/g++.exe','--version'], 'compiler-version', 20)
    binary = out/'fla-model.exe'
    managed([runtime/'bin/g++.exe','-std=c++11','-O0','-g','-Wall','-Wextra','-pedantic',
             cygpath(source/'driver.cc'),'-o',cygpath(binary)], 'model-build', 120)
    managed([sys.executable,source/'oracle.py','--driver',binary,'--output',out/'model-oracle.json'], 'model-oracle', 60)
    report = json.loads((out/'model-oracle.json').read_text(encoding='utf-8'))
    assert report['status']=='MODEL_ORACLE_PASS' and report['cases']==534 and len(report['records'])==534
    assert report['production_tier0']=='NOT_RUN'
    assert report['driver_sha256']==sha(binary)
    assert report['stdin_sha256']==sha(out/'model-oracle.input.txt')
    for suffix in ['cases.json','driver.stdout','driver.stderr','driver.json']:
        assert (out/('model-oracle.'+suffix)).is_file()
    summary.update(model='MODEL_ORACLE_PASS', status='MODEL_COMPLETE', cases=534,
                   strengthened=report['strengthened'], binary_sha256=sha(binary))
except BaseException as error:
    summary['error'] = repr(error)
    stderr = out/'model-oracle.stderr'
    if stderr.exists() and any(marker in stderr.read_bytes() for marker in
                              [b'scientific kernel LB mismatch', b'targeted behavior mismatch',
                               b'model driver crash/invalid protocol return', b'driver result count mismatch',
                               b'invalid driver protocol']):
        summary.update(model='MODEL_REJECT', status='REJECT')
finally:
    if window is not None:
        try:
            clean_owned()
            summary['cleanup_confirmed'] = True
        except BaseException as e:
            summary.update(cleanup_confirmed=False, cleanup_error=repr(e))
        try:
            restored = window.close()
            save(out/'restoration.json', restored)
            summary['restoration_confirmed'] = all(restored.get(n) for n in ['job_limit_released','affinity_restored','sleep_requirement_restored','priority_restored']) and restored['final_mask']==window.original_mask and restored['final_priority_class']==window.original_priority
        except BaseException as e:
            summary.update(restoration_confirmed=False, restoration_error=repr(e))
    try:
        save(out/'postexecution-identities.json', identities())
        summary['identity_confirmed'] = True
    except BaseException as e:
        summary.update(identity_confirmed=False, identity_error=repr(e))
    summary['valid_run'] = summary['status']=='MODEL_COMPLETE' and all(summary.get(n) for n in ['cleanup_confirmed','restoration_confirmed','identity_confirmed'])
    if summary['status']=='MODEL_COMPLETE' and not summary['valid_run']:
        summary['status'] = 'INCONCLUSIVE'
    save(out/'result.json', summary)
    save(out/'sha256.json', {str(p.relative_to(out)).replace('\\','/'):sha(p) for p in out.rglob('*') if p.is_file()})
    print(json.dumps(summary), flush=True)
sys.exit(0 if summary.get('valid_run') else 2)
