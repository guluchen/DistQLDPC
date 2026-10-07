# E004 / H-007: LTO only

Selected after the user accepted the revised research recommendation on
2026-10-07. Recorded before implementation/builds. One conceptual change:
enable GCC link-time optimization across the existing translation units.

Baseline: `24572d6d09cce9a4a5faa58300a89e0feba9da6a` (also current main).
No E001/E002/E003 code is stacked. QDistSAT local correctness harness:
`7c4774fffc49856f48a22ae5f9063d00b2661aaa`.
[Brain evidence](../../brain/2026-10-07-round2-research-revision.md).

Mechanism: opt-in `LTO=1` adds only `-flto=1` to the existing compile/link flags.
Baseline/default `LTO=0` retains existing flags. The candidate cross-repo CI build
must explicitly enable it; otherwise CI would test the disabled candidate.
No PGO, architecture tuning, fast-math, source, matrix, heuristic or bound change.
Embedded downstream MaxCDCL code/attribution remains byte-identical. DistQLDPC
is not upstream MaxCDCL; QDistSAT is the benchmark platform.

Expected affected cases: possible execution-overhead reduction in OFF and MTO;
benefit may be small because important loops already share Solver.cc. No speedup
percentage or hotspot is asserted. Risks: instruction-cache/code-layout
regressions, stronger optimization exposing undefined behavior, compiler/plugin
compatibility and increased build time/memory.

Cost: two clean serial builds; Tier 0 byte-identical WCNF checks, independent tiny
CSS exhaustive oracle, smoke, unchanged pinned QDistSAT comparison and parent
timeout checks. Then 48 serial Tier 1 solves, three per binary/case/mode, AB/BA/AB.
Cases BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6; OFF/MTO separately.
Internal wall limit 180s, watchdog 195s; maximum Tier 1 solver budget 144 minutes,
usually much shorter on the prior baseline. No repetition/parameter sweep.
Hosted PR correctness check is required; hosted timings are never scientific.

Preregistered numerical filter: retain all raw samples/medians/ranges. A case with
min(candidate) > max(baseline) fails the numerical diagnostic. Otherwise promote
only if all per-case medians are no worse and each mode's geometric mean of
max(candidate)/min(baseline) is below 1. Do not call a noisy diagnostic rejection
a controlled rejection. Any semantic mismatch/crash rejects and stops immediately.
Timeout/incomplete samples cannot pass and remain retained.

yfclab2 is occupied and CPU isolation was deferred. Enforce idle >50% and one
allocated CPU <= half measured spare capacity before/during every command;
pin one logical CPU, record its sibling contention, use make -j1 and -flto=1.
Do not install privileged helpers. All server timing here is diagnostic; final
performance status INCONCLUSIVE unless a genuinely controlled run is available.
No Tier 2/3 from diagnostic results, even if the numerical filter passes.

Controlled follow-up uses identical package/flags/compiler/input identities,
exclusive-host evidence and the same gate; Tier 2 LP_340_56_8 only if Tier 1 passes,
three repetitions per binary/mode, 600s internal/615s watchdog. No Tier 3 runner.

Relation to previous attempts: E001 and E002 changed CNF/search behavior and
regressed GB diagnostically; E003 allocation reuse established no gain. E004
does not repeat those changes. Record compiler diagnostics, binary identities,
CNF equality, result/bound semantics and available search counters; code size or
unchanged counters alone do not establish a speedup. Candidate stays isolated
and unmerged unless all required evidence supports promotion.
