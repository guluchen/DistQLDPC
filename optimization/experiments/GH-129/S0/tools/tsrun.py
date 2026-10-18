#!/usr/bin/env python3
"""Run a command, prefix every stdout/stderr line with elapsed seconds; 2 GB process-group RSS cap."""
import os, signal, subprocess, sys, threading, time
out = open(sys.argv[1], 'w', buffering=1); cmd = sys.argv[2:]
t0 = time.monotonic()
p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, stdin=subprocess.DEVNULL, start_new_session=True)
def watch():
    while p.poll() is None:
        o = subprocess.run(['ps', '-A', '-o', 'pgid=,rss='], capture_output=True, text=True).stdout
        rss = sum(int(b) for a, b in (l.split() for l in o.splitlines() if len(l.split()) == 2) if a == str(p.pid))
        if rss > 2 * 1024 * 1024:
            out.write('MEMOUT\n'); os.killpg(p.pid, signal.SIGKILL)
        time.sleep(1)
threading.Thread(target=watch, daemon=True).start()
for line in p.stdout: out.write(f'{time.monotonic() - t0:9.1f} {line}')
out.write(f'{time.monotonic() - t0:9.1f} EXIT {p.wait()}\n')
