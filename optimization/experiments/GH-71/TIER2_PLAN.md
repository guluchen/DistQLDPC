# GH-71 Tier2 plan (written before any LP340 timing)
Tier1 numerically positive with no regression => standard Tier2: LP_340_56_8, `-no-card` and
`-card-mto`, baseline 3 + candidate 3 AB/BA/AB, `-cpu-lim=600`, watchdog 615 s, same frozen
binaries, bound-soundness runner, quiet host. Decision: direction consistent with Tier1 and no
regression => Tier2 PASS (local diagnostic); otherwise not corroborated. No Tier3 launched.
Command: tier1_mac_dist.py --cases LP_340_56_8 --limit 600 --watchdog 615 --out raw/tier2-01
