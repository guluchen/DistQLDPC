// Baseline diagnostic ONLY; excluded from all production and timed binaries.
#pragma once
#include <cstdio>
#include <stdint.h>
extern "C" void gh27_enqueue_dump();
#ifdef GH27_ENQUEUE_IMPLEMENTATION
static uint64_t gh27_counts[4]={0,0,0,0};
static void gh27_enqueue_event(unsigned kind) { ++gh27_counts[kind]; }
extern "C" void gh27_enqueue_dump() {
    std::fprintf(stderr,"GH27_ENQUEUE {\"entries\":%llu,\"soft_false\":%llu,\"unlocked_false\":%llu,\"locked_false\":%llu}\n",
        (unsigned long long)gh27_counts[0],(unsigned long long)gh27_counts[1],
        (unsigned long long)gh27_counts[2],(unsigned long long)gh27_counts[3]);
    std::fflush(stderr);
}
#endif
