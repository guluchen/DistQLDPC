# GH-107 re-evaluation under the 2026-10-12 tiers (coordinator, preregistered before any run)
PI 2026-10-12: evaluate GH-107 first (then GH-95 + GH-103); a candidate replaces main only after Tier 5.
GH-107 differs from main only on codes with a verified XZ-dual map (non-dual codes: search identical; trace identity on the
non-dual Tier 3/4 codes was 8/8 in raw/nondual-identity). Codes with a verified map (-dualskip-report on main 86f4a58 data):
tier0 BB_72_12_6, BB_90_8_10, GB_144_12_8, TN_36_8_4; tier1 BB_108_8_10, BB_144_12_12; tier3 BB_144_14_14, GB_144_12_12;
tier4 BB_288_12_18; tier5 BB_360_12_17to24, BB_756_16_ge17, BB_864_4_ge17, BB_1080_4_ge17.
1. Mac (tiers 0-4, dual-map codes): tier_cached_mac.py vs the recorded Mac main baseline (3 runs + 1 drift sample, stem
   answer checks, 2 GB cap, resolved paths); limits tier0 600 s, tier1-3 1800 s, tier4 2000 s. Spot trace identity for 2
   non-dual tier2/tier3 codes (TN_108_2_12, LP_442_68_10) to confirm the identical-search argument on the new layout.
2. yfclab2 (tier5, dual-map codes): GH-107 (src 0889c59, built on the server) on the 4 BB tier5 codes x 2 modes, one pinned
   core each, 4 GB cap, 21600 s; compared with main's tier5 results from the 2026-10-12 server run (same main build, same limit).
Pass rule: no answer inconsistency; tiers 1-4: every cell median <= recorded main median with no non-overlapping regression,
per-mode geomean < 1 (tier0: correctness / severe slowdown only); tier5: never a weaker final bound than main where main
times out, and not slower where main solves.

Addendum (2026-10-13): the first Mac run (raw/eval-v2-INVALID-mac-slept) is void — the Mac went into idle/maintenance sleep
from 2026-10-12 20:19 (pmset log), stretching seconds of work into hours and triggering wall-clock watchdog kills. The Mac part is
re-run under caffeinate -i -s (2 GB cap, serial, >= 2 cores left free) into raw/eval-v2b. Tier5 (yfclab2) result: GH-107 equals
main on all 8 dual-map tier5 cells (same final bounds; all time out) => tier5 PASS (never weaker than main).
