# GH58: ACCEPT_CORRECTNESS_REPAIR

The original DistQLDPC embedded MaxCDCL-derived solver can retain inactive
auxiliary soft literals after partition replaces a conflicting group. Enqueuing
their cleared lit_Undef mapping produces an invalid trail/watch index and a
reproducible crash on a valid 300-byte WCNF. This is a downstream DistQLDPC
correctness repair, not a demonstrated upstream MaxCDCL bug or optimization.

Prerecord 4a9f274 precedes implementation a1a0f00 and original-byte preservation
f06ac3d. Only the final partition list-maintenance block changes: compact inactive
non-unit soft entries and rebuild the heap if either soft list changed. Existing
clauses, representatives, derived cost and survivor order are preserved.
Independent source/math review checks 80 configurations and 1216 feasible models;
m-s=(m-1)+(1-OR) preserves the accounted objective under existing exclusion.
MODIFICATIONS.md and NOTICE record this downstream patch and retain attribution.

Actual validation source c6c7abdfcbf6592800150ac8fe5ab8978792060c,
synthetic merge 20024d28dd0a7db38d86c43163bf292c566433e0 into original 24572d6:
- Mandatory original crash fixture now returns independently enumerated optimum 5.
- Ordinary CI: 11 WCNF oracle cases and 80 partition configurations plus no-conflict.
- Full finite CI 37869743600: 54 application results / 204 scientific fields,
  162 PMS checks / 40 independent oracles, 40 identical WCNF dumps, 2 smokes,
  and 12 genuine production or test-hook timeout checks; all PASS.
- Required QDistSAT cross-repo run 37869743498: all eight reported results
  agree at distances 4/10 across both cardinality modes and versions.
- Independent full raw, source-freeze, math and publication-scope audits PASS.
  Full catalogs, audits and immutable raw artifacts remain preserved locally.

No new scientific mismatch, crash or result/bound/timeout regression appeared.
Scientific definitions, encoding, benchmark ground truth and output meanings
remain unchanged. Existing private original debugger evidence is retained;
safe summaries and hashes are public, not its detailed host metadata.

Limits: finite correctness evidence is not a proof for all inputs. Generated
compiled CI bytes are excluded; recorded identities are checked, not independently
rehashes of absent binaries. The cross-repo artifact contains final fields only.
The original source-tree tar includes four already-public tracked Mach-O .or
copies; fresh GNU compilation never consumes them. The earlier source-only
label was imprecise; no historical package/raw data has been rewritten.
The dedicated fixed-core acquisition was refused because the sibling was busy;
no solver ran there. Prepared Windows fallback remains unexecuted.

Decision: ACCEPT for this correctness repair only. Tier 1/2/3 NOT_RUN;
performance NOT_MEASURED; new performance baseline NOT_DESIGNATED.
No prior rejected/inconclusive optimization is retroactively accepted.
Public CI: https://github.com/guluchen/DistQLDPC/actions/runs/37869743600 and https://github.com/guluchen/DistQLDPC/actions/runs/37869743498.
Automatic publication review rejected the full environment-bearing raw bundle.
It remains isolated on local evidence commit 149960e; only this safe summary
is submitted for publication. No private state or full CI artifact is added here.
Next: merge the validated repair after exact-head required CI, then explicitly
register a corrected performance baseline before resuming independent proposals.
No paper-derived method was used: diagnosis and fix come from repository source,
the original crash and independent objective/list-invariant checks.

