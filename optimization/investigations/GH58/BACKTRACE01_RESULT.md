# Original native backtrace captured; no fix yet

One unchanged original245 native Main under pinnedgdb15.1: actual SIGSEGV,
simplepropagateForLK+197 -> detectInitConflicts5804 -> solve_6566 -> Main217.
Existing binary disassembly maps offset+197 (0x18f65) to read wbin[k].blocker
at originalSolver.cc5623, mov0x4(%rax),%ecx. This narrows native fault to initial
binary watcher iteration, not failed-UB1 rollback; prior Windows last-buffered
UB1 output was only a provisional diagnostic target, not proof of cause.
No captured actualRAX/currentliteral/vectorheader proves why the pointer failed.
Do not assume OOM, NULLbuffer, invalidliteral or definite repair from this alone.

Debuggerexit0/outertransport0 means diagnostic captured and cleanup authenticated;
science_pass remainsfalse, original anomaly unresolved. All originalsource/bin/
input/debugger/T0/runtime pins pre/post PASS, independent cost5 retained, no
candidate/build/performance/newbaseline. Inner native/gdb owned session empty,
outer empty, affinity102 restored; actualpostprobe leader3492226/birth136349098
absent/helperinactive/leaseNone/groupabsent/root0-255restore. Slot6071855500
released6071893127. Original source prerecorde319a86 BEFORE19b934a; independent
SOURCE_READY/a2da2558; URLfreeze174cd6b before actualtiming. Raw tar/streams/
commands/source/manifest/disassembly/postproof retained verbatim.

Next useful finite evidence, under fresh prerecord/assignment: inspect actual
fault-register/currentliteral/outer+innerwatcherheaders/assigns/trail and
processVmPeak at the same stoppedoriginalbinary frame. Not a timing repetition
or change of solver inputs/CLI. No repair until the invalid state is established.
