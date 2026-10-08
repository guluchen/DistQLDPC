# GH21 O2-only experiment

Current status: **Tier0 PASS; performance INCONCLUSIVE / NOT ADOPTED**, all48 Tier1+12 exploratory Tier2 scientific results correct. Tier1 OFF/MTO median improvements approximately0.788%/0.679%; LP340 OFF effectively neutral, MTO approximately1.426% faster, both repeated ranges overlap. See [Tier1 result](TIER1-RESULT.md), [exploratory Tier2 result](TIER2-EXPLORATORY-RESULT.md) and exact raw/audit evidence. Windows released6064674507; no Tier3 or further suite execution. Tier1 was not promoted; low-priority controlled followup retained.

Selected proposal and paper-derived unselected alternative: [PROPOSAL](PROPOSAL.md), [BibTeX](references.bib). Issue: https://github.com/guluchen/DistQLDPC/issues/21 . Owner independent-brain-20261008-round2, exclusive branch experiment/gh21-o2; baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a. Preregistration commit5f6358d preceded implementation.

Production diff: Makefile CXXFLAGS -O3 to -O2, one token. All src, other flags, libraries, attribution unchanged. MODIFICATIONS/NOTICE need no solver-patch entry because no embedded source patch is made. No combined PGO/LTO/native/scratch/watch-copy change. Hosted tests exercise default Makefile flags; shared CI timings are informational. Local Tier0 and fixed48 Tier1 were executed under separate recorded assignments; host now released.

Reproduction in TWO fresh source checkouts on the same assigned host (baseline24572 vs this candidate), from each directory:

```sh
make -j1
bash scripts/smoke_test.sh
g++ --version
g++ -Q -O3 --help=optimizers > o3-optimizers.txt
g++ -Q -O2 --help=optimizers > o2-optimizers.txt
size bin/distqldpc bin/maxcdcl
```

Do not override CXXFLAGS. Record exact compiler/environment/default build logs; clean source directories prevent mixed objects. Set CXX consistently only if the existing make built-in selection differs on the host; retain every other flag. Source semantic hashes normalize CRLF only for Git working-tree checkout differences, with original raw hashes also recorded.

Prepared Tier0 support: run_tier0.py uses independent CSS d1/d2/d1 oracles, explicit-mode WCNF pairs, LP34 smoke, forced LP340 timeout/bounds and four tiny standalone unweighted-PMS exhaustive optimum oracles. Main.cc's standalone "optimal:" output/exit/status is checked directly; no invented o-line semantics. windows_assigned_runner.py reuses GH17's bounded file-backed supervisor and Job descendant checks, source/package/runtime provenance guards, continuous capacity telemetry and restoration. Windows builds candidate DEFAULT flags for the production bin/distqldpc target; separately links original Main with a symmetric TEST-only unsupported-platform memory-statistic fallback. Baseline original O3 objects copied/hash-verified, immutable package untouched. Original make-all/Main remains a documented Cygwin linkage limitation; no production source compatibility patch. See [Windows preparation](WINDOWS-PREPARATION.md) for prerecord, native-DLL/POSIX-make PATH split and original smoke staging. Static Python AST parse PASS; local execution and independent audit now PASS (see current result).

The Windows wrapper intentionally refuses to run until ASSIGNED_URL is replaced with a real fresh scheduler assignment recorded before execution. Use actual candidate/support HEAD, do not label earlier e1aa917 as containing later test support:

```powershell
python optimization/experiments/GH-21/windows_assigned_runner.py --candidate-sha <actual-HEAD> --run-assignment <frozen-hub-comment-URL> --out optimization/experiments/GH-21/raw/windows-assigned-01
```

Hosted ordinary CI/QDistSAT and assigned local Tier0 PASS for unchanged productione1aa917, actual executed supportc64b036. See [HOSTED-RESULT](HOSTED-RESULT.md), [TIER0-RESULT](TIER0-RESULT.md), [preserved attempts](ATTEMPTS.md). All expected CSS/PMS results, WCNFs, smoke, bounds and actual timeout semantics verified; independent raw audit PASS. Tier1 executed supportfa7531a and exploratory Tier2 supportf225760 with exact same frozen binaries; see current results above. No Tier3 or adoption.

Read-only review fixes before any local execution: CSS/smoke/timeout validate EVERY emitted bound/objective/distance against the oracle; external watchdog raises INCONCLUSIVE unless a scientific failure is established. The assigned supervisor marks valid_run=false and exits nonzero on any failure, including unconfirmed owned cleanup or any false Job/affinity/priority/sleep restoration flag. Restoration is attempted even after cleanup fails. Normal completion/restoration and actual solver timeout paths have assigned execution evidence; no claim that every external abort path was exercised.

Tier1 commands must use fixed explicit no-card/card-mto for BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6, three serial pairs AB/BA/AB each and180s parent195s watchdog. See preregistration for gates and resource policy. No timing runner is authorized by this README.
