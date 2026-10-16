#!/usr/bin/env python3
"""S0d metrics from cc traces: ns/node, per-level growth b, hit-level share, Z/X cost ratio, server/Mac ratio.
usage: s0d_metrics.py SERVER_RAW MAC_RAW TRACE_ID..."""
import json, os, statistics, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from summarize import parse_trace

srv, mac = sys.argv[1], sys.argv[2]


def tstats(path):
    tr = parse_trace(path)
    L = tr["levels"]
    nodes = sum(v["nodes"] for h in L for v in L[h].values())
    secs = sum(v["secs"] for h in L for v in L[h].values())
    big = [(v["nodes"], v["secs"]) for h in L for v in L[h].values() if v["nodes"] >= 10 ** 6]
    ns_big = 1e9 * sum(s for _, s in big) / sum(n for n, _ in big) if big else None
    growth = {}
    for h in ("X", "Z"):
        ws = sorted(w for w in L[h] if L[h][w]["verdict"] == "EMPTY")
        g = []
        for w in ws[-4:]:
            if (w - 1) in L[h] and L[h][w - 1]["nodes"] > 0:
                g.append(round(L[h][w]["nodes"] / L[h][w - 1]["nodes"], 2))
        growth[h] = g
    hit = [v["secs"] for h in L for v in L[h].values() if v["verdict"] == "FOUND"]
    sx = sum(v["secs"] for v in L["X"].values()); sz = sum(v["secs"] for v in L["Z"].values())
    return dict(nodes=nodes, secs=round(secs, 3), ns_per_node=round(1e9 * secs / nodes, 1) if nodes else None,
                ns_per_node_big=round(ns_big, 1) if ns_big else None, growth_last4=growth,
                hit_share=round(sum(hit) / secs, 4) if secs else None, z_over_x=round(sz / sx, 3) if sx and sz else None)


out = {}
for i in sys.argv[3:]:
    p = os.path.join(srv, i + ".trace")
    if os.path.exists(p):
        out[i] = tstats(p)
        print(i, json.dumps(out[i]))
# server / Mac ratio on search time (sum of per-level seconds) and wall
mres = [json.loads(l) for l in open(os.path.join(mac, "results.jsonl"))]
sres = {}
for d in (srv,):
    for l in open(os.path.join(d, "results.jsonl")):
        r = json.loads(l)
        sres[r["id"]] = r
print("\nserver/Mac ratio")
for code in ("BB_288_12_18", "TN_250_10_15", "LP_544_80_12"):
    mids = [r["id"] for r in mres if os.path.basename(r["code"]) == code]
    sids = [f"d_{code}_seed0", f"r_{code}_rep2", f"r_{code}_rep3"]
    ms = [tstats(os.path.join(mac, i + ".trace"))["secs"] for i in mids]
    ss = [tstats(os.path.join(srv, i + ".trace"))["secs"] for i in sids if os.path.exists(os.path.join(srv, i + ".trace"))]
    mw = [r["wall"] for r in mres if r["id"] in mids]
    sw = [sres[i]["wall"] for i in sids if i in sres]
    print(code, "mac search s", ms, "server search s", ss, "ratio median %.2f min %.2f" % (
        statistics.median(ss) / statistics.median(ms), min(ss) / min(ms)),
        "| wall mac", mw, "server", sw, "ratio median %.2f" % (statistics.median(sw) / statistics.median(mw)))
    mt = tstats(os.path.join(mac, mids[0] + ".trace"))
    print("   mac ns/node", mt["ns_per_node"], "big-level ns/node", mt["ns_per_node_big"])
