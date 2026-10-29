#!/usr/bin/env python3
"""Recheck of the 4 MaxSAT DIFFERENT-TIMING cells (default -ub-pre=on): base e52d15b and the adoption binary, 5 runs each,
pinned core 67, 4 GB cap; full -v logs with time fields masked (as ident_adopt.py); reports distinct log hashes per binary
and whether the two sets overlap. usage: recheck_timing.py BASE CAND (from a worktree root)"""
import hashlib, re, subprocess, sys
BASE, CAND = sys.argv[1:3]
MASK = [re.compile(r'cpu[ =]?\d+\.\d+s?'), re.compile(r'\d+\.\d+ ?s\b'), re.compile(r'\d+\.\d+s\)'), re.compile(r'detect_cpu=\d+\.\d+s'),
        re.compile(r'time\s*:?\s*\d+\.\d+'), re.compile(r'(CPU time|Real time|Wall)[^\n]*', re.I), re.compile(r'wall \d+\.\d+s')]
def h(b, args):
    p = subprocess.run(['taskset', '-c', '67', 'prlimit', '--as=4294967296', '--', b] + args, capture_output=True, text=True, stdin=subprocess.DEVNULL)
    t = p.stdout + '\n--\n' + p.stderr
    for m in MASK: t = m.sub('<T>', t)
    return hashlib.sha1(t.encode()).hexdigest()[:8]
for code, mode in (('GB_144_12_8', '-no-card'), ('LP_136_32_4', '-card-mto'), ('LP_34_20_2', '-no-card'), ('TN_36_8_3', '-card-mto')):
    a = [h(BASE, ['-v', mode, '-cpu-lim=300', code]) for _ in range(5)]
    b = [h(CAND, ['-v', mode, '-cpu-lim=300', code]) for _ in range(5)]
    print(f'{code} {mode}: base {sorted(set(a))} x{len(a)}  cand {sorted(set(b))} x{len(b)}  overlap {bool(set(a) & set(b))}', flush=True)
