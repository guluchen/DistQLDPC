# Proofs for the production CC level traversal

These modules use the Clight translation of `src/cc/cc_level.c`. The
checked baseline is the C traversal in the C++/C candidate at commit
`ca80fd7`. Proofs were developed on x86-64 Linux with Coq
8.18.0, CompCert 3.13.1, VST 2.14 and MathComp 2.1.0 (SSReflect and Algebra).

## What the contracts establish

| Result | Theorem | Conditions |
|---|---|---|
| The C detector returns one exactly when any stored detector bit is set. | `VerifPackedDetector.body_detected_bits` | The supplied read-only words satisfy their C layout. A zero-word detector may use a null pointer. |
| Stored words detect a nonzero logical response over GF(2). | `DetectorMatrix.packed_matrix_nonzero` | The bit order matches the detector rows and all padding bits are zero. |
| The one-qubit leaf test accepts exactly when toggling physical qubit q gives a zero check syndrome and a nonzero detector response. | `LeafMatrix.leaf_matrix_exact` | The sparse column lists the physical rows of q without duplicates. Matrices, dimensions, support and q are arbitrary. |
| The first C rejection in `closes` returns zero and preserves caller storage. | `VerifClosesCount.body_closes_count` | Valid offset bounds and a column degree unequal to the stored odd-row count. `LeafMatrix.count_mismatch_nonzero` explains why this cannot discard a completion when those counts represent the matrix state. |
| The full C function `closes` scans the addressed CSR column and packed syndrome. It accepts when the degree matches the odd count, every listed bit is set, and at least one logical parity word differs from the candidate column. | `VerifClosesBody.body_closes` | The contract specifies readable storage, valid array bounds and a positive logical word count. All paths preserve the caller's storage. |
| The result of that C contract is exactly the matrix test after one qubit flip. | `ClosureMatrix.closes_value_pcm` | CSR incidence contains each physical row of the column once. Packed words contain the current syndrome, logical response and logical column, with zero padding. The stored odd count represents the physical syndrome. |
| The C function `toggle` flips each incident syndrome bit, adjusts the odd count, XORs the column key, and updates every packed logical parity word. | `VerifToggleBody.body_toggle` | The contract requires valid CSR and packed storage, representable intermediate counts, and sufficient space for the addressed logical column. |
| XORing the packed response with a represented column implements addition of that column over GF(2). Repeating the update restores the words. | `ToggleModel.packed_flip`, `packed_rollback` | The two packed word lists have equal length and use the same bit order. |
| The postcondition of C `toggle` represents the syndrome, its cardinality, the logical response and the syndrome hash of the updated qubit support. | `SparseSyndrome.toggle_pcm` | The CSR slice is the ordered encoding of the distinct incident physical rows. The original counts, packed words and keys represent the input matrices. |
| Applying the physical sparse column twice restores every bit in the original syndrome buffer, including unused bits in its last word. | `SparseRollback.sparse_words_restore` | All row addresses are within the packed buffer. The scans use the same order and may include repeated entries. |
| The C function `flip` calls `toggle` and applies any extra row XORs in the supplied CSR slice, preserving the physical odd-row count and logical response from `toggle`. | `VerifFlipBody.body_flip` | Covers a null policy, a policy without extra rows, and a valid redundant-row CSR table. The contract describes the exact word writes. Correct construction of the redundant columns belongs to the caller. |
| Equal physical syndromes have equal signatures. A complete bucket and the physical leaf test find every eligible leaf even when distinct columns collide. | `SyndromeHash.signature_toggle`, `bucket_complete` | The bucket contains every key match. |
| The C function `closing_qubit` returns the first free candidate in the matching chain that passes the physical leaf test, or returns −1 on exhaustion. | `VerifLookup.body_closing_qubit`, `HashProbe.physical_lookup` | The arrays satisfy the C bounds. The mathematical absence result additionally requires the bucket to contain every eligible candidate. |
| Probing a power-of-two table visits every possible slot within one circuit of the table. A sentinel and increasing links give a finite search with a unique result. | `HashProbe.visit_slot`, `finite_lookup`, `unique_lookup` | The word mask represents table size minus one, there is an empty slot, and every nonterminal link goes to a larger in-range qubit. |
| Sibling exclusion partitions every target that meets the child list. | `SiblingExclusion.dfs_siblings_partition` | The selected child is present and earlier children are absent. The unique index is the first hit in the actual child order. |
| A terminal C DFS call returns FOUND exactly for zero odd-check count and a lit detector bit, updates the two counters and records the witness size on success. | `VerifDfsLeaf.body_dfs_terminal` | The depth equals the target weight and the poll pointer is null. `DetectorMatrix.terminal_bits_correct` interprets the decision for a represented PCM and detector matrix. |

## Search and distance over arbitrary matrices

`MinimumPrefix.minimum_prefix_odd` proves that every nonempty proper subset
of a minimum logical support has an odd check. If such a subset were closed,
the subset or its complement in the target would be a lighter logical
operator. `odd_row_hits_residual` shows that every odd check touches a qubit
that still has to be added.

`LevelSearch.descend` branches on an odd check, removes each explored
sibling from future branches and stops at closed prefixes. The soundness
and completeness proofs cover every seed and every smaller weight.
`distance_index_spec` returns the minimum when a logical operator exists.
`distance_index_empty` establishes the exhaustion sentinel otherwise.
`CSSLevelDistance.css_distance_exact` derives the two detector matrices
from the input row spaces with MathComp, combines the half distances and
proves minimality for mixed Pauli weight (the union of the X and Z supports).
`css_distance_empty` covers an empty logical set.

`DetectorRank.validated_detector` connects a supplied detector matrix to
the same row-space test. It uses the orthogonality and rank conditions
checked by the production driver. For any vector with zero check syndrome,
all its input detectors vanish exactly when it is in the stabilizer row space.

`MinimumOverlap.minimum_overlap` proves that a minimum representative
occupies at most half of a stabilizer's support. `ChargeBound.charge_bound`
proves the capacity inequality for charges on the odd rows. Its disjoint
unit-charge specialization `packing_bound` gives the packing rule.

The executable MathComp model and the Clight body contracts have separate
verification boundaries. The native CLI theorem still requires concrete
hash-table construction, correct packing and block and overlap counters across
recursion and rollback, seed enumeration, the policy callbacks and the
driver. The C++ table constructor must establish the preconditions of
`finite_lookup` and bucket coverage. The timed source has
C++ callbacks that form a past-the-end CSR
pointer with a vector subscript. Private correction `9fa8df2` uses pointer
addition for those ranges.

## Recheck

With the Coq libraries on the load path and `clightgen` on PATH, run
`make -C verification/cc check-shared-level`. An out-of-tree VST build
can be selected with `VST_ROOT`; `CLIGHTGEN` can specify its matching
CompCert installation. The checker generates a fresh Clight AST, compiles
the modules in order and passes every project module to the Coq kernel
checker. MathComp provides finite sets, cardinality, ordinal indices, the
first-match sequence lemmas, finite fields and matrix operations.
