// Test-only baseline conditional learner/lifetime gate. Never a production hook.
#include "engine_snapshot_fixture.h"
#include <iostream>
#include <stdexcept>
#include <set>
#include <algorithm>
#include <initializer_list>
using namespace Minisat;
static void need(bool p,const char* why) { if (!p) throw std::runtime_error(why); }
static bool lit(int p,int a) {return bool(a&(1<<(p/2)))!=bool(p&1);}
static bool clause(const std::vector<int>& c,int a) {
    bool r=false; for (std::size_t i=0;i<c.size();++i) r|=lit(c[i],a); return r;
}
class Conditional : public gh26::EngineSnapshotFixture {
public:
    std::vector<std::vector<int> > original;
    std::vector<int> objectives, original_units, learned;
    gh26::OffsetWitness offsets;
    int context,shape,bt,lbd,beginning,signbit;
    Lit q;
    bool root;
    void hard(std::initializer_list<Lit> ls) {
        vec<Lit> ps; std::vector<int> row;
        for (auto p:ls) {ps.push(p); row.push_back(toInt(p));}
        CRef cr=ca.alloc(ps,false); clauses.push(cr); attachClause(cr);
        original.push_back(row);
    }
    bool feasibleOriginal(int a) const {
        for (auto c:original) if (!clause(c,a)) return false;
        for (auto p:original_units) if (!lit(p,a)) return false;
        return true;
    }
    int cost(int a) const {int c=0;for(auto p:objectives)c+=!lit(p,a);return c;}
    int validate(const std::vector<int>& c,int total) const {
        int better=0;
        for(int a=0;a<64;++a) {
            bool original_ok=feasibleOriginal(a),is_better=original_ok&&cost(a)<total;
            std::cout<<"oracle sign="<<signbit<<" shape="<<shape<<" context="<<context<<" root="<<root
                     <<" total="<<total<<" assignment="<<a<<" original="<<original_ok
                     <<" cost="<<cost(a)<<" better="<<is_better<<" clause="<<clause(c,a)<<'\n';
            if(is_better) {++better;need(clause(c,a),"SCIENCE: learned clause excludes original better model");}
        }
        return better;
    }
    void decide(Lit p) {
        newDecisionLevel(); falseLits_lim.push(falseLits.size());
        uncheckedEnqueue(p); need(propagate()==CRef_Undef,"fixture hard propagation conflict");
        need(!softConflictFlag,"fixture ordinary soft conflict");
    }
    void setup(int signed_x,int alpha,int ctx,bool rootonly) {
        signbit=signed_x;context=ctx;shape=alpha;root=rootonly;beginning=0;
        for(int v=0;v<6;++v)newVar();
        staticNbVars=6; VSIDS=true; UB=100; feasible=false;
        UBconflictFlag=softConflictFlag=softLearnt=false;falseVar=var_Undef;
        LHconfl=CRef_Undef;hardenEnable=false;
        LOOKAHEAD=lk_propagations=nbLKsuccess=totalPrunedLB=totalPrunedLB2=0;
        fixedCostBySearch=derivedCost=relaxedCost=0;
        for(int v=0;v<3;++v) {softLits[v]=mkLit(v);allSoftLits.push(softLits[v]);objectives.push_back(toInt(softLits[v]));}
        if(ctx) {softLits[5]=mkLit(5);allSoftLits.push(softLits[5]);objectives.push_back(toInt(softLits[5]));}
        q=mkLit(3,signbit!=0);
        hard({~mkLit(0),~mkLit(1)});
        hard({q,~mkLit(0),~mkLit(2)});hard({q,~mkLit(1),~mkLit(2)});
        for(int v=0;v<3;++v)hard({~mkLit(5),~mkLit(v)});
        if(alpha==2)hard({q,mkLit(4)});
        if(rootonly) {original_units.push_back(toInt(~q));uncheckedEnqueue(~q);}
        std::cout<<"fixture sign="<<signbit<<" shape="<<shape<<" context="<<ctx<<" root="<<rootonly<<" hard=";
        for(auto c:original){std::cout<<'[';for(auto p:c)std::cout<<p<<',';std::cout<<']';}
        std::cout<<" original_units=";for(auto p:original_units)std::cout<<p<<',';
        std::cout<<" objectives=";for(auto p:objectives)std::cout<<p<<',';std::cout<<'\n';
        if(ctx) {
            for(int a=0;a<64;++a) if(feasibleOriginal(a)&&cost(a)<3)
                need(!lit(toInt(mkLit(5)),a),"SCIENCE: root conditional unit lacks bound proof");
            uncheckedEnqueue(~mkLit(5));
        }
        need(propagate()==CRef_Undef,"root propagation conflict");
        UB=ctx?3:2;
        if(!rootonly) {
            decide(~q);
            if(alpha==1)decide(mkLit(4));
            if(alpha==2)need(value(mkLit(4))==l_True&&reason(4)!=CRef_Undef,"missing actual binary reason");
        }
        trailRecord=trail.size();
        isets.init(0);isets[0].push(0);isetsLits.init(0);
        isetsLits[0].push(mkLit(0));isetsLits[0].push(mkLit(1));
        finalIset.push(0);isetLock.push(1);inConflicts[0]=inConflicts[1]=0;
    }
    void analyze() {
        gh26::EngineSnapshot s=extract(trailRecord,1,1,offsets);
        need(s.exported,"conditional reader declined");gh26::Stats stats;
        need(gh26::strengthenOne(s.model,stats),"conditional kernel did not cover old core");
        int exact=100,baseModels=0;
        for(int a=0;a<64;++a) if(feasibleOriginal(a)) {
            bool base=true;for(int v=0;v<6;++v)if(s.model.base[v]>=0&&bool(a&(1<<v))!=bool(s.model.base[v]))base=false;
            if(!base)continue;++baseModels;exact=std::min(exact,cost(a));
            need(!lit(toInt(mkLit(0)),a)||!lit(toInt(mkLit(1)),a),"SCIENCE: invalid old K");
            int residual=0;for(auto p:s.model.soft)residual+=!lit(p,a);
            need(residual+int(s.fixed_search_cost)==cost(a),"SCIENCE: objective coordinate mismatch");
        }
        need(baseModels>0&&s.base_false+s.core_weight+1+int(s.fixed_search_cost)<=exact,"SCIENCE: conditional bound exceeds exact");
        int better=validate(s.conditional_nogood,int(UB));
        std::vector<int> exact_seed;
        for(int i=0;i<trailRecord;++i)if(level(var(trail[i]))>0)exact_seed.push_back(toInt(~trail[i]));
        need(s.conditional_nogood==exact_seed,"reader omitted/reordered nonroot base assignments");
        if(!root)need(better>0&&!s.conditional_nogood.empty(),"vacuous nonroot conditional certificate");
        else need(better==0&&s.conditional_nogood.empty(),"root strict-bound feasibility mismatch");
        std::vector<int> beforeFalse;for(int i=0;i<falseLits.size();++i)beforeFalse.push_back(toInt(falseLits[i]));
        resetConflicts(1);
        for(auto p:s.conditional_nogood) {
            need(value(toLit(p))==l_False&&level(p/2)>0,"conditional seed polarity/level");
            involvedLits.push(toLit(p));involved[p/2]=1;
        }
        UBconflictFlag=softConflictFlag=true;vec<Lit> out;bt=lbd=-1;
        analyzeSoftConflict(out,bt,lbd);
        need(!UBconflictFlag&&!softConflictFlag&&falseVar==var_Undef&&involvedLits.empty(),"analyzer flags not cleared");
        need(falseLits.size()==int(beforeFalse.size()),"temporary falseLits size leaked");
        for(int i=0;i<falseLits.size();++i)need(toInt(falseLits[i])==beforeFalse[i],"temporary falseLits payload leaked");
        for(int v=0;v<6;++v)need(!seen[v]&&!involved[v],"analyzer seen/involved leaked");
        need(add_tmp.empty(),"analyzer activity scratch leaked");
        for(int i=0;i<out.size();++i)learned.push_back(toInt(out[i]));
        if(root) {need(out.empty()&&bt==0&&lbd==0,"root maxConflLevel0 exit mismatch");return;}
        validate(learned,int(UB));
        need(!out.empty()&&value(out[0])==l_False,"missing asserting literal");
        for(auto p:learned)need(std::find(s.conditional_nogood.begin(),s.conditional_nogood.end(),p)!=s.conditional_nogood.end(),"unexpected learned literal");
        if(shape==1)need(out.size()==2&&out[0]==~mkLit(4)&&bt==1&&lbd==2,"independent two-level analyzer shape");
        else need(out.size()==1&&out[0]==q&&bt==0&&lbd==1,"unit analyzer shape");
    }
    void install() {
        cancelUntil(bt);vec<Lit> ps;for(auto p:learned)ps.push(toLit(p));
        need(value(ps[0])==l_Undef,"learned literal not asserting after backtrack");
        for(int i=1;i<ps.size();++i)need(value(ps[i])==l_False,"learned suffix not false after backtrack");
        if(ps.size()==1)uncheckedEnqueue(ps[0]);
        else {
            need(lbd<=core_lbd_cut,"fixture expected CORE learner");
            CRef cr=ca.alloc(ps,true);ca[cr].set_lbd(lbd);learnts_core.push(cr);
            ca[cr].mark(CORE);ca[cr].touched()=conflicts;claBumpActivity(ca[cr]);
            attachClause(cr);uncheckedEnqueue(ps[0],cr);
        }
    }
    void successTransfer() {
        int total=int(UB);validate(learned,total);validate(learned,total-1);
        bool found=false;for(int a=0;a<64;++a)if(feasibleOriginal(a)&&cost(a)<total&&clause(learned,a))found=true;
        need(found,"no independently feasible success witness");
        cancelUntil(0);
        offsets.initial_fixed_search_cost=fixedCostBySearch;
        for(int i=0;i<falseLits.size();++i)offsets.transferred_root_false.push_back(toInt(falseLits[i]));
        fixedCostBySearch+=falseLits.size();beginning=trail.size();falseLits.clear();
        // Equal-coordinate intermediate check, before a smaller TOTAL bound.
        UB=total-fixedCostBySearch;feasible=true;
        for(int a=0;a<64;++a)if(feasibleOriginal(a)&&cost(a)<total) {
            int residual=cost(a)-int(fixedCostBySearch);
            for(int i=0;i<trail.size();++i)need(lit(toInt(trail[i]),a),"success retained root fact excludes prior better model");
            need((residual<int(UB))==(cost(a)<total),"SCIENCE: transfer strict-bound set changed");
        }
        UB=total-1-fixedCostBySearch;validate(learned,int(UB+fixedCostBySearch));
        need(feasible&&beginning==trail.size(),"success lifetime marker");
        // Intentionally no relaxation here: solve's feasible arm breaks first.
    }
    void relax() {
        int expanded=int(UB)+1,witness=-1;
        for(int a=0;a<64;++a)if(feasibleOriginal(a)&&cost(a)<expanded&&!clause(learned,a)) {witness=a;break;}
        need(witness>=0,"relaxation lacks lost-validity witness");
        cancelUntilBeginning(beginning);removeLearntClauses();UB=expanded;
        need(trail.empty()&&trail_lim.empty()&&falseLits.empty()&&falseLits_lim.empty(),"conditional root/decision trail survived relaxation");
        need(learnts_core.empty()&&learnts_tier2.empty()&&learnts_local.empty()&&hardens.empty()&&cardinalityC.empty()&&isetClauses.empty(),"conditional clause list survived relaxation");
        need(fixedCostBySearch==0&&value(q)==l_Undef&&value(mkLit(5))==l_Undef,"conditional root offset survived relaxation");
        std::set<std::vector<int> > expected,actual;
        for(auto c:original) {std::sort(c.begin(),c.end());expected.insert(c);}
        std::set<CRef> refs;
        for(int v=0;v<6;++v)for(int sg=0;sg<2;++sg)for(int k=0;k<2;++k) {
            vec<Watcher>& ws=k?watches[mkLit(v,sg!=0)]:watches_bin[mkLit(v,sg!=0)];
            for(int i=0;i<ws.size();++i)refs.insert(ws[i].cref);
        }
        for(auto cr:refs) {
            Clause& c=ca[cr];need(c.mark()!=1,"removed clause remains watched");
            std::vector<int> row;for(int i=0;i<c.size();++i)row.push_back(toInt(c[i]));
            std::sort(row.begin(),row.end());actual.insert(row);
        }
        need(actual==expected,"relaxation watched hard set mismatch");
        for(auto c:actual)need(clause(c,witness),"relaxed witness excluded by stale clause");
        need(feasibleOriginal(witness)&&cost(witness)<int(UB),"relaxed original witness lost");
    }
};
int main() {
    try {
        int count=0;
        for(int signbit=0;signbit<2;++signbit)for(int shape=0;shape<3;++shape)for(int ctx=0;ctx<2;++ctx) {
            Conditional success;success.setup(signbit,shape,ctx,false);success.analyze();success.install();success.successTransfer();
            Conditional relaxed;relaxed.setup(signbit,shape,ctx,false);relaxed.analyze();relaxed.install();relaxed.relax();
            std::cout<<"conditional="<<count++<<" sign="<<signbit<<" shape="<<shape<<" context="<<ctx
                     <<" bt="<<success.bt<<" lbd="<<success.lbd<<" learned=";
            for(auto p:success.learned)std::cout<<p<<',';
            std::cout<<" original_models=64 success_transfer=PASS separate_relaxation=PASS\n";
        }
        for(int ctx=0;ctx<2;++ctx) {
            Conditional s;s.setup(0,0,ctx,true);s.analyze();
            std::cout<<"conditional="<<count++<<" root_only=1 context="<<ctx<<" maxConflLevel0=PASS\n";
        }
        need(count==14,"conditional fixture count");
        std::cout<<"CONDITIONAL_14_PASS productionTier0=NOT_RUN speculativeRollback=NOT_RUN performance=NOT_MEASURED\n";
    } catch(const std::exception& e) {std::cerr<<e.what()<<'\n';return 2;}
    return 0;
}
