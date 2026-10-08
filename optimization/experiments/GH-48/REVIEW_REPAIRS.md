# GH48 preassignment support guard repair

Academic/root source review identified three inherited guard gaps in the disabled
Tier0 support5907551. No GH48 local build/probe/test/scientific/timing run occurred.
This is validation support only; productiond27cf4d and all scientific test scope,
flags, thresholds, helper source bytes and attribution remain unchanged.

1. Live current-process taskkill path now immediately rechecks membership in the
   actual owned unnamed Job before signaling, just as the orphan branch already
   did. Missing ownership throws before any signal; cleanup failure is retained
   INCONCLUSIVE. No outside process, stale PID list or broad-name cleanup.
2. Existing helper .pyc cache is neither trusted nor deleted. Read helper bytes
   once, authenticate exact SHAab2f2edc, compile those exact bytes and execute in
   an explicit module namespace with correct __file__/non-main __name__. Normal
   source-loader cache selection is bypassed. Set sys.dont_write_bytecode and
   PYTHONDONTWRITEBYTECODE=1 for descendant Python processes; do not rewrite cache.
3. Refuse compiler/header/link/search-path injection environment, extending the
   earlier Make/CXX flag guards to documented CPATH/C*_INCLUDE_PATH,
   GCC_EXEC_PREFIX/COMPILER_PATH/LIBRARY_PATH, Make override/debug flags and
   preload/library/Cygwin behavior options. Only presence is checked, never log
   variable values. No environment override is silently cleared to rescue a run.

Re-review source and new immutable support pins before a named assignment. AST
checks do not execute Windows helper, compiler, solver or benchmark. The current
driver still stops at HOST_SLOT_NOT_ASSIGNED before helper compilation/execution.
