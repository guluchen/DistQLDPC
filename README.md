# DistQLDPC

Compute the **minimum distance** `d` of a **CSS / QLDPC** code from parity-check matrices `Hx`, `Hz`, and logical bases `Gx`, `Gz`.

**Repository:** https://github.com/guluchen/DistQLDPC

---

## Quick start

```bash
make
./bin/distqldpc LP_34_20_2
```

Example output while searching:

```
c trying d: 4
c d_lb: 2
c d_ub: 6
c d  : 6
o 6
```

The last line `o 6` is the distance (or the best upper bound found before timeout).

---

## Input: four matrix files

For a code named `<code>`, put four text files in one directory (default: `data/matrices/`):

| File | Role |
|------|------|
| `<code>_Hx.txt` | **X stabilizers** — rows are X-parity checks on `n` qubits |
| `<code>_Hz.txt` | **Z stabilizers** — rows are Z-parity checks on `n` qubits |
| `<code>_Gx.txt` | **Z-type logicals** — basis of `ker(Hx) / row(Hz)` |
| `<code>_Gz.txt` | **X-type logicals** — basis of `ker(Hz) / row(Hx)` |

**File format:** each line is one binary row; entries are `0` or `1` separated by spaces. Lines starting with `#` are comments. All four matrices must have the same number of columns `n` (qubits).

**Stem names** use `{family}_{n}_{k}_{d}` (e.g. `BB_72_12_6`, `LP_34_20_2`). Use `unknown` when minimum distance is not certified. Upstream `AJ_*` / `xu_*` ids are recorded in [NOTICE](NOTICE).

Example layout:

```
data/matrices/
  MY_CODE_Hx.txt
  MY_CODE_Hz.txt
  MY_CODE_Gx.txt
  MY_CODE_Gz.txt
```

Run with a path prefix (with or without directory):

```bash
./bin/distqldpc MY_CODE
./bin/distqldpc data/matrices/MY_CODE
```

---

## Prepare matrices for a new code

You only need to **author** the parity checks `Hx` and `Hz`. The logical bases `Gx` and `Gz` can be generated automatically:

```bash
# write data/matrices/MY_CODE_Gx.txt and MY_CODE_Gz.txt from Hx/Hz
python3 scripts/compute_logicals.py MY_CODE

# custom directory
python3 scripts/compute_logicals.py --dir path/to/matrices MY_CODE

# batch: all codes that have Hx + Hz but no Gx/Gz yet
python3 scripts/compute_logicals.py --all

# replace existing Gx/Gz
python3 scripts/compute_logicals.py --overwrite MY_CODE
```

**What the tool computes**

- **Gx** — one row per Z-type logical operator (Pauli Z on qubits). Each row `z` satisfies `Hx · z = 0 (mod 2)` and is not in the row space of `Hz`.
- **Gz** — one row per X-type logical operator. Each row `x` satisfies `Hz · x = 0 (mod 2)` and is not in the row space of `Hx`.

In symplectic form (used internally by the solver): Gx rows become `[0 | z]`, Gz rows become `[x | 0]`.

Optional: remove redundant stabilizer rows or sparsify checks before distance search:

```bash
python3 scripts/preprocess_matrices.py --src data/matrices --root data
# writes data/s1/ and data/s2/ variants; re-run compute_logicals on those if needed
```

### Scripts

| Script | Purpose |
|--------|---------|
| `scripts/compute_logicals.py` | Build `Gx` / `Gz` from `Hx` / `Hz` |
| `scripts/preprocess_matrices.py` | Optional Hx/Hz preprocessing (`data/s1`, `data/s2`) |
| `scripts/benchmark_matrices.py` | Batch distance runs → CSV (see Advanced) |

---

## Usage

```bash
./bin/distqldpc <code>                 # default: quiet progress + result
./bin/distqldpc -cpu-lim=300 <code>    # wall-clock limit (seconds); SIGKILL on timeout
./bin/distqldpc -v <code>              # full solver search log (debug)
./bin/distqldpc -h                     # all options
```

**Timeout:** the solver runs in a forked child process. `-cpu-lim=N` is a **wall-clock** limit enforced by the parent (`SIGKILL` after `N` seconds). On timeout you still get the best `d_lb` / `d_ub` seen so far.

---

## What distance is computed

For a CSS code with stabilizer matrix `S = [Hx | 0]` stacked with `[0 | Hz]` (symplectic, length `2n`):

- **Pauli weight** of `(x, z)`: `|P| = Σ_i (x_i ∨ z_i)` (count qubits with nontrivial X or Z).
- **Distance:** minimum Pauli weight among nontrivial operators in `N(S) \ S` (logical operators, not stabilizers).

