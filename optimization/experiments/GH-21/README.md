# GH21 O2-only experiment

Selected proposal and paper-derived unselected alternative: [PROPOSAL](PROPOSAL.md), [BibTeX](references.bib). Issue: https://github.com/guluchen/DistQLDPC/issues/21 . Owner independent-brain-20261008-round2, exclusive branch experiment/gh21-o2; baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a. Preregistration commit5f6358d preceded implementation.

Production diff: Makefile CXXFLAGS -O3 to -O2, one token. All src, other flags, libraries, attribution unchanged. MODIFICATIONS/NOTICE need no solver-patch entry because no embedded source patch is made. No combined PGO/LTO/native/scratch/watch-copy change. Hosted tests exercise default Makefile flags; shared CI timings are informational. Local host assignment remains NONE; no build or solver workload executed.

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

Prepared Tier0 support: run_tier0.py uses independent CSS d1/d2/d1 oracles, explicit-mode WCNF pairs, LP34 smoke, forced LP340 timeout/bounds and four tiny standalone unweighted-PMS exhaustive optimum oracles. Main.cc's standalone "optimal:" output/exit/status is checked directly; no invented o-line semantics. windows_assigned_runner.py reuses GH17's bounded file-backed supervisor and Job descendant checks, source/package/runtime provenance guards, continuous capacity telemetry and restoration. It builds candidate DEFAULT Makefile flags and links baseline standalone Main using preserved O3 objects in a copied snapshot. Immutable baseline package remains untouched. Static Python AST parse PASS; scripts NOT executed.

The Windows wrapper intentionally refuses to run until ASSIGNED_URL is replaced with a real fresh scheduler assignment recorded before execution. Use actual candidate/support HEAD, do not label earlier e1aa917 as containing later test support:

```powershell
python optimization/experiments/GH-21/windows_assigned_runner.py --candidate-sha <actual-HEAD> --run-assignment <frozen-hub-comment-URL> --out optimization/experiments/GH-21/raw/windows-assigned-01
```

Hosted ordinary CI and QDistSAT correctness PASS for production e1aa917, durable evidence in [HOSTED-RESULT](HOSTED-RESULT.md); no local Tier0 execution or Tier1/2/3 evidence, medians or speed conclusion. Baseline standalone parser/engine supports the unweighted-PMS fixtures; candidate must establish baseline's correct oracle results as well. A pre-science build/provenance/harness issue is recorded honestly and cannot be relabeled a scientific mismatch.

Read-only review fixes before any local execution: CSS/smoke/timeout validate EVERY emitted bound/objective/distance against the oracle; external watchdog raises INCONCLUSIVE unless a scientific failure is established. The assigned supervisor marks valid_run=false and exits nonzero on any failure, including unconfirmed owned cleanup or any false Job/affinity/priority/sleep restoration flag. Restoration is attempted even after cleanup fails. These prepared paths still need assigned execution evidence; no claim that every abort path was exercised.

Tier1 commands must use fixed explicit no-card/card-mto for BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6, three serial pairs AB/BA/AB each and180s parent195s watchdog. See preregistration for gates and resource policy. No timing runner is authorized by this README.
