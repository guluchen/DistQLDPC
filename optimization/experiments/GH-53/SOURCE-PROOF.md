# Conditional source argument and remaining obligations
Source-only, not a replacement for correctness execution. Original245 helper bodies unchanged; default selects existing basic branch.

For a falsified input conflict clause C, a removable literal ~x has a sound reason R=(x OR antecedents), with x true on trail and each antecedent false. The basic branch keeps literals without reasons, otherwise removes ~x only if every non-root reason variable is already marked in seen. Under the caller invariant that seen corresponds to falsified clause literals, each non-root antecedent appears with its falsified polarity in C. Root-false antecedents have certified root implications in the active formula. Resolving C on x using R introduces only literals already represented, or root-false literals; eliminating root-false literals preserves implication. Multiple removals rely on legal acyclic implication order; circular synthetic reasons are invalid fixtures.

Before shared binResMinimize, basic acceptance is conservative relative to original deep recursion: a reason whose non-root antecedents are already seen does not require recursive traversal/abstract-level acceptance. Deep may remove more through additional implied variables; binary reason order can be normalized by deep but basic scans both binary entries. This observation is conditional on valid reasons/seen/trail and does not prove current-bound clause lifetime, weighted quasi-caller invariants or the later binary-resolution output. It does not imply identical clauses, ordering, activities, LBD or search. No stronger post-binRes set-containment claim.

Actual caller source:
- analyze hard conflict and analyzeSoftConflict invoke simplifyConflictClause.
- analyzeQuasiSoftConflict and fixByLookahead invoke simplifyQuasiConflictClause.
- fixByLookahead marks indices1.. before simplification; asserting UIP need not be marked. The direct fixture follows that convention.
- helpers copy original literals to analyze_toclear, perform minimization, computeLBD, may call binResMinimize, choose backtrack level, then clear seen.
- binary-resolution lookup directly consumes watches_bin; fixture has empty watchers and therefore does not establish substantive binary-resolution validity.
- changing mode affects later helper outputs and getAllUIP/hardening/learned management, so downstream tests must cover those actual callers and active bound contexts.

Required remaining proof/execution: original weighted-cost context of initial quasi clause and each stored reason, current-bound validity and deletion/reset handling, auxiliary variable semantics, actual full caller traces reaching both helper paths, hard/soft rollback/seen closure, nonempty binary watchers, independent original tiny-formula truth including PauliOR/CSS objective plus all emitted fields, lawful timeouts. Existing code path and this conditional argument do not certify the candidate. Known GH46 valid baseline anomaly is retained and blocks complete correctness/promotion; no edits to that fixture, optimum or original implementation are authorized.

