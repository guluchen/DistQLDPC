// Baseline diagnostic ONLY, excluded from all production/timed binaries.
#pragma once
#include <cstdio>
#include <stdint.h>
extern "C" void gh22_vsids_dump();
#ifdef GH22_VSIDS_IMPLEMENTATION
static uint64_t gh22_total=0, gh22_vsids=0, gh22_distinct=0;
static void gh22_vsids_event(bool vsids, bool distinct) {
    ++gh22_total;
    if (vsids) { ++gh22_vsids; if (distinct) ++gh22_distinct; }
}
extern "C" void gh22_vsids_dump() {
    std::fprintf(stderr,"GH22_VSIDS {\"binary_events\":%llu,\"vsids_events\":%llu,\"distinct_vsids_events\":%llu}\n",
        (unsigned long long)gh22_total,(unsigned long long)gh22_vsids,
        (unsigned long long)gh22_distinct);
    std::fflush(stderr);
}
#endif
