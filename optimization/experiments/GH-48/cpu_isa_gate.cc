// TEST/PROVENANCE ONLY. Build with original portable GCC target; never v2.
// Execute only on the guarded selected CPU before any v2 candidate execution.
// v2 does not require AVX/YMM/XSAVE and this probe never executes XGETBV.
#include <cpuid.h>
#include <cstdio>
int main() {
    unsigned a=0,b=0,c=0,d=0;
    if (__get_cpuid_max(0,0)<1 || __get_cpuid_max(0x80000000u,0)<0x80000001u) {
        std::printf("{\"compatible\":false,\"reason\":\"required_cpuid_leaf_missing\"}\n");
        return 2;
    }
    __cpuid_count(1,0,a,b,c,d);
    const unsigned leaf1c=c;
    const unsigned required=(1u<<0)|(1u<<9)|(1u<<13)|(1u<<19)|(1u<<20)|(1u<<23);
    // SSE3, SSSE3, CMPXCHG16B, SSE4.1, SSE4.2, POPCNT; baseline x86-64 assumed.
    __cpuid_count(0x80000001u,0,a,b,c,d);
    const unsigned extc=c;
    const bool compatible=(leaf1c&required)==required && (extc&1u)==1u;
    std::printf("{\"compatible\":%s,\"level\":\"x86-64-v2\",\"leaf1_ecx\":%u,\"ext_ecx\":%u}\n",
        compatible?"true":"false",leaf1c,extc);
    return compatible?0:2;
}
