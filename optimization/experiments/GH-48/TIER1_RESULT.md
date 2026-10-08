# GH48 Tier 1: INCONCLUSIVE, not adopted

All 48 scientific results PASS, original numeric filter REJECT, formal
performance decision INCONCLUSIVE. This is not Tier1 PASS and does not authorize
adoption or automatic Tier2/3. No reproducible material improvement is established.

Immutable candidate d27cf4d from baseline24572d6: only fixed x86-64-v2 compiler
option; no new source/binary build/tuning/diagnostic/idea during this filter.
Executed support `db3a898007132456e67cc7240c4a3db00b5f9ea0`, driver SHA
`75d9117274cab3068b38273de7ebe57bc65de33151788be13593b1f31a58e609`.
Assignment: https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6069801563
Prelaunch: https://github.com/guluchen/DistQLDPC/issues/48#issuecomment-6069808475
One fresh GH48-windows-tier1-01, session91746 exit0. No failed timing attempt.

Fixed successful Tier0 binaries: baseline70582f38a02b8e2b2948867f9ea3680f44ca9e04184bdb7891f1f51a7222693e;
candidateef61efc3d6a4605c19b9c4b279dc95d08914910efb946221030601bfe24c2317.
Actual CPU14/sibling15/mask16384/AboveNormal32768; selected-core portable v2 gate
PASS. Serial AB/BA/AB, three solves per version/case/mode, internal180/external195,
aggregate10800. No subset selection, repeat-until-win, or numeric threshold change.
Authenticated source execution of helper/original numeric filter bypassed caches.

All 48 complete outputs have correct expected d/objective/every interim-final
LB/UB, unchanged status/return code and no stderr/crash. Independent audit verifies
actual argv/order/elapsed/raw fields, all159 original manifest payloads, all input,
binary, source and original10216runtime identities/fileset. Every raw timing triple
is retained in raw/windows-tier1-01/samples.json, result.json and AUDIT.json.

| Case | Mode | Baseline median s | Candidate median s | Change | Ranges |
| --- | --- | ---: | ---: | ---: | --- |
| BB_90_8_10 | OFF | 2.457891100 | 2.460181200 | +0.093173% | disjoint slower |
| BB_90_8_10 | MTO | 3.016593400 | 3.002520700 | -0.466510% | overlap |
| GB_144_12_8 | OFF | 1.081880400 | 1.086035700 | +0.384081% | overlap |
| GB_144_12_8 | MTO | 1.344039300 | 1.346796800 | +0.205165% | disjoint slower |
| BB_108_8_10 | OFF | 3.081414900 | 3.034637900 | -1.518036% | overlap |
| BB_108_8_10 | MTO | 3.935187000 | 3.921896300 | -0.337740% | overlap |
| LP_238_44_6 | OFF | 2.119618300 | 2.127132900 | +0.354526% | overlap |
| LP_238_44_6 | MTO | 2.456275200 | 2.456323700 | +0.001975% | overlap |

OFF median geometric ratio0.9982532727034651 (-0.174672730%);
MTO0.9985036622115661 (-0.149633779%). Original numeric filter rejects at BB90OFF
because candidate minimum exceeds baseline maximum; the second tiny disjoint
GB144MTO regression is also visible in the complete eight-group table. These
thresholds are not altered. Neither tiny regression proves a material practical
loss; six overlapping groups and sub-percent aggregate direction do not prove
benefit or universal ISA inefficacy. No causal FMA/search-layout claim follows.

87 capacity-eligible samples, seven preflight contention flags;
minimum global idle82.538167939%, sibling idle91.791044776%. Observed spare
resources and serial assignment are not exclusive OS reservation. Shared CI
timings are excluded. No controlled ACCEPT is claimed.

Actual runner24848 absent after exit; only runner before Job release. Every
owned cleanup remaining[]/confirmed and all four restorations PASS (mask65535,
Normal32, Job and sleep). Immediate release:
https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6069878786

All raw including failed/engineering evidence if any remains durable under
raw/** -text; original manifests and outputs are unchanged. Unmodified root
independent Tier0 audit is separately retained with its source hash. Candidate
stays isolated in draftPR49. No STATE/HYPOTHESES/hub body edits.

Next: normal Tier1 promotion is denied. A separately preregistered single
exploratory LP_340 Tier2 could be considered under the user's standing one-tier
exception: correct science, no material regression seen, and this near-zero small
case filter does not directly deny larger-case ISA benefit. That would not mean
Tier1 PASS and requires a fresh named host assignment; no Tier2/3 has run here.

Subsequent finite experiment disposition: ONE separately preregistered exploratory LP340 Tier2 is now complete; all12 science correct, numeric/formal INCONCLUSIVE, practical SHELVE/NOT ADOPTED. See TIER2_RESULT.md and public aa2c21e; no further GH48 workload/Tier3. Historical gates and raw are unchanged.
