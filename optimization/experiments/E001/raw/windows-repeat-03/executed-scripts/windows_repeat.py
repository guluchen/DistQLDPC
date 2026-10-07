#!/usr/bin/env python3
"""Re-run unchanged E001 checks into a fresh Windows evidence directory."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    for name in ['package', 'cygwin-root', 'probe', 'previous', 'output']:
        ap.add_argument('--' + name, type=Path, required=True)
    a = ap.parse_args()
    pkg, out = a.package.resolve(), a.output.resolve()
    a.probe = a.probe.resolve()
    cygwin = a.cygwin_root.resolve()
    previous = a.previous.resolve()
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    expected = json.loads((previous / 'environment.json').read_text(encoding='utf8'))['binary_sha256']
    for version in ['baseline', 'candidate']:
        assert sha(pkg / version / 'bin/distqldpc.exe') == expected[version], version
    assert sha(a.probe) == json.loads((previous / 'native-python.json').read_text(encoding='utf8'))['probe_sha256']
    manifest = json.loads((pkg / 'manifest.json').read_text(encoding='utf8'))
    for rel, expected_sha in manifest['files'].items():
        assert sha(pkg / rel) == expected_sha, rel
    out.mkdir(parents=True, exist_ok=False)
    (out / 'identity-check.json').write_text(json.dumps({'status': 'PASS',
        'same_binaries_as_first_round': expected, 'probe_sha256': sha(a.probe),
        'package_files_verified': len(manifest['files']), 'previous': str(previous),
        'invocation': sys.argv, 'native_python_version': sys.version}, indent=2), encoding='utf8')
    os.environ['PATH'] = str(cygwin / 'bin') + os.pathsep + os.environ['PATH']
    os.environ.update(LC_ALL='C', OMP_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1', MKL_NUM_THREADS='1')
    original_run = subprocess.run

    def cygpath(value):
        text = str(value).replace('\\', '/')
        return '/cygdrive/' + text[0].lower() + text[2:] if len(text) > 2 and text[1] == ':' else text

    def adapted_run(args, *rest, **kw):
        if str(args[0]) == 'bash':
            args = [str(cygwin / 'bin/bash.exe')] + [cygpath(p) for p in args[1:]]
        else:
            args = [args[0]] + [cygpath(p) for p in args[1:]]
        return original_run(args, *rest, **kw)

    subprocess.run = adapted_run
    os.chdir(pkg / 'candidate')
    sys.argv = [str(pkg / 'candidate/optimization/tests/tier0.py'),
        '--baseline', str(pkg / 'baseline/bin/distqldpc.exe'),
        '--candidate', str(pkg / 'candidate/bin/distqldpc.exe'),
        '--probe', str(a.probe.resolve()), '--qdistsat', str(pkg / 'qdistsat'),
        '--out', str(out / 'tier0')]
    try:
        runpy.run_path(sys.argv[0], run_name='__main__')
    finally:
        subprocess.run = original_run
    sys.argv = [str(Path(__file__).resolve().with_name('windows_diagnostic.py')),
        '--package', str(pkg), '--output', str(out)]
    runpy.run_path(sys.argv[0], run_name='__main__')


if __name__ == '__main__':
    main()
