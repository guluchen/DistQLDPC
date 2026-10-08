// Baseline-only counting build; never linked into production or timed binaries.
#pragma once
#include <cstdio>
#include <stdint.h>
extern "C" void gh40_dump();
#ifdef GH40_IMPLEMENTATION
static uint64_t gh40_counts[10]={0};
static void gh40_event(unsigned index) { ++gh40_counts[index]; }
extern "C" void gh40_dump() {
    const char* keys[]={"visits","blocker_hits","loads","first_hits",
      "ternary_tail","other_tail","scans","ternary_undef","ternary_true","ternary_false"};
    std::fprintf(stderr,"GH40_COUNTS {");
    for(unsigned i=0;i<10;++i) std::fprintf(stderr,"%s\"%s\":%llu",i?",":"",keys[i],
                                          (unsigned long long)gh40_counts[i]);
    std::fprintf(stderr,"}\n"); std::fflush(stderr);
}
#endif
