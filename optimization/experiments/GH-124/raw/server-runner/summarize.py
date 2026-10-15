#!/usr/bin/env python3
"""Summarize GH-124 S0e/S0d runs: result, per-half proven-empty levels, witness check, wall time, node metrics.
usage: summarize.py RAWDIR [RAWDIR ...]   (each with results.jsonl, *.log, *.trace) -> TSV on stdout + JSON file"""
import json, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import wcheck

REPO = "/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb/cand-cc"
SD = os.path.dirname(os.path.abspath(__file__))


def local_prefix(code):
    if "/data/matrices/" in code:
        return REPO + "/data/matrices/" + code.split("/data/matrices/")[1]
    if "/gh124-s0de/calib2/" in code:
        return SD + "/calib2/" + code.split("/calib2/")[1]
    if "/gh124-s0de/calib/" in code:
        return SD + "/calib/" + code.split("/calib/")[1]
    return code


def parse_trace(path):
    lv = {"X": {}, "Z": {}}
    hdr = {}
    d = None
    trap = None
    if not os.path.exists(path):
        return None
    for line in open(path):
        line = line.rstrip("\n")
        if line.startswith("# n "):
            t = line[2:].split()
            hdr = dict(zip(t[0::2], t[1::2]))
        elif line.startswith("# d "):
            d = int(line.split()[2])
        elif line.startswith("# TRAP"):
            trap = line
        elif line and not line.startswith("#"):
            t = line.split()
            lv[t[0]][int(t[1])] = dict(verdict=t[2], nodes=int(t[3]), secs=float(t[4]),
                                       support=[int(x) for x in t[5:]])
    return dict(levels=lv, hdr=hdr, d=d, trap=trap)


def contiguous_empty(levels):
    w = 0
    while (w + 1) in levels and levels[w + 1]["verdict"] == "EMPTY":
        w += 1
    return w


def parse_log(path):
    txt = open(path, errors="replace").read()
    o = re.findall(r"^o (-?\d+)$", txt, re.M)
    lb = re.findall(r"^c d_lb: (\S+)$", txt, re.M)
    ub = re.findall(r"^c d_ub: (\S+)$", txt, re.M)
    dualimg = re.findall(r"^c witness Z \(dual image\): (.*)$", txt, re.M)
    vwit = re.findall(r"^c witness ([XZ]): (.*)$", txt, re.M)
    tot = re.findall(r"total nodes X (\d+) Z (\d+), search time X ([\d.]+)s Z ([\d.]+)s, wall ([\d.]+)s", txt)
    errs = [l for l in txt.splitlines() if l.startswith("error") or "TRAP" in l or "warning" in l]
    return dict(o=int(o[-1]) if o else None, timeout="TIMEOUT" in txt, lb=lb[-1] if lb else None,
                ub=ub[-1] if ub else None, dualimg=[[int(x) for x in s.split()] for s in dualimg],
                vwit=[(h, [int(x) for x in s.split()]) for h, s in vwit], tot=tot[-1] if tot else None, errs=errs)


def summarize(rawdirs):
    rows = []
    for rd in rawdirs:
        rf = os.path.join(rd, "results.jsonl")
        if not os.path.exists(rf):
            continue
        for l in open(rf):
            r = json.loads(l)
            if "error" in r:
                rows.append(dict(id=r["id"], error=r["error"]))
                continue
            i = r["id"]
            lg = parse_log(os.path.join(rd, i + ".log"))
            tr = parse_trace(os.path.join(rd, i + ".trace"))
            pre = local_prefix(r["code"])
            row = dict(id=i, code=os.path.basename(r["code"]), args=" ".join(a for a in r["args"] if a not in ("-v",)),
                       rc=r["rc"], wall=r["wall"], cap=r["cap"], o=lg["o"], timeout=lg["timeout"], lb=lg["lb"],
                       ub=lg["ub"], errs=lg["errs"], maxrss_kb=r.get("maxrss_kb"))
            if tr:
                dual = tr["hdr"].get("dual", "off") != "off"
                row["dual"] = dual
                for h in ("X", "Z"):
                    L = tr["levels"][h]
                    row["empty_" + h] = contiguous_empty(L) if L else None
                    row["found_" + h] = sorted(w for w, v in L.items() if v["verdict"] == "FOUND")
                    row["nodes_" + h] = sum(v["nodes"] for v in L.values())
                    row["secs_" + h] = round(sum(v["secs"] for v in L.values()), 3)
                row["trap"] = tr["trap"]
                # witness check (trace FOUND lines + dual images from the -v log)
                checks = []
                for h in ("X", "Z"):
                    for w, v in tr["levels"][h].items():
                        if v["verdict"] == "FOUND":
                            ok, why = wcheck.check(pre, h, v["support"])
                            checks.append((h, w, ok and len(v["support"]) == w, why))
                for s in lg["dualimg"]:
                    ok, why = wcheck.check(pre, "Z", s)
                    checks.append(("Z(dual image)", len(s), ok, why))
                row["witness"] = checks
            rows.append(row)
    return rows


def fmt(row):
    if "error" in row:
        return f"{row['id']}\tERROR {row['error']}"
    res = f"d={row['o']}" if row["o"] is not None and row["o"] >= 0 else \
        (f"TIMEOUT lb={row['lb']} ub={row['ub']}" if row["timeout"] else f"rc={row['rc']} o={row['o']}")
    if "empty_X" in row:
        ez = "mirror" if row.get("dual") else row["empty_Z"]
        lv = f"X<= {row['empty_X']} Z<= {ez}"
        fd = f"found X{row['found_X']} Z{row['found_Z']}"
        wit = "-" if not row["witness"] else ("yes" if all(c[2] for c in row["witness"]) else "NO")
        nodes = f"{row['nodes_X']}/{row['nodes_Z']}"
    else:
        lv = fd = wit = nodes = "-"
    return "\t".join(map(str, [row["id"], row["args"], res, lv, fd, wit, f"{row['wall']:.1f}", nodes,
                               ";".join(row["errs"]) or "-"]))


if __name__ == "__main__":
    rows = summarize(sys.argv[1:])
    print("id\targs\tresult\tempty levels (contiguous from 1)\tfound\twitness ok\twall s\tnodes X/Z\tnotes")
    for r in sorted(rows, key=lambda r: r["id"]):
        print(fmt(r))
    json.dump(rows, open(os.path.join(sys.argv[1], "summary.json"), "w"), indent=1)
