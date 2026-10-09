# GH83 focused encoding test specification — before test implementation

Selected experiment: original Hx/Hz check XOR adjacent-pair association only, from corrected baseline `72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7`. Registration: https://github.com/guluchen/DistQLDPC/issues/83. Candidate commit and exact compiled source hashes are pending. This document authorizes no execution and does not claim correctness or speed.

The focused test checks emitted CNF structure and projected Boolean semantics. Native/Cygwin production engine builds, corrected-baseline crash regression, complete scientific application gates and backend/call-site checks remain separate mandatory gates. A capturing mock is not a SimpSolver correctness certificate.

## Authenticating the code under test

Prefer a compiled test translation unit using the actual application source with a test-only entrypoint exclusion. If full inclusion is impractical, extract exact authenticated function definitions for `ensure_var`, `xor2`, `parity`, `add_xor_equals`, and candidate `add_balanced_xor_equals`, preserving their bytes. Baseline has no balanced helper: invoke its original `add_xor_equals`; candidate invokes its actual balanced helper. Record original Git commit/blob and file SHA, extraction byte ranges and source SHA, generated TU SHA, compiler/runtime/argv, object and executable SHA before first test execution. Reject incomplete/ambiguous extraction as engineering INCONCLUSIVE.

Use only a minimal capturing solver/literal adapter: contiguous `newVar`/`nVars`, actual signed literal representation and complement semantics, plus clause capture with hard-weight annotation. Preserve actual helper code and clause order; do not rewrite the helper or generate a synthetic implementation of it. If `add_hard_clause` is adapted rather than compiled unchanged, disclose that boundary: adapter must copy every incoming literal in order without normalization, duplicate elimination, tautology removal or propagation. No production solver patch, fake optimal result, production statistics hook or timing conclusion.

## Independent truth and extension oracle

For variable assignment A, signed literal `(variable v, negated s)` means `A[v] != s`. Expected parity is the modulo-two sum of these literal truth values, preserving duplicate occurrences. This oracle uses no candidate pairing schedule, emitted gate traversal, known benchmark answer or production helper.

For each nonempty row, enumerate all assignments to the emitted fresh auxiliary variables and evaluate every captured clause directly by disjunction. Exactly one satisfying auxiliary extension must exist when the independent leaf parity equals the requested value, and zero otherwise. Count actual satisfying assignments; do not substitute deterministic gate evaluation for enumeration. All fresh variables must be distinct, contiguous, absent from the original inputs, and match the recorded auxiliary vector. Empty inputs retain the original helper's no-op for both values: zero clauses/auxiliaries, exactly one empty extension for every leaf assignment. This explicitly preserves the historical empty/value=true behavior; it does not reinterpret it as an unsatisfiable equation.

Expected per-row raw counts: m=0 has zero clauses and auxiliaries; m=1 has one signed root unit and zero auxiliaries; m>=2 has m-1 auxiliaries, four defining clauses per auxiliary and one root unit, total `4*(m-1)+1`. Each defining gate independently has four clauses of length three. Header/count tests apply to raw captured clauses or unsimplified serialization, not a post-SimpSolver dump where simplification may remove clauses.

## Corpus A: exhaustive distinct positive leaves

For m=0..8, inputs are positive variables 0..m-1. For each requested value false/true enumerate all `2^m` original assignments. Total is exactly `2 * sum(2^m, m=0..8) = 1022` leaf-assignment tests **per version**, including two empty cases. Extension enumeration remains bounded: maximum 128 auxiliary assignments per original assignment; all lengths/parities sum to 87,382 clause-model evaluations per version (including empty/singleton). Missing/extra cases are engineering coverage gaps, not scientific PASS.

For m<=3, additionally require baseline/candidate raw ordered clauses and auxiliary IDs to be identical. For m>=4, require semantic projection/counts and contiguous ordered leaf coverage; do not require clause-byte equality between different association trees. Verify a structural change at m=4 and the specified candidate adjacent-pair shape, including odd carries at m=5 and m=7. Structural shape is checked separately from the independent semantic oracle and cannot replace it.

## Corpus B: fixed signed/repeated literals

Let x,y,z,w denote original variables 0..3; `!x` is the complement literal. Freeze these twelve rows in this order:

