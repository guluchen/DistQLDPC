# User memory-exhaustion hypothesis: not established

This is a read-only metadata query, not another solver execution or performance
test. Native scientific failure remains SIGSEGV(-11), not a SIGKILL(-9).
No candidate implementation ran on the failing input.

At query UTC1791505850.345289, /proc/meminfo reports MemAvailable
470215076kB (448.43GiB). This is CURRENT memory roughly10 minutes after
the crash; it cannot prove memory availability or per-process peak at the crash.
No process peak memory was collected in the original bounded one-case check.

Kernel journal queried only UTC2026-10-09 00:20:20 through00:20:50, covering
the actual solve/helper release. Unprivileged journalctl returned1/no entries
WITH a warning that system/other-user messages are not visible. This is a
coverage limitation, NOT proof there was no OOM or kernel segfault record.
No sudo log access, group changes, host service edits or privilege bypass.

Original source evidence: Vec.h capacity and XAlloc.h throw OutOfMemoryException
for null realloc with errnoENOMEM. Main.cc catches that exception and prints
Out of Memory / s UNKNOWN then exit0 (lines249-252). The observed native
rc-11 and empty streams do not match that handled exception path. This cannot
exclude an unchecked allocation, bad_alloc, earlier corruption, an arithmetic
error or other indirect memory-related failure. No exact cause established.

GH46 scratch-capacity reuse retains storage and therefore requires its own
peak-memory/lifetime validation, as preregistered. That risk cannot be used to
attribute this ORIGINAL-baseline crash to the unexecuted candidate.
The small input has10variables/28clauses; its independently enumerated cost5
remains unchanged. Known baseline anomaly must not be waived as presumed OOM.
