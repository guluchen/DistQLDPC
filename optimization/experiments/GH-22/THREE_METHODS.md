# Independent next round: exactly three methods

1. SELECTED: symmetric lookahead binary-conflict VSIDS activity, one second
   index0->1. Inspected downstream Solver.cc, lower implementation cost and
   directly falsifiable frequency/search hypothesis. Disclosed GH20 unselectedB.
   Not a bug claim and not paper-derived. Scope/risk/gates in PROPOSAL.md.
2. Unselected: compiler backend only, fixed Clang O3 against baseline GCC O3
   with same target/runtime/libstdc++/zlib and other equivalent flags. No PGO,
   LTO/native/fastmath/O2. Motivation is alternative instruction selection and
   register allocation, no measured GCC deficiency. Verify installed version/
   target/ABI/FP defaults before prerecord; withdraw if source fixes are needed.
   Latent UB and FP/search tie differences require full Tier0. No compiler sweep.
   Engineering reference [official Clang manual](https://clang.llvm.org/docs/UsersManual.html),
   read2026-10-08. No academic paper/BibTeX invented. Setup uncertainty makes rank2.
3. Unselected: shared H012 fixed-size-two further lookahead, after standard LK
   fails; deterministic core order, no RL/upstream solver import. [Zhang et al.
   CP2026](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.CP.2026.60),
   sections2/3 Algorithms1–3 and Proposition6, keyzhang2026enhanced in references.bib.
   Existing unlockReason/seeUnlockLits already present; need equivalent-operation
   audit and exhaustive residual optimum proof against overlap/doublecounting/
   speculative rollback. Several-day soundness cost, rank3. Paper proof does
   not certify downstream code. Unselected previous proposal, no novelty claim.

Search/reread GitHub22/hub15 and20/21 registrations found no active selected
duplicate: GH20 identity watch-tail copy skip, GH21 O2 only, GH16 PGO. Each
candidate stays independent on baseline24572 until a reviewed baseline change.
No baseline/source from the historical H001 documentation branch is inherited.
