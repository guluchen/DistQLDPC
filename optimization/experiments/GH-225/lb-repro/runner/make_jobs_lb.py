#!/usr/bin/env python3
"""GH-225 lb reproduction jobs: main 1239e9a2 (CC default A, -cc-roworder=auto) with and without erasure, relabelled or reordered."""
import json, sys
B = '/home/yfc/mac-agent-20261009/frozen/server-gh225lb-main-1239e9a/distqldpc'
E = '-cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,sparsemrv,erasure'
STEMS = ['TN_324_4_22to25', 'TN_496_2_27to30', 'TN_540_4_23to34', 'TN_648_14_21to28', 'COLOR_1027_1_28to37', 'TN_684_2_22to29']
LIM = 43200
ARMS = [('E.s1', [E, '-seed=1'], 1), ('E.s2', [E, '-seed=2'], 2), ('E.bfs', [E, '-cc-roworder=bfs'], 0), ('A.s1', ['-seed=1'], 1)]
with open(sys.argv[1], 'w') as f:
    for arm, extra, seed in ARMS:
        for s in STEMS:
            f.write(json.dumps(dict(id=f'lb.{s}.{arm}', bin=B, args=['-engine=cc', '-cc-stats'] + extra, code=f'data/matrices/tier5/{s}',
                                    stem=s, tier='tier5', arm=arm, seed=seed, limit=LIM)) + '\n')
