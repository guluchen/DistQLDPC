# GH63 — exact size-two LBD loop expansion

State: SOURCE PREPARATION / UNTESTED. Baseline source72d1fe18 (B002/#62).
No certified local runtime/binaries, host slot, compiled fixture, solver run or
performance result. Nothing accepted or promoted.

Issue [63](https://github.com/guluchen/DistQLDPC/issues/63), hub
[registration](https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6072632510).
[Three proposals and prerecord](PROPOSAL.md) committed45817d3 before code;
[source reasoning and pending tests](SOURCE_REASONING.md).

Only `Solver.h::computeLBD` adds 17 lines implementing two original loop bodies
in order for exactly two literals. Original counter/stamp/zero-level/wrap and
generic-loop semantics retained; attribution documents describe the experiment.
No compiler/solver configuration, other candidate or application change.

Next: peer source review, actual ordinary/cross-repo CI, then a named host slot
for meaningful compiled-state/full scientific gates and an isolated bounded
size2 opportunity/codegen diagnostic. Timing requires all gates first.
Original GH58 valid300-byte WCNF optimum5 remains mandatory, not waived.
