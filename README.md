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

**Stem names** use `{family}_{n}_{k}_{d}` (e.g. `BB_72_12_6`, `LP_34_20_2`), family in `BB`, `GB`, `LP`, `TN`. When the distance is not known, the last field holds the current proven bounds: `{lb}to{ub}` or `ge{lb}` (e.g. `TN_648_10_9to32`, `BB_756_16_30to34`; upper bounds from verified witnesses, see [data/matrices/README.md](data/matrices/README.md)). Upstream `AJ_*` / `xu_*` / `PK_*` ids and renames are recorded in [NOTICE](NOTICE) and [data/matrices/README.md](data/matrices/README.md).

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
| `-engine=auto` | **(experimental, GH-124)** `cc` unless a half's parity matrix is dense (some row weight > 32, or mean row weight > n/4 with n >= 64), then `maxsat`; every bundled code goes to `cc`; `-v` prints the decision (not the default) |
| `-frontier=auto` (default) | **(GH-129/GH-130)** Frontier branching inside MaxCDCL on the CSS split: when some parity row of the half is odd (its qubits set to 1 have odd parity and it still has unassigned qubits), the next decision sets to 1 a qubit of the odd row with the fewest candidates (CC's growth rule); otherwise MaxCDCL decides as usual. `auto` enables it per half only when the half's parity matrix has fewer than 3 Tanner 4-cycles per row (pairs of rows sharing two qubits; BB/GB/LP 0–1.6, TN 6–26), decided before the search; `-v` prints the value and the choice. `-frontier=off` reproduces the search before GH-130; `-frontier=on` forces it on every half; `postsol` / `presol` apply it only after / before a probe's first solution. The formula is unchanged, only the decision order |
| `-seed=N` | **(timing seeds)** Default 0 = the unchanged search. With MaxSAT, N > 0 sets MaxCDCL's random seed (it only drives the engine's 1% sampling of the lookahead threshold, so the search order changes but never the answer or the bounds' validity); with the CC engine it is `-cc-seed=N`. Used for seed-median timing |
| `-oddcap-skip=on\|off` | **(GH-133; default `on` since 2026-10-21; `off` reproduces the previous search)** MaxSAT split only: on a CSS half whose parity matrix has only odd column weights every logical has even weight, so the odd probe caps of the bound search are replaced by the even cap below them (cap 1: no probe, lower bound 2; a NONE at cap 2t certifies 2t+2); `-v` prints the decision per half. Applies to all bundled BB and LP codes (column weights 3 / 3,5), not to TN or GB |
| `-ub-pre=off\|on\|S` | **(GH-144; default `on` = 60 s since 2026-10-23; `-ub-pre=off` restores the previous search)** MaxSAT split only: before the bound search, run the randomized low-weight logical finder of GH-140 on both halves for at most S seconds (each half stops earlier after 16 re-hits of its bound or a plateau of max(1000, 4 x the iteration of its last improvement) iterations; tuning `-ub-pre-hits=H`, `-ub-pre-plateau=P`). The lightest verified word weight U0 is printed as the first `c d_ub`; the doubling probes stop below U0 - 1 and the rest of the search only proves that no logical of weight <= U - 1 exists (probes at U - 1). Every word is checked against the half instance before use; `-seed=N` also seeds the finder. Cost: <= 0.3 s on tiers 1-4, U0 = d on every bundled code with a known distance |
| `-ub-isd=off\|stern\|dumer[:P,L,W,B,R]` | **(GH-146; default `stern` since 2026-10-23; `-ub-isd=off` restores the previous finder, the GH-140 enumeration)** Collision mode of the randomized finder used by `-ub-search` (CC) and `-ub-pre` (MaxSAT): a Stern step instead of the 1-2-row enumeration. The information set of each random systematic form is split at random into two halves; all subsets of size <= P of each half are bucketed by the sum of their columns on L random redundancy rows, and every colliding pair whose detector parities differ is weighed (words with up to 2P ones on the information set and none on the window). `dumer` also lets the window coordinates take part in the subsets. Between rounds, W Canteaut-Chabaud pivot swaps re-randomise the information set (0: a fresh elimination); B rounds form one finder iteration; R > 0 forces a fresh elimination every R rounds. Defaults P 2, L automatic (about log2 of the list size), W 32, B 1, R 0. Needs `-ub-search=on\|budget:S` or `-ub-pre=S`; every word is still verified before use |
| `-stab-overlap=off\|on\|auto` | **(GH-148; experimental, default `off`)** MaxSAT split only: every probe of a half also requires that at most floor(\|g\|/2) qubits of each same-type stabilizer row g are 1 (rows verified with H g = 0 and G g = 0; a minimum-weight logical always satisfies this, otherwise x + g would be lighter, so no probe answer changes). `on`: all rows in every probe; `auto`: row g only in probes with cap >= 2 (floor(\|g\|/2) + 1) (factor `-stab-overlap-ratio=X`); encoding `-stab-overlap-enc=native\|clauses\|bin\|seq` (default `native`: an "at most k" propagator inside MaxCDCL with lazily created reason clauses; `clauses`: binomial clauses up to \|g\| = 9, sequential counter above). `-frontier-stats` adds a `c OVERLAP` line per probe with the native propagator. `-v` prints the rows used per half and the active rows per probe |
| `-cc-rules=excl,pack,orbf,parity,leaf,overlap[,mrv]` | **(experimental)** CC pruning rules (default `excl,pack,orbf,parity,leaf,overlap`; `none` = plain CC; `excl,pack,orbf` = the GH-124 engine, `excl,pack,orbf,parity,leaf` = the GH-133 engine): sibling exclusion, disjoint odd-row packing bound, orbit seeds from the verified per-half automorphisms, even-weight parity shortcut (GH-133), leaf hash lookup (GH-133), stabilizer-overlap rule (GH-138: a minimum logical meets every same-type stabilizer row g in at most floor(\|g\|/2) qubits; the rest of a row that reaches this limit is forbidden), fewest-candidate branching |
| `-cc-dual=on\|off` | **(experimental)** With a verified XZ-dual map, CC searches only the X half (default `on`; `-dualmode=off` also disables it) |
| `-ub-basis[=on\|off]` | **(experimental, CC only)** Emit the minimum weight of the verified logical basis rows as an initial upper bound (default on; `-ub-basis=off` disables it) |
| `-cc-seed=N` | **(experimental, testing)** Deterministic relabeling of qubits and rows for CC (default 0 = identity), for seed-median timing; alias of `-seed=N` for the CC engine (both given with different values is an error) |
| `-cc-trace=FILE` | **(experimental)** One line per finished (half, level): half, level, `EMPTY`/`FOUND`, nodes, seconds, witness support |
| `-cc-stats` | **(experimental)** Per-level CC node counts (printed also without `-v`) |
| `-cc-mutant=K` | **(test only)** Deliberately broken CC variants for mutation tests, each able to give a wrong answer; never use for results. 1 = sibling-exclusion set not restored on backtrack; 2 = packing prune uses `>=`; 3 = orbit seed rule off by one (the seed's own orbit is forbidden during its search); 4 = stop rule without the other half's lower bound (runs the sequential schedule) |
| `-cc-schedule=lockstep\|sequential` | **(test only)** CC half schedule (default `lockstep`: both halves level by level); `sequential` raises the first half to its distance before the other half, which makes the stop rule's other-half check load-bearing |

`-dump-wcnf` / `-dump-opb` and the RoundingSat backend still use the joint encoding.

### Connected-cluster (CC) engine: optional, off by default (GH-124)

DistQLDPC includes an exact connected-cluster (CC) distance engine in `src/cc/`. **It is not the default**:
without any flag (or with `-engine=maxsat`) DistQLDPC runs the MaxSAT search described above, byte-identical
to the behaviour before GH-124.

**Turning it on and off**

| What | On | Off |
|------|----|-----|
| Use the CC engine | `-engine=cc` | no flag, or `-engine=maxsat` (default) |
| Let DistQLDPC choose per code | `-engine=auto` (CC unless the code is dense, see below; `-v` prints `c engine: auto -> cc\|maxsat (...)`) | `-engine=maxsat` |
| Seed for timing panels (both engines) | `-seed=N` (N > 0; CC: same as `-cc-seed=N`) | no flag or `-seed=0` (main's search) |
| Pruning rules (CC only) | `-cc-rules=excl,pack,orbf,parity,leaf,overlap` (default), add `mrv` for fewest-candidate branching | `-cc-rules=none` (plain CC), or list only the rules you want, e.g. `-cc-rules=excl,pack,orbf,parity,leaf` (the GH-133 engine, no `overlap`) |
| Orbit seeds (CC only) | default (rule `orbf`) | drop `orbf` from `-cc-rules`, or `-no-symbreak` (index seeds) |
| Single-half search under a verified XZ-dual map (CC only) | `-cc-dual=on` (default) | `-cc-dual=off` or `-dualmode=off` |
| Initial upper bound from the verified logical basis rows (CC only) | `-ub-basis` / `-ub-basis=on` (default) | `-ub-basis=off` |
| Randomized upper-bound finder feeding the stop rule (CC only, GH-140) | `-ub-search=on` (default since 2026-10-23; no time cap) or `-ub-search=budget:S` (at most S seconds) | `-ub-search=off` |
| Stern collision mode of the finder (CC `-ub-search` and MaxSAT `-ub-pre`, GH-146) | `-ub-isd=stern` (default since 2026-10-23; or `dumer`, with `:P,L,W,B,R` tuning) | `-ub-isd=off` (previous finder, GH-140) |
| Diagnostics (CC only) | `-cc-trace=FILE`, `-cc-stats`, `-v` | omit them |

Examples:

```bash
./bin/distqldpc -engine=cc BB_288_12_18                  # CC with all rules (excl, pack, orbf, parity, leaf, overlap), dual map, basis UB
./bin/distqldpc -engine=cc -cc-rules=none BB_288_12_18   # plain connected-cluster search, no extra pruning
./bin/distqldpc -engine=cc -ub-basis=off BB_288_12_18    # no initial upper bound from the basis rows
./bin/distqldpc -engine=cc -ub-search=on TN_252_2_21     # CC plus the randomized upper-bound finder (GH-140)
./bin/distqldpc BB_288_12_18                             # default: MaxSAT, CC not used
```

**Upper-bound finder (`-ub-search`, GH-140).** A randomized low-weight logical finder runs inside the CC process
next to the level ladder (the ladder stays single-threaded; the two are time-sliced). Per CSS half it draws a random
information set (random column order, Gauss-Jordan elimination of the half's parity matrix, systematic basis of
its kernel), looks at the words made of one or two systematic basis vectors, keeps the nontrivial ones (detector
check), and lowers their weight greedily by adding same-type stabilizer rows. Every word is verified exactly like a
CC witness (H e = 0 and the independent rank test) before it becomes `c d_ub`. The stop rule then finishes as soon
as both halves' certified lower bounds reach the upper bound, so the level that would have found the witness is
skipped (and a level in progress at that weight is abandoned). The finder only ever produces upper bounds; the
distance is still certified by the empty levels below it. Schedule: a pre-pass of `-cc-ub-pre=S` seconds (default
0), then the share `-cc-ub-share=F` of the wall time (default 0.05), reduced to F/16 once `-cc-ub-hits=H` (default 16)
iterations have re-found the current bound without improving it, or after a plateau of max(64, 4 x the iteration
count of the last improvement) iterations without improvement (`H = 0`: never reduced); `budget:S` caps the finder's
total time.
`-cc-ub-triples=K` also tries sums of three basis vectors when the information set has at most K columns (default
0), `-cc-ub-slack=L` sets how far above the bound a word may be and still be improved (default 4). The random
choices follow `-seed` (deterministic sequence of words per seed; when they arrive depends on the wall clock).
`-cc-ub-only` (with `budget:S`) runs the finder alone and reports only an upper bound (diagnostic, `s UNKNOWN`).
Clean-room implementation from the published descriptions of random-information-set search (Lee-Brickell style,
QDistRnd, dist-m4ri "RW"); evidence in `optimization/experiments/GH-140/`.
`-ub-isd=stern` (GH-146; the default since 2026-10-23, `-ub-isd=off` restores the enumeration) replaces the enumeration by a Stern collision step (pairs of subsets of size <= 2 from the
two halves of the information set, matched on a window of redundancy rows, re-randomised by Canteaut-Chabaud pivot
swaps); written from the published algorithms (Stern 1988, Dumer, Canteaut-Chabaud), evidence in
`optimization/experiments/GH-146/`.

The output lines (`c d_lb`, `c d_ub`, `c d  :`, `o N`), the pipe protocol and the `-cpu-lim` timeout are the
same as for MaxSAT. With CC, `c d_lb` rises by one per completed weight level (by two on a half with only odd
column weights, where the `parity` rule skips the odd levels), and every reported upper bound
is a witness checked by `H e = 0` and an independent GF(2) rank test against the stabilizer row space.
Conflicting flags are rejected with an error (exit 1): the `-cc-*`, `-ub-basis` and `-ub-search` flags need
`-engine=cc` or `-engine=auto` (and the `-cc-ub-*` flags need `-ub-search=on|budget:S`); `-engine=cc` and `-engine=auto` refuse `-joint`, `-roundingsat[=BIN]`, `-dump-wcnf`, `-dump-opb`,
`-dump-only` and `-native-parity-opb`; `-engine=cc` also refuses the cardinality flags and `-dualshare-stats`.
With `-engine=auto` the cardinality flags and `-dualshare-stats` apply when it selects `maxsat`, the CC flags
when it selects `cc`, and a warning on stderr names the flags that its choice ignores. `make test-cc` runs the
brute-force engine tests and `make test-cc-flags` the command-line flag checks.

**`-engine=auto`.** It picks CC unless, in the parity matrix of a half that has logicals (X half: `Hz`, Z half:
`Hx`), some row has weight > 32, or n >= 64 and the mean row weight exceeds n/4; such clearly dense codes go to
MaxSAT. Basis (`optimization/experiments/GH-124/S0_REPORT.md` §5.5, `PRE_S1_NOTES.md`): CC was never slower than
MaxSAT on toric and planar surface codes with L = 6..32 (qubit degree 1-2), so qubit degree is not a criterion,
and it is faster or at the process floor on all 49 bundled codes (row weight 6..16, mean row density <= 12.5% at
n >= 64), which all go to CC. CC branches over the qubits of one odd row, so its cost grows with the row weight;
dense codes were not calibrated, and both limits keep a 2x margin over every calibrated code.

**Inputs and failures.** CC needs a complete logical basis in each half (rank `[H; G]` + rank of the same-type
stabilizers = n, i.e. `Gx`/`Gz` span the logicals modulo the stabilizers, as all bundled data does); on an
incomplete basis it refuses to answer (`s UNKNOWN`), where MaxSAT answers relative to the given `G`. When CC
stops without an answer (a consistency trap or an unusable input), the final summary withdraws every bound it
had sent (`c d_lb: -`, `c d_ub: -`, `c status: UNKNOWN (CC engine stopped without an answer: ...)`); live
`c d_lb:` lines printed earlier do not count.

**What CC borrows, and from where**

The search skeleton is the published connected-cluster algorithm of I. Dumer, A. A. Kovalev and
L. P. Pryadko, "Distance verification for classical and quantum LDPC codes", IEEE Trans. Inf. Theory 63(7),
2017. We learned how it performs in practice by studying Quantinuum's **Qubitserf** library (Serban Cercelescu,
MIT License, commit `ab96b9c`, `method="cc"`), whose CC implementation follows the same skeleton. From that
study DistQLDPC takes these ideas (re-implemented from scratch; no Qubitserf code is copied):

1. a minimum-weight nontrivial logical of a CSS half is connected in the half's Tanner graph, so it suffices
   to grow clusters from a seed qubit;
2. each weight level is searched exhaustively and in increasing order, so every empty level is a certified
   lower bound and the first hit is the half's distance;
3. branching only over the qubits of one unsatisfied (odd) check, with the seed as the smallest index of
   the support;
4. a cluster that becomes syndrome-free before reaching the target weight is a dead end;
5. the X and Z halves are searched interleaved, level by level.

**What DistQLDPC adds**

| Addition | Effect |
|----------|--------|
| Disjoint odd-check **packing bound** (`pack`): odd checks whose remaining candidate qubits are pairwise disjoint each need a distinct extra qubit, so a branch is pruned when the cluster size plus the packing exceeds the target weight | cuts nodes 50-500x per level; per-level growth drops from about 4.5-6x to about 3x |
| **Sibling exclusion** (`excl`): after the branch adding qubit a is exhausted, a is forbidden in the later sibling branches | removes duplicate cluster orderings (large effect on weight-8/9 checks) |
| **Orbit seeds** (`orbf`) from DistQLDPC's GF(2)-verified per-half automorphisms (GH-85): one seed per orbit, earlier orbits forbidden | 10-16x on BB codes, 6-18x on LP codes, 2-3x on TN codes with symmetry |
| **Single-half search** under DistQLDPC's verified XZ-dual map (GH-87/GH-107) | about 2x on BB/GB codes |
| **Stop rule**: once one half hits at level w and the other half's lower bound is >= w, d = w | no wasted level after the distance is determined |
| **Even-weight parity shortcut** (`parity`, GH-133): when every column weight of the half's parity matrix is odd, the sum of the rows of `H v` equals `\|v\|` mod 2, so every logical has even weight; odd levels are skipped (an EMPTY level 2t certifies 2t+2) and the per-node parity check is a free consistency check. The fact is classical (C. Crocker uses it for BB_360); its use in the lockstep level schedule is ours. Applies to all bundled BB and LP codes, not to TN/GB | 3-4x on BB/LP codes (the skipped odd level is the most expensive one before each hit); nothing on TN/GB |
| **Leaf hash lookup** (`leaf`, GH-133; the idea is described in dist-m4ri's README): at remaining budget 1 the closing qubit is looked up in a hash from column to qubit, at budget 2 each candidate of the branching row is completed by one lookup instead of a recursion | neutral in our engine (0-5% fewer nodes, 0-3% time): the packing bound already prunes almost every cluster before budget 1 (`-cc-stats` nodes-by-budget) |
| **Witness verification** by an independent GF(2) rank test, always-on consistency traps, verified **basis-row upper bound** at t = 0 (`-ub-basis`) | every reported bound is checked; an anytime upper bound before the exact level |
| **Randomized upper-bound finder** (`-ub-search`, GH-140): random information sets with 1-2 systematic rows and stabilizer local improvement, time-sliced with the ladder, every word verified | the stop rule ends a run as soon as the certified lower bound meets the finder's bound (no hit level); realistic upper bounds on the open codes |
| DistQLDPC's anytime bound reporting, timeout handling and output format; `-cc-seed`, `-cc-trace`, `-cc-stats`; brute-force and mutation tests (`make test-cc`) | drop-in use with the existing tools and benchmarks |

With these additions the CC engine solves every bundled tier1-4 code in seconds on one core and confirmed five
distances that MaxSAT had not solved in 6 h (BB_360_12_24, TN_252_2_21, LP_1054_140_20, LP_1428_184_24,
LP_1768_224_22); see `optimization/experiments/GH-124/` and, for the GH-133 rules, `optimization/experiments/GH-133/`.
A survey of the published connected-cluster searches and of the ideas still open is in `docs/LITERATURE_CC_2026.md`.

---

## Output

| Line | Meaning |
|------|---------|
| `c trying d: N` | currently testing candidate distance `N` |
| `c d_lb: N` | proven lower bound on `d` |
| `c d_ub: N` | best upper bound found so far |
| `c d  : N` | final distance (when optimal) |
| `o N` | result line for scripts (`N` = distance); without an answer (timeout or failure) `c d  : UNKNOWN` and `s UNKNOWN` are printed instead |

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

## Authors

DistQLDPC is developed by Yu-Fang Chen (Academia Sinica) in collaboration with Ching-Yi Lai
(National Yang Ming Chiao Tung University). The project was started at
Ching-Yi Lai's suggestion, and the work continues through ongoing joint discussion.

## License

DistQLDPC is licensed under **GPL-3.0-or-later** — see [LICENSE](LICENSE).

The MaxSAT engine in `src/solver/` is derived from **MaxCDCL** (MIT).
Upstream copyright and license: [src/solver/LICENSE](src/solver/LICENSE).

Third-party attribution (MaxCDCL engine, benchmark matrices from
[codeDistancePYPI](https://github.com/m-webster/codeDistancePYPI)) and
DistQLDPC-specific solver patches:

- [NOTICE](NOTICE)
- [MODIFICATIONS.md](MODIFICATIONS.md)
