"""GH-106 identity traces. Serial (one solver process at a time), 2 GB cap, -cpu-lim=120 on both sides.
  cand -inc-policy=gh89 -v   == frozen89 -v          (byte-identical)
  cand -joint -v             == frozen89 -joint -v   (byte-identical)
  cand -v (default postsol)  recorded (o value compared with frozen89)
usage (repo root): traces.py CAND FROZEN89 OUTDIR"""
import os, sys, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import memlimit
cand, ref, out = sys.argv[1:4]
os.makedirs(out, exist_ok=True)
codes = ['BB_90_8_10', 'GB_144_12_8', 'BB_108_8_10', 'LP_238_44_6', 'LP_34_20_2', 'BB_72_12_6', 'TN_36_8_4']
def run(b, args, path):
    rc, o, e, pk = memlimit.run([b, '-v', '-cpu-lim=120'] + args, timeout=200)
    open(path, 'w').write(o + e)
    return rc, o
res = []; nid = 0; n = 0
for code in codes:
    for m in ['no-card', 'card-mto', 'default']:
        f = [] if m == 'default' else ['-' + m]
        p = lambda tag: os.path.join(out, '%s.%s.%s.txt' % (code, m, tag))
        _, a = run(ref, f + [code], p('gh89'))
        _, b = run(cand, ['-inc-policy=gh89'] + f + [code], p('cand-gh89'))
        _, c = run(ref, ['-joint'] + f + [code], p('gh89-joint'))
        _, d = run(cand, ['-joint'] + f + [code], p('cand-joint'))
        _, e = run(cand, f + [code], p('cand'))
        oo = lambda s: ([l for l in s.split('\n') if l.startswith('o ')] or ['o ?'])[-1]
        id1 = a == b; id2 = c == d
        n += 2; nid += id1 + id2
        builds = [l for l in e.split('\n') if 'solver builds' in l]
        line = '%s %s gh89-policy-vs-frozen89=%s joint-vs-frozen89-joint=%s frozen89_o=[%s] cand_default_o=[%s] default_builds=[%s]' % (
            code, m, 'IDENTICAL' if id1 else 'DIFFER', 'IDENTICAL' if id2 else 'DIFFER', oo(a), oo(e), builds[-1][2:] if builds else '')
        print(line, flush=True); res.append(line)
open(os.path.join(out, 'SUMMARY.txt'), 'w').write('\n'.join(res) + '\nidentical %d/%d\n' % (nid, n))
print('identical %d/%d' % (nid, n))
