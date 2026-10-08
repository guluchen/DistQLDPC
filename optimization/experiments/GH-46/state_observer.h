// Test-only relevant state observer, included after Solver.h in Solver.cc.
// It does not claim every byte of Solver is meaningful or initialized.
#ifndef GH46_STATE_OBSERVER_H
#define GH46_STATE_OBSERVER_H
#include <cstdio>
#include <cstdlib>
#include <cstring>
namespace Minisat {
struct GH46TraceSnapshot {
    static bool enabled() {
        static const bool on=std::getenv("GH46_TRACE") &&
            std::strcmp(std::getenv("GH46_TRACE"),"1")==0;
        return on;
    }
    template<class T> static void ints(const char* label,const vec<T>& xs) {
        std::fprintf(stderr," %s=",label);
        for(int i=0;i<xs.size();++i) std::fprintf(stderr,"%lld,",(long long)xs[i]);
    }
    static void lits(const char* label,const vec<Lit>& xs,int start=0) {
        std::fprintf(stderr," %s=",label);
        for(int i=start;i<xs.size();++i) std::fprintf(stderr,"%d,",toInt(xs[i]));
    }
    static void doubles(const char* label,const vec<double>& xs) {
        std::fprintf(stderr," %s=",label);
        for(int i=0;i<xs.size();++i) std::fprintf(stderr,"%.17g,",xs[i]);
    }
    template<class C> static void heap(const char* label,const Heap<C>& xs) {
        std::fprintf(stderr," %s=",label);
        for(int i=0;i<xs.size();++i) std::fprintf(stderr,"%d,",xs[i]);
    }
    static void emit(Solver& s,const char* phase,bool substantive,bool result) {
        if(!enabled()) return;
        std::fprintf(stderr,"GH46_STATE phase=%s call=%llu substantive=%d result=%d UB=%llu qhead=%d",
            phase,(unsigned long long)s.gh46_allocation_counts.entries,int(substantive),int(result),
            (unsigned long long)s.UB,s.qhead);
        lits("trail",s.trail); ints("limits",s.trail_lim);
        ints("seen",s.seen); ints("involved",s.involved);
        ints("owners",s.inConflicts); ints("unlock",s.unLockedVars);
        ints("representatives",s.finalIset); ints("locks",s.isetLock);
        ints("soft_locked",s.softVarLocked); ints("old_owners",s.inConflict);
        lits("involved_lits",s.involvedLits); lits("false_lits",s.falseLits);
        lits("confl_lits",s.conflLits); lits("last_confl_lits",s.lastConflLits);
        lits("initial_confl_lits",s.initConflLits); lits("soft_lits",s.softLits);
        std::fputs(" vars=",stderr);
        for(int i=0;i<s.nVars();++i)
            std::fprintf(stderr,"%d:%u:%d,",toInt(s.assigns[i]),s.vardata[i].reason,s.vardata[i].level);
        for(int i=0;i<s.isets.size();++i) {
            std::fprintf(stderr," core%d=",i);
            for(int j=0;j<s.isets[i].size();++j) std::fprintf(stderr,"%d,",s.isets[i][j]);
        }
        for(int i=0;i<s.isetsLits.size();++i) {
            std::fprintf(stderr," corelits%d=",i);
            for(int j=0;j<s.isetsLits[i].size();++j) std::fprintf(stderr,"%d,",toInt(s.isetsLits[i][j]));
        }
        doubles("VSIDS",s.activity_VSIDS); doubles("CHB",s.activity_CHB);
        doubles("distance",s.activity_distance); doubles("LB_activity",s.activityLB);
        heap("VSIDS_heap",s.order_heap_VSIDS); heap("CHB_heap",s.order_heap_CHB);
        heap("distance_heap",s.order_heap_distance); heap("aux_heap",s.orderHeapAuxi);
        std::fprintf(stderr," soft=%d harden=%d conflicts=%llu decisions=%llu propagations=%llu",
            int(s.softConflictFlag),int(s.hardenEnable),(unsigned long long)s.conflicts,
            (unsigned long long)s.decisions,(unsigned long long)s.propagations);
        if(substantive) std::fprintf(stderr,
            " trail_record=%d false_var=%d UB_conflict=%d LH_confl=%u lookahead=%llu lkprops=%llu success=%llu quasi=%llu fixed=%llu",
            s.trailRecord,s.falseVar,int(s.UBconflictFlag),s.LHconfl,
            (unsigned long long)s.LOOKAHEAD,(unsigned long long)s.lk_propagations,
            (unsigned long long)s.nbLKsuccess,(unsigned long long)s.quasiSoftConflicts,
            (unsigned long long)s.nbFixedByLH);
        std::fputc('\n',stderr);
    }
    static void reset(Solver& s,const vec<Lit>& out,bool uip,int core) {
        bool selected=gh46_active_allocation && gh46_active_allocation->target==&out &&
            &gh46_active_allocation->counts==&s.gh46_allocation_counts;
        if(selected) ++s.gh46_allocation_counts.resets;
        if(selected && uip) ++s.gh46_allocation_counts.uip_resets;
        if(!enabled()) return;
        std::fprintf(stderr,"GH46_RESET call=%llu core=%d selected=%d uip=%d size=%d",
            (unsigned long long)s.gh46_allocation_counts.entries,core,int(selected),int(uip),out.size());
        lits("populated",out,uip?0:1); std::fputc('\n',stderr);
    }
    static void buffer_entry(Solver& s,const vec<Lit>& out) {
        if(enabled()) std::fprintf(stderr,"GH46_BUFFER_ENTRY call=%llu size=%d\n",
            (unsigned long long)s.gh46_allocation_counts.entries,out.size());
    }
};
struct GH46TraceScope {
    Solver& solver;
    bool substantive=false, result=true;
    explicit GH46TraceScope(Solver& s):solver(s) {
        GH46AllocationCounts& c=s.gh46_allocation_counts;
        if(c.entries && c.last_ub!=s.UB) ++c.ub_transitions;
        c.last_ub=s.UB; ++c.entries;
        GH46TraceSnapshot::emit(s,"enter",false,true);
    }
    ~GH46TraceScope() { GH46TraceSnapshot::emit(solver,"exit",substantive,result); }
};
}
#endif
