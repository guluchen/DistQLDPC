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

For a code named `<code>`, put four text files in one directory (default: `data/matrices/`; the bundled benchmark codes live in tier subdirectories `data/matrices/tier0` … `tier5`, see [data/matrices/README.md](data/matrices/README.md)):

| File | Role |
|------|------|
| `<code>_Hx.txt` | **X stabilizers** — rows are X-parity checks on `n` qubits |
| `<code>_Hz.txt` | **Z stabilizers** — rows are Z-parity checks on `n` qubits |
| `<code>_Gx.txt` | **Z-type logicals** — basis of `ker(Hx) / row(Hz)` |
| `<code>_Gz.txt` | **X-type logicals** — basis of `ker(Hz) / row(Hx)` |

**File format:** each line is one binary row; entries are `0` or `1` separated by spaces. Lines starting with `#` are comments. All four matrices must have the same number of columns `n` (qubits).

**Stem names** use `{family}_{n}_{k}_{d}` (e.g. `BB_72_12_6`, `LP_34_20_2`), family in `BB`, `GB`, `LP`, `TN`. When the distance is not known, the last field holds the current proven bounds: `{lb}to{ub}` or `ge{lb}` (e.g. `BB_360_12_17to24`, `LP_1768_224_ge17`). Upstream `AJ_*` / `xu_*` / `PK_*` ids and renames are recorded in [NOTICE](NOTICE) and [data/matrices/README.md](data/matrices/README.md).

Example layout:

```
data/matrices/
  MY_CODE_Hx.txt
  MY_CODE_Hz.txt
  MY_CODE_Gx.txt
  MY_CODE_Gz.txt
```

Run with a path prefix (with or without directory). A bare name is looked up in `data/matrices/` first, then in `data/matrices/tier0` … `tier5` (first match wins); a name containing `/` is used as given:

```bash
./bin/distqldpc MY_CODE
./bin/distqldpc data/matrices/MY_CODE
./bin/distqldpc LP_34_20_2                      # -> data/matrices/tier0/LP_34_20_2
./bin/distqldpc data/matrices/tier0/LP_34_20_2
```

---

## Prepare matrices for a new code

You only need to **author** the parity checks `Hx` and `Hz`. The logical bases `Gx` and `Gz` can be generated automatically:

```bash
# write data/matrices/MY_CODE_Gx.txt and MY_CODE_Gz.txt from Hx/Hz
python3 scripts/compute_logicals.py MY_CODE

# custom directory (flat; e.g. a tier directory)
python3 scripts/compute_logicals.py --dir path/to/matrices MY_CODE

# batch: all codes in one directory that have Hx + Hz but no Gx/Gz yet
python3 scripts/compute_logicals.py --all
python3 scripts/compute_logicals.py --dir data/matrices/tier0 --all

# replace existing Gx/Gz
python3 scripts/compute_logicals.py --overwrite MY_CODE
```

**What the tool computes**

- **Gx** — one row per Z-type logical operator (Pauli Z on qubits). Each row `z` satisfies `Hx · z = 0 (mod 2)` and is not in the row space of `Hz`.
- **Gz** — one row per X-type logical operator. Each row `x` satisfies `Hz · x = 0 (mod 2)` and is not in the row space of `Hx`.

In symplectic form (used internally by the solver): Gx rows become `[0 | z]`, Gz rows become `[x | 0]`.

Optional: remove redundant stabilizer rows or sparsify checks before distance search:

