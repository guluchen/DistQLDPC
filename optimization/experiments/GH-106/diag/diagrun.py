"""GH-106 diagnostic runner: ONE solver process at a time, 2 GB cap (coord/memlimit.py), fixed -cpu-lim.
Usage: diagrun.py --bin B --label L --cpu 300 [--extra '-inc-policy=x'] CASE:MODE ...  (MODE default|no-card|card-mto|...)"""
import argparse, os, sys, time, json
sys.path.insert(0, '/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/coord')
import memlimit
ap = argparse.ArgumentParser()
ap.add_argument('--bin', required=True); ap.add_argument('--label', required=True)
ap.add_argument('--cpu', type=int, default=300); ap.add_argument('--extra', default='')
ap.add_argument('--cwd', default='/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb/cand106')
ap.add_argument('--outdir', default=os.path.join(os.path.dirname(os.path.abspath(__file__)), 'runs'))
ap.add_argument('--noverbose', action='store_true')
ap.add_argument('cells', nargs='+')
a = ap.parse_args()
os.makedirs(os.path.join(a.outdir, a.label), exist_ok=True)
os.chdir(a.cwd)
for cell in a.cells:
    case, mode = cell.split(':')
    cmd = [a.bin, f'-cpu-lim={a.cpu}'] + ([] if a.noverbose else ['-v']) + a.extra.split()
    if mode != 'default': cmd.append('-' + mode)
    cmd.append(case)
    t0 = time.time()
    rc, out, err, peak = memlimit.run(cmd, timeout=a.cpu + 60)
    dt = time.time() - t0
    base = os.path.join(a.outdir, a.label, f'{case}.{mode}')
    open(base + '.out', 'w').write(out); open(base + '.err', 'w').write(err)
    o = [l for l in out.split('\n') if l.startswith('o ')]
    print(json.dumps({'cell': cell, 'label': a.label, 'rc': rc, 'o': o[-1] if o else None, 'peak_rss_mb': peak // 1024, 'cmd': cmd[1:]}), flush=True)
