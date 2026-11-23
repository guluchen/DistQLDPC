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
| Sibling exclusion partitions every target that meets the child list. | `SiblingExclusion.dfs_siblings_partition` | The selected child is present and earlier children are absent. The unique index is the first hit in the actual child order. |
| A terminal C DFS call returns FOUND exactly for zero odd-check count and a lit detector bit, updates the two counters and records the witness size on success. | `VerifDfsLeaf.body_dfs_terminal` | The depth equals the target weight and the poll pointer is null. `DetectorMatrix.terminal_bits_correct` interprets the decision for a represented PCM and detector matrix. |

Overall minimum-distance correctness for this production traversal still
requires the array-state invariants across flips, hash lookup, row selection
and pruning callbacks, recursive descent and seed enumeration. The positive
path through the packed C function `closes` also needs a body proof. The
matrix theorem describes the intended leaf criterion in both directions.
Applying the logical detector test to CSS minimum distance requires the
caller's logical detector basis to span the appropriate quotient.

## Recheck

With the Coq libraries on the load path and `clightgen` on PATH, run
`make -C verification/cc check-shared-level`. An out-of-tree VST build
can be selected with `VST_ROOT`; `CLIGHTGEN` can specify its matching
CompCert installation. The checker generates a fresh Clight AST, compiles
the modules in order and passes every project module to the Coq kernel
checker. MathComp provides finite sets, cardinality, ordinal indices, the
first-match sequence lemmas, finite fields and matrix operations.
