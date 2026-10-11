"""Tier4 feasibility probe (PI 2026-10-11): can main 7eadd54 solve TN_250_10_15, BB_288_12_unknown, LP_714_100_unknown in 6 h?
One run per case x mode, all in parallel, 2 GB cap (RSS poll on macOS), stdout streamed with elapsed-time stamps."""
import os, sys, time, json, signal, subprocess, threading
W = os.path.abspath('..'); BIN = f'{W}/frozen-main7e/distqldpc'; LIM = 21600; WD = 21700; CAP_KB = 2048 * 1024
OUT = f'{W}/tier4-main-probe'
cases = ['TN_250_10_15', 'BB_288_12_unknown', 'LP_714_100_unknown']; modes = ['no-card', 'card-mto']
def rss(pgid):
    t = 0
    for l in subprocess.run(['ps', '-A', '-o', 'pgid=,rss='], capture_output=True, text=True).stdout.splitlines():
        p = l.split()
        if len(p) == 2 and p[0] == str(pgid): t += int(p[1])
    return t
def one(c, m, res):
    t0 = time.time(); f = open(f'{OUT}/{c}.{m}.log', 'w', buffering=1)
    p = subprocess.Popen([BIN, f'-cpu-lim={LIM}', '-' + m, c], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, preexec_fn=os.setsid)
    st = {'peak': 0, 'status': None}
    def reader():
        for line in p.stdout: f.write(f'{time.time()-t0:9.1f}\t{line}')
    th = threading.Thread(target=reader); th.start()
    while p.poll() is None:
        time.sleep(5); r = rss(p.pid); st['peak'] = max(st['peak'], r)
        if r > CAP_KB: st['status'] = 'MEMOUT'
        if time.time() - t0 > WD: st['status'] = st['status'] or 'WATCHDOG'
        if st['status']:
            try: os.killpg(p.pid, signal.SIGKILL)
            except ProcessLookupError: pass
            break
    p.wait(); th.join(); f.close()
    lines = open(f'{OUT}/{c}.{m}.log').read().splitlines()
    def last(prefix):
        v = [(float(l.split('\t')[0]), l.split('\t')[1]) for l in lines if '\t' in l and l.split('\t')[1].startswith(prefix)]
        return v
    res.append(dict(case=c, mode=m, rc=st['status'] or p.returncode, wall=round(time.time()-t0, 1), peak_rss_mb=round(st['peak']/1024),
                    lb_events=[(t, s.split()[-1]) for t, s in last('c d_lb:')], ub_events=[(t, s.split()[-1]) for t, s in last('c d_ub:')],
                    result=[(t, s) for t, s in last('o ')] + [(t, s) for t, s in last('c d  :')]))
res = []; ths = [threading.Thread(target=one, args=(c, m, res)) for c in cases for m in modes]
[t.start() for t in ths]; [t.join() for t in ths]
json.dump({'binary': BIN, 'limit_s': LIM, 'parallel_runs': len(ths), 'host': 'Mac (Apple M6, 12 CPUs)', 'results': res}, open(f'{OUT}/results.json', 'w'), indent=1)
for r in res: print(r['case'], r['mode'], r['rc'], r['wall'], 'lb', r['lb_events'][-1:] , 'ub', r['ub_events'][-1:], r['result'][-1:], 'peakMB', r['peak_rss_mb'])
