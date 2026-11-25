# Verified connected-cluster distance kernel

This plain-C implementation solves one Pauli half of a CSS code. It uses an
explicit search stack with six independently selectable rules: sibling
exclusion, disjoint packing, one-column closure, stabilizer overlap, uniform
charge and minimum-remaining-values row selection. The default mask is 63.

The [kernel theorem](proof/CCVerifiedKernel.v) combines VST contracts for the
19 linked C functions with termination of the original Clight search, bounded
decision and distance entries. The [operational theorem](proof/CCPublicTermination.v)
quantifies over typed calls with the specified storage, all-index VST caller
resources and an external specification permitting return. The
[CSS contract](proof/VerifCertificateDistance.v) accepts a checked logical
quotient certificate. For a legal half:

| Distance outcome | Guarantee |
|---|---|
| FOUND | The output vector commutes with the opposite checks and is outside the same-type stabilizer row span. Its Hamming weight is minimal. |
| EMPTY | No such vector exists at any weight. |
| UNKNOWN | The iteration budget was exhausted. No bound follows. |

The x86-64 Clight proofs cover the two C translation units in the linked
library. The host CLI, its parser and allocator, and the production C++ solver
have separate verification boundaries.

The [indexed and certified drivers](indexed/README.md) add sparse C search, input-checked X/Z symmetry, and certification of an externally proposed witness with verified bounded queries.

## Raw PCM entry for the optimized C kernel

The experimental C API `cc_pcm_distance` accepts two binary row-major
check matrices with a common width. It checks commutation, reduces each
stabilizer matrix and builds free-coordinate detectors, sparse incidence
tables and the leaf lookup used by `cc_run_level`. It searches both Pauli
halves in increasing weight and replays the winning support against the
original checks and reduced stabilizers. A finite return identifies the
Pauli half and writes the distance and indicator vector. A code with no
encoded qubits returns `CC_PCM_NO_LOGICAL`. An interrupt, invalid input
and insufficient storage have separate outcomes. Only a finite return
writes the output buffers.

Run `make -C verification/cc test-native-pcm` for the exhaustive small
matrix oracle, Shor codes and boundary cases. Run `make -C verification/cc check-native-pcm` to regenerate the raw C
Clight AST and kernel-check the packed-word sizing and row-exchange proofs. The ABI is defined in
[native/pcm.h](native/pcm.h). This entry is under verification. The
complete C input-to-distance theorem is open.

## Shared C kernel used by the native CLI

On this experimental branch the native CLI calls `src/cc/cc_level.c` for the
default CC traversal. C owns the seed and sibling loops, recursive search,
syndrome and parity updates, leaf checks and rollback. It borrows the C++
driver’s row selection, pruning and orbit/overlap bookkeeping through callbacks.
The index-seeded `excl,pack,leaf` specialization keeps its C packing scan.
Test mutants, xorunit, and rule sets lacking excl, pack or leaf use the
original C++ traversal. Use `OPTFLAGS` in the root Makefile to
set optimization and architecture options for both C and C++.

Run `make -C verification/cc check-shared-level` from the repository root with
64-bit CompCert 3.13.1 `clightgen`, Coq 8.18.0 and VST 2.14. Set `CLIGHTGEN`
to the generator executable and `VST_ROOT` to the built VST tree when they
are outside the standard paths. The target generates Clight directly from the
native source in a fresh temporary directory, compiles the proofs, runs
`coqchk` on each project module, and prints the input and AST digests.

The [detector theorem](shared/VerifDetected.v) covers the actual C function
that scans the logical parity words. It returns one exactly when some word
is nonzero and preserves the caller’s memory. This includes an empty array
with a null data pointer. The [production proof inventory](shared/README.md)
also covers the C closure scan, terminal DFS, and a MathComp implementation
of weight-level search with a CSS minimum-distance theorem. Refinement of
the native recursive traversal and its C++ policies remains open.

## Build and check

Use Linux, Coq 8.18.0 and VST 2.14 built for 64-bit CompCert semantics.
From this directory run:

```sh
make -j1 test
make mutants
make check-ast
make proofs
```

