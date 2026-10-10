"""Parse GH-106 counter-build output into per-probe rows (delta = post - pre of that solver)."""
import sys, re
NUM = ['confl','dec','prop','starts','lk','lksucc','lkprop','softconfl']
def parse_kv(rest):
    t = rest.split(); d = {}
    i = 0
    while i + 1 < len(t):
        k, v = t[i], t[i+1]
        try: d[k] = float(v) if ('.' in v or 'e' in v) and '/' not in v else (v if '/' in v else int(v))
        except ValueError: d[k] = v
        i += 2
    return d
def probes(path):
    rows = []; cur = None; pre = None
    for line in open(path, errors='replace'):
        if line.startswith('c GH106P '):
            t = line.split(); cur = {'half': t[2], 'cap': int(t[4]), 'lb': int(t[6]), 'first': int(t[8]), 'builds': int(t[10])}
        elif line.startswith('c GH106S '):
            t = line.split(); cur['S'] = dict(zip(t[2::2], t[3::2]))
        elif line.startswith('c GH106 pre '):
            pre = parse_kv(line[len('c GH106 pre '):])
        elif line.startswith('c GH106 post '):
            rest = line[len('c GH106 post '):]
            outcome, rest = rest.split(' ', 1)
            post = parse_kv(rest)
            r = dict(cur); r['outcome'] = outcome; r['pre'] = pre; r['post'] = post
            fresh = outcome in ('TRUE','FALSE','UNDEF')
            if fresh: pre = dict(pre); [pre.__setitem__(k, 0) for k in NUM]; r['pre'] = pre
            for k in NUM: r['d_' + k] = post[k] - pre[k]
            rows.append(r)
    return rows
def table(path, extra=()):
    rows = probes(path)
    hdr = ['#','half','cap','lb','1st','out','d_confl','d_dec','d_prop(M)','d_lk','d_lkprop(M)','d_starts','pre core/t2/loc','post core/t2/loc','pre_trail'] + list(extra)
    out = ['| ' + ' | '.join(hdr) + ' |', '|' + '---|' * len(hdr)]
    tot = {k: 0 for k in NUM}
    for i, r in enumerate(rows):
        p, q = r['pre'], r['post']
        for k in NUM: tot[k] += r['d_' + k]
        cells = [i, r['half'], r['cap'], r['lb'], r['first'], r['outcome'], r['d_confl'], r['d_dec'], '%.1f' % (r['d_prop']/1e6), r['d_lk'], '%.1f' % (r['d_lkprop']/1e6), r['d_starts'],
                 '%d/%d/%d' % (p['core'], p['tier2'], p['local']), '%d/%d/%d' % (q['core'], q['tier2'], q['local']), p['trail']] + [str(p.get(e)) + '->' + str(q.get(e)) for e in extra]
        out.append('| ' + ' | '.join(map(str, cells)) + ' |')
    out.append('| total | | | | | | %d | %d | %.1f | %d | %.1f | %d | | | |' % (tot['confl'], tot['dec'], tot['prop']/1e6, tot['lk'], tot['lkprop']/1e6, tot['starts']) + ' |' * len(extra))
    return '\n'.join(out), tot, rows
if __name__ == '__main__':
    extra = sys.argv[2].split(',') if len(sys.argv) > 2 and sys.argv[2] else ()
    print(table(sys.argv[1], extra)[0])
