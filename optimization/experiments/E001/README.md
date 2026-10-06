# E001 — first approved optimization experiment

**Decision: INCONCLUSIVE — pending controlled run.**

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

Tier 1 not run. All four cases in both modes: baseline and candidate medians **N/A**,
raw controlled sample count **0**. This interactive macOS ARM laptop has no
exclusive reservation; no dedicated server was available through this task.
No shared/noisy measurement was used to accept or reject the optimization.
Tier 2 blocked by Tier 1; Tier 3 not run and omitted from the server runner.

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
Scientific semantics changed: no. No PI scientific decision required now;
dedicated-host access/reservation is required to resolve performance.
