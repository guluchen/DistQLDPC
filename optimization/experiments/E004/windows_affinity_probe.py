"""Short owned-process probe: validate Cygwin solver fork affinity and cleanup."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time
from windows_cpu_window import Window, affinity, descendant_affinities
from run_windows_tier1 import cygpath

ap = argparse.ArgumentParser()
ap.add_argument('--prior', type=Path, required=True)
ap.add_argument('--cygwin-root', type=Path, required=True)
ap.add_argument('--output', type=Path, required=True)
a = ap.parse_args()
a.output.mkdir(exist_ok=False, parents=True)
pkg = a.prior.resolve()/'E004-server-package'
os.environ['PATH'] = str(a.cygwin_root.resolve()/'bin') + os.pathsep + os.environ['PATH']
w = Window(True)
records = []
try:
    for version in ['baseline', 'candidate']:
        cmd = [str(pkg/version/'bin/distqldpc.exe'), '-v', '-cpu-lim=1', '-no-card',
               cygpath(pkg/'baseline/data/matrices/BB_108_8_10')]
        with (a.output/(version+'.stdout')).open('w', encoding='utf8') as so:
            proc = subprocess.Popen(cmd, stdout=so, stderr=subprocess.STDOUT)
            masks = []
            deadline = time.monotonic()+10
            while proc.poll() is None and time.monotonic() < deadline:
                masks += descendant_affinities(proc.pid)
                time.sleep(0.1)
            if proc.poll() is None:
                subprocess.run(['taskkill', '/PID', str(proc.pid), '/T', '/F'], capture_output=True)
                proc.wait(timeout=10)
                raise RuntimeError('Probe external watchdog')
        records.append(dict(version=version, command=cmd, returncode=proc.returncode,
                            affinities=masks, child_observed=any(r['pid'] != proc.pid for r in masks)))
        assert masks and all(r['mask'] == w.mask for r in masks), 'Affinity inheritance failed'
        assert records[-1]['child_observed'], 'Fork child not observed; no inheritance claim'
        output = (a.output/(version+'.stdout')).read_text(encoding='utf8')
        assert proc.returncode == 1 and 's UNKNOWN' in output and 'c status: TIMEOUT' in output
finally:
    cleanup = w.close()
    (a.output/'probe.json').write_text(json.dumps(dict(selection=w.selection, records=records,
        cleanup=cleanup), indent=2), encoding='utf8')
    assert cleanup['affinity_restored'] and cleanup['sleep_requirement_restored']
print('AFFINITY_PROBE_PASS', flush=True)
