// TEST LINK SUPPORT ONLY. Never linked into the production DistQLDPC binary.
// Original Main.cc calls memUsedPeak(), while the original Cygwin System.cc
// unsupported-platform branch supplies only memUsed() (returning zero).
// Retain original Main/solver source and use that existing statistic fallback
// equally for baseline and candidate standalone tests. No solver state hook.
#include "utils/System.h"
#ifndef __CYGWIN__
#error "This test-only statistics fallback is restricted to Cygwin"
#endif
double Minisat::memUsedPeak() { return Minisat::memUsed(); }
