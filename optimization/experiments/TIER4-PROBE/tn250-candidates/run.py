import sys, os, json, time, concurrent.futures as cf
sys.path.insert(0, '/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/coord')
import memlimit
W = os.path.abspath('..')
bins = {'main': f'{W}/frozen-main7e/distqldpc', 'gh106_postsol': f'{W}/frozen106/cand/distqldpc',
        'gh89': f'{W}/frozen89/cand/distqldpc', 'gh98_xor': f'{W}/frozen98/cand/distqldpc'}
jobs = [(k, m) for k in bins for m in ('no-card', 'card-mto')]
def one(km):
    k, m = km; t = time.time()
    rc, out, err, peak = memlimit.run([bins[k], '-cpu-lim=1800', '-' + m, 'TN_250_10_15'], 1830)
    open(f'{k}.{m}.out', 'w').write(out); open(f'{k}.{m}.err', 'w').write(err)
    lbs = [int(l.split()[-1]) for l in out.splitlines() if l.startswith('c d_lb:')]
    ubs = [int(l.split()[-1]) for l in out.splitlines() if l.startswith('c d_ub:')]
    res = [l for l in out.splitlines() if l.startswith('o ') or l.startswith('c d  :')]
    return dict(bin=k, mode=m, rc=rc, wall=round(time.time()-t, 1), final_lb=max(lbs) if lbs else None, final_ub=min(ubs) if ubs else None, result=res, peak_kb=peak)
with cf.ThreadPoolExecutor(8) as ex:
    R = list(ex.map(one, jobs))
json.dump(R, open('results.json', 'w'), indent=1)
for r in R: print(r)
