# E001 — first approved optimization experiment

**Decision: INCONCLUSIVE — pending controlled run.**

2026-10-07 continuation: the preserved implementation passed supplemental MSYS
Tier 0 checks; a verified offline archive and reproducible exporter are now
retained in the repo. Controlled samples remain zero. See the
[continuation record](CONTINUATION-2026-10-07.md) for raw evidence, the local
build limitation, package checksum and exact server commands.

Later [yfclab2 server continuation](SERVER-2026-10-07.md): server Tier 0 PASS;
48 diagnostic Tier 1 samples completed with identical scientific results.
GB medians regress in both modes while the other three cases improve. Occupied
host timings do not pass the controlled gate. Medians, raw runs, capacity checks,
the interrupted initial attempt and learning are retained.

Baseline: `24572d6d09cce9a4a5faa58300a89e0feba9da6a`.
Candidate implementation: `50623f9` (full identity in result.json).
QDistSAT: `7c4774fffc49856f48a22ae5f9063d00b2661aaa`.
Source hypothesis: final answer in Brain chat 01a111cd-9e52-7112-ad06-4a4b4a078c0c;
user confirmed in referenced chat and explicitly requested this exact restart.

## Change and correctness argument

See PROPOSAL.md and implementation.patch. One conceptual change, 29 added lines
and one changed call in src/core/distqldpc.cc: deterministic, sequential,
weight-reducing row XOR on separate logical-basis copies before MaxCDCL.
Each update is invertible, preserving row space and nonzero syndrome, hence the
feasible original Pauli operators and objective. Matrix files, solver code,
cardinality, bounds, timeout and result semantics are unchanged. RoundingSat
and dump-only entry points retain original bases.

## Evidence

Final local Tier 0: PASS (`raw/tier0/summary.json`).
- 676 algebra inputs: exhaustive n=3 ordered row lists of lengths 1–3,
  80 fixed-seed random matrices and 12 real matrices. Checks production C++
  helper against an independent sequential reference, span/rank and syndrome.
- Real pilot/Tier cases: quotient rank, logical kernel and pairing rank preserved.
- Exhaustive 4^n original-Pauli feasibility and distance for two CSS fixtures:
  n=4 distance 2; n=5 distance 1. Baseline/candidate agree in BOTH, OFF and MTO.
- Existing smoke passes for both binaries.
- Existing pinned QDistSAT pilot functions/parsing: LP_136_32_4 d=4,
  BB_108_8_10 d=10 in OFF and MTO; exact result, objective, bounds and exit
  status match. All eight solves complete. Full stdout/stderr retained.
- Six forced one-second timeout runs in BOTH/OFF/MTO: TIMEOUT + UNKNOWN,
  no false exact result, bounds contain certified d=10.
- Six runner gate/parser tests pass (`raw/server-tests.log`).

Hosted QDistSAT PR check: PASS on `18f1603`, run 37490553731. General CI also
passed. The downloaded report ZIP (SHA-256 verified), extracted report and
complete job log are retained under raw/hosted-cross-repo*. Follow-up changes
only retain this evidence; implementation remains commit 50623f9. Shared GitHub
timing is diagnostic only, not a Tier 1 pass. Draft PR: https://github.com/guluchen/DistQLDPC/pull/11.

Local build uses Apple Clang with `-Wno-reserved-user-defined-literal` on BOTH
versions, because unmodified upstream headers fail default Clang compilation.
No portability patch was mixed in. Default failure log and successful build logs
are retained; warnings are pre-existing engine warnings. Local timing is purely
diagnostic and is excluded from performance decisions.

Initial passing Tier 0 evidence is retained under raw/tier0-pre-scope-review.
Scope review moved the transformation out of the shared encoding builder into
the MaxCDCL-only entry point. Final Tier 0 was rerun from the start under raw/tier0;
no scientific mismatch was observed in either candidate. Only the final diff is
eligible for further tests.

## Performance / medians / decision

Controlled Tier 1 sample count remains **0**. The initial macOS execution had
no dedicated-server access. Later, 48 diagnostic samples were collected on
yfclab2 under the user's CPU capacity rule; medians are in SERVER-2026-10-07.md.
They show mixed behavior and a substantial GB regression, but the occupied host
was not reserved. Shared/noisy timings are not used to accept or reject H-001.
Tier 2 remains blocked; Tier 3 was not run.

Preregistered per-mode medians, conservative variability envelope, case regression
rule, limits, repetitions and aggregation are in PROPOSAL.md. Run package instructions
are in ../../server/README.md. Do not treat the historical table as this baseline.

## New observations / next step

Total logical weights (equal to raw logical xor2 calls in this encoding):
LP_136 560 -> 428; BB_90 204 -> 190; GB_144_12_8 491 -> 434;
BB_108 250 -> 222; LP_238 1160 -> 936; LP_340 2220 -> 1688.
Raw per-row weights and isolated probe duration are in raw/tier0/structure.json.
These quantities precede simplification; fewer gates may still worsen search.
Full per-solve preprocessing time is not separately instrumented; total measured
wall time in the server runner includes it. Missing counters remain unknown.

Next: exclusive dedicated-server run of the supplied package, then import raw
runs/medians/decision into this experiment and reconcile STATE/HYPOTHESES.
Scientific semantics changed: no. SSH access is configured; a controlled
reservation is required to resolve the GB warning and overall performance.

Attempt 5 adds another Tier 0 PASS and 48 matching diagnostic runs on a different
CPU pair: GB medians +45.5% OFF/+45.3% MTO, other cases faster. Total diagnostic
sample count is now 96; controlled sample count remains 0. Full raw runs,
independent verification and interrupted strict attempts are in the server
record. The repeated warning does not authorize Tier 2, merging, or changing
the selected hypothesis; resource permission and timing validity are separate.
