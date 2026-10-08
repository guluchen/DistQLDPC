// Counter-only diagnostic support; copied ONLY into a separate baseline snapshot.
// Never included in the production candidate or performance timing binaries.
#ifndef GH17_ALLOCATION_DIAGNOSTIC_H
#define GH17_ALLOCATION_DIAGNOSTIC_H
#include <cstdio>
#include <cstdint>
struct GH17AllocationDiagnostic;
static GH17AllocationDiagnostic* gh17_active_diagnostic = NULL;
struct GH17AllocationDiagnostic {
    const char* caller;
    GH17AllocationDiagnostic* previous;
    uint64_t calls, populated, baseline_allocations, reusable_allocations;
    int reusable_capacity, peak_size, peak_capacity;
    explicit GH17AllocationDiagnostic(const char* name)
        : caller(name), previous(gh17_active_diagnostic), calls(0), populated(0),
          baseline_allocations(0), reusable_allocations(0), reusable_capacity(0),
          peak_size(0), peak_capacity(0) { gh17_active_diagnostic=this; }
    void push(int size, int capacity, bool grew) {
        baseline_allocations += grew ? 1 : 0;
        if (size > peak_size) peak_size=size;
        if (capacity > peak_capacity) peak_capacity=capacity;
        if (size > reusable_capacity) {
            int required=(size-reusable_capacity+1)&~1;
            int geometric=((reusable_capacity>>1)+2)&~1;
            reusable_capacity += required>geometric ? required : geometric;
            ++reusable_allocations;
        }
    }
    void finish(int size) { ++calls; populated += size>0 ? 1 : 0; }
    ~GH17AllocationDiagnostic() {
        std::fprintf(stderr,
            "GH17_ALLOCATION {\"caller\":\"%s\",\"calls\":%llu,\"populated\":%llu,"
            "\"baseline_allocations\":%llu,\"predicted_reuse_allocations\":%llu,"
            "\"peak_size\":%d,\"baseline_peak_capacity\":%d,\"predicted_reuse_capacity\":%d}\n",
            caller,(unsigned long long)calls,(unsigned long long)populated,
            (unsigned long long)baseline_allocations,(unsigned long long)reusable_allocations,
            peak_size,peak_capacity,reusable_capacity);
        gh17_active_diagnostic=previous;
    }
};
#endif
