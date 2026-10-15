#!/usr/bin/env python3
"""GH-124 S0 report: compare in-repo CC traces (114b901, raw/mac-s0d, raw/server-s0de*) with the
prototype LOGS under ext/logs (proto_validate_orbf, proto_t5, proto_t5_mt, proto_xcheck): per (half, level)
verdict and node count, and ns/node on large EMPTY levels. Reads logs only (clean-room rule: no prototype
source). Paths are absolute to the Mac scratch workspace. Output: cmp_proto.txt."""
import re, sys, os, glob
ROOT = "/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb"
RAW = ROOT + "/cand-cc/optimization/experiments/GH-124/raw"
PL = ROOT + "/ext/logs"

def read_trace(p):
    cells = {}
    for ln in open(p):
        if ln.startswith('#') or not ln.strip(): continue
        f = ln.split()
        cells[(f[0], int(f[1]))] = (f[2], int(f[3]), float(f[4]))
    return cells

pat = re.compile(r'^\[\s*([0-9.]+)s\]\s+([XZ]) w=(\d+) (none|FOUND) nodes=(\d+)')
def read_proto(p):
    cells = {}; prev = 0.0
    for ln in open(p):
        m = pat.match(ln)
        if not m: continue
        t = float(m.group(1)); v = 'EMPTY' if m.group(4) == 'none' else 'FOUND'
        cells[(m.group(2), int(m.group(3)))] = (v, int(m.group(5)), t - prev)
        prev = t
    return cells

def cmp(name, ours, proto, ns_min=5e6, mt=False):
    a = read_trace(ours); b = read_proto(proto)
    common = sorted(set(a) & set(b), key=lambda k: (k[1], k[0]))
    vm = sum(1 for k in common if a[k][0] == b[k][0])
    nm = sum(1 for k in common if a[k][1] == b[k][1])
    diff = [(k, a[k][:2], b[k][:2]) for k in common if a[k][:2] != b[k][:2]]
    # ns/node on big EMPTY levels
    rat = []
    for k in common:
        if a[k][0] == 'EMPTY' and b[k][0] == 'EMPTY' and a[k][1] >= ns_min and a[k][1] == b[k][1]:
            nsa = a[k][2] / a[k][1] * 1e9; nsb = b[k][2] / b[k][1] * 1e9
            rat.append((k, round(nsa, 1), round(nsb, 1), round(nsa / nsb, 3)))
    onlyb = sorted(set(b) - set(a), key=lambda k: (k[1], k[0]))
    onlya = sorted(set(a) - set(b), key=lambda k: (k[1], k[0]))
    print(f"== {name}: common {len(common)}, verdict match {vm}, node match {nm}, only-proto {len(onlyb)} {[(h+str(w), b[(h,w)][0]) for h,w in onlyb][-6:]}, only-ours {len(onlya)} {[(h+str(w), a[(h,w)][0]) for h,w in onlya][-6:]}")
    for d in diff: print("   DIFF", d)
    if rat:
        rs = [r[3] for r in rat]
        print(f"   ns/node ours/proto on {len(rat)} levels >= {ns_min:.0e} nodes: min {min(rs)} max {max(rs)}; last: {rat[-3:]}")

T5 = PL + "/proto_t5"; XC = PL + "/proto_xcheck"; V = PL + "/proto_validate_orbf"
S = RAW + "/server-s0de"
mac = RAW + "/mac-s0d"
which = sys.argv[1] if len(sys.argv) > 1 else 'all'
if which in ('mac', 'all'):
    for c, t in [('BB_288_12_18', 'mac_BB_288_12_18_dualoff_rep1'), ('BB_288_12_18', 'mac_BB_288_12_18_rep1'), ('TN_250_10_15', 'mac_TN_250_10_15_rep1'), ('TN_250_10_15', 'mac_TN_250_10_15_rep2'), ('TN_250_10_15', 'mac_TN_250_10_15_rep3'), ('LP_544_80_12', 'mac_LP_544_80_12_rep1'), ('BB_288_12_18', 'mac_BB_288_12_18_dualoff_rep2'), ('BB_288_12_18', 'mac_BB_288_12_18_dualoff_rep3')]:
        cmp('MAC ' + t, f"{mac}/{t}.trace", f"{V}/{c}.excl,pack,orbf.t1.log", ns_min=1e6)
if which in ('srv', 'all'):
    pairs = [
      ('e_BB_360_12_17to24_def', T5 + '/BB_360_12_17to24.excl,pack,orbf.t1.log'),
      ('e_BB_360_12_17to24_mrv', XC + '/BB_360_12_17to24.excl,mrv,pack,orbf.t1.log'),
      ('e_LP_1054_140_17to32_def', T5 + '/LP_1054_140_17to32.excl,pack,orbf.t1.log'),
      ('e_LP_1054_140_17to32_mrv', XC + '/LP_1054_140_17to32.excl,mrv,pack,orbf.t1.log'),
      ('e_LP_1054_140_17to32_noorb', XC + '/LP_1054_140_17to32.excl,pack.t1.log'),
      ('e_LP_1428_184_ge17_def', T5 + '/LP_1428_184_ge17.excl,pack,orbf.t1.log'),
      ('e_LP_1428_184_ge17_mrv', XC + '/LP_1428_184_ge17.excl,mrv,pack,orbf.t1.log'),
      ('e_LP_1768_224_ge17_def', T5 + '/LP_1768_224_ge17.excl,pack,orbf.t1.log'),
      ('e_LP_1768_224_ge17_mrv', XC + '/LP_1768_224_ge17.excl,mrv,pack,orbf.t1.log'),
      ('e_TN_252_2_17to28_def', T5 + '/TN_252_2_17to28.excl,pack,orbf.t1.log'),
      ('e_TN_252_2_17to28_def', PL + '/proto_t5_mt/TN_252_2_17to28.excl,pack,orbf.t4.log'),
      ('e_TN_252_2_17to28_mrv', XC + '/TN_252_2_17to28.excl,mrv,pack,orbf.t4.log'),
      ('x_LP_1020_136_16_def', T5 + '/LP_1020_136_16.excl,pack,orbf.t1.log'),
      ('x_TN_216_4_18_def', T5 + '/TN_216_4_18.excl,pack,orbf.t1.log'),
    ]
    for t, p in pairs:
        d = S if os.path.exists(f"{S}/{t}.trace") else RAW + "/server-s0de2"
        cmp('SRV ' + t + ' vs ' + os.path.basename(p), f"{d}/{t}.trace", p, ns_min=1e7)
    cmp('SRV e_TN_252_seqsched vs t4', RAW + '/server-s0de3/e_TN_252_2_17to28_seqsched.trace', PL + '/proto_t5_mt/TN_252_2_17to28.excl,pack,orbf.t4.log', ns_min=1e7)
    for p in sorted(glob.glob(T5 + '/*.excl,pack,orbf.t1.log')):
        stem = os.path.basename(p).split('.')[0]
        t = f"{S}/o_{stem}_def.trace"
        if os.path.exists(t): cmp('SRV o_' + stem, t, p, ns_min=1e7)
