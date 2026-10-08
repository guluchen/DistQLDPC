# GH48 Tier 0 evidence

Tier 0: PASS after full local execution, independent raw audit, and separately
retained hosted source/science audit. Overall experiment: INCONCLUSIVE; no
optimization is adopted. The subsequent standard48 Tier1 is complete, scientifically
correct but numerically rejected/formally INCONCLUSIVE; see TIER1_RESULT.md.

Immutable production `d27cf4d54bc08c6db4b2ffcebfe0372417bb13ef` contains only
the original Make compile flags plus `-march=x86-64-v2`. Baseline is
`24572d6d09cce9a4a5faa58300a89e0feba9da6a`; all solver/application source,
MODIFICATIONS and NOTICE bytes remain unchanged. QDistSAT/DistQLDPC remains a
downstream project derived from MaxCDCL, not identical to upstream MaxCDCL.

Executed support `5f9a4522ad53b480ec75fe3d38cf7d7bdd361c42`, driver SHA-256
`fba3d71d83b874640e15ffb3dd532b3d771d801f5eb113f345d9160d539a37db`.
Assignment: https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6069265947
Prelaunch freeze: https://github.com/guluchen/DistQLDPC/issues/48#issuecomment-6069332137
One fresh `GH48-windows-tier0-01`, session 52540, exit 0. No failed local attempt.

Actual CPU 4 / sibling 5, mask 16, AboveNormal 32768. Portable original-flags
gate authenticated this selected core as x86-64-v2 compatible before candidate
execution. Original GCC 14.4, generic tuning, floating-point optimizer policy,
language/ABI, GNU linking, PE and live original DLL provenance passed. Both builds
exclude AVX/FMA macros. Exact authenticated helper source execution bypasses
bytecode cache; all produced sources/objects/binaries were pinned before execution.

Full local science and independent audit passed: 50 application scientific
streams (30 CSS, eight LP_34/LP_136 production traces, 12 genuine timeouts),
two original smoke tests, 72 standalone PMS solves covering 36 independently
enumerated Boolean optimum cases, and 15 byte-identical WCNF pairs. The separate
CSS oracle enumerates Pauli support using the original stabilizer and logical
predicates (distances 1, 2, 1). Every interim/final bound, distance, objective,
status and return code was checked. Isolated test-only objects exercise both
pre-search and post-model genuine timeout semantics; production objects contain
neither hook nor test shim. No scientific mismatch or crash occurred.

All 782 original raw-manifest payloads and artifact pins verified. All 10216
original runtime files and the complete runtime file set remained unchanged.
248 resource samples were capacity-eligible; 19 reported contention. No exclusive
reservation or performance measurement was claimed. Before Job release only
runner PID 21040 remained, and actual post-exit Get-Process confirmed it absent.
Every owned cleanup record confirms remaining=[]; Job affinity, original parent
mask 65535, Normal priority 32 and sleep requirement were all restored.
Release: https://github.com/guluchen/DistQLDPC/issues/15#issuecomment-6069494116

Hosted checks: ordinary CI 37846104241 and cross-repo 37846104190, job
113547252432, SUCCESS. Actual executed PR merge
`22d1af454adacb81446044d13d03de62e9b024d5` has all 32 Make/src blobs equal
to production d27, and all src blobs equal baseline 245. The v2 gate preceded
production build. Eight final scientific results (LP_136 distance 4 and BB_108
distance 10, OFF/MTO, both versions) match ground truth.
Artifact 11580311686, 1254 bytes, SHA-256
`451d63d84f4d55472d6eba77500175eec12035c63f2b1637381b5739afe20c38`
matches GitHub metadata. No hosted elapsed-time conclusion or Linux/Windows
binary reproducibility claim is made. The local runner's original
Tier0_complete=false/hosted-required fields remain unmodified; this combined
record completes that separate hosted gate.

Executed production binary SHA-256:
- baseline: `70582f38a02b8e2b2948867f9ea3680f44ca9e04184bdb7891f1f51a7222693e`
- candidate: `ef61efc3d6a4605c19b9c4b279dc95d08914910efb946221030601bfe24c2317`

All 793 retained raw files are recorded in raw-sha256.json with raw/** -text;
original SHA256.json and every raw payload remain unchanged. Source and runtime
compatibility here establish correctness on these tested hosts; they do not
prove faster execution, identical search trajectory, or compatibility elsewhere.
Next: independently review a disabled fixed-binary standard 48-solve Tier 1,
then acquire a fresh named serial Windows assignment before any timing.

Subsequent finite experiment disposition: ONE separately preregistered exploratory LP340 Tier2 is now complete; all12 science correct, numeric/formal INCONCLUSIVE, practical SHELVE/NOT ADOPTED. See TIER2_RESULT.md and public aa2c21e; no further GH48 workload/Tier3. Historical gates and raw are unchanged.
