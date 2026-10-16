#!/usr/bin/env python3
"""GH-124 S0 report: S0d metrics recomputed from the 114b901 traces (ns/node, growth b of the last 4 EMPTY
levels, hit-level share of search time, Z/X search-time ratio, server/Mac ratio on seed-0 repeats, seed
variance). Output: metrics.txt."""
import json, os, statistics as st, glob
RAW = "/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb/cand-cc/optimization/experiments/GH-124/raw"
def tr(p):
    L = {'X': {}, 'Z': {}}
    for ln in open(p):
        if ln.startswith('#') or not ln.strip(): continue
        f = ln.split(); L[f[0]][int(f[1])] = (f[2], int(f[3]), float(f[4]))
    return L
def m(p):
    L = tr(p)
    nodes = sum(v[1] for h in L for v in L[h].values()); secs = sum(v[2] for h in L for v in L[h].values())
    big = [(v[1], v[2]) for h in L for v in L[h].values() if v[1] >= 1e6 and v[0] == 'EMPTY']
    nsb = [round(1e9 * s / n, 1) for n, s in big]
    hit = sum(v[2] for h in L for v in L[h].values() if v[0] == 'FOUND')
    sx = sum(v[2] for v in L['X'].values()); sz = sum(v[2] for v in L['Z'].values())
    g = {}
    for h in 'XZ':
        ws = sorted(w for w in L[h] if L[h][w][0] == 'EMPTY')
        g[h] = [round(L[h][w][1] / L[h][w-1][1], 2) for w in ws[-4:] if w-1 in L[h] and L[h][w-1][1] > 0]
    return dict(nodes=nodes, secs=round(secs, 3), ns_all=round(1e9*secs/nodes, 1) if nodes else None,
                ns_big=(min(nsb), max(nsb)) if nsb else None, hit=round(hit/secs, 4) if secs else None,
                zx=round(sz/sx, 2) if sx and sz else None, g=g)
S = RAW + "/server-s0de"; M = RAW + "/mac-s0d"
def sp(i):
    for d in ("/server-s0de", "/server-s0de2", "/server-s0de3"):
        if os.path.exists(RAW + d + "/" + i + ".trace"): return RAW + d + "/" + i + ".trace"
    raise FileNotFoundError(i)
print("--- S0d server/Mac (seed 0 default, 3 each)")
mres = {json.loads(l)['id']: json.loads(l) for l in open(M + "/results.jsonl")}
sres = {}
for d in ("/server-s0de", "/server-s0de2", "/server-s0de3"):
    for l in open(RAW + d + "/results.jsonl"):
        r = json.loads(l); sres[r['id']] = r
for c in ("BB_288_12_18", "TN_250_10_15", "LP_544_80_12"):
    mids = [f"mac_{c}_rep{i}" for i in (1, 2, 3)]
    sids = [f"d_{c}_seed0", f"r_{c}_rep2", f"r_{c}_rep3"]
    ms = [m(f"{M}/{i}.trace")['secs'] for i in mids]; ss = [m(sp(i))['secs'] for i in sids]
    mw = [mres[i]['wall'] for i in mids]; sw = [sres[i]['wall'] for i in sids]
    print(c, "mac search", ms, "srv search", ss, "ratio med %.2f" % (st.median(ss)/st.median(ms)), "| wall mac", mw, "srv", sw, "ratio %.2f" % (st.median(sw)/st.median(mw)))
    for i in mids: print("   mac", i, m(f"{M}/{i}.trace"))
    for i in sids: print("   srv", i, m(sp(i)), "core", sres[i]['core'])
print("--- seeds")
for c in ("BB_288_12_18", "TN_250_10_15", "LP_544_80_12"):
    for s in range(5):
        mi = f"mac_{c}_rep1" if s == 0 else f"mac_{c}_seed{s}_rep1"; si = f"d_{c}_seed{s}"
        a = m(f"{M}/{mi}.trace"); b = m(sp(si))
        print(c, s, "nodes", a['nodes'], b['nodes'], "mac s", a['secs'], "mac wall", mres[mi]['wall'], "srv wall", sres[si]['wall'], "srv ns_all", b['ns_all'], "core", sres[si]['core'])
print("--- dual off")
for i in ("mac_BB_288_12_18_dualoff_rep1", "mac_BB_288_12_18_dualoff_rep2", "mac_BB_288_12_18_dualoff_rep3"):
    print(i, m(f"{M}/{i}.trace"), mres[i]['wall'])
print("--- tier5")
for p in sorted(glob.glob(S + "/[exo]_*.trace")) + [RAW + "/server-s0de3/e_TN_252_2_17to28_seqsched.trace"]:
    i = os.path.basename(p)[:-6]
    r = sres.get(i) or {}
    print(i, m(p), "core", r.get('core'), "maxrss", r.get('maxrss_kb'))
