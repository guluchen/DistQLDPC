# Windows platform/test preparation addendum

Prerecorded before any GH21 local compile or solver workload. Learned from GH20 attempt02/03/04 evidence; this is support repair, not a second performance optimization or a scientific mismatch.

Original downstream Main.cc:83 calls memUsedPeak() outside _MSC_VER. Original System.cc:23–97 defines memUsedPeak only on Linux/Apple; Cygwin follows unsupported branch that defines memUsed() returning zero, leaving memUsedPeak undefined. GH20 original-baseline make-all link log confirms this Cygwin limitation. This is not an O2-specific defect. No production src/Makefile compatibility patch is made.

Windows production candidate command is original default flags, `make -j1 bin/distqldpc`; baseline immutable production distqldpc package remains fully hash verified. Linux hosted original make-all O3/O2 already passed. Do not claim Windows original make-all passed, and do not define _MSC_VER to bypass other unrelated platform behavior.

Standalone tiny-PMS tests use ORIGINAL Main.cc linked separately with cygwin_test_stats_shim.cc, equally for O3 and O2. The test shim supplies the missing statistic as existing unsupported-platform memUsed() (zero); it has no solver state hook. It is excluded from production DistQLDPC objects/binary and never timed. Main output/result/exit semantics remain actual original Main, with platform statistics fallback explicitly recorded. These artifacts are labelled test-only Main; they are not portable production maxcdcl binaries. Original CXXFLAGS including -Wall/-Wno-parentheses/-g/macros/DNDEBUG are copied exactly, with only O3 vs O2 differing, original four verified engine objects and -lz retained. No solver/source/timeout/ISA change.

managed_run provides POSIX PATH only to make, so make's shell finds the bundled GCC. Direct native executables (GCC, solver, test Main, size, bash) retain Windows PATH with the runtime DLL directory. Every command records its path_kind and argv; no global POSIX PATH substitution that loses cygwin DLL lookup.

Both original smoke scripts now execute. LP34 matrices are present/hash-verified under each source's data/matrices because the original script resolves its stem there. Candidate Git matrices are asserted equal to immutable package; any missing staged file is copied unchanged, not regenerated. Explicit scientific smoke still checks d2 afterward; script integration assertions complement it.

Source tree hash equality and one-token Makefile assertion, no external flags overrides, fresh candidate build, all-bound checks, bounded cleanup/nonzero invalid-run behavior remain. Prepared script still requires fresh RUN_ASSIGNMENT; static AST/diff checks only. No local production/test build or solver executed, no Tier0 PASS claim from preparation, no measured performance.
