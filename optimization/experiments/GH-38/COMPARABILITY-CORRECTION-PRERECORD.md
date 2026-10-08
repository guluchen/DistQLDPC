# Prerecord before changing candidate: fixed Clang codegen, original GNU link

Hypothesis remains one conceptual performance change: fixed Clang22.1.8-3
code generation at original O3 versus original GCC14.4 O3. Attempt01 proved an
isolated overlay feasible but default Clang link recipe omits original GNU
manifest and differs in default libraries. It is retained INCONCLUSIVE; this is
a supporting comparability correction, not a second optimization or acceptance.

Scope: retain candidate src exactly24572d6 and all original CXXFLAGS/LDFLAGS.
Compile app and every engine object using fixed Clang, then link through original
g++14.4 GNU driver in existing app-first/engine order. Standalone Main similarly
needs a separate object before GNU linking. Both configurations therefore use
original GNU libraries, default manifest and PE/runtime settings. Original g++
baseline binary22e398 remains immutable; a necessary matched baseline rebuild
would need separate prerecord and identity before comparison. GNU make default
or undefined CXX chooses Clang codegen with GNU linking; explicit caller CXX
overrides retain their chosen compile/link driver unless separately specifying
LINK_CXX. Experimental environment rejects all external compiler/link overrides.
No solver-side optimization, numerical/ISA/language/security flags, source repair,
LTO/PGO or unrelated refactor. Attribution/NOTICE unchanged because src identical.

Expected affected cases: unknown; fixed standard Tier1 only after meaningful
scientific Tier0 and hosted checks. Risks: Clang compatibility with downstream
MaxCDCL-derived sources, builtin/resource-header or codegen differences affecting
assumptions; compile-object restructuring must preserve app-first link order and
existing caller override behavior. Scientific distance/Pauli/logical/bounds/
timeout/results unchanged requirements remain mandatory. No science result yet.

Fresh minimal setup/probe attempt02 only after review/named slot. Reuse attempt01
overlay and exact cached archives without redownload/reclone ONLY after verifying
all original bytes plus every additional file against pinned archive contents
and aliases; unexpected files/version changes invalidate reuse. Freeze previous
support/raw evidence and actual new support SHA. Compile minimal baseline and
candidate objects separately with original flags; original GNU driver links both
in same recipe. Capture actual compile and link -###/trace, headers/macros, live
DLL paths/hashes, PE characteristics and embedded manifest. Effective security/
manifest/ABI/language/ISA properties must match; differing unused/import sets
from optimizer elimination are allowed only when every actually used dependency
resolves to original bytes. No arbitrary normalization flags.

Expected cost: bounded600s for this minimal package/probe round plus300s final
immutable cleanup verification, one eligible CPU. No solver/Tier0/timing in this
probe slot. Trace assessment before future scientific Tier0 remains required;
any unresolved comparability failure remains engineering INCONCLUSIVE. Actual
science mismatch later means REJECT/stop, never a performance benchmark.

Engineering provenance: original GNU driver behavior measured in attempt01 and
official Clang Toolchain documentation https://clang.llvm.org/docs/Toolchain.html .
Academic BibTeX NOT APPLICABLE. No new academic/scientific conclusion.
