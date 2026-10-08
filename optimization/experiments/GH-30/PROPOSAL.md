# GH-30 preregistration: MTO-gated binary lookahead activity

Agent codex-primary-round3. Issue30, hub15. Fresh immutable baseline
24572d6d09cce9a4a5faa58300a89e0feba9da6a. Branch experiment/gh30-mto-vsids.
This document is committed before implementation. No experiment accepted yet.

Exactly three independent concepts considered:

| ID | Concept | Rank / choice | Origin |
|---|---|---|---|
| GH-30-A | Existing MTO mode gates symmetric binary lookahead activity | 1 SELECTED | New configuration following complete GH22 mode-separated evidence |
| GH-30-B | Fixed Clang O3 backend with otherwise identical target/runtime/flags | 2 unselected | Rerank unselected GH22-B, general compiler optimization |
| GH-30-C | Fixed cap2 further lookahead | 3 unselected, active GH26-owned | Shared earlier H012, CP2026 paper; no duplicate execution |

Hypothesis: explicit MTO searches may benefit from symmetric endpoint activity,
while other modes keep their original heuristic. GH22 globally changed the second
binary-conflict .1 bump from endpoint0 to endpoint1. Allfour MTO median changes
were -10 to -22%; OFF BB90/GB144/BB108 +9.41/+39.39/+5.97%, so that version was
locally REJECTED, dedicated-controlled INCONCLUSIVE, NOT ADOPTED. This is fresh
preregistered specialization, never posthoc adoption or global-version Tier2.

One production expression only: second bump in lookbackResetTrail selects
binConfl[cardinalityEncMode == CARD_ENC_MTO ? 1 : 0]. Existing enum/field/option;
no new API, application change, compiler flag, encoder, or truth-label selection.
OFF/BOTH/Sinz/forcedBoth choose original endpoint0. Both .1 weights and other
activity paths stay unchanged. MODIFICATIONS/NOTICE describe isolated downstream
patch and preserve original MaxCDCL headers. DistQLDPC/QDistSAT is not upstream
MaxCDCL. No stacked PGO/O2/LTO/inline/FLA or unrelated refactoring.

Expected exposure: MTO lookahead binary-conflict activity; no percentage promised
on new sizes. Risks: changed search order/bounds, wrong mode propagation/default,
branch overhead in OFF, small-case improvement failing on LP340/large cases.
All distance/Pauli/CSS/QECC/logical/bounds/timeout/output/ground-truth and solver
correctness assumptions preserved; mismatch immediately STOP/REJECT/escalate.

Tier0 before timing: actual production propagation/reset fixture expanded over
allfive existing modes, 640 combinations/version; independent CSS/Pauli oracle,
identical WCNF pairs, tiny PMS exhaustive optima, original smoke and real timeout
bound checks. Existing QDistSAT cross-repo CI mandatory. Hosted timings diagnostic
only. No local build until hub15 named host assignment.

Tier1 allfour BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6, both OFF/MTO,
baseline3/candidate3, AB/BA/AB, 48 raw runs,180s solver/195s outer. Freeze inputs,
binaries/parser/helper/runtime and retain streams/argv/timing/telemetry/cleanup.
Per-mode medians, geometric direction, range-envelope/variability examined;
require repeatable positive direction beyond noise and no serious regression in
either mode. OFF neutrality is explicit, never hidden by mixing modes. Worst
timeout envelope ~2h24m, expected prior suite minutes. Tier0 expected <=20min.
Tier2 LP_340_56_8 both modes3+3,600/615s only gate or separately prerecorded one
user exploratory exception; max~2h, previous~12–16min. No Tier3 without clear
Tier2 support. Research-grade dedicated runs require >50% spare and <=half spare
team use. Authorized serial monitored Windows fallback remains diagnostic; retain
exact controlled server commands if performance is INCONCLUSIVE.

Prior records read: E001–E006 and GH16/17/20/21/22, loop/attribution/CI policy.
No originality or bug claim. Search open/closed choices and reread after claiming;
GH26 owns cap2 so C is explicitly unavailable. B's ABI/latent UB/toolchain setup
risk is less directly supported than A; fixed Clang version must be defined before
any future selection. C's cost/adapter/nogood proof obligations remain substantial.

Selected A has engineering origin, no paper/Bib attributed. Unselected C reference:
Zhang, Li, Cherif, Li, Enhanced Lower Bound Computation in Branch-and-Bound for
MaxSAT, CP2026 LIPIcs379 article60, DOI10.4230/LIPIcs.CP.2026.60, Algorithms1–3,
Proposition6. Copy verified Bib from GH22; do not claim algorithm/code invention or
copy upstream code without license review. Clang primary documentation:
https://clang.llvm.org/docs/UsersManual.html (prior GH22 reading 2026-10-08).

Result initially UNTESTED. New implementation must repeat fresh gates. Latest
source/evidence commits and observations will be added without rewriting prior
results or suppressing failures.
