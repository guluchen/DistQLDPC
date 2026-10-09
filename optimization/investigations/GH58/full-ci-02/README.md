# GH58 full gate support — SOURCE ONLY / UNEXECUTED

Root owns production, host scheduling and CI dispatch. None of these drivers has been executed. `corpus.py` is the shared finite scientific corpus; `full.py` requires actual fixed-native targeted PASS and the original frozen runtime. `ci.py` uses fresh GNU builds on ordinary Linux correctness CI, with explicit different provenance. CI timings are never scientific performance evidence.

Root-reviewed original source package is `../GH58-native-targeted-package-01`, with eleven targeted inputs, forty PMS inputs, small CSS matrices, LP34 and LP340 matrices, exact baseline245/f06 source. Support is frozen independently; do not add it into or modify the existing targeted package. Copy this directory into its final committed location, generate its manifest there, and use that actual manifest SHA in the invocation.

CI prerequisites: a root-audited JSON frozen by SHA, containing `verdict: "PASS"`, `actual_run_id` (actual 37868844321), `raw_audit_verified: true`, `candidate_solver_sha`, `original_fixture_sha`, and counts `targeted_cases: 11`, `partition_cases: 80`, `no_conflict_cases: 1`. Original known-failing baseline remains retained, not rerun or waived. Root independently authenticates the recorded source/log/artifact relationship; the adapter checks the frozen proof, not a fabricated CI colour.

CI invocation after review/commit/provenance freeze:

```
PYTHONDONTWRITEBYTECODE=1 python3 -B <support>/ci.py --package <original-target-package> --manifest-sha <original-package-sha> --support <support> --support-manifest-sha <support-sha> --prerequisite <audited-prerequisite.json> --prerequisite-sha <proof-sha> --out <fresh-output>
```

The CI runner has a 540s aggregate guard; use an outer job ceiling >=600s. All production and hook builds are serial original-O3, no instrumentation in production, no profile/training/timing. Deadline/coverage failure is INCONCLUSIVE; actual wrong science/crash rejects immediately. Preserve complete output even on failure via an always-upload artifact step. Generated binaries/objects must be reviewed separately before any public export; text/source/raw scientific streams are retained unchanged.

Fixed-server invocation stays disabled until root freezes a new assignment URL and targeted catalogue, original package, all support and runtime hashes. `full.py` runs only inside the existing restricted CPU102/230 helper and a reviewed outer owned-session watchdog; the CI runner never claims that policy. No auto-promotion, performance run or new-baseline designation.
