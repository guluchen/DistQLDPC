# GH83: balanced original stabilizer XOR association

Owner: academic-brain-20261009-round4; root schedules execution.
[Issue and prerecord](https://github.com/guluchen/DistQLDPC/issues/83),
[registration](https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6078486042).
Published before production edits. Exactly three proposals and selection are
preserved in [PROPOSAL.md](PROPOSAL.md), original receipt SHA256
`b69b4cd5e836bb8aeec65527d8de8dae8c4feb8506e7f2b3ab61bf0ea9a18abc`.

Selected GH-83-A: adjacent-pair balanced association for original Hx/Hz checks
in the live MaxCDCL application builder only. Unselected B adds bounded redundant
check-pair equations; unselected C uses demand dirty-watch cleanup. Neither is
combined with A. Corrected baseline72d1fe18; isolated candidate branch
`experiment/gh-83-balanced-stabilizer-xor`, with no GH64 prefetch patch.

Status IMPLEMENTED_PENDING_FULL_TIER0, benefit unproved. Candidate commit
aea3ee070392c4f610f17dec4646a977d03b9509 is preserved in draft PR84.
Hosted CI37914800935 and QDistSAT cross-repo37914800707 completed successfully:
LP136 and BB108 distances match in OFF/MTO against corrected baseline72d1.
The tested PR merge is5be5c0449baafa3758adcebb3258f1497e4c7a93. Shared CI
timings are informational only; this pilot is not full scientific Tier0.
Native focused tests completed PASS_GATE_CNF_ONLY (72rows/9086assignments per
version, actual helper/outer0,41rawpayloads; independent audit22379706 PASS).
The three engineering runner blockers were repaired and independently reviewed
before execution. Acquisition01 declined before reservation;02 succeeded after
a new eligible snapshot. Cleanup independently captured, all13births absent.
See FOCUSED-ATTEMPT01.md and FOCUSED-RESULT01.md. Full scientific Tier0 and
Tier1/Tier2/Tier3 NOT_RUN; no actual scientific mismatch or candidate alteration.
The only production change is XOR association; logical rows/Pauli OR/objective/
nontriviality/engine/bounds/timeouts/output meanings stay unchanged. Projection
proof and focused actual-helper checks precede full science and performance.
BibTeX NOT_APPLICABLE: engineering/algebra hypothesis, not a paper adaptation.

Canonical baseline Git matrix inspection confirms row weights6 for BB90/BB108,
7 for GB144 and8 for LP238/LP340, in both original H sectors. Chain maximum
dependency depths5/6/7 would become3 with the same per-row gate count. These
are structural facts, not propagation or speed measurements. Initial physical
Windows worktree hashes differ from original Git bytes only through CRLF/LF;
the separate canonical Git check proves the parsed rows equal and matches the
original Tier1 input bytes. No matrix or benchmark ground truth was changed.

Prior GH64 [negative native result](../../observations/GH64-NATIVE-TIER1-01-RESULT.md)
remains intact and independently audited. Do not infer accepted optimization
from source depth, unchanged clause counts or correctness alone.