```bash
python3 scripts/preprocess_matrices.py --src data/matrices/tier0 --root data
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
When a verified XZ-dual qubit permutation maps the X half onto the Z half (so `d_X = d_Z`), both halves
still run, but every lower bound proven in one half is shared with the other, so duplicated refutations are skipped.
The distance definition, Pauli weight and output format are unchanged.

| Flag | Effect |
|------|--------|
| `-joint` | Original single symplectic encoding over `(x, z)` (previous default) |
| `-no-symbreak` | CSS split without the per-half symmetry breaking |
| `-symbreak-report` | Print the detected per-half automorphism generators and orbits, then exit |
| `-dualmode=off` (alias `-no-dualskip`) | Ignore XZ-dual maps (previous default) |
| `-dualmode=skip` | With a verified dual map, solve only the X half |
| `-dualskip-report` | Print the verified XZ-dual maps, then exit |
| `-engine=maxsat` | **(experimental flag, GH-124)** The MaxSAT search described above (default; identical to the behaviour without the flag) |
| `-engine=cc` | **(experimental, GH-124)** Exact connected-cluster (CC) level search per CSS half instead of MaxSAT (see below) |
| `-engine=auto` | **(experimental, GH-124)** `cc` when every qubit has degree >= 3 and every row weight is <= 16 in each half's parity matrix, else `maxsat` (not the default) |
| `-cc-rules=excl,pack,orbf[,mrv]` | **(experimental)** CC pruning rules (default `excl,pack,orbf`; `none` = plain CC): sibling exclusion, disjoint odd-row packing bound, orbit seeds from the verified per-half automorphisms, fewest-candidate branching |
| `-cc-dual=on\|off` | **(experimental)** With a verified XZ-dual map, CC searches only the X half (default `on`; `-dualmode=off` also disables it) |
| `-ub-basis` | **(experimental, CC only)** Emit the minimum weight of the verified logical basis rows as an initial upper bound (default off) |
| `-cc-seed=N` | **(experimental, testing)** Deterministic relabeling of qubits and rows for CC (default 0 = identity), for seed-median timing |
| `-cc-trace=FILE` | **(experimental)** One line per finished (half, level): half, level, `EMPTY`/`FOUND`, nodes, seconds, witness support |
| `-cc-stats` | **(experimental)** Per-level CC node counts (printed also without `-v`) |
| `-cc-mutant=K` | **(test only)** Deliberately broken CC variants for mutation tests, each able to give a wrong answer; never use for results. 1 = sibling-exclusion set not restored on backtrack; 2 = packing prune uses `>=`; 3 = orbit seed rule off by one (the seed's own orbit is forbidden during its search); 4 = stop rule without the other half's lower bound (runs the sequential schedule) |
| `-cc-schedule=lockstep\|sequential` | **(test only)** CC half schedule (default `lockstep`: both halves level by level); `sequential` raises the first half to its distance before the other half, which makes the stop rule's other-half check load-bearing |

`-dump-wcnf` / `-dump-opb` and the RoundingSat backend still use the joint encoding.

**CC engine (`-engine=cc`, experimental, GH-124).** Each CSS half is searched one weight level at a time
(1, 2, 3, ...): a level-w search decides exactly whether the half has a nontrivial logical of weight w by
growing Tanner-connected clusters from a seed (Dumer, Kovalev, Pryadko, IEEE Trans. Inf. Theory 63(7), 2017),
with sibling exclusion, a disjoint odd-row packing bound and orbit seeds from DistQLDPC's verified per-half
automorphisms. The two halves run interleaved level by level, so `c d_lb` rises by one per completed level;
every reported upper bound is a witness verified by `H e = 0` and an independent GF(2) rank test against the
stabilizer row space. The output lines, the pipe protocol and the `-cpu-lim` timeout are the same as for
MaxSAT; `-no-symbreak` gives index seeds instead of orbit seeds and `-dualmode=off` disables the dual map
(`-dualmode=share` and `skip` both allow it). Conflicting flags are rejected with an error (exit 1): the
`-cc-*` and `-ub-basis` flags need `-engine=cc` or `-engine=auto`; `-engine=cc` and `-engine=auto` refuse
`-joint`, `-roundingsat[=BIN]`, `-dump-wcnf`, `-dump-opb`, `-dump-only` and `-native-parity-opb`; `-engine=cc`
also refuses the cardinality flags and `-dualshare-stats`. With `-engine=auto` the cardinality flags and
`-dualshare-stats` apply when it selects `maxsat`, the CC flags when it selects `cc`, and a warning on stderr
names the flags that its choice ignores. `make test-cc` runs the brute-force engine tests and
`make test-cc-flags` the command-line flag checks.

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
python3 scripts/benchmark_matrices.py --matrices-dir data/matrices/tier1 --all   # one data tier
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
src/cc/                 # CC level-search engine (experimental, -engine=cc)
src/solver/             # MaxCDCL MaxSAT engine
data/matrices/tierN/    # benchmark codes (Hx, Hz, Gx, Gz) by tier; see data/matrices/README.md
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
