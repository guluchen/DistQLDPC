#!/usr/bin/env python3
"""Write the GH-124 S0e/S0d job list for yfclab2 (cores 0-63, one process per core at a time)."""
import json, sys

R = "/home/yfc/mac-agent-20261009/gh124-114b901/data/matrices"
CAL = "/home/yfc/mac-agent-20261009/gh124-s0de/calib"
CC = ["-engine=cc", "-v", "-cc-stats"]
jobs = []


def job(i, core, cap, code, args, trace=True):
    jobs.append(dict(id=i, core=core, cap=cap, code=code, args=args, trace=trace))


claims = ["BB_360_12_17to24", "TN_252_2_17to28", "LP_1054_140_17to32", "LP_1428_184_ge17", "LP_1768_224_ge17"]
# S0e: default rules (cores 0-4), MRV rule-diverse (cores 5-9), LP_1054 without orbits (core 10)
for k, s in enumerate(claims):
    job(f"e_{s}_def", k, 21600, f"{R}/tier5/{s}", CC)
    job(f"e_{s}_mrv", 5 + k, 21600, f"{R}/tier5/{s}", CC + ["-cc-rules=excl,pack,orbf,mrv"])
job("e_LP_1054_140_17to32_noorb", 10, 21600, f"{R}/tier5/LP_1054_140_17to32", CC + ["-cc-rules=excl,pack"])

others = ["TN_288_2_ge9", "TN_324_4_ge9", "TN_432_8_ge9", "TN_540_4_ge9", "TN_576_2_ge9", "TN_648_14_ge9",
          "TN_648_10_9to52", "TN_684_2_ge9", "TN_360_4_ge17", "TN_396_4_ge17", "TN_468_4_ge17", "TN_496_2_ge17",
          "TN_504_2_ge17", "TN_612_2_ge17", "BB_756_16_ge17", "BB_864_4_ge17", "BB_1080_4_ge17"]
assert len(others) == 17
for k, s in enumerate(others):   # cores 11-27
    job(f"o_{s}_def", 11 + k, 3600, f"{R}/tier5/{s}", CC)

# extra (not requested): the four tier5 codes main already solves, default rules, 6 h cap (cores 28-31)
for k, s in enumerate(["LP_714_100_16", "LP_1020_136_16", "TN_180_2_17", "TN_216_4_18"]):
    job(f"x_{s}_def", 28 + k, 21600, f"{R}/tier5/{s}", CC)

# S0d: -cc-stats and -cc-seed variance, seeds 0-4 (cores 32-46)
d3 = [("tier3", "BB_288_12_18"), ("tier4", "TN_250_10_15"), ("tier3", "LP_544_80_12")]
core = 32
for t, s in d3:
    for seed in range(5):
        job(f"d_{s}_seed{seed}", core, 3600, f"{R}/{t}/{s}", CC + [f"-cc-seed={seed}"])
        core += 1
# single-half saving: BB_288 with the dual map off (core 47)
job("d_BB_288_12_18_dualoff", 47, 3600, f"{R}/tier3/BB_288_12_18", CC + ["-cc-dual=off"])

# selector calibration, cap 600 s (cores 48-63)
cal = ["TORIC_72_2_6", "PLANAR_61_1_6", "TORIC_128_2_8", "PLANAR_113_1_8", "TORIC_200_2_10", "PLANAR_181_1_10",
       "TORIC_288_2_12", "PLANAR_265_1_12"]
cfgs = [("ccpack", ["-engine=cc", "-cc-stats"], True), ("ccnopack", ["-engine=cc", "-cc-stats", "-cc-rules=excl,orbf"], True),
        ("maxsat", ["-engine=maxsat"], False)]
cal_jobs = [(s, c) for s in reversed(cal) for c in cfgs]   # largest first
for k, (s, (cn, a, tr)) in enumerate(cal_jobs):
    job(f"c_{s}_{cn}", 48 + (k % 16), 600, f"{CAL}/{s}", a, tr)
# speed-ratio repeats on the server (seed 0 twice more per code), after the calibration jobs
k = len(cal_jobs)
for rep in (2, 3):
    for t, s in d3:
        job(f"r_{s}_rep{rep}", 48 + (k % 16), 3600, f"{R}/{t}/{s}", CC)
        k += 1

with open(sys.argv[1], "w") as f:
    for j in jobs:
        f.write(json.dumps(j) + "\n")
print(len(jobs), "jobs on", len({j["core"] for j in jobs}), "cores")
