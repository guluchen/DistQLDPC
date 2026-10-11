"""One-line-per-run summary: probe sequence (half cap kind -> result value conflicts[k]) + totals."""
import sys, re
sys.path.insert(0, __import__('os').path.dirname(__file__))
from probes import probes
def summ(path):
    rows = probes(path)
    res = [l for l in open(path, errors='replace') if re.match(r'c CSS i[a-z]*: [XZ] half cap', l)]
    o = [l.strip() for l in open(path, errors='replace') if l.startswith('o ')]
    parts = []; tc = tl = tp = 0
    it = iter(res)
    for r in rows:
        if r['outcome'] in ('INTR', 'REBUILD'):
            tc += r['d_confl']; tl += r['d_lk']; tp += r['d_prop']
            parts.append('%s%d:%s/%dk' % (r['half'], r['cap'], r['outcome'][0], round(r['d_confl'] / 1000))); continue
        l = next(it)
        m = re.search(r'(feasibility|optimize) -> (\w+) (\d+)', l)
        kind = 'f' if m.group(1) == 'feasibility' else 'o'
        v = m.group(3) if m.group(2) in ('FOUND', 'OPT') else ''
        tc += r['d_confl']; tl += r['d_lk']; tp += r['d_prop']
        if r['cap'] >= 9 or r['d_confl'] > 5000:
            parts.append('%s%d%s:%s%s/%dk' % (r['half'], r['cap'], kind, m.group(2)[0], v, round(r['d_confl'] / 1000)))
    return 'confl %8d lk %8d prop %6.1fM %s | %s' % (tc, tl, tp / 1e6, o[-1] if o else 'o ?', ' '.join(parts))
if __name__ == '__main__':
    for p in sys.argv[1:]: print('%-50s %s' % (p.split('runs/')[-1], summ(p)))
