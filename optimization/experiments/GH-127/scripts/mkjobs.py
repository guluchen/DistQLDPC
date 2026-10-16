#!/usr/bin/env python3
"""GH-127: write a runjobs.py job file. Each job runs BIN -v -dualshare-stats CFG MODE -cpu-lim=LIM CODE.
Usage: mkjobs.py BIN REPO OUTDIR LIM JOBS.jsonl --codes C1,C2 --cfgs NAME1,NAME2 [--modes no-card,card-mto] [--quiet]"""
import argparse, json, os

CFGS = {
    "default": [],
    "on": ["-orbit-split=on"],
    "auto": ["-orbit-split=auto"],
    "unit": ["-lb-ladder=unit"],
    "both": ["-orbit-split=on", "-lb-ladder=unit"],
    "unit4": ["-lb-ladder=unit:4"],
    "on_unit4": ["-orbit-split=on", "-lb-ladder=unit:4"],
    "unit2": ["-lb-ladder=unit:2"],
    "unit8": ["-lb-ladder=unit:8"],
    "on_unit8": ["-orbit-split=on", "-lb-ladder=unit:8"],
    "on_unit2": ["-orbit-split=on", "-lb-ladder=unit:2"],
    "auto_unit2": ["-orbit-split=auto", "-lb-ladder=unit:2"],
    "on_skip": ["-orbit-split=on", "-dualmode=skip"],
    "on_dualoff": ["-orbit-split=on", "-dualmode=off"],
    "on_nosym": ["-orbit-split=on", "-no-symbreak"],
    "both_skip": ["-orbit-split=on", "-lb-ladder=unit:4", "-dualmode=skip"],
    "cc": ["-engine=cc"],
}
ap = argparse.ArgumentParser()
ap.add_argument("bin"); ap.add_argument("repo"); ap.add_argument("outdir"); ap.add_argument("lim"); ap.add_argument("jobs")
ap.add_argument("--codes", required=True); ap.add_argument("--cfgs", required=True)
ap.add_argument("--modes", default="no-card,card-mto")
ap.add_argument("--quiet", action="store_true", help="no -v / stats: the live anytime d_lb/d_ub lines are printed")
a = ap.parse_args()
os.makedirs(a.outdir, exist_ok=True)
with open(a.jobs, "w") as f:
    for code in a.codes.split(","):
        stem = os.path.basename(code)
        for cfg in a.cfgs.split(","):
            modes = [""] if cfg == "cc" else a.modes.split(",")
            for mode in modes:
                cmd = ([a.bin] if a.quiet else [a.bin, "-v"] + ([] if cfg == "cc" else ["-dualshare-stats"])) + CFGS[cfg]
                cmd += (["-" + mode] if mode else []) + ["-cpu-lim=" + a.lim, code]
                out = os.path.join(a.outdir, "%s.%s.%s.log" % (stem, cfg, mode or "cc"))
                f.write(json.dumps({"cmd": cmd, "out": out, "cwd": a.repo}) + "\n")
