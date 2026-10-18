#!/usr/bin/env python3
"""Summarise S0 work counts: per (code, mode, arm) wall, total conflicts/decisions (sum over probes,
from -frontier-stats lines), frontier picks share, answer check; ratios vs arm 'off' and geomeans."""
import json, math, re, sys, collections
d = sys.argv[1]
jobs = {j["id"]: j for j in map(json.loads, open(f"{d}/jobs.jsonl"))}
res = {r["id"]: r for r in map(json.loads, open(f"{d}/results.jsonl"))}
rows = {}
for jid, r in res.items():
    j = jobs[jid]; code, mode, arm = jid.split(".")
    err = open(j["err"]).read(); out = open(j["out"]).read()
    conf = dec = picks = 0
    for m in re.finditer(r"conflicts (\d+) decisions (\d+) frontier_picks (\d+)", err):
        conf += int(m.group(1)); dec += int(m.group(2)); picks += int(m.group(3))
    o = re.findall(r"^o (\d+)", out, re.M)
    dstem = code.split("_")[3]
    ok = bool(o) and o[-1] == dstem
    rows[(code, mode, arm)] = dict(tier=j.get("tier", ""), wall=r["wall"], conf=conf, dec=dec, picks=picks, o=o[-1] if o else "-", ok=ok, status=r["status"], rss=r["peak_rss_mb"])
arms = ["off", "on", "postsol", "presol"]
print("| tier | code | mode | off wall s / conflicts / decisions | " + " | ".join(f"{a} wall ratio / confl ratio / dec ratio (picks %)" for a in arms[1:]) + " | answers |")
print("|---|---|---|---|" + "---|" * (len(arms) - 1) + "---|")
geo = collections.defaultdict(list)
for (code, mode, arm), x in sorted(rows.items(), key=lambda kv: (kv[1]["tier"], kv[0])):
    if arm != "off": continue
    cells = []; ans = []
    for a in arms:
        y = rows.get((code, mode, a))
        if not y: cells.append("-"); continue
        ans.append(("ok" if y["ok"] else "BAD:" + y["o"]))
        if a == "off": continue
        wr = y["wall"] / x["wall"]; cr = (y["conf"] + 1) / (x["conf"] + 1); dr = (y["dec"] + 1) / (x["dec"] + 1)
        geo[(x["tier"], mode, a, "wall")].append(wr); geo[(x["tier"], mode, a, "conf")].append(cr)
        cells.append(f"{wr:.3f} / {cr:.3f} / {dr:.3f} ({100*y['picks']/max(1,y['dec']):.0f}%)")
    print(f"| {x['tier']} | {code} | {mode} | {x['wall']:.2f} / {x['conf']} / {x['dec']} | " + " | ".join(cells[1:] if False else cells) + f" | {','.join(ans)} |")
print()
print("| tier | mode | arm | geomean wall ratio | geomean conflict ratio | max wall ratio | n |")
print("|---|---|---|---|---|---|---|")
for k in sorted(set((t, m, a) for t, m, a, _ in geo)):
    w = geo[k + ("wall",)]; c = geo[k + ("conf",)]
    g = lambda v: math.exp(sum(map(math.log, v)) / len(v))
    print(f"| {k[0]} | {k[1]} | {k[2]} | {g(w):.3f} | {g(c):.3f} | {max(w):.3f} | {len(w)} |")
