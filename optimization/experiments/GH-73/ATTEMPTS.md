# GH-73 development log (informal single runs; disclosed because they informed the design)

Design iterations before freezing, each judged on single informal wall times of Tier1 cases plus
TN_200_10_10 and LP_340_56_8 (LP340 is also the Tier2 case: mild case contamination, disclosed).
1. stop-at-first fixed only in the outer loop -> every result UNKNOWN (MaxCDCL finds solutions inside
   `search()`); fixed by returning l_True there too.
2. Optimisation started at the proven LB -> hardest refutation first; ~2.5 s on BB90.
3. startAtCap for optimisation only -> probes still re-proved lower levels; BB90 ~1.9 s.
4. startAtCap for all runs -> BB90 ~1.0 s, LP340 ~3.4 s, but TN_200 ~58 s (tie 16/16 in phase 1 picked X).
5. Pure alternating stop-at-first probes -> minimal steps but refutations from scratch are slow
   (BB90 ~1.5–1.8 s; TN_200 25/59 s).
6. Hybrid (frozen): phase-1 doubling probes on both halves (anytime LB), tie-break probe rounds while
   incumbents are equal, then optimise halves smaller-incumbent first with cap U (find, descend,
   prove). Informal: BB90 0.9/1.5 s, BB108 1.4/1.1, GB144 0.31/0.35, LP238 0.56/0.59, TN_200 10.5/13.6,
   LP340 3.4/3.3 (default-or-OFF / MTO-or-no-card). Correct d in all runs; -joint byte-identical to baseline.
Learning: in MaxCDCL a refutation "no solution <= k" from scratch is several times more expensive than
the same proof reached by descending from a found solution within one run.
