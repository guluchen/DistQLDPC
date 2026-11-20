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
