"""All per-probe rows of all runs under runs/ -> per_probe.csv (deltas + selected pre/post state)."""
import sys, os, csv, re, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from probes import probes, NUM
STATE = ['core','tier2','local','card','hardens','vars','trail','lk_thres','lk_coef','lk_nbS','lk_maxS','var_decay','step','timer','var_inc','polT','actV','actC','actLB','coreLimit','conflV','feas']
w = csv.writer(open(sys.argv[2], 'w', newline=''))
w.writerow(['config','cell','idx','half','cap','lb','first','outcome','value'] + ['d_'+k for k in NUM] + ['pre_'+k for k in STATE] + ['post_'+k for k in STATE])
for d in sorted(glob.glob(os.path.join(sys.argv[1], '*'))):
    for f in sorted(glob.glob(os.path.join(d, '*.out'))):
        rows = probes(f)
        res = [re.search(r'(feasibility|optimize) -> (\w+) (\d+)', l) for l in open(f, errors='replace') if re.match(r'c CSS i[a-z]*: [XZ] half cap', l)]
        for i, r in enumerate(rows):
            m = res[i] if i < len(res) else None
            v = m.group(3) if m and m.group(2) in ('FOUND','OPT') else ''
            w.writerow([os.path.basename(d), os.path.basename(f)[:-4], i, r['half'], r['cap'], r['lb'], r['first'], r['outcome'], v] + [r['d_'+k] for k in NUM] + [r['pre'].get(k) for k in STATE] + [r['post'].get(k) for k in STATE])
