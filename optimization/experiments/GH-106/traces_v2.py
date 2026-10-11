"""GH-106 v2 identity traces. Serial (one solver process at a time), 2 GB cap, -cpu-lim=120 on both sides.
  v2 -inc-policy=gh89 -v     == frozen89 -v             (byte-identical)
  v2 -joint -v               == frozen89 -joint -v      (byte-identical)
  v2 -inc-policy=postsol -v  == frozen106 (v1) -v       (byte-identical: v1's default was postsol)
  v2 -v (default budgettot)  recorded (o compared)
usage (repo root): traces_v2.py V2 FROZEN89 FROZEN106V1 OUTDIR"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import memlimit
cand, ref89, ref106, out = sys.argv[1:5]
os.makedirs(out, exist_ok=True)
codes = ['BB_90_8_10', 'GB_144_12_8', 'BB_108_8_10', 'LP_238_44_6', 'LP_34_20_2', 'BB_72_12_6', 'TN_36_8_4']
def run(b, args, path):
    rc, o, e, pk = memlimit.run([b, '-v', '-cpu-lim=120'] + args, timeout=200)
    open(path, 'w').write(o + e)
    return o
res = []; nid = 0; n = 0
oo = lambda s: ([l for l in s.split('\n') if l.startswith('o ')] or ['o ?'])[-1]
for code in codes:
    for m in ['no-card', 'card-mto', 'default']:
        f = [] if m == 'default' else ['-' + m]
        p = lambda tag: os.path.join(out, '%s.%s.%s.txt' % (code, m, tag))
        a = run(ref89, f + [code], p('gh89')); b = run(cand, ['-inc-policy=gh89'] + f + [code], p('v2-gh89'))
        c = run(ref89, ['-joint'] + f + [code], p('gh89-joint')); d = run(cand, ['-joint'] + f + [code], p('v2-joint'))
        g = run(ref106, f + [code], p('v1')); h = run(cand, ['-inc-policy=postsol'] + f + [code], p('v2-postsol'))
        e = run(cand, f + [code], p('v2'))
        ids = [a == b, c == d, g == h]; n += 3; nid += sum(ids)
        line = '%s %s gh89=%s joint=%s postsol-vs-v1=%s frozen89_o=[%s] v1_o=[%s] v2_default_o=[%s]' % (
            code, m, *['IDENTICAL' if x else 'DIFFER' for x in ids], oo(a), oo(g), oo(e))
        print(line, flush=True); res.append(line)
open(os.path.join(out, 'SUMMARY.txt'), 'w').write('\n'.join(res) + '\nidentical %d/%d\n' % (nid, n))
print('identical %d/%d' % (nid, n))
