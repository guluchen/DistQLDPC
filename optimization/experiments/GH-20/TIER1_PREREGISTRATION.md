# Single next filter: GH20 Tier1

Preregistered after nonzero opportunity and Tier0 PASS, before any performance
run. Same selected concept, no production edits, tuning, PGO or other method.
Immutable baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a / production3fe5afead91cf0527cd39529a6d48b4e19e12041.
Reuse only successful attempt05 production binaries, frozen hashes:

- baseline cfa5b6ca62b8f1ef7c2e705c01f20454c9a32fe35b4a694ac78c3940d08003f4
- candidate33f20395f69b032166dee3fb72797d75dd03d52afad3bd7f81b58ddf1140676e

Cases BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6; both OFF/MTO.
Each case/mode baseline3 and candidate3, serial repeat order AB/BA/AB:48 solves.
180s internal /195s external watchdog each; worst-case156min plus preflights.
Same pinned QDistSAT/package matrix inputs, seed/default engine settings, compiler
flags and one owned CPU; no diagnostic/profiling hooks in either production binary.

Runner derives reviewed GH16 Windows Tier1 resource/semantic rules and records
provenance explicitly; no reuse of PGO engine/training profiles. Check every
interim/final lower/upper bound, objective/distance, completed numeric tuple,
genuine timeout UNKNOWN/rc1, malformed output/crash and process cleanup. Any
scientific mismatch rejects and stops; incomplete/resource-aborted runs cannot
produce a promoted timing median. No quiet repeat-until-favorable.

Keep raw commands/stdout/stderr/wall durations, all3/version medians, ratios,
sample ranges, per-run capacity/physical-sibling contention and immutable binary/
input/source/support hashes. One named host RUN_ASSIGNMENT required; spare>50%,
team use<=half spare, fixed one-worker Windows Job/AboveNormal,2s guard sampling,
owned-only bounded cleanup and all restoration booleans true. These do not claim
exclusive OS scheduling. Uncontrolled/noisy timing stays formal INCONCLUSIVE,
with exact reproducible dedicated-server commands and the retained observations.

Promote only unchanged correctness, positive reproducible direction and no serious
case regression; use previously reviewed GH16 numeric filter without retrospective
threshold changes. Tier2 LP340 only after an adequate gate or separately scoped
user exception. No Tier3. Current host owner GH21; **Tier1 NOT STARTED**.
