# GH-148 status: paused by PI (token budget) during Tier 5 wave 1

Issue #148. Baseline main 12b3e05. Branch experiment/gh-148-stab-overlap; evaluated binary 2b297b5
(`-stab-overlap=auto`, native propagator in MaxCDCL). No PR, no merge.

## Proposals
- **A (chosen):** stabilizer-overlap dominance constraints in every MaxSAT half probe: for each same-type stabilizer
  row g with H g = 0, G g = 0, require |x & g| <= floor(|g|/2) (every minimum-weight logical satisfies it).
- B: MaxSAT Phase 2 step policy (lb ladder after Phase 1) - rejected (cannot beat main on Tiers 1-4 since GH-144).
- C: stronger CC lower bound (LP / fractional packing) - rejected (CC is optional; per-node cost).

## Evidence gathered before the pause
- Tier 0 PASS: make test-cc (300/200 and 1500/600, Part G vs enumeration, mutants 1/2 detected), test-cc-flags 329,
  tier0 78/78 answers, default and -stab-overlap=off logs identical to main (modulo main's own timing-dependent
  ub-pre print order).
- 5-seed panels (yfclab2 cores 90-123, ratio cand/main): Tier 1 1.000/1.000 (identical search; measured 0.989/0.956),
  Tier 2 0.698/0.697, Tier 3 0.949/0.994 (watch TN_144 1.07-1.10), Tier 4 0.781/0.859 (no-card/card-mto). All PASS.
  Tables: S1/panel_table.md; raw: S1/server/.
- Tier 5: wave 1 (34 cells) killed after ~1.1 h of 6 h; partial raw in S1/server/t5_wave1_partial.jsonl and S0 1 h
  probes in S0/server/s0_tier5_probe.jsonl: LP_1020 solved in 538-541 s (main recorded 1247-1254 s); lb 18 on
  BB_756/864/1080 at 14-24 s (main 685-2538 s); BB_360 lb 18 at 12 s (main 72 s); TN unchanged within 1 h.
  Tier 5 gate NOT evaluated; no Tier 5 bound claims.
- Not done: Tier 5 (6 h, 54 cells), REPORT.md, final PI decision. Default stays off.
