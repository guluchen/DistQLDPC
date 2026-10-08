# GH44 Tier0: local and hosted correctness PASS; performance untested

Tier0 decision: PASS. This assignment executed no performance work. The later
preregistered Tier1 is recorded in TIER1_RESULT.md: local REJECT / NOT ADOPTED,
formal controlled performance INCONCLUSIVE; no Tier2/3.

The sole conceptual change is GCC `-march=x86-64-v3`, with original generic
tuning, optimization/FP policy, linking/runtime and every solver source byte
preserved. Production commit `4a820ac5c1910d64930ed26a719af2f046a6a693`, baseline
`24572d6d09cce9a4a5faa58300a89e0feba9da6a`.

Assignment: https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6068471706
Frozen executed support `09f32016f6da1d6218f534b0c3f8ae16d1b52614`, driver SHA256
`08dba010b4cbf09cb63997d811957953c0024f34c66b82506a2ec8aed9287c48`.
Fresh `GH44-windows-tier0-01`, session86465 exited0. Actual CPU8/sibling9,
mask256, AboveNormal32768; one guarded Job, j1, 2700-second aggregate limit.
Original launch mask65535; CPUID and OSXSAVE/XCR0 gate authenticated v3 support
on the selected CPU before any candidate execution. ABI outputs and PE security
manifest match. The original FP contraction policy remains `fast`; FMA feature
availability can change search rounding, so trace equality is diagnostic rather
than a correctness or speed oracle. No fast-math or tuning change was added.

Local full Tier0 and independent retained-output audit PASS:

- 30 small CSS scientific streams with independent full Pauli enumeration,
  15 identical original WCNF pairs, all five builder modes.
- Eight original LP34/LP136 scientific solves and two original smoke tests.
- 72 standalone test-only PMS solves (36 independently enumerated cases),
  identical baseline/candidate status, return code and optimum sequence.
- 12 genuine timeout streams: four production LP340 and eight isolated
  pre-search/post-model hook tests. Every interim/final LB/UB/d/objective and
  incomplete status checked; actual pre-model absence and post-model UB verified.
- Full original 10216 runtime hashes and exact pre/post fileset unchanged;
  source/support/input/artifact pins validated, including produced objects and
  binaries before first execution. Test hooks and unsupported-stat shim are
  isolated from production.

Actual production binary SHA256:

- Baseline: `5d21d6c0c8daf117470e0dd353086f5a27bf5751f2a8ddb35136f2ac779325a8`
- Candidate: `42ebb16923087a68472cb5b821f470fd5f08be565033a82acf2d67765b78168e`

All252 resource samples were eligible;57 detected contention. This is a
correctness run, not comparative timing or an exclusively reserved CPU window.
Only runner18980 remained before Job release; it was absent after exit. All
owned-cleanup records confirm no remaining children. Job, affinity, sleep and
priority restoration all PASS (actual final mask65535/Normal32). Immediate release:
https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6068681197

Hosted gated validation separately PASS: ordinaryCI37840170280 and cross-repo
37840170300/job113527236175. Executed merge
`10d4f85d9a9cdf1d70189a66cd3e297240e872f1` has baseline245 and support09f3201
parents. All32 Make/src Git blobs equal the pinned production, and all src blobs
equal baseline. Portable ISA/OS gate ran before production builds. Artifact
11576644058 ZIP1251bytes SHA256
`38da683948eacea6202b1940645211f092fa47f2e862ef6600499c188d064f0d`
matches GitHub metadata. Eight final scientific results match known distances4/10.
Earlier ungated workflow successes are excluded from this gate. No CI elapsed
values are used as performance evidence; source identity does not assert
bit-identical Linux/Windows binaries or reproducible builds across environments.

Raw: `raw/windows-tier0-01` preserves all782 original manifest payloads unchanged,
plus exact post-exit and independent audit evidence; `raw/hosted-09f3201` retains
ZIP, extracted results/gate, decoded job log and exact-source audit. Original
`SHA256.json`, final `raw-sha256.json`, and raw `-text` attributes preserve byte
identity. No failed local attempt occurred.

Learning: fixed v3 is compatible and scientifically consistent on these two
validated hosts. This proves neither material vectorization nor performance
benefit. The subsequently executed standard48 filter found serious regressions,
as recorded separately. Unsupported CPUs must remain gated; do not deploy this
ISA globally.

Additional provenance limitation discovered during GH48 support review (2026-10-09): GH44 checked the helper source SHA but imported that helper through the normal Python source loader. A reusable helper bytecode cache exists in the workspace. Past cache bytes were not retained independently, so the source hash alone does not establish the exact imported helper bytecode for the historical run. Current cache contents cannot prove which bytes were used then. This is a limited historical executable-provenance gap, not evidence of a scientific mismatch; actual outputs, timing, observed affinity/priority, cleanup and public raw bytes remain retained. GH44 stays NOT ADOPTED/local REJECT with formal controlled timing INCONCLUSIVE. GH48 separately executes authenticated source bytes directly and launches Python with -B. No historical raw files or audit assertions are rewritten.
