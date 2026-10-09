# GH-89 Tier1 result (coordinator) — POSITIVE vs 72d1fe1; also faster than GH-85 in every cell
Mac, timing lock, tier1_mac_dist.py; all samples correct (o = d, sound bounds), stopped None, no regression flags.
## Gate vs 72d1fe1 (frozen 3f2fbc42… vs frozen89/cand fb6846d0…)
| Case | OFF base s | OFF cand s | OFF ratio | MTO base s | MTO cand s | MTO ratio |
|---|---:|---:|---:|---:|---:|---:|
| BB_90_8_10 | 1.808 | 0.108 | 0.0597 | 1.645 | 0.121 | 0.0736 |
| GB_144_12_8 | 0.663 | 0.077 | 0.1161 | 1.109 | 0.078 | 0.0703 |
| BB_108_8_10 | 2.275 | 0.153 | 0.0673 | 2.328 | 0.175 | 0.0752 |
| LP_238_44_6 | 1.219 | 0.318 | 0.2609 | 1.157 | 0.250 | 0.2161 |
Gate geomean OFF 0.1050 (envelope 0.1479), MTO 0.0957 (envelope 0.0973). Replication (10 pairs): OFF 0.1036, MTO 0.0964.
Reference on the same host: GH-85 0.159 / 0.145, GH-73 0.485 / 0.498 (GH-76 alone: see GH-76 records).
## Attribution vs GH-85 (frozen85/cand 1c6f028a… as base), informational
| Case | OFF ratio | MTO ratio |
|---|---:|---:|
| BB_90_8_10 | 0.7200 | 0.8768 |
| GB_144_12_8 | 0.7802 | 0.9176 |
| BB_108_8_10 | 0.4005 | 0.3755 |
| LP_238_44_6 | 0.7737 | 0.6291 |
Geomean OFF 0.6463 (envelope 0.6885), MTO 0.6609 (envelope 0.6986), no regression flag.
The incremental half solver adds about 1.5x on top of per-half symmetry breaking; the gains compose.
Caveat: several candidate runs are ~0.1 s, where process start-up is a visible share; Tier2/Tier3 matter more.
