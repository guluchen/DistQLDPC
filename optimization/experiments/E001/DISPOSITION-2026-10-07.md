# E001 disposition and LEARN — user-authorized provisional shelving

Latest user direction: provisionally regard this method as ineffective and
move to a fresh Brain proposing three alternatives. This supersedes the prior
scheduling instruction to keep E001 active until controlled confirmation.
It does not change benchmark gates, scientific semantics or evidence labels.

Practical disposition: **SHELVED / NOT ADOPTED for the current general-purpose
optimization track**. Controlled performance decision: **INCONCLUSIVE**.
No controlled ACCEPT/REJECT is manufactured, no Tier 2/3, no merge, no solver
revert on this historical experiment branch. Subsequent candidates must start
independently from baseline `24572d6`, without E001/E002/E003 patches.
CPU-isolation setup remains deferred by the user.

## LEARN

Mechanism: one deterministic sequential weight-reducing row-XOR pass on Gx/Gz
memory copies, in the DistQLDPC application before its patched embedded MaxCDCL
encoding. DistQLDPC/QDistSAT is not identical to upstream MaxCDCL.

Prediction: shorter logical rows reduce XOR encoding work and may improve whole
solve time, especially LP. Validation supports algebraic correctness and reduced
raw gate counts; it does not support a universally faster candidate.

Outcome: Tier 0 PASS; three Windows diagnostic rounds / 144 correct solves,
and two yfclab2 diagnostic rounds / 96 correct solves. Keep all five rounds
separate; do not pool timings across CPUs/hosts. GB regresses in both modes in
every retained complete round. Server ratios are OFF 1.503/1.455 and MTO
1.425/1.453; BB_90, BB_108 and LP_238 are faster in those server rounds.
The observed numerical filter fails; correctness does not fail.

New search observation: both server rounds reproduce final GB OFF LRB phase-1
conflicts 3055 -> 5813, starts 15 -> 31, UP 127023 -> 234913. This is evidence
of changed phase-specific search work, not a total-search count or proof that
memory, preprocessing or search exclusively caused the wall-time difference.
Windows counters and raw records remain in their own experiment files.

Confidence: strong consistency of the observed diagnostic GB warning; no
controlled hardware-independent wall-time regression claim. Specific causal
explanation remains unisolated. Smaller CNF is not a sufficient runtime proxy.
Do not declare every possible logical-basis transformation mathematically or
practically invalid, or enable this one by hard-coded benchmark family names.

Implication: prioritize hypotheses with a distinct mechanism and explicit
certification contract; compare total wall time, bounds and search work rather
than clause count alone. Prefix sharing (E002) also has negative local filters;
local buffer reuse (E003) has no established gain. Neither is an automatic next
step. Fresh proposals are in
[Brain Round 2](../../brain/2026-10-07-round2.md).

Evidence: [server attempts](SERVER-2026-10-07.md),
[Windows repeat 03](WINDOWS_REPEAT_03_RESULT.md),
[original proposal](PROPOSAL.md), implementation commit `50623f9` and its
retained patch. Raw data, inputs, limits and result interpretation are unchanged.
