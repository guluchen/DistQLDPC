#!/usr/bin/env python3
"""GH-144 Mac quick check (answers only; no timing claim): candidate with -ub-pre=on on tier0-2 x {-no-card, -card-mto},
serial, each process polled for RSS and killed above 2 GB (MEMOUT); the caller wraps it in caffeinate -i -s.
Records the answer, the first c d_ub (the pre-pass U0) and the wall seconds (informational).
usage: mac_quick.py BIN OUT.jsonl   (from a worktree root)"""
import glob, json, os, signal, subprocess, sys, time
BIN, OUT = sys.argv[1:3]
codes = []
for t in (0, 1, 2):
    codes += [(t, f[:-7]) for f in sorted(glob.glob(f'data/matrices/tier{t}/*_Hx.txt'))]
bad = 0
with open(OUT, 'w') as fo:
    for t, code in codes:
        stem = os.path.basename(code); d = int(stem.split('_')[3])
        for mode in ('-no-card', '-card-mto'):
            t0 = time.monotonic()
            p = subprocess.Popen([BIN, mode, '-ub-pre=on', '-cpu-lim=600', code], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                 stdin=subprocess.DEVNULL, text=True, start_new_session=True)
            memout = False
            while p.poll() is None:
                try:
                    rss = sum(int(x) for x in subprocess.run(['ps', '-o', 'rss=', '-g', str(p.pid)], capture_output=True, text=True).stdout.split())
                except Exception: rss = 0
                if rss > 2 * 1024 * 1024:
                    memout = True; os.killpg(p.pid, signal.SIGKILL); break
                time.sleep(0.2)
            out = p.communicate()[0]; wall = time.monotonic() - t0
            ans = [int(l.split()[1]) for l in out.splitlines() if l.startswith('o ')]
            ub = [int(l.split()[2]) for l in out.splitlines() if l.startswith('c d_ub: ') and l.split()[2].isdigit()]
            ok = (not memout) and ans == [d] and all(u >= d for u in ub)
            bad += not ok
            rec = dict(tier=t, stem=stem, mode=mode[1:], answer=ans[0] if ans else None, first_ub=ub[0] if ub else None, wall=round(wall, 3), memout=memout, ok=ok)
            fo.write(json.dumps(rec) + '\n'); fo.flush()
            print(rec, flush=True)
print('bad', bad)
