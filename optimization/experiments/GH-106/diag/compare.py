"""Markdown table: total conflicts / lookaheads per (cell, config) and ratio vs the first config; geomean."""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from probes import probes
def tot(path):
    rows = probes(path)
    o = [l.split()[1] for l in open(path, errors='replace') if l.startswith('o ')]
    return sum(r['d_confl'] for r in rows), sum(r['d_lk'] for r in rows), len(rows), (o[-1] if o else '?')
def table(rundir, cells, configs, names):
    hdr = '| cell | ' + ' | '.join('%s confl (lk) [probes] o' % n for n in names) + ' | ' + ' | '.join('%s/%s' % (n, names[0]) for n in names[1:]) + ' |'
    out = [hdr, '|' + '---|' * (1 + 2 * len(names) - 1)]
    logs = {n: [] for n in names[1:]}
    for c in cells:
        vals = []
        for cfg in configs:
            p = os.path.join(rundir, cfg, c + '.out')
            vals.append(tot(p) if os.path.exists(p) else None)
        cellsv = ['%d (%d) [%d] %s' % v if v else 'n/a' for v in vals]
        rat = []
        for n, v in zip(names[1:], vals[1:]):
            if v and vals[0]: r = v[0] / vals[0][0]; logs[n].append(math.log(r)); rat.append('%.2f' % r)
            else: rat.append('n/a')
        out.append('| %s | %s | %s |' % (c, ' | '.join(cellsv), ' | '.join(rat)))
    out.append('| geomean | ' + ' | '.join([''] * len(names)) + ' | ' + ' | '.join('%.2f' % math.exp(sum(l) / len(l)) if l else 'n/a' for l in logs.values()) + ' |')
    return '\n'.join(out)
if __name__ == '__main__':
    rundir = sys.argv[1]; cells = sys.argv[2].split(','); pairs = [x.split('=') for x in sys.argv[3].split(',')]
    print(table(rundir, cells, [p[1] for p in pairs], [p[0] for p in pairs]))
