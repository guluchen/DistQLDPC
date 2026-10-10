#!/usr/bin/env python3
"""GH-107 (copy of GH-102 capped.py): run one command under the PI-mandated 2 GB per-process cap (memlimit.run, copied from
scratchpad/coord/memlimit.py). usage: capped.py OUTFILE TIMEOUT_S CMD... ; writes stdout (then stderr, if any)
to OUTFILE and prints 'rc=<rc> peak_rss_kb=<kb>' (rc may be MEMOUT or WATCHDOG)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import memlimit
out, tmo, cmd = sys.argv[1], float(sys.argv[2]), sys.argv[3:]
rc, so, se, peak = memlimit.run(cmd, tmo)
with open(out, 'w') as f:
    f.write(so)
    if se: f.write(se)
print(f'rc={rc} peak_rss_kb={peak}')
sys.exit(0 if rc == 0 else 1)
