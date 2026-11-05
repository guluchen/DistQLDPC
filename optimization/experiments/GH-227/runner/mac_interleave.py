#!/usr/bin/env python3
"""GH-227 (copied from GH-225) same-session interleaved re-run on the Mac (serial, one process at a time, run under caffeinate -i -s by the
caller; 2 GB RSS cap by polling the process group). Default seed (Tier 5 convention). For each code, REPS rounds in ABBA
order (round r: A,E if r even, else E,A). Records wall, user time and the per-level search times from -cc-stats.
usage: mac_interleave.py A_BIN E_BIN DATAROOT OUT.jsonl REPS STEM...   (STEM found under DATAROOT/*/)"""
import glob, json, os, re, signal, subprocess, sys, time
ABIN, EBIN, ROOT, OUT, REPS = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5])
CAP = 2 * 1024 * 1024   # KB


def rss_kb(pgid):
    p = subprocess.run(['ps', '-g', str(pgid), '-o', 'rss='], capture_output=True, text=True)
    return sum(int(x) for x in p.stdout.split() if x.isdigit())


def one(binp, code, stem, arm, rep):
    t0 = time.monotonic()
    p = subprocess.Popen([binp, '-engine=cc', '-cc-stats', '-cpu-lim=3600', code], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                         stdin=subprocess.DEVNULL, text=True, start_new_session=True)
    memout = False
    lines = []
    import threading
    def watch():
        nonlocal memout
        while p.poll() is None:
            if rss_kb(p.pid) > CAP:
                memout = True
                os.killpg(p.pid, signal.SIGKILL); return
            time.sleep(1)
    threading.Thread(target=watch, daemon=True).start()
    for l in p.stdout: lines.append(l)
    _, st, ru = os.wait4(p.pid, 0)
    wall = time.monotonic() - t0
    res = next((int(l.split()[1]) for l in lines if l.startswith('o ')), None)
    levels = [l.strip()[12:] for l in lines if l.startswith('c cc-stats: ') and ' level ' in l]
    stime = sum(float(m.group(1)) for lv in levels for m in [re.search(r'(?:EMPTY|FOUND)\S* nodes \d+ .*time ([0-9.]+)s', lv)] if m)
    rec = dict(stem=stem, arm=arm, rep=rep, wall=round(wall, 3), utime=round(ru.ru_utime, 3), result=res, memout=memout,
               search_time=round(stime, 3), levels=levels)
    with open(OUT, 'a') as f: f.write(json.dumps(rec) + '\n')
    print(f'{stem} {arm} rep {rep}: wall {wall:.2f}s search {stime:.2f}s o {res}', flush=True)


for stem in sys.argv[6:]:
    code = glob.glob(f'{ROOT}/*/{stem}_Hx.txt')[0][:-7]
    for r in range(REPS):
        order = [('A', ABIN), ('E', EBIN)] if r % 2 == 0 else [('E', EBIN), ('A', ABIN)]
        for arm, b in order: one(b, code, stem, arm, r)
