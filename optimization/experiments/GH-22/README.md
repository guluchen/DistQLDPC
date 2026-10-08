# GH-22 symmetric lookahead binary-conflict activity

[Preregistered proposal](PROPOSAL.md), [three methods](THREE_METHODS.md),
[issue22](https://github.com/guluchen/DistQLDPC/issues/22).
Baseline24572d6. Branch experiment/gh22-vsids. Exactly one Solver.cc byte:
second `.1` VSIDS lookahead binary-conflict bump selects binConfl[1].
No scientific formulation/build/compiler changes. Original notices preserved;
MODIFICATIONS/NOTICE record the downstream experimental patch.

State Tier0 PASS / performance UNMEASURED / NOT ADOPTED. Hosted and guarded
local checks pass; mechanism is active in LP136. See [Tier0 result](TIER0_RESULT.md)
and [hosted audit](HOSTED_RESULT.md). Windows released after assignment6063822659;
fresh host assignment required for [Tier1](TIER1_PLAN.md). No Tier2/3 or speedup claim.
Do not mistake changed search counters for incorrect results; exact independent
optima/bounds/output/timeout correctness is mandatory. Read prior failed methods.
