// TEST/PROVENANCE ONLY. Compile with original portable GCC flags, never v3.
// Run solely on the guarded selected benchmark CPU before v3 execution.
#include <cpuid.h>
#include <cstdint>
#include <cstdio>
int main() {
    unsigned a=0,b=0,c=0,d=0;
    const unsigned maxbasic=__get_cpuid_max(0,0);
    const unsigned maxext=__get_cpuid_max(0x80000000u,0);
    if (maxbasic < 7 || maxext < 0x80000001u) return 2;
    __cpuid_count(1,0,a,b,c,d);
    const unsigned leaf1c=c;
    // v2: SSE3, SSSE3, CX16, SSE4.1, SSE4.2 and POPCNT.
    const unsigned v2=(1u<<0)|(1u<<9)|(1u<<13)|(1u<<19)|(1u<<20)|(1u<<23);
    // v3: FMA, MOVBE, XSAVE, OSXSAVE, AVX, F16C.
    const unsigned v3=(1u<<12)|(1u<<22)|(1u<<26)|(1u<<27)|(1u<<28)|(1u<<29);
    const bool leaf1ok=(c&(v2|v3))==(v2|v3);
    // Avoid executing XGETBV unless CPU and OS expressly support XSAVE.
    if ((c&((1u<<26)|(1u<<27)))!=((1u<<26)|(1u<<27))) {
        std::printf("{\"compatible\":false,\"reason\":\"XSAVE_OSXSAVE_missing\"}\n");
        return 2;
    }
    unsigned lo=0,hi=0;
    __asm__ volatile("xgetbv" : "=a"(lo),"=d"(hi) : "c"(0));
    const uint64_t xcr0=(uint64_t(hi)<<32)|lo;
    __cpuid_count(7,0,a,b,c,d);
    const unsigned leaf7b=b;
    const unsigned extra=(1u<<3)|(1u<<5)|(1u<<8); // BMI1, AVX2, BMI2.
    __cpuid_count(0x80000001u,0,a,b,c,d);
    const unsigned extc=c;
    const bool compatible=leaf1ok && (leaf7b&extra)==extra
        && (extc&((1u<<0)|(1u<<5)))==((1u<<0)|(1u<<5)) // LAHF/SAHF, LZCNT.
        && (xcr0&6u)==6u; // OS preserves XMM and YMM.
    std::printf("{\"compatible\":%s,\"leaf1_ecx\":%u,\"leaf7_ebx\":%u,\"ext_ecx\":%u,\"xcr0\":%llu}\n",
        compatible?"true":"false",leaf1c,leaf7b,extc,(unsigned long long)xcr0);
    return compatible?0:2;
}
