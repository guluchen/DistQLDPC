# GH-fable-triwatch: ternary-clause inline watchers (tri-watch)

Agent `fable-triwatch-20261008` (Claude Fable 5.1 session on the PI's macOS
host). Coordination hub: [issue 15](https://github.com/guluchen/DistQLDPC/issues/15).
Preregistration: [PROPOSAL.md](PROPOSAL.md) (three proposals, selection,
preregistered gates). Bibliography: [references.bib](references.bib).
Downstream attribution: `MODIFICATIONS.md`, `NOTICE` at the repository root.

| Item | Value |
|---|---|
| Baseline (immutable) | `24572d6d09cce9a4a5faa58300a89e0feba9da6a` |
| Preregistration commit | `1e623e1` (record only, no source change) |
| Candidate source | `8fbdbc475dce1ed6144b80df2a838b060da5757f` (3 source files, +161/−19) |
| Branch | `experiment/fable-triwatch-20261008` |
| Status | see [RESULT.md](RESULT.md) |

## Directory

- `PROPOSAL.md` — preregistration written before any candidate edit.
- `ISSUE_BODY.md` — the GitHub issue text as registered.
- `references.bib` — local BibTeX additions (integrator reconciles later).
- `profile_case.sh` — macOS `sample` wrapper used for the baseline/candidate profiles.
- `run_tier1_macos.py` — Tier 1 serial AB/BA/AB runner with telemetry, medians and the preregistered decision rule.
- `tests/prop_closure_test.cc` — test-only propagation-closure differential harness (compiled against baseline and candidate object files; outputs must be byte-identical).
- `tests/tiny_css_oracle.py` — test-only brute-force CSS distance oracle on five tiny codes, all cardinality modes.
- `raw/baseline-profile/` — baseline `sample` profiles and solver logs (8 case/mode pairs).
- `raw/diag-instrumentation.patch`, `raw/diag-counts.txt` — baseline visit/dereference counters (instrumented copy, never in the candidate).
- `raw/diag-counts-candidate.txt` — the same counters on an instrumented copy of the candidate.
- `raw/tier0/` — Tier 0 evidence: WCNF identity, closure dumps (gzip), assertion-build end-to-end logs, production end-to-end logs, tiny oracle output, timeout checks.
- `raw/tier1/` — Tier 1 raw logs, `runs.json`, `SHA256SUMS` (only after a host assignment).

## Build used on this host

`CXX=g++-16` (Homebrew GCC 16.2.0), original Makefile flags `-O3 -g -DNDEBUG`
plus `-isysroot $(xcrun --show-sdk-path)` (needed on macOS 27 for Homebrew GCC;
no other flag change). Apple clang cannot compile the baseline (`PRIi64`
literal-suffix errors in `utils/Options.h`), so GCC is used for both versions.
