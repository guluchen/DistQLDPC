# Nonzero-rate HGP cycle-factor ladder (GH-154)

All codes retain the approved `HGP_{n}_{k}_unknown` stem convention. This is
a separate batch from the repetition-factor HGPs of GH-153. It is stacked
on that branch's common infrastructure and is pushed directly without a PR,
as requested by the PI. No tier, distance-name or main-branch adoption.

| Graph | V | E | n | k | Claimed exact d |
|---|---|---|---|---|---|
| K4 | 4 | 6 | 45 | 9 | 3 |
| K3,3 | 6 | 9 | 106 | 16 | 4 |
| Petersen | 10 | 15 | 306 | 36 | 5 |
| Heawood | 14 | 21 | 610 | 64 | 6 |
| Desargues | 20 | 30 | 1261 | 121 | 6 |
| Tutte-Coxeter | 30 | 45 | 2866 | 256 | 8 |

These instances specialize the published HGP theorem; the numbers are not
copied from a quantum-code numerical table. `claimed_d` identifies this
derivation. Observed solver bounds are kept separate and begin as NOT_RUN.

## Mathematics and scope

For a connected cubic graph with V vertices and E=3V/2 edges, let H be its
binary vertex-edge incidence matrix with the last vertex row deleted. The
deleted parity is the XOR of all retained rows, so the kernel is unchanged.
Connectedness gives rank(H)=V-1. Each nonzero kernel vector is a nonempty
even-degree edge subgraph, hence contains a cycle; a shortest cycle is itself
a kernel vector. Therefore the classical code has parameters [E,E-V+1,g],
where g is the graph's girth.

Apply the self-product construction in Tillich-Zemor,
[arXiv:0903.0566v2, Theorem 1](https://arxiv.org/pdf/0903.0566),
[DOI 10.1109/TIT.2013.2292061](https://doi.org/10.1109/TIT.2013.2292061):

```
Hx = [H tensor I_E | I_(V-1) tensor H^T]
Hz = [I_E tensor H | H^T tensor I_(V-1)]
n = E^2 + (V-1)^2
k = (E-V+1)^2
d = g
```

Columns are (edge,edge), followed by (retained vertex,retained vertex), with
the second coordinate fastest. Hx rows are (vertex,edge), Hz rows (edge,vertex).
Checks have weight at most 5; qubit degrees are bounded. Over the construction
class, k/n tends to 1/13 as V increases. This is nonzero-rate HGP, with a
different growth regime from HGP built from asymptotically good classical
LDPC factors: cycle-factor distance is girth, not linear classical distance.
No square-root quantum-distance scaling is claimed for this ladder.

## Graph definitions and provenance

All edges are generated from mathematics, sorted lexicographically. No graph
files, source code or page text is copied; original code/matrices are distributed
under the repository's GPL-3.0-or-later license.

- K4 and K3,3: complete and complete-bipartite graph definitions.
- Petersen: disjoint pairs of a 5-set are adjacent, following the mathematical
  description on [Brouwer's Petersen page](https://aeb.win.tue.nl/graphs/Petersen.html).
- Heawood: incidence of the Fano plane; points are nonzero GF(2)^3 vectors,
  lines are triples {a,b,a+b}. See [Brouwer's Heawood page](https://aeb.win.tue.nl/graphs/Heawood.html).
- Desargues: bipartite double of Petersen, following
  [Brouwer's Desargues page](https://aeb.win.tue.nl/graphs/Desargues.html).
- Tutte-Coxeter: incidence graph of GQ(2,2); points are pairs of a 6-set,
  lines are partitions into three pairs. See
  [Brouwer's GQ(2,2) page](https://aeb.win.tue.nl/graphs/GQ22.html).

## Reproduction and validation

```sh
python3 scripts/codegen/hgp_cycle.py --ladder --out /tmp/hgp-cycle-fresh
python3 tests/test_codegen_cycle.py
python3 tests/test_codegen_hgp.py
python3 scripts/codegen/validate_css.py --output /tmp/css-validation.json
```

The generator invokes `scripts/compute_logicals.py --method bitset` for every
code. Its opt-in backend has the same pivot order and basis as the original
dense backend; the default remains dense. Differential tests compare exact
bases on 100 random small CSS inputs, degenerate inputs and existing small
benchmarks, and compare the generated logical files byte for byte.

Independent graph checks verify simplicity, degree 3, connectedness, full
retained rank and girth using edge-deletion BFS. An independent exhaustive
enumeration of at most 2^16 classical codewords gives the same distances.
Tiny quantum-support oracles check the [[10,4,2]] product and the K4 product's
d=3. The shared verifier checks all matrix ranks, commutation, complete logical
quotients, full pairing rank, and same-(n,k) duplicate row spaces with X/Z swap.

Solver smoke checks run only as short ordinary CI in GitHub Actions, under
`-cpu-lim=60`, one pinned core, a 4 GiB AS cap and a 90-second backstop per
input. Supplemental settings are labeled separately; no unavailable default
bound is filled from a claim or another setting. Solver runs do not use the
PI Mac, external distance solvers or dedicated-server cores. Raw logs and
identities are retained in `optimization/experiments/GH-154/`.

The first default runs reproduced d=3/4/5/6 on n=45/106/306/610 and bounds
5..6 on n=1261. Both the default and `-ub-pre=1 -v` n=2866 attempts returned
TIMEOUT_NO_BOUNDS. The verbose run confirms all input dimensions and finishes
symmetry detection before the timeout, with no finder banner yet. A separately
labeled `-ub-pre=off -v` 60-second check skips that initialization to check
search-bound visibility. This is not a default change or a timing comparison.
