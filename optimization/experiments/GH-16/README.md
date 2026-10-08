# GH-16 / H010: engine-only PGO

Owner codex-primary-20261008, [selection issue16](https://github.com/guluchen/DistQLDPC/issues/16),
[coordination hub15](https://github.com/guluchen/DistQLDPC/issues/15).
[Prerecorded hypothesis/mechanism/scope/cost](PROPOSAL.md).
Baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a, isolated branch
experiment/gh16-pgo. Exactly one performance concept: compiler profile feedback
for the unchanged embedded downstream MaxCDCL engine.

Current disposition **INCONCLUSIVE / SHELVED / NOT ADOPTED**. Tier0 PASS:
local and required hosted ordinary/cross-repo checks pass. [Tier1 diagnostic](TIER1_RESULT.md)
completed48 correct solves; about2% positive median direction but OFF variability
fails original numeric filter. No formal Tier1 PASS. One user-authorized bounded
[exploratory Tier2](TIER2_RESULT.md) completed12 correct solves; OFF-0.535%,
MTO+0.333% medians with overlapping ranges/large MTO variation. No corroborated
general gain, no Tier3. Both raw rounds/failed preparations retained.
Continuous user-authorized Brain->select->experiment->learn loop active;
this round cannot be accepted from correctness or shared CI timing alone.

## Implementation

Makefile off/generate/use modes instrument only four engine translation units.
Generation links libgcov and enables a training-only C-linkage dump before the
child's original _exit. Off/use builds exclude it. Final candidate nm verifies
no __gcov symbols. Mode/path/compiler/CXXFLAGS stamp requires clean before
switching; generated profile directory explicitly created for Cygwin support.
No embedded solver source, encoding, heuristic, scientific or timeout changes.
No LTO/native/fast-math. MODIFICATIONS records application/build support.

Hosted cross-repo workflow trains its own same-host profiles using
[pgo_train_build.sh](../../../scripts/pgo_train_build.sh), then compares actual
PGO-use production candidate on the original short pilot. Ordinary CI tests off.
Profile completeness/freeze/hook absence checked; hosted timings informational.

## Preparation and correctness evidence

- Attempt01: routine training link failure (C++ gcov symbol linkage); no training
  or scientific mismatch, cleanup PASS. Repaired extern C header scope.
- Attempt02: all four fixed training results correct, but no profiles. Tiny
  standalone gcov diagnostic reproduced Skip; precreating only its output
  directory produced a gcda. Directory support repaired, no case/parameter tuning.
- Attempt03: routine Windows path-key mismatch in resume provenance before
  training. Cleanup PASS; fixed key normalization.
- Attempt04: reused unchanged verified baseline/off/training binaries from02,
  exact binary hashes/reason retained. Fixed LP34/LP136 OFF/MTO results2/4,
  four engine gcda files. Solver search count89 and propagation-family count375867
  nonzero. Profiles frozen/hashed; final PGO-use build PASS with no gcov symbols.
  CSS1/4/5 independently brute-force verified,18 correct solves across baseline/
  default-off/candidate and both modes; all original WCNFs byte-identical.
  Smoke then hit inherited Windows checkout CRLF shell parsing; no solver anomaly.
  Only script working-tree line endings normalized (no Git content diff).
- Followup01: no retraining/rebuild. Smoke all3 binaries PASS; pinned QDistSAT
  pilot LP136/BB108 both modes:8 scientifically equal complete solves. Six
  timeout checks retain UNKNOWN/TIMEOUT, no reported optimum and valid bounds.
  One-worker affinity/capacity/priority and cleanup evidence retained. Local
  Tier0 PASS, performance not measured, hosted checks still mandatory.

Candidate binary SHA256:
`2c7896d35cf569e6f78ec25e2f9f2d5c148ee9196b99e0e21e802139695beb3b`.
Baseline binary SHA256:
`9574ed70921663b2ef5036a06980aed71a8278a5fa0270c25fa059448851ad5f`.
Baseline/default-off hashes differ due separate source/build paths; no assertion
of byte-identical binaries, only independently checked scientific equivalence.

All commands, logs, profiles/coverage notes/reports, inputs, environment/source/
tool hashes and cleanup are under [raw](raw), with [SHA256 manifest](raw-sha256.json).
Large reproducible binaries/object files remain in local GH16-windows-preparation
artifact directories, identified by hashes; raw science/profile evidence retained
in Git. [Preparation driver](windows_prepare.py),
[pending-check driver](windows_finish_tier0.py),
[owned-job resource helper](windows_cpu_window.py) preserve executed mechanisms.
Executed driver snapshots accompany each raw attempt. Preparation/CI times are
not performance data and are not used as Tier1 samples.

## Next and limitations

Hosted checks and independent artifact/science/identity audit completed;
see [Tier0 result](TIER0_RESULT.md). Both scoped rounds complete; Windows released
after verified cleanup to GH20. No parallel agent timings/resource over-allocation.
No proven speedup or accepted method. [Server reproduction](SERVER_COMMANDS.md)
pending eligible controlled resources; primary fresh three-proposal GH22 round
continues independently, no PGO bundle.
Training is fixed and excludes Tier1/2/3 inputs; LP136 training is also a smoke
pilot, so its pilot timing is not holdout evidence. Cygwin preparation failures
do not reject PGO as a method, and ordinary off CI does not certify PGO-use.
Record future candidate SHA/hosted reports and exact reached-gate decision here.
