# DistQLDPC

Compute the **minimum distance** `d` of a **CSS / QLDPC** stabilizer code from parity-check matrices, using a MaxSAT solver (MaxCDCL).

**Repository:** https://github.com/guluchen/DistQLDPC

---

## Quick start

```bash
make
./bin/distqldpc AJ_01
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

```bash
python3 scripts/benchmark_matrices.py
python3 scripts/benchmark_matrices.py --all --timeout 180
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

Third-party attribution and DistQLDPC-specific solver patches:

- [NOTICE](NOTICE)
- [MODIFICATIONS.md](MODIFICATIONS.md)
