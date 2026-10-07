"""Run unchanged Tier 0 using native Python and Cygwin's compiled solver/probe."""
import os
from pathlib import Path
import runpy
import subprocess
import sys

taskdir = Path(__file__).resolve().parent.parent
package = taskdir / 'E001-linux-package'
evidence = taskdir / 'DistQLDPC/optimization/experiments/E001/raw/windows-validation'
os.environ['PATH'] = str(taskdir / 'windows-validation/cygwin/bin') + os.pathsep + os.environ['PATH']
os.environ.update(LC_ALL='C', OMP_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1')
original_run = subprocess.run


def cygpath(value):
    text = str(value).replace('\\', '/')
    if len(text) > 2 and text[1] == ':':
        return '/cygdrive/' + text[0].lower() + text[2:]
    return text


def adapted_run(args, *rest, **kw):
    if str(args[0]) == 'bash':
        args = [str(taskdir / 'windows-validation/cygwin/bin/bash.exe')] + [cygpath(p) for p in args[1:]]
    else:
        # The Unix CLI recognizes '/' in matrix prefixes, not Windows '\\'.
        args = [args[0]] + [cygpath(p) for p in args[1:]]
    return original_run(args, *rest, **kw)


subprocess.run = adapted_run
failed = evidence / 'tier0'
retained = evidence / 'tier0-invalid-native-path'
if retained.exists():
    retained = evidence / 'tier0-before-utf8-fix'
if failed.exists() and not (failed / 'summary.json').exists() and not retained.exists():
    assert failed.resolve().is_relative_to(taskdir)
    assert retained.resolve().is_relative_to(taskdir)
    failed.rename(retained)
os.chdir(package / 'candidate')
sys.argv = [str(package / 'candidate/optimization/tests/tier0.py'),
    '--baseline', str(package / 'baseline/bin/distqldpc.exe'),
    '--candidate', str(package / 'candidate/bin/distqldpc.exe'),
    '--probe', str(evidence / 'probe.exe'), '--qdistsat', str(package / 'qdistsat'),
    '--out', str(evidence / 'tier0')]
runpy.run_path(sys.argv[0], run_name='__main__')
subprocess.run = original_run
sys.argv = [str(taskdir / 'DistQLDPC/optimization/server/windows_diagnostic.py'),
    '--package', str(package), '--output', str(evidence)]
runpy.run_path(sys.argv[0], run_name='__main__')
