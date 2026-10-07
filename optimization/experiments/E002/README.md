# E002 / H-002 — exact XOR-prefix sharing

**Decision: INCONCLUSIVE for controlled performance; Windows numerical Tier 1 REJECT.**

This is a new engineering experiment, not another E001 repeat. The existing
Brain candidate name was recovered from HYPOTHESES.md; detailed original Brain
prose was unavailable. PROPOSAL.md records the chosen concrete scope explicitly.
E001's logical row-XOR change is absent. Baseline: 24572d6d09cce9a4a5faa58300a89e0feba9da6a.
Candidate code: 80a6eba17fc169e3ab99dfd2266df1e78120752a; exact application diff in implementation.patch.
Only exact signed, ordered XOR pairs within one MaxCDCL application encoding
share a defined auxiliary literal. Matrices, objective, bounds, timeout/results,
embedded engine and attribution unchanged. Dump-only/other backends default
to uncached encoding. Candidate isolated on experiment/h002-xor-prefix.

## Tier 0

Windows application build PASS with identical GCC 14.4 original Makefile flags;
baseline executable and unchanged engine objects verified and reused. Production
XOR-clause probe: 584 signed/repeated chain cases, each with all 16 original
assignments and all auxiliary extensions; exactly one correct extension. Checks
duplicate reuse, ordered keys and fresh per-solver cache lifetime. Small exact
CSS oracle d=2/d=1 in BOTH/OFF/MTO; smoke; pinned QDistSAT pilot OFF/MTO; six
one-second timeout checks PASS. No crash, wrong distance/bound or semantic mismatch.
All 48 measured solves return certified expected distance/objective/lower/upper
bounds. Local pilot is not a hosted PR check; that check remains pending.

## Tier 1 local diagnostics

Windows/Cygwin interactive desktop, no reservation/pinned CPU/fixed power policy.
Same four cases and OFF/MTO modes, 3 runs/version, serial AB/BA/AB; verbose raw
logs, 180 s internal timeout / 195 s watchdog. Full wall includes construction
and solving. No timing timeout/failure/sample discarded. Results are local,
not machine-independent or controlled dedicated-server performance evidence.

| Case | Mode | Baseline median (s) | Candidate median (s) | Candidate/base |
|---|---|---:|---:|---:|
| BB_90_8_10 | no-card | 2.4118 | 2.1655 | 0.8979 |
| BB_90_8_10 | card-mto | 2.8645 | 2.7493 | 0.9598 |
| GB_144_12_8 | no-card | 0.9830 | 1.1839 | 1.2044 |
| GB_144_12_8 | card-mto | 1.2491 | 1.3475 | 1.0787 |
| BB_108_8_10 | no-card | 2.8731 | 2.9983 | 1.0436 |
| BB_108_8_10 | card-mto | 3.6821 | 3.2995 | 0.8961 |
| LP_238_44_6 | no-card | 1.8653 | 1.7157 | 0.9198 |
| LP_238_44_6 | card-mto | 2.1988 | 2.1815 | 0.9921 |

Equal-weight median-ratio geomeans: OFF 1.00938; MTO 0.97949.
The local filter rejects; averages do not hide these disjoint regressions:
- GB_144_12_8 no-card: baseline 0.9812–0.9991 s, candidate 1.1814–1.2142 s.
- GB_144_12_8 card-mto: baseline 1.2487–1.2500 s, candidate 1.3472–1.3507 s.
- BB_108_8_10 no-card: baseline 2.8649–2.9157 s, candidate 2.9922–2.9996 s.

## Learning / next action

Sharing reduced generated XOR gates on every inspected case before elimination:
LP_136 1400->1328, BB_90 654->630, GB 1283->1277, BB_108 790->775,
LP_238 2630->2552, LP_340 4320->4125. This did not guarantee faster solving.
Do not infer which search/propagation mechanism caused regression; it was not
isolated. H-002 is unpromoted, and no Tier 2/3 or merge occurred. Keep the failed
local filter. Next iteration should read E001 and E002 history; no replacement
hypothesis is selected here. Controlled reproduction is available if needed.

## Reproducible dedicated-server package

Requires exclusive reserved Linux host, g++, make, Python >=3.10, zlib headers.
Reserve a physical CPU and its sibling, fix governor/power and stop other jobs.
The package contains pinned source/data/harness and exact identity manifest;
it excludes Windows binaries/objects and preserves licenses. Replace CPU 2 and
reservation note below with real reservation values. Use a new output directory.
The runner re-enters Tier 0, runs Tier 1, and only on a controlled Tier 1 PASS
allows LP_340 Tier 2 (3/version/mode, 600 s / 615 s watchdog); no Tier 3 code.
Worst internal timing budgets: Tier 1 144 min, Tier 2 120 min; overhead extra.

```sh
printf '%s  %s\n' bb80b66f41d5443fca8529f109f06832ae14d6fa547ddc3f908606cb222cbe78 E002-run-package.tar.gz | sha256sum --check
tar -xzf E002-run-package.tar.gz
cd E002-run-package
python3 server_run.py --package . --output ../E002-controlled-results --cpu 2 --exclusive-host --reservation-note 'actual exclusive reservation ID'
```

Package SHA-256: `bb80b66f41d5443fca8529f109f06832ae14d6fa547ddc3f908606cb222cbe78`; 1359 payload hashes verified.
Retain complete controlled outputs before reconciling the decision; never replace the Windows data.
