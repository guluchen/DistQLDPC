// Diagnostic ONLY: included in a fresh baseline export, never production.
#pragma once
#include <cstdio>
#include <stdint.h>
extern "C" void gh20_tail_dump();
#ifdef GH20_TAIL_IMPLEMENTATION
static uint64_t gh20_events[2]={}, gh20_identity[2]={}, gh20_stores[2]={}, gh20_all_stores[2]={}, gh20_max[2]={}, gh20_bins[2][6]={};
static void gh20_tail_event(int kind, bool identity, uint64_t length) {
    ++gh20_events[kind]; gh20_all_stores[kind]+=length;
    if (identity) {
        ++gh20_identity[kind]; gh20_stores[kind]+=length;
        if (length>gh20_max[kind]) gh20_max[kind]=length;
        unsigned b=length==0?0:length==1?1:length==2?2:length<=7?3:length<=31?4:5;
        ++gh20_bins[kind][b];
    }
}
extern "C" void gh20_tail_dump() {
    std::fprintf(stderr,"GH20_TAIL [");
    for (int k=0;k<2;++k) {
        std::fprintf(stderr,"%s{\"kind\":\"%s\",\"events\":%llu,\"identity_events\":%llu,\"identity_stores\":%llu,\"all_stores\":%llu,\"identity_max\":%llu,\"identity_bins\":[",k?",":"",k?"soft":"hard",
            (unsigned long long)gh20_events[k],(unsigned long long)gh20_identity[k],
            (unsigned long long)gh20_stores[k],(unsigned long long)gh20_all_stores[k],(unsigned long long)gh20_max[k]);
        for (int b=0;b<6;++b) std::fprintf(stderr,"%s%llu",b?",":"",(unsigned long long)gh20_bins[k][b]);
        std::fprintf(stderr,"]}");
    }
    std::fprintf(stderr,"]\n"); std::fflush(stderr);
}
#endif
