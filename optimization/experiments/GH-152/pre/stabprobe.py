import sys
sys.path.insert(0, sys.argv[1])
from autprobe import load, build, refine2
for stem in sys.argv[2:]:
    hx = load(stem + '_Hx.txt'); hz = load(stem + '_Hz.txt')
    n = max(max(r) for r in hx + hz) + 1
    adj, col = build(hx, hz, n)
    base = refine2(adj, col, col)[0]
    res = []
    for v in (0, n // 2):
        c = list(base); c[v] = max(base) + 1
        r = refine2(adj, c, c)[0]
        res.append(f"q{v}: cells {len(set(r))}/{len(adj)}")
    print(stem.split('/')[-1], 'base cells', len(set(base)), *res)
