# GH-22 symmetric lookahead binary-conflict activity

[Preregistered proposal](PROPOSAL.md), [three methods](THREE_METHODS.md),
[issue22](https://github.com/guluchen/DistQLDPC/issues/22).
Baseline24572d6. Branch experiment/gh22-vsids. Exactly one Solver.cc byte:
second `.1` VSIDS lookahead binary-conflict bump selects binConfl[1].
No scientific formulation/build/compiler changes. Original notices preserved;
MODIFICATIONS/NOTICE record the downstream experimental patch.

State general-purpose LOCAL REJECT / NOT ADOPTED; formal controlled performance
INCONCLUSIVE. Tier0 PASS, Tier1 completed48 correct solves with a strong mode
interaction: OFF regresses, all four MTO cases improve. See [result](RESULT.md),
[Tier0](TIER0_RESULT.md), [hosted](HOSTED_RESULT.md). No Tier2/3 or merge;
new specialization must be separately proposed/prerecorded, not silently retuned.
Do not mistake changed search counters for incorrect results; exact independent
optima/bounds/output/timeout correctness is mandatory. Read prior failed methods.
