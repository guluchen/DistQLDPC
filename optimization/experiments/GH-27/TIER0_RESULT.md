# GH27 Tier 0 evidence

Tier 0 PASS for the tested production change 58fbae546e74c158c21070cd10106e94d6bd2b98
against immutable baseline 24572d6d09cce9a4a5faa58300a89e0feba9da6a.
Performance remains INCONCLUSIVE / NOT MEASURED. No comparative tier was run.

The first Windows attempt remains an engineering INCONCLUSIVE, not a scientific
PASS. The separately assigned full retry used frozen support
dc86b2926f57b9e09682770f93472944d6969804, driver SHA256
7e7a32ab3a1e894f2bac61c73c77981dc7987d1fb872920a4980e9fcb4df9c79 and corrected
fixture e720e19c0e7712e9a10d21124f0408a7e8d6e4592215dd6a98a3f9048246676c.
Only test fixture API was repaired; production was unchanged.

Windows retry 02 session 59542 exited 0, LOCAL_PASS, diagnostic PASS, valid_run=true.
Full default-O3 single-job rebuilds; 480 enqueue states in release and assertions-on
debug per version, plus 120 original watch and 120 actual GC states per version,
gave byte-identical baseline/candidate traces (2,400 individual fixture instances).
Three independently enumerated tiny CSS cases (distance 1/2/1), both OFF/MTO modes
and both versions gave 12 correct solves and six byte-identical WCNF pairs. Both
original smoke scripts passed. Four actual LP340 one-second parent timeouts gave
the original rc1/UNKNOWN/TIMEOUT semantics with all numeric interim bounds checked;
these were timeout checks, not Tier 2 performance. Thirty-six tiny unit-weight PMS
instances gave 72 matching exact-oracle solves with consistent status/exit semantics.

Hosted evidence is separately retained under raw/hosted-7a25708 and HOSTED_RESULT.md:
ordinary CI 37811855749 and cross-repository CI 37811855712 succeeded. Executed
merge 7e139c60b0f32733bc3f693a77ca3a8837072f08 has exact production source identity;
QDistSAT integration used 7c4774fffc49856f48a22ae5f9063d00b2661aaa. Four case/mode
comparisons (eight solves) matched final scientific results. Hosted artifact only
contains final summaries; it does not provide every interim output or binary bytes,
and hosted timings are not used as performance evidence. The raw Windows runner
conservatively says hosted REQUIRED_SEPARATELY; this document consolidates the
separate source-verified hosted evidence without rewriting that original raw result.

Baseline-only diagnostic opportunity, not comparative timing:

| Case | Mode | Entries | Soft false | Unlocked false | Locked false |
|---|---|---:|---:|---:|---:|
| LP_34_20_2 | OFF | 230 | 1 | 1 | 0 |
| LP_34_20_2 | MTO | 230 | 1 | 1 | 0 |
| LP_136_32_4 | OFF | 1,324,453 | 7,857 | 5,970 | 1,887 |
| LP_136_32_4 | MTO | 1,672,392 | 8,847 | 6,580 | 2,267 |

Actual production propagateForLK disassembly has two baseline calls to
uncheckedEnqueueForLK (100419134 and 100419401); candidate instead has two guarded
tail calls to handleSoftViolationForLK (100419133 and 100419504). This verifies
the intended call boundary changed in these actual Cygwin binaries. It does not
prove a speedup. Production symbol checks found no diagnostic hook.

Actual binary SHA256: baseline f2afe14e8f70c776372e0d4a23c21b7418510a6f6fe9b409aefbf0a98f062307;
candidate 9e920d9513541bdc87f13beebc78f040c5b95d16ffb291803a9c0f3244bde96e.
Original helper/runtime, sources, support, inputs and executable hashes were
checked before/after execution. Makefile/smoke CRLF normalization is documented;
there is no claim of bit-identical Linux/Cygwin builds.

Actual helper selected logical CPU 14 / sibling 15, one-CPU Job mask 16384,
AboveNormal 32768, fresh capacity guards and telemetry. This was not an exclusive
reservation. Only runner PID 15724 remained before close and was absent afterward.
Job limit, affinity, priority and sleep inhibition restoration all passed.
Coordinator RELEASE: issue15 comment6065816741. No further workload is authorized
by that completed assignment.

All 635 output/source/object/binary/raw files are retained in ZIP_STORED
raw/windows-attempt-02/attempt.zip, SHA256
e58ddf58c2e81dbb0883e8bae1f0ff87470702489a66f0f76c33e38d7c652a35,
with per-member digest manifest and directly accessible summaries, scientific
results, diagnostics, identities and cleanup. Path-specific raw/** -text protects
retained bytes; staged Git blob hashes must equal raw-sha256.json before publication.

Next: preregister the standard 48-solve Tier 1 filter on these immutable production
binaries under a fresh coordinator assignment. Nonzero opportunity warrants that
filter; it does not warrant accepting the method or advancing to Tier 2/3 yet.