This matches the standard symplectic MaxSAT encoding: commutation with all stabilizers, nontrivial Pauli, and independence from the logical basis encoded via `Gx` / `Gz`.

### How the distance is solved (default)

For CSS codes every nontrivial logical `(x, z)` has `x` a nontrivial X-type logical or `z` a nontrivial
Z-type logical, with `|x|, |z| <= |(x, z)|`, so `d = min(d_X, d_Z)`. By default DistQLDPC therefore solves
two smaller MaxSAT instances, the X half (`Hz x = 0`, nontrivial w.r.t. `Gx`) and the Z half
(`Hx z = 0`, nontrivial w.r.t. `Gz`), with an interleaved global bound search that keeps reporting valid
`d_lb` / `d_ub` while it runs (also on timeout). Inside each half, qubit permutations that are verified
automorphisms of that half (exact GF(2) rank checks) are used for optimum-preserving symmetry breaking.
The distance definition, Pauli weight and output format are unchanged.

| Flag | Effect |
|------|--------|
| `-joint` | Original single symplectic encoding over `(x, z)` (previous default) |
| `-no-symbreak` | CSS split without the per-half symmetry breaking |
| `-symbreak-report` | Print the detected per-half automorphism generators and orbits, then exit |

`-dump-wcnf` / `-dump-opb` and the RoundingSat backend still use the joint encoding.

---

## Output

| Line | Meaning |
|------|---------|
| `c trying d: N` | currently testing candidate distance `N` |
| `c d_lb: N` | proven lower bound on `d` |
| `c d_ub: N` | best upper bound found so far |
| `c d  : N` | final distance (when optimal) |
| `o N` | result line for scripts (`N` = distance or `-1` on failure) |

Use `-v` or `-debug` for matrix paths, dimensions, and internal solver log.

---

## Advanced

### Cardinality encoding (solver tuning)

By default the MaxSAT engine uses Sinz + MTO cardinality constraints when helpful. For experiments or hard instances you can override:

```bash
./bin/distqldpc -no-card <code>              # soft-conflict only
./bin/distqldpc -card-sinz <code>             # Sinz sequential counter only
./bin/distqldpc -card-mto <code>              # MTO tree encoding only
./bin/distqldpc -card-both-force <code>       # Sinz + MTO even when n > 100
```

Most QLDPC users can ignore these flags.

### Batch benchmarks

Optimization experiments must follow the [optimization loop policy](docs/OPTIMIZATION_LOOP_POLICY.md): progressive Tier 0–3 filtering, one main hypothesis per round, and retained evidence for accepted and rejected experiments. Research-grade performance claims require controlled dedicated-server runs; [QDistSAT cross-repo CI](docs/QDISTSAT_CROSS_REPO_CI.md) timing is diagnostic only. The batch script's default/advanced/full groups are not the policy's filtering tiers; select the tier's cases explicitly. Full suites and other heavy runs belong on the dedicated server.

```bash
python3 scripts/benchmark_matrices.py
python3 scripts/benchmark_matrices.py --all --timeout 180
python3 scripts/benchmark_matrices.py --compare-roundingsat
```

Compare MaxCDCL (embedded) vs [RoundingSat](https://gitlab.com/MIAOresearch/software/roundingsat) on the same WCNF encoding:

```bash
./bin/distqldpc LP_34_20_2                      # MaxCDCL (default)
./bin/distqldpc -roundingsat LP_34_20_2       # external RoundingSat binary on PATH
./bin/distqldpc -roundingsat=/path/to/roundingsat LP_34_20_2
./bin/distqldpc -dump-wcnf=/tmp/LP_34_20_2.wcnf LP_34_20_2
```

---

## Build

```bash
make
```

Requires **g++** and **zlib**. Binary: `bin/distqldpc`.

```
src/core/distqldpc.cc   # CLI, QLDPC encoding, fork/pipe
src/solver/             # MaxCDCL MaxSAT engine
data/matrices/          # example codes (Hx, Hz, Gx, Gz)
```

---

## License

DistQLDPC is licensed under **GPL-3.0-or-later** — see [LICENSE](LICENSE).

The MaxSAT engine in `src/solver/` is derived from **MaxCDCL** (MIT).
Upstream copyright and license: [src/solver/LICENSE](src/solver/LICENSE).

Third-party attribution (MaxCDCL engine, benchmark matrices from
[codeDistancePYPI](https://github.com/m-webster/codeDistancePYPI)) and
DistQLDPC-specific solver patches:

- [NOTICE](NOTICE)
- [MODIFICATIONS.md](MODIFICATIONS.md)
