# One finite original-binary state probe after captured stack

Backtrace01 narrowed originalnative SIGSEGV to simplepropagateForLK+197;
authenticatedbinary disassembly maps it to wbin[k].blocker. It did not retain
actual watcherpointer/currentliteral/vectorheaders, so no repair cause is yet
established. This new probe follows that evidence, not a timing retry.
User correctness-repair authorization applies; original245/input/CLI unchanged.

Run exactlyONE fresh originalnativeMain under same pinnedgdb15.1, new02 output/
source/frozen assignment. Reuse reviewed15s subprocess/90s outer/fullidentity/
fixed102230 lease/ownSID cleanup guards. No source/build/candidate/performance
or newbaseline. Keep previous01 evidence unchanged. Preregister before code.

Add only debugger state displays at stoppedSIGSEGV: bounded frames/registers,
qhead/trail size+currentLit, assigns header, outerwatches_bin header and current
innerwatcher header, current p/k/wbin when DWARF available, siginfo, and own
inferior /procstatus memorypeak. Print elements capped24; no file/env/private
data or core/whole-memorydump. No inferior function calls or state modification;
field reads only. Optimized-out data/ptrace restriction remain INCONCLUSIVE.
Do not infer OOM from an unreadable pointer or debuggerexit0. Only if valid state
and original source establish mechanism propose minimalcorrectnessfix; otherwise
record limitation and select next finite diagnostic based on new evidence.
Globalspare>50%/team<=halfspare/one namedrunner perhost. No Tier1/2/3.
