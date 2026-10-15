#!/usr/bin/env python3
"""Compare the 3600 s -engine=cc lower bounds of the 17 open tier5 codes with ADJUDICATION.md section 3
(prototype, excl,pack,orbf, 30 min TN / 60 min BB). Per-half lb = (levels 1..w all EMPTY) + 1.
usage: compare17.py SERVER_RAW"""
import os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from summarize import parse_trace, contiguous_empty

# stem: (prototype lb, Z lb reached, X lb reached, orbits per half)
ADJ = {
    "TN_288_2_ge9": (18, 19, 18, "trivial"), "TN_324_4_ge9": (18, 19, 18, "trivial"),
    "TN_432_8_ge9": (19, 19, 19, "trivial"), "TN_540_4_ge9": (19, 19, 19, "trivial"),
    "TN_576_2_ge9": (20, 20, 20, "trivial"), "TN_648_14_ge9": (19, 20, 19, "trivial"),
    "TN_648_10_9to52": (19, 20, 19, "trivial"), "TN_684_2_ge9": (20, 20, 20, "36"),
    "TN_360_4_ge17": (20, 21, 20, "36"), "TN_396_4_ge17": (20, 21, 20, "36"), "TN_468_4_ge17": (20, 21, 20, "36"),
    "TN_496_2_ge17": (20, 20, 20, "16"), "TN_504_2_ge17": (21, 22, 21, "36"), "TN_612_2_ge17": (22, 22, 22, "36"),
    "BB_756_16_ge17": (25, 25, 25, "2"), "BB_864_4_ge17": (25, 25, 25, "2"), "BB_1080_4_ge17": (25, 26, 25, "2"),
}
raw = sys.argv[1]
print("stem\tours lb (Z/X)\tprototype lb (Z/X)\tdelta\tlast level running at cap\tdual")
for s, (plb, pz, px, orb) in ADJ.items():
    tr = parse_trace(os.path.join(raw, f"o_{s}_def.trace"))
    L = tr["levels"]
    dual = tr["hdr"].get("dual", "off") != "off"
    ex = contiguous_empty(L["X"]) + 1
    ez = ex if dual else contiguous_empty(L["Z"]) + 1
    lb = min(ex, ez)
    print(f"{s}\t{lb} ({ez}/{ex})\t{plb} ({pz}/{px})\t{lb - plb:+d}\tnext: X{ex} Z{'-' if dual else ez}\t{'yes' if dual else 'no'}")
