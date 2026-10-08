# Bounded setup/probe source ready for review; not executed

Actual implementation is windows_setup_probe.py with setup_worker.py, the exact
reviewed windows_cpu_window.py helper, and resolve_packages.py. The earlier
prepare_setup_probe.py remains a disabled historical planner and is not the
execution entry point. No download, installer, compiler, build or probe has run.
ASSIGNMENT is HOST_SLOT_NOT_ASSIGNED, so the supervisor refuses execution until
a named setup/probe slot is frozen in source and committed. No solver or timed
workload is part of this setup scope.

PACKAGE-CLOSURE.json is the read-only cached-index result: 53 physical package
nodes, 9 missing overlay archives, 74,279,960 compressed bytes. Current installed
versions match every reused physical dependency; gcc14 is provided by the exact
installed gcc-core14.4.0-1. The sole external predicate is Windows>=6.3, checked
by the future supervisor. The index is the preserved official-mirror setup.ini
with pinned SHA512, not a new signed-index download. Downloads must match its
exact archive size/SHA512 and remain on the declared public HTTPS mirror; no
version selection, dependency upgrade, signature bypass or destination change.

The supervisor snapshots the entire original E004 runtime, copies its files
into a fresh output/overlay and extracts only missing packages there. Cygwin
logical usr/bin and usr/lib archive paths map to physical bin and lib, matching
the original default mount layout. Original files are never overwritten unless
new package content is already byte-identical. Every original-file hash must
still match both the original prefix and overlay subset after extraction.
The original installed.db is also checked against its preserved public record.
No installer, registry mutation, global PATH/power change or postinstall script
runs. Package licenses/docs are retained. Archive devices/FIFOs, escaping paths,
reparse points, unsupported/directory/unresolved aliases, excessive members or
expansion stop the attempt. Contained regular-file aliases are copied byte
identically; clang++ basename remains the driver selector. This is a compiler
overlay, not a claim of fully configured Python or other postinstall packages.

All file hashing/copying/download/extraction/probes execute under the single-CPU
unnamed Job through bounded file-backed subprocesses. Original helper SHA256
ab2f2edc50af1587e901e18fc2e9d03d6bf86c297ff9e5736099a3538a29b2b2 is checked
before import, along with each support file's exact assigned Git blob. Global
idle must exceed50%, half spare capacity must accommodate1CPU, active checks
occur every2s; SMT contention is recorded, not called exclusive reservation.
Each worker is bounded300s (clone600s), probe60s, whole work1800s; final immutable
runtime verification has a separate bounded300s cleanup allowance. Download
socket timeout20s/expected byte limit and archive expansion/member limits apply.
Cleanup rechecks Job membership immediately before every taskkill, waits at
most10s for owned direct process and5s for remaining descendants, and requires
all4 Job/affinity/sleep/priority restoration booleans. Any command/identity/
cleanup failure produces nonzero supervisor exit and INCONCLUSIVE evidence.

Actual probes, only after assignment: GCC/Clang version and target, default C++
macros, include search and -### driver; a minimal vector/zlib/ABI program built
with original O3/g/defines and GNU-link trace, then executed with a5s wait so
actual Windows loaded modules can be captured. This is not DistQLDPC code or a
scientific test. It requires22.1.8 versus14.4.0, identical printed basic ABI/
zlib output, identical declared ISA/language/platform macros and every loaded
cyg DLL byte-identical to an original runtime file. Full driver/header/GNU ld/
libstdc++/libgcc/zlib trace review remains mandatory: original-subset hashes
prove available bytes, not which static libraries a linker chose. All proof
paths must resolve to byte-identical original files; compiler resource headers
must be disclosed separately. Any compiler-rt/libc++/LLD/new runtime, numerical
flags, ISA/language change or required semantic source fix invalidates the narrow
comparison. The supervisor deliberately records engineering INCONCLUSIVE until
this retained trace evidence is independently reviewed. No automatic solver
build/Tier0, performance conclusion or promotion follows from setup exit0.

Future exact entry point (placeholder cannot run):

```powershell
python GH38-CLANG/optimization/experiments/GH-38/windows_setup_probe.py --out GH38-setup-probe-01 --assignment <FROZEN_SETUP_SLOT_URL> --support-sha <ACTUAL_COMMITTED_HEAD>
```

Only AST parsing and cached metadata resolution have been performed during
preparation. Actual file operations, Job behavior, archive layouts, driver paths
and live-module APIs remain engineering UNTESTED until the named bounded run.

Static follow-up explicitly declares OpenProcess HANDLE and PSAPI BOOL/DWORD
return types within the module inspector; complete aligned module arrays and
non-truncated path returns are required. Archive-file size<=256MiB, per-package
expansion<=2GiB and member-count<150000 remain strict engineering gates. Cached
compressed sizes do not prove expanded member sizes or supported alias layouts;
those facts will be checked during the assigned pinned extraction, with no
automatic relaxation if the archive fails them.
