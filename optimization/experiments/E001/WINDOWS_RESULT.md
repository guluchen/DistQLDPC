# E001 Windows result — 2026-10-07

Overall decision: **INCONCLUSIVE for the original controlled-host experiment**.
Windows diagnostic numeric Tier 1 filter: **REJECT** in both modes, caused by
GB_144_12_8 regression. No Tier 2 or Tier 3. Candidate remains isolated; no merge.
Do not confuse local numerical rejection with a controlled Linux performance claim.

## Versions, environment and validation

Baseline code: 24572d6d09cce9a4a5faa58300a89e0feba9da6a.
Candidate code: 50623f9710969288d3a9d1c6325f3a72c35ff6d5; snapshot
9d68f459019e9c5a20c5c513cf89aaf4a2cd2854. QDistSAT harness:
7c4774fffc49856f48a22ae5f9063d00b2661aaa. No production code, matrices, notices,
attribution, cardinality options or solver/timeout/result semantics changed.

Windows 11, Intel Core Ultra 5 225, 10 cores/logical processors, balanced power
plan, 254 processes at host capture; no exclusive reservation, no pinned CPU,
no fixed governor. Cygwin 3.6.11, GCC 14.4.0. Native Python runs the unchanged
Tier 0 checks and the timing driver. This differs from native Linux execution.
All timing pairs share this environment, inputs, flags and limits. See raw host,
compiler, manifest and binary hashes under raw/windows-validation/.

Both DistQLDPC applications compiled with the exact root Makefile flags.
Fresh Windows Tier 0: **PASS**. Production-helper checks cover 676 algebra
inputs, row-space/quotient/pairing/syndrome preservation; exhaustive CSS fixtures
have d=2 and d=1. BOTH/OFF/MTO fixture solves, existing smoke, unchanged QDistSAT
pilot in OFF/MTO, and six one-second timeout checks pass. All 48 measured solves
complete with certified expected distance/objective/lower/upper bounds matching.

Environment failures were resolved without solver changes, before timing:
- Cygwin make/Guile failed to start; invoke exact application compiler commands.
- Standalone maxcdcl CLI fails to link memUsedPeak() on Cygwin; retain its failure
  log; it is not used by the distance experiment. Full `make all` did not pass.
- Compile the POSIX production-helper probe using gnu++11, not strict c++11.
- Cygwin Python cannot import _posixsubprocess; use native bundled Python.
- Convert native Windows matrix arguments to Unix paths in the test launcher.
  The earlier fixture run failed to find input, before any candidate solve;
  it was a harness invocation failure, not a distance mismatch.
- Enable native Python UTF-8 to read unchanged QDistSAT Unicode metadata.
All failed attempts and commands retained; no failed timing sample was discarded.

## Tier 1 local measurements

Serial AB/BA/AB; three baseline and three candidate runs per case/mode;
180-second internal limit, 195-second watchdog; verbose output captured identically.
End-to-end wall time includes process start, matrix loading, transformation,
encoding, simplification and search. No separate preprocessing cost is inferred.

| Case | Mode | Baseline median (s) | Candidate median (s) | Candidate/baseline |
|---|---|---:|---:|---:|
| BB_90_8_10 | no-card | 2.3817 | 2.2321 | 0.9372 |
| BB_90_8_10 | card-mto | 2.8155 | 2.3660 | 0.8403 |
| GB_144_12_8 | no-card | 0.9820 | 1.4659 | 1.4929 |
| GB_144_12_8 | card-mto | 1.2482 | 1.7648 | 1.4138 |
| BB_108_8_10 | no-card | 2.8979 | 2.5156 | 0.8681 |
| BB_108_8_10 | card-mto | 3.6811 | 2.9660 | 0.8057 |
| LP_238_44_6 | no-card | 1.8816 | 1.7824 | 0.9472 |
| LP_238_44_6 | card-mto | 2.2152 | 1.7311 | 0.7815 |

Equally weighted geometric mean of median ratios: OFF 1.03565, MTO 0.93002.
Do not aggregate modes to hide GB's regression. GB OFF baseline range
0.9805–1.0326 s versus candidate 1.4494–1.4828 s; MTO baseline 1.2472–1.2493 s
versus candidate 1.7482–1.7838 s. All three candidate runs are slower than all
three baseline runs in both modes, exceeding their observed sample ranges.
This is strong local counterevidence to promotion; three samples on this host
do not establish hardware independence or remove the original controlled gate.

Raw records: samples.json contains all 48 timings, commands and semantic tuples;
all stdout/stderr, build/probe logs, intermediate harness failures, final Tier 0
summary, environment.json and windows-host.json are retained. all-medians.json
and all-medians.csv retain all eight comparisons, including their full ranges.

## Learning and next action

H-001 preserves correctness in this Windows environment but fewer logical XOR
gates do not guarantee faster complete solves: GB shortened structurally yet
became slower here. The causal solver mechanism is unmeasured; do not invent it.
No portability claim, acceptance, merge or higher-tier run follows from this.

Keep H-001 unpromoted. When dedicated access becomes available, run the supplied
original package to determine whether GB's regression reproduces under controlled
conditions. If it does, reject H-001 under the original gates and use that evidence
when choosing the next hypothesis. Do not bundle another idea into this candidate.
