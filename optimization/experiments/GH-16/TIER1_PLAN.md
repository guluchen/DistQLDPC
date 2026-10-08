# H010 Windows Tier1 plan, before timing

Production source4674331; immutable binary/profile hashes in Tier0 record.
No retraining, rebuilding or compiler parameter tuning against evaluation cases.
Four cases BB90/GB144/BB108/LP238, OFF/MTO separately; baseline and candidate
three times each in AB/BA/AB order on one identical selected logical CPU.
48 solves, parent180s/watchdog195s, one worker. All raw output/commands/timings,
median and ranges retained. Verify exact distance/objective/LB/UB eachrun;
any semantic mismatch/crash rejects immediately, sound incomplete run is inconclusive.

Numerical filter is the unchanged original package judge, fixed before timing:
per mode geometric mean of median ratios; conservative range-envelope geometric
mean (max candidate/min baseline); require all per-case medians nonworse and
range-envelope mean<1 for a positive numerical filter. All candidate samples
slower than all baseline samples is a numerical regression flag. This flag
requires variance/contention review before a performance disposition; a small
nonoverlap alone does not prove a serious research regression.
No pooling modes or hiding case regressions in an aggregate. Both modes PGO affected.

Windows has no exclusive reservation. Numeric pass alone remains formally
INCONCLUSIVE pending sufficient resource/evidence review; shared CI times ignored.
Minor contention retained with2s telemetry; cannot turn uncertain noise into PASS.
Source/profile/binary identity frozen and checked before/after, original parser
and immutable inputs reused from verified E004 package but its LTO binaries neverrun.
One coordinator-assigned runner, aggregate spare>50%, no more thanhalfspare,
owned Windows Job affinity/AboveNormal only, bounded worker cleanup, restoreall.

Host assignment is recorded in issue15 before execution. No Tier2/3 execution
is authorized by this plan. Bounded user-directed exploratory continuation,
if appropriate after inconclusive positive/no-serious-regression evidence,
requires its own prerecord and is not a Tier1 PASS.
