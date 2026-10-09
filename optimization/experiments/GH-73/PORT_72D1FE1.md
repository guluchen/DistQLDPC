# GH-73 port to the corrected baseline 72d1fe1 (#62)

Per the integrator (comment on #60) promotable comparisons must apply the single selected delta onto
corrected source 72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7. Branch experiment/gh-73-mac-cssinterleave-72d =
72d1fe1 + cherry-pick of b3a2fd9 (only conflict: NOTICE list, both entries kept). Source delta otherwise
identical. Earlier Tier0 sweep on 24572d6 was stopped at 52/200 comparisons (all OK) and is retained on
branch experiment/gh-73-mac-cssinterleave as historical evidence; all gating below uses 72d1fe1.
Mandatory regressions on both new baseline and ported candidate: smoke PASS;
scripts/test_partition_soft_literals.py (fixture optimum 5, 11 adjacent oracles) PASS;
tests/test_partition_soft_literals.cc GH58_PARTITION_ORACLE_PASS cases=80.