With a built VST source tree, use `make proofs VST_ROOT=/absolute/path/to/VST-2.14`.
The proof target uses normal coqc with dependency ordering. To regenerate
the checked-in ASTs, use x86_64-linux CompCert 3.13.1 clightgen:

```sh
clightgen -normalize -canonical-idents -I. -o proof/ccv_primitives.v ccv_primitives.c
clightgen -normalize -canonical-idents -I. -o proof/ccv_core.v ccv.c
make check-ast
```

## Compute a full CSS distance from the two PCMs

Build the extracted front end with 64-bit OCaml, ocamlfind and the Coq 8.18 native development libraries (on Ubuntu, `libcoq-core-ocaml-dev`). Then pass the qubit count
and the original X- and Z-check files. Rows can contain contiguous or
whitespace-separated bits. A line starting with `#` is a comment. Empty
files represent zero rows of the declared width.

```sh
make pcm
make test-packed
python3 extract/css_distance.py 7 ../../data/matrices/tier0/COLOR_7_1_3_Hx.txt ../../data/matrices/tier0/COLOR_7_1_3_Hz.txt
python3 tests/test_pcm.py --matrices ../../data/matrices/tier0
```

This example returns distance 3. A successful report includes two bit
strings, `x` and `z`, giving the Pauli witness in input column order. The
reported distance counts the union of their supports. Each half receives
its own `--budget`. If either half returns UNKNOWN, the combined report
returns UNKNOWN (exit 3). EMPTY means neither half has a logical witness.

[Detector construction](proof/CCPCMDetectors.v) performs GF(2) elimination
on same-type stabilizers. Its detectors vanish exactly on their row span.
Dependent rows, empty matrices and zero rows are supported. The detector
set can contain opposite checks; it need not be a minimum-size logical basis.
[PCM preparation](proof/CCPCMInput.v) checks the binary row-major buffers,
commutation and the C size limits, then supplies all three matrices for the
[linked C entry](proof/CCPCMEntry.v). The caller supplies no logical-basis
certificate. The [preparation proof](proof/CCPCMBitRows.v) establishes
that the extracted front end returns the same optional model as the reference
for every raw input, including detector bytes and row order. It computes GF(2) products and sums by traversing stored Boolean rows in column order.
Successive rows are decoded by a [streaming traversal](proof/CCPCMChunks.v).
The command reads each file once and prepares both validated half models.
At the default budget and rule mask it can certify an upper witness from the
input with the packed search. The implementation tries this for widths 96
through 189, up to 189 check and detector rows per half, and a proposed weight
from 7 through 18. It verifies the witness and excludes every smaller logical
operator in each half. A checked weight-preserving map can transfer the lower
bound to the opposite half. Every row suggestion, orbit, row index and
short-syndrome filter must pass its corresponding checks. The two- and
three-column filters permit collisions, which can only retain search branches.
The [packed report theorem](proof/CCPackedAnswer.v) proves that every accepted
answer is a minimum over mixed Pauli operators for the decoded input PCMs.

When the packed route is inapplicable or inconclusive, the command calls the
VST-verified C kernel on each half and runs the extracted result aggregation.
The [C-path theorem](proof/CCPCMAnswer.v) establishes the same mixed-distance
guarantee from the C half contracts. The standalone half CLI supports
cross-checks. Text I/O, extraction, the 64-bit OCaml runtime, host allocation
and foreign-function marshalling form the executable trust boundary. The C
row-choice helper supplies advice to the Coq checker. Its body has no VST
proof. The membership and index callbacks must return consistent values for
the duration of a check. Search-order advice has a two-million-call allowance
per half, after which the standard C search uses its regular iteration budget.

## Run the half-distance CLI

The first input line is the number of qubits, opposite check rows, logical
detector rows and optional same-type pruning rows. Supply binary rows in
that order. A three-qubit repetition half with minimum weight three is:

```sh
printf '3 2 1 0\n110\n011\n100\n' | ./ccv
```

The optional arguments are the whole-call iteration budget and rule mask.
The exit codes are 0 for FOUND or EMPTY, 3 for UNKNOWN and 2 for invalid
input. See [ccv.h](ccv.h) for array extents, integer limits and ownership.
