# GH27 retained attempts

## Windows attempt01 — engineering INCONCLUSIVE, no scientific run

RUN_ASSIGNMENT6065364988, frozen support3afdbacc71b853e3d751b498f7d34f1e757d080d,
driverbcfad2ef6b911fae3d6f3e0e2e6c2092a9bd13b9d2fb17d95e36f3d6ecf0be25,
fixture22d5e8a00e9b92bd4b432462fd1cf585e89b36cb350e3e8ca151942013819c51.
Source candidate58fbae546e74c158c21070cd10106e94d6bd2b98, baseline24572d6.
Actual logicalCPU8/sibling9, Job mask256, AboveNormal32768.

Compiler identity and baseline default-O3 production application/assertions-on
Solver object compiled. The first480-case release fixture compilation failed:
vec2<int,vec<int>> and vec2<int,vec<Lit>> have no growTo member. Candidate not
built and NO fixture, solver/CSS/PMS/timeout/opportunity/performance run occurred.
Summary INCONCLUSIVE/Tier0NOTRUN/valid_runfalse; no scientific rejection or PASS.

Only runner22644 remained in owned Job before release, then runner absent.
Job limit/affinity/sleep requirement/priority all restored; finalmask65535/Normal32.
Session35564 exited1, coordinator notified, hub RELEASE6065417935. No automatic retry.
Complete output/source/object/binary/raw files retained in ZIP_STORED archive with
per-member SHA256 manifest, plus directly accessible failure/stdout/summary/cleanup/
identity telemetry and exact executed driver/fixture. Original files are unchanged.

Routine test-support repair changes isets.growTo(2)/isetsLits.growTo(2) to
isets.init(1)/isetsLits.init(1). Actual vec2 declaration Solver.h67–80 grows
underlying vectors to index+1; production uses same init API at Solver.cc
3384/4240/4889/4929.480 cases and production source unchanged. New support/driver
must be frozen under a reviewed continuation before another attempt. No old
failed record becomes PASS, and no performance conclusion follows from this failure.

## Windows attempt02 — full local Tier0 PASS and baseline-only diagnostics

Fresh assignment6065614772, frozen supportdc86b2926f57b9e09682770f93472944d6969804,
driver7e7a32ab3a1e894f2bac61c73c77981dc7987d1fb872920a4980e9fcb4df9c79,
corrected480-case fixturee720e19c0e7712e9a10d21124f0408a7e8d6e4592215dd6a98a3f9048246676c.
Production unchanged58fbae5; baseline24572d6. Actual selectedCPU14/sibling15,
mask16384, AboveNormal32768. Session59542 exit0; LOCAL_PASS, diagnosticPASS,
valid_runtrue. All original review scope rerun from full-j1 baseline/candidate builds.
See TIER0_RESULT.md for exact fixture/scientific/assembly/opportunity evidence and
raw/windows-attempt-02 for immutable original output. No comparative timing.
Only runner15724 remained before close, absent afterward; all restorationtrue.
Resource released6065816741 before retaining evidence or requesting another tier.
