# E001 execution continuation — 2026-10-07

Preregistered continuation: recover and audit existing H-001, retain the exact
candidate, and materialize its dedicated-server package. No second hypothesis
or additional performance change is authorized by this continuation.

Recovered from `origin/experiment/h001-logical-row-xor` at
`9d68f45`; proposal, result, raw correctness evidence and server gates already
exist there. Main is `24572d6d09cce9a4a5faa58300a89e0feba9da6a`.
Candidate code is `50623f9710969288d3a9d1c6325f3a72c35ff6d5`.

Hypothesis: independently shorten Gx/Gz copies with one sequential row-XOR
pass, choosing the greatest strict weight reduction and lowest-index tie,
before encoding with DistQLDPC's embedded MaxCDCL engine. Preserve row order/count.
Mechanism: fewer logical XOR gates, preserving logical row spaces through
invertible elementary row operations. Expected effect is strongest on LP cases;
all named Tier 1 cases must be measured. Search can regress despite fewer gates.
Scope: existing application helper and MaxCDCL entry-point call only. No solver
patch, matrix edit, new instrumentation, or semantics change. Attribution remains.
Expected cost: 48 Tier 1 runs across OFF/MTO, then only if passed 12 Tier 2 runs;
180/600-second internal limits, 195/615-second watchdogs, serial execution.
Full proposal and decision criteria remain in PROPOSAL.md. Relation to previous
attempt: resume E001's missing controlled measurement; do not relabel it a new trial.

Current machine: Windows desktop, no visible g++/make/clang++, no installed WSL
distribution, and no supplied dedicated-host reservation or connection. Existing
macOS Tier 0 and hosted Linux correctness evidence can be audited; they cannot
establish a controlled performance result. No performance benchmark is scheduled
on this machine. Tier 2 and Tier 3 remain gated.

The source candidate is isolated on local `experiment/h001-execution-review`,
continuing the existing remote experiment branch. Main remains unchanged.
Final audit: PASS, recorded in `raw/execution-review.json`. All 914 archive
payloads match their manifest; all 28 original input identities match; the source
diff matches the retained implementation patch and the tested application file.
The hosted report ZIP matches its recorded SHA-256 and all four case/mode pairs
have matching certified distance/objective/bounds. Fresh runner tests: 6 PASS.
No fresh solver build or run was possible here; prior Tier 0 PASS is retained,
not represented as a new local run. No mismatch or scientific anomaly observed.

The Windows Git archive default applied CRLF conversion on an initial packaging
attempt. The delivered package disables that conversion and uses exact blob
bytes, confirmed against input and patch hashes. Initial staging directories
`E001-run-package` and `E001-dedicated-package` are not deliverables.

Decision: **INCONCLUSIVE pending controlled run**. Tier 1 raw sample count 0,
all medians unavailable. Tier 2 not reached; Tier 3 not run. No performance claim.
New observation: the prior candidate and correctness evidence already exist;
the missing work is controlled timing, not another implementation. No evidence
supports changing the hypothesis, gates, or accepted solver behavior.

Delivered archive: `E001-linux-package.tar.gz` in the parent workspace.
SHA-256: `3df26a2e60dd23216c37c3cd2f3dfe07b5173059a383c9ba565e28078973b84e`.
Baseline `24572d6d09cce9a4a5faa58300a89e0feba9da6a`, candidate snapshot
`9d68f459019e9c5a20c5c513cf89aaf4a2cd2854` (unchanged code from `50623f9`),
QDistSAT `7c4774fffc49856f48a22ae5f9063d00b2661aaa`.

On the reserved dedicated Linux server, with g++, make, Python >=3.10 and zlib
development headers, run from the archive's directory:

```sh
printf '%s  %s\n' \
  3df26a2e60dd23216c37c3cd2f3dfe07b5173059a383c9ba565e28078973b84e \
  E001-linux-package.tar.gz | sha256sum --check
tar -xzf E001-linux-package.tar.gz
cd E001-linux-package
python3 candidate/optimization/server/run.py \
  --package . --output ../E001-controlled-results \
  --cpu 2 --exclusive-host --reservation-note 'actual exclusive reservation ID'
```

Replace CPU 2 and the reservation note with real reservation values. Use a new
output directory. Reserve the physical core and its SMT sibling, fix governor
and power policy, and stop unrelated workloads. The runner rebuilds both and
reruns Tier 0 before 48 interleaved Tier 1 runs; Tier 2 is conditional. It records
commands, full outputs, samples, medians and gate decisions. No Tier 3 code.
Import the entire results directory under E001/controlled and reconcile STATE,
HYPOTHESES and result.json. Do not substitute shared CI timing.

Next action: provide dedicated Linux server connection and exclusive reservation,
or run this package there and return the complete results directory. No scientific
decision or new hypothesis is required while controlled evidence remains absent.