1. `[!x]`
2. `[x,x]`
3. `[x,!x]`
4. `[!x,!y]`
5. `[x,y,x]`
6. `[x,!x,y]`
7. `[!x,y,!z]`
8. `[x,y,x,y]`
9. `[x,!x,y,!y]`
10. `[!x,y,!z,w]`
11. `[x,y,!x,z,!y]`
12. `[!x,y,!z,w,x,!y,z,!w]`

Allocate all four originals before each row, even if unused. For each row and both requested values enumerate all 16 assignments of x,y,z,w and enumerate its fresh auxiliaries. Total 384 leaf-assignment tests per version; maximum eight leaves/seven auxiliaries. Unused-original-variable multiplicity is intentional. The independent signed occurrence sum handles cancellation algebraically without deleting any input occurrence or gate. Corpus A and B total 1406 leaf tests per version.

## Corpus C: multirow allocation and unchanged logical suffix

Create eight original variables and an auxiliary vector initially containing an explicit sentinel allocated before the check rows; do not clear it implicitly. Append original check rows of lengths `[0,1,2,3,4,5,7,8]`, using ascending prefixes of these eight positive leaves, requested false. There are exactly 23 newly allocated check auxiliaries; empty/small rows and odd/even changes exercise allocation boundaries. Record every row's start/end variable count and its appended auxiliary segment. Require identical baseline/candidate per-row allocation counts and final variable count, original IDs unchanged, sentinel retained, and no cross-row gate sharing.

Immediately append two logical equations with the **unchanged original chain helper**, using `[!x0,x2,!x4,x6]` at true and `[x1,!x2,x3,!x4,x5,x7]` at false. Their 3+5=8 new auxiliaries must start at the identical suffix index in both versions. Require suffix captured clause sequence, auxiliary IDs, requested signs and allocation counts byte/tuple identical. For each row separately, enumerate all 256 original assignments and all row-local auxiliaries to verify unique extension/independent parity; repeated checking of an already captured row does not change allocations. For the conjunction, derive expected feasibility from the conjunction of the ten independent row predicates; assert zero/one global extension using the individually certified unique/disjoint extensions, rather than enumerating all 31 auxiliaries. This is a finite mathematical decomposition, not production solver execution.

Additionally repeat the allocation-only construction with no initial sentinel and with an already allocated unused original variable; require preservation of pre-existing variables/auxiliary prefix and correct fresh start index. This covers append semantics without silently assuming auxiliary vector starts empty.

## Serialization and integration obligations

If the capturing test serializes WCNF, its header variable count is the actual final allocator count, hard-clause count the actual raw captured count, every literal is in range and every clause terminates with zero. Reparse independently and verify equality to captured clauses and projected truth. No soft objective appears in the focused parity-only test, so it cannot certify Pauli weight/distance.

Later actual application tests must certify candidate live-MaxCDCL dumps by semantic projection/independent tiny Pauli-OR optimum, not assume identical bytes. Unaffected dump-only, RoundingSat/OPB paths and logical equations need exact source/call-site or appropriate same-path artifact checks. Any header drift due actual solver normalization must be explained from actual emitted artifacts, not waived using nominal raw gate counts.

## Bounded execution and disposition

One serial compiled fixture per version, one allocated CPU, aggregate focused-test external budget 120 seconds and at most 60 seconds per executable; compilation has a separately preregistered bounded j1 budget. Capture stdout/stderr/return code and exact case/count summary. No performance measurements, huge sweep, retry selection or unrelated 316-watch sweep. Extension enumeration uses at most seven fresh bits per row; no integer shifts beyond that finite test domain. Actual total workload is expected small, but exceeding the budget is INCONCLUSIVE coverage, never a smaller-corpus PASS.

Wrong projected parity, zero/multiple extension where one is required, wrong signed semantics, changed m<=3 behavior, overwritten allocation prefix, altered logical suffix, malformed clauses/header or crash attributable to actual helper implementation is a correctness mismatch: STOP and retain evidence. Compiler/API/extraction/provenance failure, watchdog cut-off or missing planned coverage is engineering INCONCLUSIVE. A focused PASS is only the bounded gate-CNF/association certificate; it does not authorize performance until separate full scientific gates pass.

No harness source has been written or executed for this specification. Root publishes/freezes the specification and assigns resources before implementation/execution.
