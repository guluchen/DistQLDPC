"""Per-process memory cap for solver runs (PI request 2026-10-10: 2 GB per process).
Linux: RLIMIT_AS set in the child before exec (inherited by the solver's forked worker).
macOS (RLIMIT_AS not enforced): poll the process group's total RSS and kill the group above the cap.
A capped run reports rc 'MEMOUT'."""
import os, resource, signal, subprocess, sys, time
DEFAULT_MB = 2048

def _preexec(limit_bytes):
    def f():
        os.setsid()
        if sys.platform.startswith('linux'):
            resource.setrlimit(resource.RLIMIT_AS, (limit_bytes, limit_bytes))
    return f

def _group_rss_kb(pgid):
    out = subprocess.run(['ps', '-A', '-o', 'pgid=,rss='], capture_output=True, text=True).stdout.split('\n')
    tot = 0
    for line in out:
        parts = line.split()
        if len(parts) == 2 and parts[0] == str(pgid): tot += int(parts[1])
    return tot

def run(cmd, timeout, mem_mb=DEFAULT_MB, poll=1.0):
    """Returns (rc, stdout, stderr, peak_rss_kb). rc is int, 'WATCHDOG' or 'MEMOUT'."""
    lim = mem_mb * 1024 * 1024
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, preexec_fn=_preexec(lim))
    t0 = time.time(); peak = 0; status = None
    import threading
    res = {}
    def comm(): res['out'], res['err'] = p.communicate()
    th = threading.Thread(target=comm); th.start()
    while th.is_alive():
        th.join(poll)
        if not th.is_alive(): break
        if sys.platform == 'darwin':
            r = _group_rss_kb(p.pid); peak = max(peak, r)
            if r > mem_mb * 1024: status = 'MEMOUT'
        if time.time() - t0 > timeout: status = status or 'WATCHDOG'
        if status:
            try: os.killpg(p.pid, signal.SIGKILL)
            except ProcessLookupError: pass
            th.join(); break
    rc = status if status else p.returncode
    if rc not in ('MEMOUT', 'WATCHDOG') and sys.platform.startswith('linux') and rc != 0 and 'bad_alloc' in (res.get('err') or ''):
        rc = 'MEMOUT'
    return rc, res.get('out', ''), res.get('err', ''), peak
