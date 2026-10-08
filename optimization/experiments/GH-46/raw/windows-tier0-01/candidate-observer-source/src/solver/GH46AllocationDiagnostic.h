// GH46 counter-only support. Included ONLY in separately prepared test snapshots.
// Never included in production or timing binaries. Requires the fixed GCC14 default C++17.
#ifndef GH46_ALLOCATION_DIAGNOSTIC_H
#define GH46_ALLOCATION_DIAGNOSTIC_H
#include <cstdio>
#include <cstdint>
#include <cstddef>
#include <cstdlib>
#include <climits>
#include <cstring>

inline uint64_t gh46_next_solver_id=0;
struct GH46AllocationCounts {
    uint64_t solver_id=++gh46_next_solver_id;
    uint64_t calls=0, populated_calls=0, growths=0, predicted_growths=0;
    uint64_t requested_bytes=0, predicted_requested_bytes=0, pushes=0;
    int predicted_capacity=0, peak_capacity=0, peak_size=0;
    size_t element_bytes=0;
    bool failed=false;
    uint64_t entries=0, ub_transitions=0, resets=0, uip_resets=0;
    uint64_t last_ub=0;
    static int next_capacity(int cap, int need) {
        int linear=(need-cap+1)&~1, geometric=((cap>>1)+2)&~1;
        int add=linear>geometric ? linear : geometric;
        if (add>INT_MAX-cap) { std::fputs("GH46_COUNTER_OVERFLOW\n",stderr); std::abort(); }
        return cap+add;
    }
    void dump(bool complete) const {
        if ((!calls && !complete) || !std::getenv("GH46_REPORT") ||
            std::strcmp(std::getenv("GH46_REPORT"),"1")!=0) return;
        std::fprintf(stderr,
            "GH46_ALLOCATION {\"solver_id\":%llu,\"complete\":%s,\"calls\":%llu,\"populated_calls\":%llu,"
            "\"actual_growths\":%llu,\"predicted_reuse_growths\":%llu,"
            "\"actual_requested_bytes\":%llu,\"predicted_requested_bytes\":%llu,"
            "\"pushes\":%llu,\"peak_size\":%d,\"peak_capacity\":%d,"
            "\"predicted_capacity\":%d,\"element_bytes\":%llu,\"entries\":%llu,"
            "\"ub_transitions\":%llu,\"resets\":%llu,\"uip_resets\":%llu,\"failed\":%s}\n",
            (unsigned long long)solver_id,complete?"true":"false",
            (unsigned long long)calls,(unsigned long long)populated_calls,
            (unsigned long long)growths,(unsigned long long)predicted_growths,
            (unsigned long long)requested_bytes,(unsigned long long)predicted_requested_bytes,
            (unsigned long long)pushes,peak_size,peak_capacity,predicted_capacity,
            (unsigned long long)element_bytes,(unsigned long long)entries,
            (unsigned long long)ub_transitions,(unsigned long long)resets,
            (unsigned long long)uip_resets,failed?"true":"false");
    }
    ~GH46AllocationCounts() { dump(true); }
};
struct GH46AllocationScope;
inline GH46AllocationScope* gh46_active_allocation=nullptr;
struct GH46AllocationScope {
    GH46AllocationCounts& counts;
    const void* target;
    GH46AllocationScope* previous;
    int call_peak=0;
    GH46AllocationScope(GH46AllocationCounts& c,const void* p)
        : counts(c),target(p),previous(gh46_active_allocation) {
        gh46_active_allocation=this; ++counts.calls;
    }
    ~GH46AllocationScope() {
        if (call_peak) ++counts.populated_calls;
        // Bounded-rate progress only; never confuse a killed process's prefix
        // with complete counts. Original Main gets an explicit pre-exit report;
        // the application's local Solver destructor emits the actual final row.
        if(counts.calls==1 || counts.calls%512==0) counts.dump(false);
        gh46_active_allocation=previous;
    }
    void pushed(int size,size_t bytes) {
        if (counts.element_bytes && counts.element_bytes!=bytes) {
            counts.failed=true; std::abort();
        }
        counts.element_bytes=bytes; ++counts.pushes;
        if (size>call_peak) call_peak=size;
        if (size>counts.peak_size) counts.peak_size=size;
        if (size>counts.predicted_capacity) {
            counts.predicted_capacity=GH46AllocationCounts::next_capacity(counts.predicted_capacity,size);
            ++counts.predicted_growths;
            counts.predicted_requested_bytes+=uint64_t(counts.predicted_capacity)*bytes;
        }
    }
};
inline void gh46_observe_push(const void* p,int size,size_t bytes) {
    if (gh46_active_allocation && gh46_active_allocation->target==p)
        gh46_active_allocation->pushed(size,bytes);
}
inline void gh46_observe_growth(const void* p,int oldcap,int newcap,size_t bytes) {
    if (!gh46_active_allocation || gh46_active_allocation->target!=p) return;
    GH46AllocationCounts& c=gh46_active_allocation->counts;
    if (newcap<=oldcap) { c.failed=true; std::abort(); }
    ++c.growths; c.requested_bytes+=uint64_t(newcap)*bytes;
    if (newcap>c.peak_capacity) c.peak_capacity=newcap;
}
#endif
