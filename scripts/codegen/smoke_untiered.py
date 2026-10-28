#!/usr/bin/env python3
"""Linux-only, serial 60s HGP smoke package; run only on a PI-assigned free core.

Never assigns a core. Preserves logs, argv, binary/input hashes and raw bounds.
Writes a separate results CSV, leaving manifest edits for evidence review.
"""
import argparse
import csv
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def parse(text, expected):
    lbs = re.findall(r'^c d_lb:\s*(\d+)\s*$', text, re.M)
    ubs = re.findall(r'^c d_ub:\s*(\d+)\s*$', text, re.M)
    answers = re.findall(r'^o (\d+)\s*$', text, re.M)
    for kind in ('lb','ub'):
        events = re.findall(rf'^c d_{kind}:\s*(\d+|-)\s*$',text,re.M)
        if events and events[-1] == '-':
            raise ValueError('final bound unavailable/withdrawn; review required')
    if any(int(x)>expected for x in lbs) or any(int(x)<expected for x in ubs):
        raise ValueError('bound contradicts published exact distance')
    if any(int(x)!=expected for x in answers):
        raise ValueError('answer contradicts published exact distance')
    if not lbs or not ubs:
        raise ValueError('missing bounds; inspect load/run failure')
    return dict(lb=max(map(int,lbs)), ub=min(map(int,ubs)),
                status='SOLVED' if answers else 'BOUNDED')


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--cpu', type=int, required=True, help='PI-assigned core, check it is free first')
    ap.add_argument('--bin', type=Path, default=ROOT/'bin/distqldpc')
    ap.add_argument('--out', type=Path, required=True, help='new evidence directory')
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()
    rows = list(csv.DictReader((ROOT/'data/matrices/untiered/MANIFEST.csv').open()))
    jobs = []
    for row in rows:
        if row['family'] != 'HGP':
            continue
        cmd = ['taskset','-c',str(args.cpu),'prlimit','--as=4294967296','--',
               str(args.bin.resolve()),'-cpu-lim=60',f'data/matrices/untiered/{row["stem"]}']
        jobs.append((row,cmd))
    if args.dry_run:
        print(json.dumps([cmd for _,cmd in jobs],indent=2))
        return
    if not sys.platform.startswith('linux'):
        ap.error('execution is Linux-server only; use --dry-run to inspect jobs')
    if args.cpu not in os.sched_getaffinity(0):
        ap.error('core outside allowed affinity')
    # A snapshot supplements, but does not replace, the operator free-core check.
    for proc in Path('/proc').glob('[0-9]*/status'):
        try:
            text = proc.read_text()
        except (OSError,ProcessLookupError):
            continue
        if re.search(rf'^Cpus_allowed_list:\s*{args.cpu}\s*$',text,re.M):
            ap.error(f'core already has a pinned process: {proc}')
    args.out.mkdir(parents=True,exist_ok=False)
    records = []
    for row,cmd in jobs:
        stem = row['stem']
        identity = {kind:sha(ROOT/f'data/matrices/untiered/{stem}_{kind}.txt')
                    for kind in ('Hx','Hz','Gx','Gz')}
        meta = {'cmd':cmd,'binary_sha256':sha(args.bin),'input_sha256':identity,
                'source_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()}
        (args.out/f'{stem}.json').write_text(json.dumps(meta,indent=2)+'\n')
        with (args.out/f'{stem}.log').open('w') as log:
            proc = subprocess.Popen(cmd,cwd=ROOT,stdin=subprocess.DEVNULL,
                                    stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
            try:
                rc = proc.wait(timeout=90)
            except subprocess.TimeoutExpired:
                os.killpg(proc.pid,signal.SIGKILL)
                proc.wait()
                raise RuntimeError(f'{stem}: wall backstop hit; inspect raw log')
        result = parse((args.out/f'{stem}.log').read_text(),int(row['claimed_d'].split()[1]))
        if rc not in (0,1) or (rc == 0) != (result['status']=='SOLVED'):
            raise RuntimeError(f'{stem}: unexpected exit status {rc}')
        records.append(dict(stem=stem,rc=rc,**result))
        with (args.out/'results.csv').open('w',newline='') as f:
            writer = csv.DictWriter(f,fieldnames=['stem','rc','lb','ub','status'])
            writer.writeheader()
            writer.writerows(records)
        print(stem,result,flush=True)
    (args.out/'DONE').write_text(f'{len(records)} smoke runs; review before updating manifest\n')


if __name__ == '__main__':
    main()
