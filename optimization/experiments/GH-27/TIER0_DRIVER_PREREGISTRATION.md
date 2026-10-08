# GH27 Windows Tier0 preparation — NOT EXECUTED

Baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a;
production candidate58fbae546e74c158c21070cd10106e94d6bd2b98.
These do not change when this test-support record is committed.
Current exclusive Windows owner GH21 exploratory Tier2 at hub6064431256;
GH22 finished its negative local filter. GH27 has NO host assignment.

`windows_tier0.py` stops at HOST_SLOT_NOT_ASSIGNED before creating output,
importing the resource helper, reserving a Job or running any command.
Its source was inspected and Python AST parsed only, not imported/executed.
Fixture480 replaces the previously prepared240, after independent review found
UBconflictFlag uninitialized. Both versions now explicitly initialize printed
flags/counters and test UB false/true. No previous fixture PASS is claimed.

Supervisor ancestry: actual GH22 Tier0 source SHA256
86587e2cb965ca688c7da01e053ea59c4b548519f76542a1fde083964ff4f723;
reviewed GH20 Tier1 owned-cleanup action journaling/ownership rechecks and
independent restoration/finalization. Temporary helper unchanged, pinned SHA256
ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2;
the four reviewed Cygwin runtime DLL hashes are pinned in the driver.
All six tool binaries, support, exported source and input hashes are recorded
before execution and rechecked afterward. Production binaries are pinned after
their fresh builds; no prior candidate binary is reused. Entire output SHA256
manifest includes sources/objects/raw/logs; raw/** -text preserves public bytes.

Execution scope, only after a fresh reviewed RUN_ASSIGNMENT:

- Default Makefile O3 production application from independent exact Git archives,
  baseline and candidate, make -j1,300s watchdog/build. Only Makefile/original
  smoke CRLF normalization for Cygwin shell; no bit-identical rebuild claim.
- Focused480-case enqueue fixture in release/default-O3 production Solver object
  and separate -O0/assertions-on Solver object; original/candidate byte-identical
  complete state traces required. Debug Solver compile180s, each probe link120s,
  each trace30s. Release fixture caller retains assertions; original/candidate
  valid inputs satisfy them. Options/System are unchanged support objects.
- Original120-case propagation and actual120-case watched-state/reason-GC fixtures
  from durable GH20, both versions' release production objects, no solver hooks.
- Actual production nm/objdump/size output,30s/tool; no diagnostic symbols in
  production; propagateForLK instructions required; optional absent enqueue/helper
  symbols are recorded honestly. Generated-code interpretation requires review.
- Three tiny exact CSS oracles,2modes×2versions:12 solves5/20s and12 dump-only
  runs,6 byte-identical WCNF comparisons; original2 smoke scripts20s.
- Four genuine LP340 rc1/TIMEOUT/UNKNOWN tests1/20s, bothversions/modes. These
  are Tier0 timeout semantics, NOT Tier2 or comparative performance evidence.
- Original standalone Main linked only for tests with same Cygwin statistics
  fallback from GH22 (memUsedPeak delegates original memUsed); no shim in production.
  Four fixed plus32 seeded tiny partial MaxSAT cases, exact exhaustive Boolean
  oracle,72 original/candidate solves20s; every optimal token, status and exit
  checked and compared. No broad parameter sweep.
- Only after all local correctness passes, four preregistered pinned-BASE-only
  diagnostic LP34/LP136 OFF/MTO solves120/135s. Original function gets test-only
  counters for entries/soft-false/unlocked-false/locked-false, dumped by child
  before its _exit via C linkage. Validate sum/range and scientific result.
  Separate source/binary hash and instrumented archive; never timed baseline/
  candidate or profile-driven production. Counters are opportunity, not speed.

One selected logical CPU/AboveNormal unnamed Job, same reviewed temporary helper,
2s fresh capacity/descendant checks, 50ms child polling. Global spare>50% and
oneCPU<=half spare must hold; sibling contention is recorded, no exclusivity
claim.45-minute aggregate watchdog plus per-command limits. Bounded file-backed
stdout/stderr avoids pipe-drain hang. Only owned PID tree can be terminated;
cleanup journal precedes wait and each orphan ownership is rechecked.
Restoration always attempted even when child cleanup fails. Summary/raw survive
errors; scientific rejection retained separately from cleanup invalidity.
Valid_run false and exit1 on identity/cleanup/restoration/manifest errors.

Every interim/final numeric LB/UB/d/objective is validated, malformed fields
rejected, trying-distance syntax checked. Completed output must have exact final
distance/objective/bounds and no UNKNOWN/status regression. Timeout requires
rc1, one UNKNOWN status, TIMEOUT comment, unknown distance and no objective.
Any semantic mismatch/crash/test assertion => REJECT/stop, no diagnostics afterward.
Build/resource failures remain INCONCLUSIVE with actual failing command retained.

The driver can only record LOCAL_PASS; required ordinary CI/QDistSAT cross-repo
evidence must independently reconcile actual source/artifact before overall Tier0.
No Tier1/2/3 auto queue, no performance timings/claim. Parent reviews source/driver
and issues a future assignment before only ASSIGNED_URL is frozen into the actual
executed support commit/hash. Record frozen hash before start and never edit it
while active. Example command AFTER that authorization/freeze, from workspace:

```powershell
python -X utf8 GH27-ENQUEUE/optimization/experiments/GH-27/windows_tier0.py --out GH27-windows-tier0-01 --run-assignment '<fresh actual hub RUN_ASSIGNMENT URL>'
```

Raw output must be fresh direct workspace child. Parent supervisor additionally
retains runner stdout/stderr and verifies owned descendants/restoration at release.
No remote server resource use is authorized by this prepared driver.
