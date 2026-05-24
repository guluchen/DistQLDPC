/***************************************************************************************[Solver.cc]
 MiniSat -- Copyright (c) 2003-2006, Niklas Een, Niklas Sorensson
 Copyright (c) 2007-2010, Niklas Sorensson
 
Chanseok Oh's MiniSat Patch Series -- Copyright (c) 2015, Chanseok Oh

Maple_LCM, Based on MapleCOMSPS_DRUP --Copyright (c) 2017, Mao Luo, Chu-Min LI, Fan Xiao: implementing a learnt clause minimisation approach
 Reference: M. Luo, C.-M. Li, F. Xiao, F. Manya, and Z. L. , “An effective learnt clause minimization approach for cdcl sat solvers,” in IJCAI-2017, 2017, pp.703-711.
 
Maple_CM, Based on Maple_LCM --Copyright (c) 2018, Chu-Min LI, Mao Luo, Fan Xiao: implementing a clause minimisation approach.

Copyright (c) 2021,Chu-Min Li (chu-min.li@u-picardie.fr)

A MaxSAT solver combining branch-and-bound and clause learning, implemented by Chu-Min Li with the help of Jordi Coll
Based on Maple_LCM

Reference: Chu-Min Li, Zhenxing Xu, Jordi Coll, Felip Manyà, Djamal Habet, Kun He, Combining Clause Learning and Branch and Bound for MaxSAT, in CP-2021, to appear


Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge, publish, distribute,
 sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**************************************************************************************************/

// Based on newMaxMaple_CM+distACT1W5lastPointAllLRB+

// Based on MaxCDCL3+coreRedctnBis+lookhead+clsRedtn+

// Based on MaxCDCL4+lastConfl+auxiHeap+adaptRL+

// Based on MaxCDCL5+softLits+binS+keepsuc+clsRdn-+-, exploiting conflicting soft literals
// when two soft literals l1 and l2 are conflicting, i.e., they cannot be satisfied at the same time
// without violating a hard clause, then they can be combined into one soft clause.
// See Li & Quan AAAI2010 for different encodings of MaxClique into patial MaxSAT

// Based on newMaxCDCL8+lkUB+lastConfl-+initConfls, treat specially the soft lits involved
//in disjoint inconsistent sets

// Based on newMaxCDCL11+sUB2times+harden4, create new variables to shorten clauses when hardening

// Based on MaxCDCL12bis+act+gc20, detect initial conflicts (different but noy necessarily
// disjoint) and create initial clauses to represent them

// Based on MaxCDCL15UB+saveDynVars-+shortenCls+coretier2+hard+lim4

// Based on newMaxCDCL16+ub+reset+partitnMin2

// Based on MaxCDCL20+lb3

// Based on MaxCDCL21-localrdtn+hardenbis

// Based on newMaxCDCL22+core5+s+purharden3+allUIP+LRBlastL

// Based on newMaxCDCL23+minLBD+core5+hardenEnable2

// Based on MaxCDCL27+quasiConfl

// Based on MaxCDCL30-dist+cardinality+hardC

// Based on newMaxCDCL31bis++dynvarDec+alt+isetCls

// Based on newMaxCDCL32+isetscls-+cls--+hconfl3+allAct

// Based on newMaxCDCL33+unitIset2+nk10k+flyRdtn

// Based on MaxCDCL35+impGbaselineBis++--isetcls+mto+

// Based on new5MaxCDCL37+uip2+isetclsbis+inv+coef2

// Based on MaxCDCL1.0+quasi-+prepro+bin2++fl+vsids01+binRes+

/* Based on MaxCDCL1.1-involv+falseLit-imply+optUP+impLitbis */

#define _CRT_SECURE_NO_DEPRECATE

#ifdef _MSC_VER
//#include <io.h>
//#include <process.h>
#else
#include <unistd.h>
#endif

#ifdef _MSC_VER
#include <windows.h>
#include <thread>

#define _MSC_VER_Sleep
#endif



#include <math.h>
#include <signal.h>

#include "mtl/Sort.h"
#include "Solver.h"
#include "utils/System.h"

using namespace Minisat;

#ifdef BIN_DRUP
int Solver::buf_len = 0;
unsigned char Solver::drup_buf[2 * 1024 * 1024];
unsigned char* Solver::buf_ptr = drup_buf;
#endif

//=================================================================================================
// Options:


static const char* _cat = "CORE";

static DoubleOption  opt_step_size         (_cat, "step-size",   "Initial step size",                             0.40,     DoubleRange(0, false, 1, false));
static DoubleOption  opt_step_size_dec     (_cat, "step-size-dec","Step size decrement",                          0.000001, DoubleRange(0, false, 1, false));
static DoubleOption  opt_min_step_size     (_cat, "min-step-size","Minimal step size",                            0.06,     DoubleRange(0, false, 1, false));
static DoubleOption  opt_var_decay         (_cat, "var-decay",   "The variable activity decay factor",            0.80,     DoubleRange(0, false, 1, false));
static DoubleOption  opt_clause_decay      (_cat, "cla-decay",   "The clause activity decay factor",              0.999,    DoubleRange(0, false, 1, false));
static DoubleOption  opt_random_var_freq   (_cat, "rnd-freq",    "The frequency with which the decision heuristic tries to choose a random variable", 0, DoubleRange(0, true, 1, true));
static DoubleOption  opt_random_seed       (_cat, "rnd-seed",    "Used by the random variable selection",         91648253, DoubleRange(0, false, HUGE_VAL, false));
static IntOption     opt_ccmin_mode        (_cat, "ccmin-mode",  "Controls conflict clause minimization (0=none, 1=basic, 2=deep)", 2, IntRange(0, 2));
static IntOption     opt_phase_saving      (_cat, "phase-saving", "Controls the level of phase saving (0=none, 1=limited, 2=full)", 2, IntRange(0, 2));
static BoolOption    opt_rnd_init_act      (_cat, "rnd-init",    "Randomize the initial activity", false);
static IntOption     opt_restart_first     (_cat, "rfirst",      "The base restart interval", 100, IntRange(1, INT32_MAX));
static DoubleOption  opt_restart_inc       (_cat, "rinc",        "Restart interval increase factor", 2, DoubleRange(1, false, HUGE_VAL, false));
static DoubleOption  opt_garbage_frac      (_cat, "gc-frac",     "The fraction of wasted memory allowed before a garbage collection is triggered",  0.20, DoubleRange(0, false, HUGE_VAL, false));


//=================================================================================================
// Constructor/Destructor:


Solver::Solver() :

    // Parameters (user settable):
    //
    drup_file        (NULL)
  , verbosity        (0)
  , step_size        (opt_step_size)
  , step_size_dec    (opt_step_size_dec)
  , min_step_size    (opt_min_step_size)
  , timer            (5000)
  , var_decay        (opt_var_decay)
  , clause_decay     (opt_clause_decay)
  , random_var_freq  (opt_random_var_freq)
  , random_seed      (opt_random_seed)
  , VSIDS            (false)
  , ccmin_mode       (opt_ccmin_mode)
  , phase_saving     (opt_phase_saving)
  , rnd_pol          (false)
  , rnd_init_act     (opt_rnd_init_act)
  , garbage_frac     (opt_garbage_frac)
  , restart_first    (opt_restart_first)
  , restart_inc      (opt_restart_inc)

  // Parameters (the rest):
  //
  , learntsize_factor((double)1/(double)3), learntsize_inc(1.1)

  // Parameters (experimental):
  //
  , learntsize_adjust_start_confl (100)
  , learntsize_adjust_inc         (1.5)

  // Statistics: (formerly in 'SolverStats')
  //
  , solves(0), starts(0), decisions(0), rnd_decisions(0), propagations(0), conflicts(0), conflicts_VSIDS(0)
  , dec_vars(0), clauses_literals(0), learnts_literals(0), max_literals(0), tot_literals(0)

  , ok                 (true)
  , cla_inc            (1)
  , var_inc            (1)
  , watches_bin        (WatcherDeleted(ca))
  , watches            (WatcherDeleted(ca))
  , qhead              (0)
  , simpDB_assigns     (-1)
  , simpDB_props       (0)
  , order_heap_CHB     (VarOrderLt(activity_CHB))
  , order_heap_VSIDS   (VarOrderLt(activity_VSIDS))
  , progress_estimate  (0)
  , remove_satisfied   (false)

  , core_lbd_cut       (5)
  , global_lbd_sum     (0)
  , lbd_queue          (50)
  , next_T2_reduce     (10000)
  , next_L_reduce      (15000)

  , counter            (0)

  // Resource constraints:
  //
  , conflict_budget    (-1)
  , propagation_budget (-1)
  , asynch_interrupt   (false)

  // simplfiy
  , nbSimplifyAll(0)
  , s_propagations(0)

  // simplifyAll adjust occasion
  , curSimplify(1)
  , nbconfbeforesimplify(1000)
  , incSimplify(1000)

  , my_var_decay       (0.6)
  , order_heap_distance(VarOrderLt(activity_distance))
  , var_iLevel_inc     (1)
  , DISTANCE           (true)

    , softConflicts (0)
    , softConflictFlag (false)
    //, softWatches        (softWatcherDeleted(ca))
   , solutionCost (0)
    , lastOptimalCost (UINT64_MAX)
    , totalWeight (0)
    , nbClauseReduce (0)

    , orderHeapAuxi(VarOrderGt(activityLB))

    , tier2_lbd_cut (7)
    , coreLimit (50000)
    , coreInactiveLimit (100000)
    , tier2Limit (7000)
    , tier2InactiveLimit (30000)

    , hardenEnable (false)
    , cardinalityEncMode (CARD_ENC_BOTH)
    , quasiSoftConflicts (0)
    , fixedByQuasiConfl (0)

    , pureSoftConfl (0)
    , nbFlyReduced (0)
    , nbFixedByLH  (0)
    , bestSolutionFound(false)
    , bestSup(0)
    , nbSatLitsAtStart(0)
    , bounds_pipe_w(-1)

{}


Solver::~Solver()
{
}

// simplify All
//
CRef Solver::simplePropagate() {
  // if (falseLits.size() + rootNbIsets >= UB) { // no need to propagate if a soft conflict occurs
  //   softConflictFlag=true;
  //   return CRef_Undef;
  // }
    CRef    confl = CRef_Undef;
    int     num_props = 0;
    softConflictFlag = false;
    watches.cleanAll();
    watches_bin.cleanAll();
    while (qhead < trail.size()) {
      Lit            p = trail[qhead++];     // 'p' is enqueued fact to propagate.
      vec<Watcher>&  ws = watches[p];
      Watcher        *i, *j, *end;
      num_props++;
      // First, Propagate binary clauses
      vec<Watcher>&  wbin = watches_bin[p];
      
      for (int k = 0; k<wbin.size(); k++) {
	Lit imp = wbin[k].blocker;
	if (value(imp) == l_False) {
	  binConfl[0] = ~p; binConfl[1]=imp;
	  return CRef_Bin;
	}   
	if (value(imp) == l_Undef) {
	  simpleUncheckEnqueue(imp, wbin[k].cref);
	  // if (falseLits.size() + rootNbIsets >= UB) {
	  //   softConflictFlag = true;
	  //   return confl;
	  // }
	}
      }
      for (i = j = (Watcher*)ws, end = i + ws.size(); i != end;) {
	// Try to avoid inspecting the clause:
	Lit blocker = i->blocker;
	if (value(blocker) == l_True) {
	  *j++ = *i++; continue;
	}
	// Make sure the false literal is data[1]:
	CRef     cr = i->cref;
	Clause&  c = ca[cr];
	Lit      false_lit = ~p;
	if (c[0] == false_lit)
	  c[0] = c[1], c[1] = false_lit;
	assert(c[1] == false_lit);
	// If 0th watch is true, then clause is already satisfied.
	// However, 0th watch is not the blocker, make it blocker using a new watcher w
	// why not simply do i->blocker=first in this case?
	Lit     first = c[0];
	//  Watcher w     = Watcher(cr, first);
	if (first != blocker) {
	  i->blocker = first;
	  if (value(first) == l_True){
	    *j++ = *i++; continue;
	  }
	}
	assert(c.lastPoint() >=2);
	if (c.lastPoint() > c.size())
	  c.setLastPoint(2);
	for (int k = c.lastPoint(); k < c.size(); k++) {
	  if (value(c[k]) == l_Undef) {
	    // watcher i is abandonned using i++, because cr watches now ~c[k] instead of p
	    // the blocker is first in the watcher. However,
	    // the blocker in the corresponding watcher in ~first is not c[1]
	    //  Watcher w = Watcher(cr, first); i++;
	    c[1] = c[k]; c[k] = false_lit;
	    watches[~c[1]].push(*i++);
	    c.setLastPoint(k+1);
	    goto NextClause;
	  }
	  else if (value(c[k]) == l_True) {
	    i->blocker = c[k];  *j++ = *i++;
	    c.setLastPoint(k);
	    goto NextClause;
	  }
	}
	for (int k = 2; k < c.lastPoint(); k++) {
	  if (value(c[k]) ==  l_Undef) {
	    // watcher i is abandonned using i++, because cr watches now ~c[k] instead of p
	    // the blocker is first in the watcher. However,
	    // the blocker in the corresponding watcher in ~first is not c[1]
	    //   Watcher w = Watcher(cr, first); i++;
	    c[1] = c[k]; c[k] = false_lit;
	    watches[~c[1]].push(*i++);
	    c.setLastPoint(k+1);
	    goto NextClause;
	  }
	  else if (value(c[k]) == l_True) {
	    i->blocker = c[k];  *j++ = *i++;
	    c.setLastPoint(k);
	    goto NextClause;
	  }
	}
	// Did not find watch -- clause is unit under assignment:
	//	i->blocker = first;
	*j++ = *i++;
	if (value(first) == l_False) {
	  confl = cr;
	  qhead = trail.size();
	  // Copy the remaining watches:
	  while (i < end)
	    *j++ = *i++;
	}
	else {
	    simpleUncheckEnqueue(first, cr);
	    // if (falseLits.size()+ rootNbIsets >= UB) {
	    //   qhead = trail.size();
	    //   // Copy the remaining watches:
	    //   while (i < end)
	    // 	*j++ = *i++;
	    //   softConflictFlag = true;
	    // }
	}
NextClause:;
      }
      ws.shrink(i - j);
      // if (confl == CRef_Undef)
      // 	if (shortenSoftClauses(p))
      // 	  break;
    }
    s_propagations += num_props;

    if (confl == CRef_Undef && falseLits.size() + rootNbIsets >= UB)
      softConflictFlag = true;
	
    return confl;
}

//the soft lits in the locked isets falsified by the main UP must not counted two times:
// in falseLits.size() and in isets
//So, they are counted in falseLits.size() but not in isets by using rootNbIsets--. But they are used to
//decrease the lock of the isets by calling decrmentIsetLock(iset)
void Solver::updateIsetLock(int savedFalseLits) {
  for(int i=savedFalseLits; i<falseLits.size(); i++) {
    Lit p=falseLits[i];
    if (inConflicts[var(p)] != NON) {
      int iset = getLockedVarIsetForLK(var(p));
      if (getIsetLock(iset) > 0) {
	decrmentIsetLock(iset);
	rootNbIsets--;
      }
    }
  }
}

void Solver::simpleUncheckEnqueue(Lit p, CRef from){
  assert(value(p) == l_Undef);
  Var v = var(p);
  assigns[v] = lbool(!sign(p)); // this makes a lbool object whose value is sign(p)
  // vardata[x] = mkVarData(from, decisionLevel());
  vardata[v].reason = from;
  vardata[v].level = decisionLevel() + 1;
  trail.push_(p);
  
  if (auxiVar(v) && value(softLits[v]) == l_False) {// a soft clause is falsified
    if (unLockedSoftVarForLK(v)) {
      assert(softLits[v] == ~p);
      falseLits.push(softLits[v]);
    }
    else {
      int iset = getLockedVarIsetForLK(v);
      decrmentIsetLock(iset);
      unLockedVars.push(v);
    }
  }
}

void Solver::cancelUntilTrailRecord()
{
    for (int c = trail.size() - 1; c >= trailRecord; c--)
    {
        Var x = var(trail[c]);
        assigns[x] = l_Undef;
        
    }
    qhead = trailRecord;
    trail.shrink(trail.size() - trailRecord);
    falseLits.shrink(falseLits.size() - falseLitsRecord);

    for(int c = unLockedVars.size()-1; c >= 0; c--) {
      Var x = unLockedVars[c];
      incrementIsetLock(inConflicts[x]);
    }
    unLockedVars.shrink(unLockedVars.size());
    
}

void Solver::litsEnqueue(int cutP, Clause& c)
{
    for (int i = cutP; i < c.size(); i++)
    {
        simpleUncheckEnqueue(~c[i]);
    }
}

bool Solver::removed(CRef cr) {
    return ca[cr].mark() == 1;
}

void Solver::simplereduceClause(CRef cr, int pathC) {
  nbFlyReduced++;
  Clause& c=ca[cr];
  assert(value(c[0]) == l_True);
  if (feasible || c.learnt()) {
    detachClause(cr, true);
    int max_i = 2;
    // Find the first literal assigned at the next-highest level:
    for (int i = 3; i < c.size(); i++)
      if (level(var(c[i])) >= level(var(c[max_i])))
	max_i = i;
    // here c must contain at least 3 literals assigned at level(var(c[1])): c[0], c[1] and c[max_i],
    // otherwise pathC==1, where c[0] is satisfied
    assert(level(var(c[1])) == level(var(c[max_i])));
    // put this literal at index 0:
    c[0] = c[max_i];

    for(int i=max_i+1; i<c.size(); i++)
      c[i-1] = c[i];
    c.shrink(1);
    attachClause(cr);
  }
}

void Solver::simpleAnalyze(CRef confl, vec<Lit>& out_learnt, bool True_confl)
{
    int pathC = 0;
    Lit p; // = lit_Undef;
    int index = trail.size() - 1;

    if (confl == CRef_Bin) {
      assert(level(var(binConfl[0])) > 0);
      assert(level(var(binConfl[1])) > 0);
      seen[var(binConfl[0])] = 1; seen[var(binConfl[1])] = 1;  pathC = 2;
    }
    else {
      Clause& c = ca[confl]; // c can be binary clause
      if (True_confl && c.size() == 2 && value(c[0]) == l_False) {
	assert(value(c[1]) == l_True);
	Lit tmp = c[0];
	c[0] = c[1], c[1] = tmp;
      }
      for(int i= (True_confl ? 1: 0); i<c.size(); i++)
	if (level(var(c[i])) > 0) {
	  seen[var(c[i])] = 1; 	pathC++;
	}
    }
    while(pathC > 0) {
      // Select next clause to look at:
      while (!seen[var(trail[index--])]);
      p = trail[index + 1];
      confl = reason(var(p));
      seen[var(p)] = 0;
      pathC--;
      if (confl != CRef_Undef) {
	// reason_clause.push(confl);
	Clause& c = ca[confl];
	// Special case for binary clauses
	// The first one has to be SAT
	if (c.size() == 2 && value(c[0]) == l_False) {
	  assert(value(c[1]) == l_True);
	  Lit tmp = c[0];
	  c[0] = c[1], c[1] = tmp;
	}
	int nbSeen=0, nbNotSeen = 0;
	int resolventSize=pathC + out_learnt.size();
	// if True_confl==true, then choose p begin with the 1th index of c;
	for (int j = 1; j < c.size(); j++){
	  Lit q = c[j]; Var v=var(q);
	  if (level(v) > 0) {
	    if (seen[v])
	      nbSeen++;
	    else {
	      nbNotSeen++;
	      seen[v] = 1;
	      pathC++;
	    }
	  }
	}
	assert(resolventSize == pathC + out_learnt.size() - nbNotSeen);
	if (pathC > 1 && p!=lit_Undef && nbSeen >= resolventSize)
	  simplereduceClause(confl, pathC);
	//printf("b\n");
      }
      else if (confl == CRef_Undef){
	out_learnt.push(~p); seen[var(p)] = 1;
      }
    }
    for(int i=0; i<out_learnt.size(); i++)
      seen[var(out_learnt[i])] = 0;
}

void Solver::simpleAnalyzeSoftConflict(vec<Lit>& out_learnt) {
    int pathC = 0;
    Lit p;
    CRef confl;
    int index   = trail.size() - 1;

    for(int a=falseLitsRecord; a<falseLits.size(); a++) {
      Var v=var(falseLits[a]);
      if (!seen[v] && level(v) > 0) {
	seen[v] = 1; 	pathC++;
	if (inConflicts[v] != NON) {
	  int iset=getLockedVarIsetForLK(v);
	  vec<int>& myInconfls = isets[iset];
	  for(int i=0; i<myInconfls.size(); i++) {
	    vec<Lit>& lits = isetsLits[myInconfls[i]];
	    for(int j=0; j<lits.size(); j++) {
	      if (value(lits[j]) == l_False && !seen[var(lits[j])] && level(var(lits[j])) > 0) {
		seen[var(lits[j])] = 1; pathC++;
	      }
	    }
	  }
	}
      }
    }

    // if (pathC < UB)
    //   printf("pathC %d, falseLits: %d, isets %d, UB %llu\n",
    // 	     pathC, falseLits.size(), rootNbIsets, UB);
    
    while (pathC > 0) {
      while (!seen[var(trail[index--])]);
      // if the reason cr from the 0-level assigned var, we must break avoid move forth further;
      // but attention that maybe seen[x]=1 and never be clear. However makes no matter;
      if (trailRecord > index + 1) break;
      p     = trail[index+1];
      confl = reason(var(p));
      seen[var(p)] = 0;
      pathC--;
      // if (pathC + out_learnt.size() == 0 && confl != CRef_Undef)
      // 	printf("b\n");
      if (confl == CRef_Undef)
	out_learnt.push(~p);
      else {
	// reason_clause.push(confl);
	Clause& c = ca[confl];
	// Special case for binary clauses: the first one has to be SAT
	if (c.size() == 2 && value(c[0]) == l_False) {
	  assert(value(c[1]) == l_True);
	  Lit tmp = c[0];
	  c[0] = c[1], c[1] = tmp;
	}
	for (int j = 1; j < c.size(); j++){
	  Var v = var(c[j]);
	  if (!seen[v] && level(v) > 0){
	    seen[v] = 1;
	    pathC++;
	  }
	}
      }
    }
}

bool Solver::simplifyLearnt(Clause& c, CRef cr, vec<Lit>& lits) {
    
    trailRecord = trail.size();// record the start pointer
    //sort(&c[0], c.size(), VarOrderLevelLt(vardata));
    falseLitsRecord = falseLits.size(); //unLockedVarsRecord = unLockedVars.size();
    
    bool True_confl = false, sat=false, false_lit=false;
    int i, j;
    CRef confl;
    for (int i = 0; i < c.size(); i++){
        if (value(c[i]) == l_True){
            sat = true;
            break;
        }
        else if (value(c[i]) == l_False){
            false_lit = true;
        }
    }
    if (sat){
        removeClause(cr);
        return false;
    }
    else{
        // detachClause(cr, true);
        
        if (false_lit){
            int li, lj;
            for (li = lj = 0; li < c.size(); li++){
                if (value(c[li]) != l_False){
                    c[lj++] = c[li];
                }
                else assert(li>1);
            }
            if (lj==2) {
                assert(li>2);
                detachClause(cr, true);
                c.shrink(li - lj);
                attachClause(cr);
            }
            else {
                assert(lj>2);
                c.shrink(li - lj);
            }
        }
        original_length_record += c.size();
        
        assert(c.size() > 1);
        
        Lit implied;
        lits.clear();
        for(i=0; i<c.size(); i++) lits.push(c[i]);
        assert(lits.size() == c.size());
        for (i = 0, j = 0; i < lits.size(); i++){
            if (value(lits[i]) == l_Undef){
                simpleUncheckEnqueue(~lits[i]);
                lits[j++] = lits[i];
                confl = simplePropagate();
                if (confl != CRef_Undef || softConflictFlag){
                    break;
                }
            }
            else{
                if (value(lits[i]) == l_True){
                    //printf("///@@@ uncheckedEnqueue:index = %d. l_True\n", i);
                    lits[j++] = lits[i];
                    True_confl = true; implied=lits[i];
                    confl = reason(var(lits[i]));
                    assert(confl  != CRef_Undef);
                    break;
                }
            }
        }
        if (j<lits.size()) {
            lits.shrink(lits.size() - j);
        }
        assert(lits.size() > 0 && lits.size() == j);
        
        if (confl != CRef_Undef || True_confl == true || softConflictFlag) {
            simp_learnt_clause.clear();
            //  simp_reason_clause.clear();
	    if (softConflictFlag) {
	      simpleAnalyzeSoftConflict(simp_learnt_clause);
	      softConflictFlag = false;
	    }
	    else {
	      if (True_confl == true){
                simp_learnt_clause.push(implied);
	      }
	      simpleAnalyze(confl, simp_learnt_clause, True_confl);
	    }
            assert(simp_learnt_clause.size() <= lits.size());
            cancelUntilTrailRecord();
            if (simp_learnt_clause.size() < lits.size()){
                for (i = 0; i < simp_learnt_clause.size(); i++){
                    lits[i] = simp_learnt_clause[i];
                }
                lits.shrink(lits.size() - i);
            }
            assert(simp_learnt_clause.size() == lits.size());
        }
        cancelUntilTrailRecord();
        
        simplified_length_record += lits.size();
        return true;
    }
}

bool Solver::simplifyLearnt_core() {
    
    int learnts_core_size_before = learnts_core.size();
    unsigned int nblevels;
    vec<Lit> lits;
    
    int nbSimplified = 0, nbSimplifing = 0, nbShortened=0, ci, cj;
    
    for (ci = 0, cj = 0; ci < learnts_core.size(); ci++){
        CRef cr = learnts_core[ci];
        Clause& c = ca[cr];
        
        if (removed(cr)) continue;
        else if ((c.simplified() && !WithNewUB)
		 || c.touched() + coreInactiveLimit < conflicts || c.activity() == 0){
            learnts_core[cj++] = learnts_core[ci];
            ////
            nbSimplified++;
        }
        else{
            ////
            nbSimplifing++;
            if (drup_file){
                add_oc.clear();
                for (int i = 0; i < c.size(); i++) add_oc.push(c[i]); }
            if (simplifyLearnt(c, cr, lits)) {

                if(drup_file && add_oc.size()!=lits.size()){
#ifdef BIN_DRUP
                    binDRUP('a', lits , drup_file);
//                    binDRUP('d', add_oc, drup_file);
#else
                    for (int i = 0; i < lits.size(); i++)
                        fprintf(drup_file, "%i ", (var(lits[i]) + 1) * (-2 * sign(lits[i]) + 1));
                    fprintf(drup_file, "0\n");

//                      fprintf(drup_file, "d ");
//                     for (int i = 0; i < add_oc.size(); i++)
//                         fprintf(drup_file, "%i ", (var(add_oc[i]) + 1) * (-2 * sign(add_oc[i]) + 1));
//                     fprintf(drup_file, "0\n");
#endif
                }
               if (lits.size() == 0)
                  return false;
                if (lits.size() == 1){
		  int savedFalseLits=falseLits.size();
                    // when unit clause occur, enqueue and propagate
                    uncheckedEnqueue(lits[0]);
                    if (propagate() != CRef_Undef  || softConflictFlag==true){
		      // ok = false;
                        return false;
                    }
                    // delete the clause memory in logic
		    detachClause(cr, true);
                    c.mark(1);
                    ca.free(cr);
		    updateIsetLock(savedFalseLits);
                }
                else {
                    if (c.size() > lits.size())
                        nbShortened++;
                    detachClause(cr, true);
                    for(int i=0; i<lits.size(); i++)
                        c[i]=lits[i];
                    c.shrink(c.size()-lits.size());
                    attachClause(cr);
                    
                    nblevels = computeLBD(c);
                    if (nblevels < c.lbd()){
                        //printf("lbd-before: %d, lbd-after: %d\n", c.lbd(), nblevels);
                        c.set_lbd(nblevels);
                    }
                    learnts_core[cj++] = learnts_core[ci];
                    c.setSimplified(2);
                }
            }
        }
    }
    learnts_core.shrink(ci - cj);

       // printf("c nbLearnts_core %d / %d, nbSimplified: %d, nbSimplifing: %d, of which nbShortened: %d\n",
       //        learnts_core_size_before, learnts_core.size(), nbSimplified, nbSimplifing, nbShortened);
    
    return true;
}

struct reduceTIER2_lt {
    ClauseAllocator& ca;
    reduceTIER2_lt(ClauseAllocator& ca_) : ca(ca_) {}
  bool operator () (CRef x, CRef y) {
    
    if (ca[x].touched() < ca[y].touched()) return true;
    if (ca[x].touched() > ca[y].touched()) return false;

    if(ca[x].lbd() > ca[y].lbd()) return true;
    if(ca[x].lbd() < ca[y].lbd()) return false;    
    
    // Finally we can use old activity or size, we choose the last one
    
     return ca[x].size() > ca[y].size();
    }
};

bool Solver::simplifyLearnt_tier2() {
    int learnts_tier2_size_before = learnts_tier2.size();
    unsigned int nblevels;
    vec<Lit> lits;
    
    int nbSimplified = 0, nbSimplifing = 0, nbShortened=0, ci, cj;
    int limit;
    if (learnts_tier2.size() <= tier2Limit/2)
      limit = 0;
    else {
      sort(learnts_tier2, reduceTIER2_lt(ca));
      limit = learnts_tier2.size() - (tier2Limit/2);
    }
    
    for (ci = 0, cj = 0; ci < learnts_tier2.size(); ci++){
        CRef cr = learnts_tier2[ci];
        Clause& c = ca[cr];
        
        if (removed(cr)) continue;
        else if ((c.simplified() && !WithNewUB) || c.activity() == 0){
            learnts_tier2[cj++] = learnts_tier2[ci];
            ////
            nbSimplified++;
        }
        else{
            ////
            nbSimplifing++;
            if (drup_file){
                add_oc.clear();
                for (int i = 0; i < c.size(); i++) add_oc.push(c[i]); }
            if (simplifyLearnt(c, cr, lits)) {

                if(drup_file && add_oc.size()!=lits.size()){
#ifdef BIN_DRUP
                    binDRUP('a', lits , drup_file);
//                    binDRUP('d', add_oc, drup_file);
#else
                    for (int i = 0; i < lits.size(); i++)
                        fprintf(drup_file, "%i ", (var(lits[i]) + 1) * (-2 * sign(lits[i]) + 1));
                    fprintf(drup_file, "0\n");

//                      fprintf(drup_file, "d ");
//                     for (int i = 0; i < add_oc.size(); i++)
//                         fprintf(drup_file, "%i ", (var(add_oc[i]) + 1) * (-2 * sign(add_oc[i]) + 1));
//                     fprintf(drup_file, "0\n");
#endif
                }
               if (lits.size() == 0)
                  return false;
                if (lits.size() == 1){
		  int savedFalseLits=falseLits.size();
                    // when unit clause occur, enqueue and propagate
                    uncheckedEnqueue(lits[0]);
                    if (propagate() != CRef_Undef  || softConflictFlag==true){
		      // ok = false;
                        return false;
                    }
                    // delete the clause memory in logic
		    detachClause(cr, true);
                    c.mark(1);
                    ca.free(cr);
		    updateIsetLock(savedFalseLits);
                }
                else {
                    if (c.size() > lits.size())
                        nbShortened++;
                    detachClause(cr, true);
                    for(int i=0; i<lits.size(); i++)
                        c[i]=lits[i];
                    c.shrink(c.size()-lits.size());
                    attachClause(cr);
                    
                    nblevels = computeLBD(c);
                    if (nblevels < c.lbd()){
                        //printf("lbd-before: %d, lbd-after: %d\n", c.lbd(), nblevels);
                        c.set_lbd(nblevels);
                    }
                    
                    if (c.lbd() <= core_lbd_cut){
                        learnts_core.push(cr);
                        c.mark(CORE);
                    }
                    else
                        learnts_tier2[cj++] = learnts_tier2[ci];
                    c.setSimplified(2);
                }
            }
        }
    }
    learnts_tier2.shrink(ci - cj);
    
    //    printf("c nbLearnts_tier2 %d / %d, nbSimplified: %d, nbSimplifing: %d, of which nbShortened: %d\n",
    //           learnts_tier2_size_before, learnts_tier2.size(), nbSimplified, nbSimplifing, nbShortened);
    
    return true;
}

#define maxNbTestedVars 1000

void Solver::cancelUntilTrailRecord1()
{
  counter++;
    for (int c = trail.size() - 1; c >= trailRecord; c--)
    {
        Var x = var(trail[c]);
        assigns[x] = l_Undef;
	seen2[toInt(trail[c])] = counter;
    }
    qhead = trailRecord;
    trail.shrink(trail.size() - trailRecord);
    falseLits.shrink(falseLits.size() - falseLitsRecord);

    for(int c = unLockedVars.size()-1; c >= 0; c--) {
      Var x = unLockedVars[c];
      incrementIsetLock(inConflicts[x]);
    }
    unLockedVars.shrink(unLockedVars.size());
    
}

void Solver::cancelUntilTrailRecord2()
{
  add_tmp.clear();
    for (int c = trail.size() - 1; c >= trailRecord; c--)
    {
        Var x = var(trail[c]);
        assigns[x] = l_Undef;
	if (seen2[toInt(trail[c])] == counter)
	  add_tmp.push(trail[c]);
    }
    qhead = trailRecord;
    trail.shrink(trail.size() - trailRecord);
    falseLits.shrink(falseLits.size() - falseLitsRecord);

    for(int c = unLockedVars.size()-1; c >= 0; c--) {
      Var x = unLockedVars[c];
      incrementIsetLock(inConflicts[x]);
    }
    unLockedVars.shrink(unLockedVars.size());
    
}

bool Solver::failedLiteralDetection() {
  int nbFailedLits=0, initTrail = trail.size(), maxNoFail=0, nbTested=0, nbI=0;
  CRef confl;
  bool res = true;
  falseLitsRecord = falseLits.size(); trailRecord = trail.size();
  while (1) {
    if (maxNoFail > maxNbTestedVars)
      break;
    Lit p=pickBranchLit();
    if (p==lit_Undef)
      break;
    // if (watches_bin[p].size() > 0 || watches_bin[~p].size() > 0) {
    //   nbTested++;
    //   if (watches_bin[p].size() < watches_bin[~p].size())
    // 	p = ~p;
    //   assert(watches_bin[p].size() > 0);
    //   if (watches_bin[p].size() > 0) {
    nbTested++;
    simpleUncheckEnqueue(p);
    confl = simplePropagate();
    if (confl != CRef_Undef || softConflictFlag) {
      maxNoFail = 0; cancelUntilTrailRecord(); softConflictFlag=false;
      int savedFalseLits=falseLits.size();
      uncheckedEnqueue(~p);
      assert(decisionLevel() == 0);
      if (propagate() != CRef_Undef  || softConflictFlag==true) {
	res = false;
	break;
      }
      updateIsetLock(savedFalseLits);
      trailRecord = trail.size();  falseLitsRecord = falseLits.size();
      nbFailedLits++;
    }
    else {
      cancelUntilTrailRecord1(); 
      simpleUncheckEnqueue(~p);
      confl = simplePropagate();
      if (confl != CRef_Undef || softConflictFlag) {
	maxNoFail = 0; cancelUntilTrailRecord(); softConflictFlag=false;
	int savedFalseLits=falseLits.size();
	uncheckedEnqueue(p);
	if (propagate() != CRef_Undef  || softConflictFlag==true) {
	  res = false;
	  break;
	}
	updateIsetLock(savedFalseLits);
	trailRecord = trail.size();  falseLitsRecord = falseLits.size();
	nbFailedLits++;
      }
      else {
	cancelUntilTrailRecord2(); 
	if (add_tmp.size() > 0) {
	  nbI += add_tmp.size(); maxNoFail = 0;
	  int savedFalseLits=falseLits.size();
	  for(int i=0; i<add_tmp.size(); i++) 
	    uncheckedEnqueue(add_tmp[i]);
	  if (propagate() != CRef_Undef || softConflictFlag==true) {
	    res = false;
	    break;
	  }
	  updateIsetLock(savedFalseLits);
	  trailRecord = trail.size();  falseLitsRecord = falseLits.size();
	}
	else
	  maxNoFail++;
	if (value(p) == l_Undef)
	  testedVars.push(var(p));
      }
    }
  }
  for(int i=0; i<testedVars.size() ; i++)
    if (value(testedVars[i]) == l_Undef)
      insertVarOrder(testedVars[i]);
  testedVars.clear();
  printf("c nbFailedLits %d, nbI %d, fixedVarsByFL %d, totalFixedVars %d, nbTested: %d, counter %llu\n", 
	 nbFailedLits, nbI, trail.size()-initTrail, trail.size(), nbTested, counter);
  return res;
}

bool Solver::simplifyAll()
{
    ////
    simplified_length_record = original_length_record = 0;
    
    if (!ok || propagate() != CRef_Undef)
      return false; //ok = false;
    
    //// cleanLearnts(also can delete these code), here just for analyzing
    //if (local_learnts_dirty) cleanLearnts(learnts_local, LOCAL);
    //if (tier2_learnts_dirty) cleanLearnts(learnts_tier2, TIER2);
    //local_learnts_dirty = tier2_learnts_dirty = false;

    if (!failedLiteralDetection()) return false;
    
    if (!simplifyLearnt_core()) return false; //ok = false;
    if (!simplifyLearnt_tier2()) return false; //ok = false;
    // if (!simplifyLearnt_local()) return false; //ok = false;
    //if (!simplifyLearnt_x(learnts_local)) false //return ok = false;
    // if (!simplifyUsedOriginalClauses()) false; //return ok = false;

    // if (WithNewUB)
    //   collectDynVars();

    WithNewUB = false;
    
    checkGarbage();
    
    ////
    // printf("c size_reduce_ratio     : %4.2f%%\n",
    //        original_length_record == 0 ? 0 : (original_length_record - simplified_length_record) * 100 / (double)original_length_record)
      ;
    
    return true;
}

#define lbdLimitForOriCls 20

// bool Solver::simplifyUsedOriginalClauses() {
    
//     int usedClauses_size_before = usedClauses.size();
//     unsigned int nblevels;
//     vec<Lit> lits;
//     int nbSimplified = 0, nbSimplifing = 0, nbShortened=0, nb_remaining=0, nbRemovedLits=0, ci;
//     double avg;
    
//     for (ci = 0; ci < usedClauses.size(); ci++){
//         CRef cr = usedClauses[ci];
//         Clause& c = ca[cr];
        
//         if (!removed(cr)) {
//             nbSimplifing++;

//             if (drup_file){
//                 add_oc.clear();
//                 for (int i = 0; i < c.size(); i++) add_oc.push(c[i]); }

//             if (simplifyLearnt(c, cr, lits)) {

//                 if(drup_file && add_oc.size()!=lits.size()){
// #ifdef BIN_DRUP
//                     binDRUP('a', lits , drup_file);
//                     binDRUP('d', add_oc, drup_file);
// #else
//                     for (int i = 0; i < lits.size(); i++)
//                         fprintf(drup_file, "%i ", (var(lits[i]) + 1) * (-2 * sign(lits[i]) + 1));
//                     fprintf(drup_file, "0\n");

//                       fprintf(drup_file, "d ");
//                      for (int i = 0; i < add_oc.size(); i++)
//                          fprintf(drup_file, "%i ", (var(add_oc[i]) + 1) * (-2 * sign(add_oc[i]) + 1));
//                      fprintf(drup_file, "0\n");
// #endif
//                 }

//                 if (lits.size() == 1){
//                     // when unit clause occur, enqueue and propagate
//                     uncheckedEnqueue(lits[0]);
//                     if (propagate() != CRef_Undef || softConflictFlag==true){
// 		      //ok = false;
//                         return false;
//                     }
//                     // delete the clause memory in logic
// 		    detachClause(cr, true);
//                     c.mark(1);
//                     ca.free(cr);
//                 }
//                 else {

//                     if (c.size() > lits.size()) {
//                         nbShortened++; nbRemovedLits += c.size() - lits.size();
//                         nblevels = computeLBD(c);
//                         if (nblevels < c.lbd()){
//                             //printf("lbd-before: %d, lbd-after: %d\n", c.lbd(), nblevels);
//                             c.set_lbd(nblevels);
//                         }
//                     }
//                     detachClause(cr, true);
//                     for(int i=0; i<lits.size(); i++)
//                         c[i]=lits[i];
//                     c.shrink(c.size()-lits.size());
//                     attachClause(cr);
                    
//                     nb_remaining++;
//                     c.setSimplified(3);
//                 }
//             }
//         }
// 	//      c.setUsed(0);
//     }
//     if (nbShortened==0) avg=0;
//     else avg=((double) nbRemovedLits)/nbShortened;
//     //    printf("c nb_usedClauses %d / %d, nbSimplified: %d, nbSimplifing: %d, of which nbShortened: %d with nb removed lits %3.2lf\n",
//     //           usedClauses_size_before, nbSimplified+nb_remaining, nbSimplified, nbSimplifing, nbShortened, avg);
//     usedClauses.clear();
    
//     return true;
// }

struct clauseSize_lt {
    ClauseAllocator& ca;
    clauseSize_lt(ClauseAllocator& ca_) : ca(ca_) {}
    bool operator () (CRef x, CRef y) const { return ca[x].size() > ca[y].size(); }
};

#define simpLimit 100000000
#define tolerance 100

bool Solver::simplifyOriginalClauses() {

    int last_shorten=0, nbOriginalClauses_before = clauses.size();
    vec<Lit> lits;

    int nbShortened=0, ci, cj, nbRemoved=0, nbShortening=0;

    // sort(clauses, clauseSize_lt(ca));
    printf("c total nb of literals: %llu\n", clauses_literals);
    // if (clauses.size()> simpLimit) {
    //   printf("c too many original clauses (> %d), no original clause minimization \n",
    // 	     simpLimit);
    //   return true;
    // }
    double      begin_simp_time = cpuTime();
    for (ci = 0, cj = 0; ci < clauses.size(); ci++){
        CRef cr = clauses[ci];
        Clause& c = ca[cr];
        if (removed(cr)) continue;
        // if (ci - last_shorten > tolerance)
        //    clauses[cj++] = clauses[ci];
        // else
        if (s_propagations>simpLimit && ci-last_shorten>tolerance)
            clauses[cj++] = clauses[ci];
        else{
            if (drup_file){
                add_oc.clear();
                for (int i = 0; i < c.size(); i++) add_oc.push(c[i]); }

            if (simplifyLearnt(c, cr, lits)) {
                if(drup_file && add_oc.size()!=lits.size()){
#ifdef BIN_DRUP
                    binDRUP('a', lits , drup_file);
                    binDRUP('d', add_oc, drup_file);
#else
                    for (int i = 0; i < lits.size(); i++)
                        fprintf(drup_file, "%i ", (var(lits[i]) + 1) * (-2 * sign(lits[i]) + 1));
                    fprintf(drup_file, "0\n");

                      fprintf(drup_file, "d ");
                     for (int i = 0; i < add_oc.size(); i++)
                         fprintf(drup_file, "%i ", (var(add_oc[i]) + 1) * (-2 * sign(add_oc[i]) + 1));
                     fprintf(drup_file, "0\n");
#endif
                }


                nbShortening++;
                if (lits.size() == 1){
                    // when unit clause occur, enqueue and propagate
                    uncheckedEnqueue(lits[0]);
                    if (propagate() != CRef_Undef || softConflictFlag==true){
		      //ok = false;
                        return false;
                    }
                    // delete the clause memory in logic
		    detachClause(cr, true);
                    c.mark(1);
                    ca.free(cr);

                }
                else {

                    if (c.size() > lits.size()) {
                        nbShortened++; nbRemoved += c.size() - lits.size(); last_shorten = ci;
                    }
                    detachClause(cr, true);
                    for(int i=0; i<lits.size(); i++)
                        c[i]=lits[i];
                    c.shrink(c.size()-lits.size());
                    attachClause(cr);
                    assert(c == ca[cr]);
                    clauses[cj++] = clauses[ci];
                    //  c.setSimplified(2);
                }
            }
        }
    }
    clauses.shrink(ci - cj);
    double avg;
    if (nbShortened>0)
        avg= ((double)nbRemoved)/nbShortened;
    else avg=0;
//    printf("c nbOriginalClauses before/after: %d / %d, nbShortening: %d, nbShortened: %d, avg nbLits removed: %4.2lf\n",
//           nbOriginalClauses_before, clauses.size(), nbShortening, nbShortened, avg);
//    printf("c Original clause minimization time: %5.2lfs, number UPs: %llu\n",
//           cpuTime() - begin_simp_time, s_propagations);

    return true;
}

//=================================================================================================
// Minor methods:


// Creates a new SAT variable in the solver. If 'decision' is cleared, variable will not be
// used as a decision variable (NOTE! This has effects on the meaning of a SATISFIABLE result).
//
Var Solver::newVar(bool sign, bool dvar)
{
    int v = nVars();
    watches_bin.init(mkLit(v, false));
    watches_bin.init(mkLit(v, true ));
    watches  .init(mkLit(v, false));
    watches  .init(mkLit(v, true ));
    assigns  .push(l_Undef);
    vardata  .push(mkVarData(CRef_Undef, 0));
    activity_CHB  .push(0);
    activity_VSIDS.push(rnd_init_act ? drand(random_seed) * 0.00001 : 0);
    
    picked.push(0);
    conflicted.push(0);
    almost_conflicted.push(0);
#ifdef ANTI_EXPLORATION
    canceled.push(0);
#endif
    
    seen     .push(0);
    seen2    .push(0);
    seen2    .push(0);
    polarity .push(sign);
    decision .push();
    trail    .capacity(v+1);

    activity_distance.push(0);
    var_iLevel.push(0);
    var_iLevel_tmp.push(0);
    pathCs.push(0);

    // softWatches.init(mkLit(v, false));
    // softWatches.init(mkLit(v, true));

    //  lookaheadCNT.push(0);

    imply.push(lit_Undef);
    imply.push(lit_Undef);

    activityLB.push(0);
    //  lastTested.push(0);
    softLits.push(lit_Undef);

    conflictLits.init(mkLit(v, false));
    conflictLits.init(mkLit(v, true));

    softVarLocked.push(0);
    inConflict.push(NON);
    unlockReason.push(var_Undef);

    inConflicts.push(NON);

    //  unlockReasonForLK.push(var_Undef);
    
    setDecisionVar(v, dvar);
    // testedVars.push(0);
    involved.push(0);
    return v;
}

bool Solver::addClause_(vec<Lit>& ps, unsigned weight) {
    assert(decisionLevel() == 0);
    if (!ok) return false;
    // Check if clause is satisfied and remove false/duplicate literals:
    sort(ps);
    Lit p; int i, j;
    if (drup_file){
        add_oc.clear();
        for (int i = 0; i < ps.size(); i++) add_oc.push(ps[i]); }
    for (i = j = 0, p = lit_Undef; i < ps.size(); i++)
        if (value(ps[i]) == l_True || ps[i] == ~p)
            return true;
        else if (value(ps[i]) != l_False && ps[i] != p)
            ps[j++] = p = ps[i];
    ps.shrink(i - j);
    
    if (drup_file && i != j){
#ifdef BIN_DRUP
        binDRUP('a', ps, drup_file);
        binDRUP('d', add_oc, drup_file);
#else
        for (int i = 0; i < ps.size(); i++)
            fprintf(drup_file, "%i ", (var(ps[i]) + 1) * (-2 * sign(ps[i]) + 1));
        fprintf(drup_file, "0\n");
        
        fprintf(drup_file, "d ");
        for (int i = 0; i < add_oc.size(); i++)
            fprintf(drup_file, "%i ", (var(add_oc[i]) + 1) * (-2 * sign(add_oc[i]) + 1));
        fprintf(drup_file, "0\n");
#endif
    }
    
    if (ps.size() == 0) {
      if (hardWeight>0 && weight >= hardWeight)
        return ok = false;
      else solutionCost += weight;
    }
    else if (hardWeight>0 && weight >= hardWeight) {
      if (ps.size() == 1) {
      	uncheckedEnqueue(ps[0]);
      	return ok = (propagate() == CRef_Undef);
      }
      else{
	CRef cr = ca.alloc(ps, false);
	clauses.push(cr);
	attachClause(cr);
	//      weighVarInClauses(cr, weight);
	//if (ps.size()>maxOriClauseLength) maxOriClauseLength=ps.size();
	//      }
      }
    }
    else {
      CRef cr = ca.alloc(ps, false);
      softClauses.push(cr);
      //   attachSoftClause(cr);
      //  weights.push(weight);
    }
    return true;
}

// void Solver::attachSoftClause(CRef cr) {
//   const Clause& c = ca[cr];
//   OccLists<Lit, vec<softWatcher>, softWatcherDeleted>& ws = softWatches;
//   ws[~c[0]].push(softWatcher(cr));
//   softLiterals += c.size();
// }

// void Solver::detachSoftClause(CRef cr, bool strict) {
//     const Clause& c = ca[cr];
//     OccLists<Lit, vec<softWatcher>, softWatcherDeleted>& ws = softWatches;
    
//     if (strict){
//       remove(ws[~c[0]], softWatcher(cr));
//     }else{
//         // Lazy detaching: (NOTE! Must clean all watcher lists before garbage collecting this clause)
//         ws.smudge(~c[0]);
//     }
//     softLiterals -= c.size();
// }

// void Solver::removeSoftClause(CRef cr) {
//     Clause& c = ca[cr];
    
//     detachSoftClause(cr);
//     c.mark(1);
//     ca.free(cr);
// }

// void Solver::removeSoftSatisfied(vec<CRef>& cs)
// {
//     int i, j;
//     for (i = j = 0; i < cs.size(); i++){
//         Clause& c = ca[cs[i]];
//         if(c.mark()!=1){
//             if (satisfied(c))
//                 removeSoftClause(cs[i]);
//             else
//                 cs[j++] = cs[i];
//         }
//     }
//     cs.shrink(i - j);
// }

void Solver::attachClause(CRef cr) {
    const Clause& c = ca[cr];
    assert(c.size() > 1);
    OccLists<Lit, vec<Watcher>, WatcherDeleted>& ws = c.size() == 2 ? watches_bin : watches;
    ws[~c[0]].push(Watcher(cr, c[1]));
    ws[~c[1]].push(Watcher(cr, c[0]));
    if (c.learnt()) learnts_literals += c.size();
    else            clauses_literals += c.size(); }


void Solver::detachClause(CRef cr, bool strict) {
    const Clause& c = ca[cr];
    assert(c.size() > 1);
    OccLists<Lit, vec<Watcher>, WatcherDeleted>& ws = c.size() == 2 ? watches_bin : watches;
    
    if (strict){
        remove(ws[~c[0]], Watcher(cr, c[1]));
        remove(ws[~c[1]], Watcher(cr, c[0]));
    }else{
        // Lazy detaching: (NOTE! Must clean all watcher lists before garbage collecting this clause)
        ws.smudge(~c[0]);
        ws.smudge(~c[1]);
    }
    
    if (c.learnt()) learnts_literals -= c.size();
    else            clauses_literals -= c.size(); }


void Solver::removeClause(CRef cr) {
    Clause& c = ca[cr];
//    if(c.mark()==1)
//        exit(0);
    
    if (drup_file){
        if (c.mark() != 1){
#ifdef BIN_DRUP
            binDRUP('d', c, drup_file);
#else
            fprintf(drup_file, "d ");
            for (int i = 0; i < c.size(); i++)
                fprintf(drup_file, "%i ", (var(c[i]) + 1) * (-2 * sign(c[i]) + 1));
            fprintf(drup_file, "0\n");
#endif
        }else
            printf("c Bug. I don't expect this to happen.\n");
    }
    
    detachClause(cr);
    // Don't leave pointers to free'd memory!
    if (locked(c)){
        Lit implied = c.size() != 2 ? c[0] : (value(c[0]) == l_True ? c[0] : c[1]);
        vardata[var(implied)].reason = CRef_Undef; }
    if (c.mark() != 1 ) {
      c.mark(1);
      ca.free(cr);
    }
}


bool Solver::satisfied(const Clause& c) const {
    for (int i = 0; i < c.size(); i++)
        if (value(c[i]) == l_True)
            return true;
    return false; }


// Revert to the state at given level (keeping all assignment at 'level' but not beyond).
//
void Solver::cancelUntil(int level) {
    if (decisionLevel() > level){
        for (int c = trail.size()-1; c >= trail_lim[level]; c--){
            Var      x  = var(trail[c]);
            
            if (!VSIDS){
                uint32_t age = conflicts - picked[x];
                if (age > 0){
                    double adjusted_reward = ((double) (conflicted[x] + almost_conflicted[x])) / ((double) age);
                    double old_activity = activity_CHB[x];
                    activity_CHB[x] = step_size * adjusted_reward + ((1 - step_size) * old_activity);
                    if (order_heap_CHB.inHeap(x)){
                        if (activity_CHB[x] > old_activity)
                            order_heap_CHB.decrease(x);
                        else
                            order_heap_CHB.increase(x);
                    }
                }
#ifdef ANTI_EXPLORATION
                canceled[x] = conflicts;
#endif
            }
            assigns [x] = l_Undef;
            if (phase_saving > 1 || (phase_saving == 1) && c > trail_lim.last())
	      polarity[x] = sign(trail[c]);
	    insertAuxiVarOrder(x);
	    insertVarOrder(x);
	}
        qhead = trail_lim[level];
        trail.shrink(trail.size() - trail_lim[level]);
        trail_lim.shrink(trail_lim.size() - level);
	falseLits.shrink(falseLits.size() - falseLits_lim[level]);
	falseLits_lim.shrink(falseLits_lim.size() - level);
	//	unLockedVars_lim.shrink(unLockedVars_lim.size() - level);
    } }


//=================================================================================================
// Major methods:


Lit Solver::pickBranchLit()
{
    Var next = var_Undef;
    //Heap<VarOrderLt>& order_heap = VSIDS ? order_heap_VSIDS : order_heap_CHB;
    Heap<VarOrderLt>& order_heap = DISTANCE ? order_heap_distance : (VSIDS ? order_heap_VSIDS : order_heap_CHB);
    
    // Random decision:
    /*if (drand(random_seed) < random_var_freq && !order_heap.empty()){
     next = order_heap[irand(random_seed,order_heap.size())];
     if (value(next) == l_Undef && decision[next])
     rnd_decisions++; }*/
    
    // Activity based decision:
    while (next == var_Undef || value(next) != l_Undef || !decision[next])
        if (order_heap.empty())
            return lit_Undef;
        else{
#ifdef ANTI_EXPLORATION
            if (!VSIDS){
                Var v = order_heap_CHB[0];
                uint32_t age = conflicts - canceled[v];
                while (age > 0){
                    double decay = pow(0.95, age);
                    activity_CHB[v] *= decay;
                    if (order_heap_CHB.inHeap(v))
                        order_heap_CHB.increase(v);
                    canceled[v] = conflicts;
                    v = order_heap_CHB[0];
                    age = conflicts - canceled[v];
                }
            }
#endif
            next = order_heap.removeMin();
        }

    // if (dynVar(next))
    //   printf("a");
    
    return mkLit(next, polarity[next]);
}

void Solver::reduceClause(CRef cr, int pathC) {
  nbFlyReduced++;
  Clause& c=ca[cr];
  assert(value(c[0]) == l_True);
  if (feasible || c.learnt()) {
    if (pathC == 1) {
      // if (c.learnt())
      // 	removeClause(cr); 
      //the clause learnt from the conflict will take the place of cr
      return;
    }
    detachClause(cr, true);
    int max_i = 2;
    // Find the first literal assigned at the next-highest level:
    for (int i = 3; i < c.size(); i++)
      if (level(var(c[i])) >= level(var(c[max_i])))
	max_i = i;
    // here c must contain at least 3 literals assigned at level(var(c[1])): c[0], c[1] and c[max_i],
    // otherwise pathC==1, where c[0] is satisfied
    assert(level(var(c[1])) == level(var(c[max_i])));
    // put this literal at index 0:
    c[0] = c[max_i];

    for(int i=max_i+1; i<c.size(); i++)
      c[i-1] = c[i];
    c.shrink(1);
    attachClause(cr);
  }
}

void Solver::updateClauseUse(CRef confl) {
  Clause& c = ca[confl];
  int lbd = computeLBD(c);
  if (lbd < c.lbd()){
    if (lbd == 1)
      c.setSimplified(0);
    if (c.simplified() > 0)
      c.setSimplified(c.simplified()-1);
    if (c.learnt()) {
      if (c.lbd() <= 30) c.removable(false); // Protect once from reduction.
      // move confl into CORE or TIER2 if the new lbd is small enough
      if  (c.mark() != CORE){
	if (lbd <= core_lbd_cut){
	  learnts_core.push(confl);
	  c.mark(CORE);
	}else if (lbd <= tier2_lbd_cut && c.mark() == LOCAL){
	  // Bug: 'cr' may already be in 'learnts_tier2', e.g., if 'cr' was demoted from TIER2
	  // to LOCAL previously and if that 'cr' is not cleaned from 'learnts_tier2' yet.
	  learnts_tier2.push(confl);
	  c.mark(TIER2); }
      }
    }
    c.set_lbd(lbd);
  }
  if (c.learnt()) {
    if (c.mark() == TIER2 || c.mark() == CORE)
      c.touched() = conflicts;
    //   else if (c.mark() == LOCAL)
    claBumpActivity(c);
  }
  // else {
  //     if (c.used()==0 && c.simplified()==0) {
  //         // if (c.used()==0 && c.lbd() <= lbdLimitForOriCls) {
  //         usedClauses.push(confl);
  //         c.setUsed(1);
  //     }
  // }
}
  
/*_________________________________________________________________________________________________
 |
 |  analyze : (confl : Clause*) (out_learnt : vec<Lit>&) (out_btlevel : int&)  ->  [void]
 |
 |  Description:
 |    Analyze conflict and produce a reason clause.
 |
 |    Pre-conditions:
 |      * 'out_learnt' is assumed to be cleared.
 |      * Current decision level must be greater than root level.
 |
 |    Post-conditions:
 |      * 'out_learnt[0]' is the asserting literal at level 'out_btlevel'.
 |      * If out_learnt.size() > 1 then 'out_learnt[1]' has the greatest decision level of the
 |        rest of literals. There may be others from the same level though.
 |
 |________________________________________________________________________________________________@*/
void Solver::analyze(CRef confl, vec<Lit>& out_learnt, int& out_btlevel, int& out_lbd)
{
    int pathC = 0;
    Lit p; //     = lit_Undef;
    
    // Generate conflict clause:
    //
    out_learnt.push();      // (leave room for the asserting literal)
    int index   = trail.size() - 1;
    
    if (confl == CRef_Bin) {
      assert(level(var(binConfl[0])) == decisionLevel());
      assert(level(var(binConfl[1])) == decisionLevel());
      seen[var(binConfl[0])] = 1; seen[var(binConfl[1])] = 1;  pathC = 2;
      if (VSIDS){
	varBumpActivity(var(binConfl[0]), .5);
	varBumpActivity(var(binConfl[1]), .5);
	add_tmp.push(binConfl[0]);
	add_tmp.push(binConfl[1]);
      }else {
	conflicted[var(binConfl[0])]++;
	conflicted[var(binConfl[1])]++;
      }
      //     printf("c bin bin...\n");
    }
    else {
      updateClauseUse(confl);
      Clause& c = ca[confl];
      for(int i= 0; i<c.size(); i++)
	if (level(var(c[i])) > 0) {
	  Var v=var(c[i]);
	  if (VSIDS){
	    varBumpActivity(v, .5);
	    add_tmp.push(c[i]);
	  }else
	    conflicted[v]++;
	  seen[v] = 1;
	  if (level(v) >= decisionLevel())
	    pathC++;
	  else
	    out_learnt.push(c[i]);
	}
    }
    while (pathC > 0) {
      // Select next clause to look at:
      while (!seen[var(trail[index--])]);
      p     = trail[index+1];
      confl = reason(var(p));
      seen[var(p)] = 0; pathC--;
      if (pathC > 0)
	assert(confl != CRef_Undef); // (otherwise should be UIP)
      else
	break;
      Clause& c = ca[confl];
        // For binary clauses, we don't rearrange literals in propagate(), so check and make sure the first is an implied lit.
      if (c.size() == 2 && value(c[0]) == l_False){
	assert(value(c[1]) == l_True);
	Lit tmp = c[0];
	c[0] = c[1], c[1] = tmp; }

      updateClauseUse(confl);
      
      int nbSeen=0, nbNotSeen = 0;
      int resolventSize=pathC + out_learnt.size() - 1;
      for (int j = 1; j < c.size(); j++) {
	Lit q = c[j]; Var v=var(q);
	if (level(v) > 0) {
	  if (seen[v])
	    nbSeen++;
	  else /*if (!redundantLit(q))*/ {
	    nbNotSeen++;
	    if (VSIDS){
	      varBumpActivity(v, .5);
	      add_tmp.push(q);
	    }else
	      conflicted[v]++;
	    seen[v] = 1;
	    if (level(v) >= decisionLevel()){
	      pathC++;
	    }else
	      out_learnt.push(q);
	  }
	  //  else printf("m\n");
	}
      }
      assert(resolventSize == pathC + out_learnt.size() - 1 - nbNotSeen);
      if (p != lit_Undef && nbSeen >= resolventSize)
	reduceClause(confl, pathC); //printf("a\n");
    }
    out_learnt[0] = ~p;
    
    simplifyConflictClause(out_learnt, out_btlevel, out_lbd);
    
    // if (out_lbd > lbdLimitForOriCls) {
    //     for(int i = saved; i < usedClauses.size(); i++)
    //         ca[usedClauses[i]].setUsed(0);
    //     usedClauses.shrink(usedClauses.size() - saved);
    // }
}


// Try further learnt clause minimization by means of binary clause resolution.
bool Solver::binResMinimize(vec<Lit>& out_learnt)
{
    // Preparation: remember which false variables we have in 'out_learnt'.
    counter++;
    for (int i = 1; i < out_learnt.size(); i++)
        seen2[var(out_learnt[i])] = counter;

    int to_remove = 0, limit=out_learnt.size()/2;
    for (int j=1; j<limit; j++) {
      Lit p=out_learnt[j];
      if (seen2[var(p)] == counter) {
	// Get the list of binary clauses containing 'p'.
	const vec<Watcher>& ws = watches_bin[~p];
	
	for (int i = 0; i < ws.size(); i++){
	  Lit the_other = ws[i].blocker;
	  // Does 'the_other' appear negatively in 'out_learnt'?
	  if (seen2[var(the_other)] == counter && value(the_other) == l_True){
            to_remove++;
            seen2[var(the_other)] = counter - 1; // Remember to remove this variable.
	  }
	}
      }
    }
    const vec<Watcher>& ws = watches_bin[~out_learnt[0]];
    for (int i = 0; i < ws.size(); i++){
      Lit the_other = ws[i].blocker;
      // Does 'the_other' appear negatively in 'out_learnt'?
      if (seen2[var(the_other)] == counter && value(the_other) == l_True){
	to_remove++;
	seen2[var(the_other)] = counter - 1; // Remember to remove this variable.
      }
    }
    // Shrink.
    if (to_remove > 0){
        int last = out_learnt.size() - 1;
        for (int i = 1; i < out_learnt.size() - to_remove; i++)
            if (seen2[var(out_learnt[i])] != counter)
                out_learnt[i--] = out_learnt[last--];
        out_learnt.shrink(to_remove);
    }
    return to_remove != 0;
}


// Check if 'p' can be removed. 'abstract_levels' is used to abort early if the algorithm is
// visiting literals at levels that cannot be removed later.
bool Solver::litRedundant(Lit p, uint32_t abstract_levels)
{
    analyze_stack.clear(); analyze_stack.push(p);
    int top = analyze_toclear.size();
    while (analyze_stack.size() > 0){
        assert(reason(var(analyze_stack.last())) != CRef_Undef);
        Clause& c = ca[reason(var(analyze_stack.last()))]; analyze_stack.pop();
        
        // Special handling for binary clauses like in 'analyze()'.
        if (c.size() == 2 && value(c[0]) == l_False){
            assert(value(c[1]) == l_True);
            Lit tmp = c[0];
            c[0] = c[1], c[1] = tmp; }
        
        for (int i = 1; i < c.size(); i++){
            Lit p  = c[i];
            if (!seen[var(p)] && level(var(p)) > 0){
                if (reason(var(p)) != CRef_Undef && (abstractLevel(var(p)) & abstract_levels) != 0){
                    seen[var(p)] = 1;
                    analyze_stack.push(p);
                    analyze_toclear.push(p);
                }else{
                    for (int j = top; j < analyze_toclear.size(); j++)
                        seen[var(analyze_toclear[j])] = 0;
                    analyze_toclear.shrink(analyze_toclear.size() - top);
                    return false;
                }
            }
        }
    }
    
    return true;
}


/*_________________________________________________________________________________________________
 |
 |  analyzeFinal : (p : Lit)  ->  [void]
 |
 |  Description:
 |    Specialized analysis procedure to express the final conflict in terms of assumptions.
 |    Calculates the (possibly empty) set of assumptions that led to the assignment of 'p', and
 |    stores the result in 'out_conflict'.
 |________________________________________________________________________________________________@*/
void Solver::analyzeFinal(Lit p, vec<Lit>& out_conflict)
{
    out_conflict.clear();
    out_conflict.push(p);
    
    if (decisionLevel() == 0)
        return;
    
    seen[var(p)] = 1;
    
    for (int i = trail.size()-1; i >= trail_lim[0]; i--){
        Var x = var(trail[i]);
        if (seen[x]){
            if (reason(x) == CRef_Undef){
                assert(level(x) > 0);
                out_conflict.push(~trail[i]);
            }else{
                Clause& c = ca[reason(x)];
                for (int j = c.size() == 2 ? 0 : 1; j < c.size(); j++)
                    if (level(var(c[j])) > 0)
                        seen[var(c[j])] = 1;
            }
            seen[x] = 0;
        }
    }
    
    seen[var(p)] = 0;
}


void Solver::uncheckedEnqueue(Lit p, CRef from)
{
    assert(value(p) == l_Undef);
    Var x = var(p);
    if (!VSIDS){
        picked[x] = conflicts;
        conflicted[x] = 0;
        almost_conflicted[x] = 0;
#ifdef ANTI_EXPLORATION
        uint32_t age = conflicts - canceled[var(p)];
        if (age > 0){
            double decay = pow(0.95, age);
            activity_CHB[var(p)] *= decay;
            if (order_heap_CHB.inHeap(var(p)))
                order_heap_CHB.increase(var(p));
        }
#endif
    }
    
    assigns[x] = lbool(!sign(p));
    vardata[x] = mkVarData(from, decisionLevel());
    trail.push_(p);
    if (auxiVar(x) && value(softLits[x]) == l_False) {// a soft clause is falsified
	assert(softLits[x] == ~p);
	falseLits.push(softLits[x]);
    }
}


/*_________________________________________________________________________________________________
 |
 |  propagate : [void]  ->  [Clause*]
 |
 |  Description:
 |    Propagates all enqueued facts. If a conflict arises, the conflicting clause is returned,
 |    otherwise CRef_Undef.
 |
 |    Post-conditions:
 |      * the propagation queue is empty, even if there was a conflict.
 |________________________________________________________________________________________________@*/
CRef Solver::propagate()
{
  // if (falseLits.size() >= UB) { // no need to propagate if a soft conflict occurs
  //   softConflictFlag=true;
  //   return CRef_Undef;
  // }
  softConflictFlag=false;
    CRef    confl     = CRef_Undef;
    int     num_props = 0;
    //   Lit conflLit = lit_Undef;
    watches.cleanAll();
    watches_bin.cleanAll();
    
    while (qhead < trail.size()){
        Lit            p   = trail[qhead++];     // 'p' is enqueued fact to propagate.
	// if (p == conflLit)
	//   break;
        vec<Watcher>&  ws  = watches[p];
        Watcher        *i, *j, *end;
        num_props++;
        
        vec<Watcher>& ws_bin = watches_bin[p];  // Propagate binary clauses first.
        for (int k = 0; k < ws_bin.size(); k++){
            Lit the_other = ws_bin[k].blocker;
            if (value(the_other) == l_False){
	      binConfl[0] = ~p; binConfl[1]=the_other;
	      confl = CRef_Bin;
	      //confl = ws_bin[k].cref;
#ifdef LOOSE_PROP_STAT
                return confl;
#else
                goto ExitProp;
#endif
            }else if(value(the_other) == l_Undef) {
	        uncheckedEnqueue(the_other, ws_bin[k].cref);
		// if (falseLits.size() >= UB && conflLit == lit_Undef) {
		//   assert(auxiVar(var(the_other)));
		//   conflLit = the_other;
		
// 		  softConflictFlag = true;
// #ifdef LOOSE_PROP_STAT
// 		  return confl;
// #else
// 		  goto ExitProp;
// #endif
		//	}
	    }
	}
        for (i = j = (Watcher*)ws, end = i + ws.size();  i != end;){
            // Try to avoid inspecting the clause:
            Lit blocker = i->blocker;
            if (value(blocker) == l_True){
                *j++ = *i++; continue; }
            
            // Make sure the false literal is data[1]:
            CRef     cr        = i->cref;
            Clause&  c         = ca[cr];
            Lit      false_lit = ~p;
            if (c[0] == false_lit)
                c[0] = c[1], c[1] = false_lit;
            assert(c[1] == false_lit);
            
            // If 0th watch is true, then clause is already satisfied.
            Lit     first = c[0];
	    //  Watcher w     = Watcher(cr, first);
            if (first != blocker){
	      i->blocker = first;
	      if (value(first) == l_True) {
                *j++ = *i++; continue;
	      }
	    }
            
            // Look for new watch:
	    assert(c.lastPoint() >=2);
	    if (c.lastPoint() > c.size())
	      c.setLastPoint(2);
	    for (int k = c.lastPoint(); k < c.size(); k++) {
	      if (value(c[k]) == l_Undef) {
		// watcher i is abandonned using i++, because cr watches now ~c[k] instead of p
		// the blocker is first in the watcher. However,
		// the blocker in the corresponding watcher in ~first is not c[1]
		//	Watcher w = Watcher(cr, first); i++;
		c[1] = c[k]; c[k] = false_lit;
		watches[~c[1]].push(*i++);
		c.setLastPoint(k+1);
		goto NextClause;
	      }
	      else if (value(c[k]) == l_True) {
		i->blocker = c[k];  *j++ = *i++;
		c.setLastPoint(k);
		goto NextClause;
	      }
	    }
	    for (int k = 2; k < c.lastPoint(); k++) {
	      if (value(c[k]) ==  l_Undef) {
		// watcher i is abandonned using i++, because cr watches now ~c[k] instead of p
		// the blocker is first in the watcher. However,
		// the blocker in the corresponding watcher in ~first is not c[1]
		//	Watcher w = Watcher(cr, first); i++;
		c[1] = c[k]; c[k] = false_lit;
		watches[~c[1]].push(*i++);
		c.setLastPoint(k+1);
		goto NextClause;
	      }
	      else if (value(c[k]) == l_True) {
		i->blocker = c[k];  *j++ = *i++;
		c.setLastPoint(k);
		goto NextClause;
	      }
	    }
	
            // Did not find watch -- clause is unit under assignment:
	    //   i->blocker=first;
            *j++ = *i++;
            if (value(first) == l_False){
                confl = cr;
                qhead = trail.size();
                // Copy the remaining watches:
                while (i < end)
                    *j++ = *i++;
            }else {
                uncheckedEnqueue(first, cr);
		// if (falseLits.size() >= UB && conflLit == lit_Undef) {
		//   assert(auxiVar(var(first)));
		//   conflLit = first;
		
		  // qhead = trail.size();
		  // // Copy the remaining watches:
		  // while (i < end)
		  //   *j++ = *i++;
		  // softConflictFlag = true;
		//	}
	    }
NextClause:;
        }
        ws.shrink(i - j);
	// if (confl == CRef_Undef)
	//   if (shortenSoftClauses(p))
	//     break;
    }
    
ExitProp:;
    propagations += num_props;
    simpDB_props -= num_props;

    if (confl == CRef_Undef && falseLits.size() >= UB)
      softConflictFlag = true;
    
    return confl;
}

bool Solver::redundantLit(Lit p) {
  Lit q=imply[toInt(p)];
  return q != lit_Undef && value(q) == l_False && seen[var(q)];
}

void Solver::getAllUIP(vec<Lit>& out_learnt, int& out_btlevel, int& out_lbd) {
  assert(out_learnt.size() > 2);
  vec<Lit> uips;
  uips.clear(); uips.push(out_learnt[0]);
  counter++;
  int minLevel=decisionLevel(), lbd=0;
  for(int i=1; i<out_learnt.size(); i++) {
    Var v=var(out_learnt[i]);
    if (level(v)>0) {
      assert(!seen[v]);
      seen[v]=1;
      pathCs[level(v)]++;
      if (minLevel>level(v))
	minLevel=level(v);
      if (seen2[level(v)] != counter) {
	lbd++;
	seen2[level(v)] = counter;
      }
    }
  }
  int limit=trail_lim[minLevel-1]; //begining position of level minLevel
  for(int i=trail_lim[level(var(out_learnt[1]))] - 1; i>=limit; i--) {
      
      // for(int ii=0; ii<learnts_tier2.size(); ii++) {
      // 	if (!ca[learnts_tier2[ii]].has_extra())
      // 	  printf("++++%d %llu\n", ii, conflicts);
      // 	assert(ca[learnts_tier2[ii]].has_extra());
      // }
    assert(limit>=0);
    Lit p=trail[i]; Var v=var(p);
    if (seen[v]) {
      int currentDecLevel=level(v);
      assert(pathCs[currentDecLevel] > 0);
      seen[v]=0;
      if (--pathCs[currentDecLevel]==0) {
	// v is the last var of the level directly involved in the conflict
	uips.push(~p); lbd--;
      }
      else {
	assert(reason(v) != CRef_Undef);
	Clause& c=ca[reason(v)];
	if (c.size()==2 && value(c[0])==l_False) {
	  // Special case for binary clauses
	  // The first one has to be SAT
	    assert(value(c[1]) != l_False);
	    Lit tmp = c[0];
	    c[0] =  c[1], c[1] = tmp;
	}
	
	// for(int ii=0; ii<learnts_tier2.size(); ii++) {
	//   if (!ca[learnts_tier2[ii]].has_extra())
	//     printf("----%d %d %llu\n", ii, i, conflicts);
	//   assert(ca[learnts_tier2[ii]].has_extra());
	// }
	int j;
	for (j = 1; j < c.size(); j++){
	  Lit q = c[j]; Var v1=var(q);
	  if (!seen[v1] && level(v1) > 0 && seen2[level(v1)] != counter) //&& !redundantLit(q)
	    break; // new level
	}
	if (j < c.size()) {
	  uips.push(~p);
	  if (uips.size() + lbd >= out_learnt.size()) {
	    for(int k=i; k>=limit; k--) {
	      Lit q=trail[k]; Var vv=var(q);
	      if (seen[vv]) {
		seen[vv] = 0;
		pathCs[level(vv)] = 0;
	      }
	    }
	    break;
	  }
	}
	else {
	  for (j = 1; j < c.size(); j++){
	    Lit q = c[j]; Var v1=var(q);
	    if (!seen[v1] && level(v1) > 0) {// && !redundantLit(q)){
	      assert(level(v1)<pathCs.size() && minLevel <= level(v1));
	      // if (minLevel>level(v1)) {
	      // 	minLevel=level(v1); limit=trail_lim[minLevel-1]; 
	      // }
	      seen[v1] = 1;
	      pathCs[level(v1)]++;
	    }
	  }
	}
      }
    }
  }
  if (uips.size() + lbd < out_learnt.size()) {
    int myLevel = decisionLevel() +1;
    out_learnt.clear(); 
    for(int i=0; i<uips.size(); i++) {
      out_learnt.push(uips[i]);
      assert(myLevel >= level(var(uips[i])));
      myLevel = level(var(uips[i]));
    }
    //   out_lbd = out_learnt.size();
    out_btlevel = level(var(out_learnt[1]));
  }
}
  

void Solver::analyzeSoftConflict(vec<Lit>& out_learnt, int& out_btlevel, int& out_lbd)
{
    int pathC = 0;
    Lit p;
    CRef confl;

    if (falseLits.size() >= UB)
      pureSoftConfl++;
    // Generate conflict clause:
    //
    out_learnt.push();      // (leave room for the asserting literal)
    int index   = trail.size() - 1;
    //   int saved = usedClauses.size();
    // The last falsified literal is fixed most recently
    assert(falseLits.size() >= UB || UBconflictFlag);
    int nbFalseLits;
    if (falseLits.size() > UB) {
      nbFalseLits = UB;
      falseLits.shrink(falseLits.size() - UB);
    }
    else nbFalseLits = falseLits.size();
    int maxConflLevel = (falseLits.size() > 0) ? level(var(falseLits[nbFalseLits-1])) : 0;
    int debutFalse = falseLits_lim.size() > 0 ? falseLits_lim[0] : falseLits.size();

    // if (constraintRelaxed)
    //   for(int a=debutFalse; a<nbFalseLits; a++) {
    // 	Var v=var(falseLits[a]);
    // 	if (inConflict[v] != NON) {
    // 	  Var u = unlockReason[v];
    // 	  assert(u != var_Undef);
    // 	  assert(level(u) <= maxConflLevel);
    // 	  if (!seen[u]) {
    // 	    seen[u] = 1;
    // 	    assert(value(softLits[u]) == l_False);
    // 	    falseLits.push(softLits[u]);
    // 	  }
    // 	}
    //   }
      
    if (UBconflictFlag) {
      // if (constraintRelaxed)
      // 	for(int a=0; a<conflLits.size(); a++) {
      // 	  p = conflLits[a];
      // 	  if (p !=lit_Undef) {
      // 	    Var v=var(p);
      // 	    if (inConflict[v] != NON) {
      // 	      Var u=unlockReason[v];
      // 	      //  assert(u != var_Undef);
      // 	      if (u != var_Undef && !seen[u]) {
      // 		seen[u] = 1;
      // 		assert(value(softLits[u]) == l_False);
      // 		falseLits.push(softLits[u]);
      // 		if (level(u) > maxConflLevel)
      // 		  maxConflLevel = level(u);
      // 	      }
      // 	    }
      // 	  }
      // 	}
      
      for(int i=0; i<involvedLits.size(); i++) { 
	Lit q = involvedLits[i]; Var v = var(q);
	involved[v] = 0;
	assert(level(v) > 0);
	if (!seen[v] && value(q) == l_False) {
	  seen[v] = 1;
	  falseLits.push(q);
	  if (level(v) > maxConflLevel)
	    maxConflLevel = level(v);
	}
      }
      involvedLits.clear();
    }
    
    for(int a=nbFalseLits; a<falseLits.size(); a++)
      seen[var(falseLits[a])] = 0;
    
    for(int a=debutFalse; a<falseLits.size(); a++) {
      Var v=var(falseLits[a]);
      if (!seen[v] && level(v) > 0) { // && !redundantLit(falseLits[a])) {
	seen[v] = 1;
	if (VSIDS){
	  varBumpActivity(v, .5);
	  add_tmp.push(falseLits[a]);
	}else
	  conflicted[v]++;
	if (level(v) >= maxConflLevel)
	  pathC++;
	else
	  out_learnt.push(falseLits[a]);
      }
    }
    falseLits.shrink(falseLits.size() - nbFalseLits);
    // if (UBconflictFlag) {
    //   for(int i=0; i<involvedClauses.size(); i++) { 
    // 	CRef cr = involvedClauses[i]; // clause cr could occur several times, an optimization must be done here.
    // 	Clause& c = ca[cr];
    // 	for(int j=0; j<c.size(); j++) {
    // 	  Lit q = c[j]; Var v= var(q);
    // 	  if (!seen[v] && level(v) > 0 && value(q) == l_False) {
    // 	    seen[v] = 1;
    // 	    if (VSIDS){
    // 	      varBumpActivity(v, .5);
    // 	      add_tmp.push(q);
    // 	    }else
    // 	      conflicted[v]++;
    // 	    if (level(v) >= maxConflLevel)
    // 	      pathC++;
    // 	    else
    // 	      out_learnt.push(q);
    // 	  }
    // 	}
    //   }
    // }
    assert(pathC > 0 || maxConflLevel==0);
    if (maxConflLevel==0) {
      printf("c ***** \n");
      assert(pathC == 0 && UBconflictFlag);
      UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
      out_btlevel=0; out_lbd=0; out_learnt.clear();
      return;
    }
    while (pathC > 0) {
      while (!seen[var(trail[index--])]);
      p     = trail[index+1];
      confl = reason(var(p));
      seen[var(p)] = 0;
      pathC--;
      // sign(p) returns the last bit of p. p is positive iff sign(p)= 0 or false
      // p should not be UIP if it is a negative auxi literal (i.e., if it represents a false soft clause)
      //if (pathC == 0 && !(auxiVar(var(p)) && sign(p)))
	//if (pathC == 0 && !(auxiVar(var(p))))
      if (pathC == 0)
	break;
      
      assert(confl != CRef_Undef); // (otherwise should be UIP)
      Clause& c = ca[confl];
      
        // For binary clauses, we don't rearrange literals in propagate(), so check and make sure the first is an implied lit.
        if (c.size() == 2 && value(c[0]) == l_False){
	  assert(value(c[1]) == l_True);
	  Lit tmp = c[0];
	  c[0] = c[1], c[1] = tmp; }
        
        int lbd = computeLBD(c);
        if (lbd < c.lbd()){
	  if (lbd == 1)
	    c.setSimplified(0);
	  if (c.simplified() > 0)
	    c.setSimplified(c.simplified()-1);
	  if (c.learnt()) {
	    if (c.lbd() <= 30) c.removable(false); // Protect once from reduction.
	    // move confl into CORE or TIER2 if the new lbd is small enough
	    if  (c.mark() != CORE){
	      if (lbd <= core_lbd_cut){
		learnts_core.push(confl);
		c.mark(CORE);
	      }else if (lbd <= tier2_lbd_cut && c.mark() == LOCAL){
		// Bug: 'cr' may already be in 'learnts_tier2', e.g., if 'cr' was demoted from TIER2
		// to LOCAL previously and if that 'cr' is not cleaned from 'learnts_tier2' yet.
		learnts_tier2.push(confl);
		c.mark(TIER2); }
	    }
	  }
	  c.set_lbd(lbd);
        }
        if (c.learnt()) {
	  if (c.mark() == TIER2  || c.mark() == CORE)
	    c.touched() = conflicts;
	  //  else if (c.mark() == LOCAL)
	  claBumpActivity(c);
        }
        // else {
	//   if (c.used()==0 && c.simplified()==0) {
	//     // if (c.used()==0 && c.lbd() <= lbdLimitForOriCls) {
	//     usedClauses.push(confl);
	//     c.setUsed(1);
	//   }
        // }
 	int nbSeen=0, nbNotSeen = 0;
	int resolventSize=pathC + out_learnt.size() - 1;
	for (int j = 1; j < c.size(); j++){
	  Lit q = c[j]; Var v = var(q);
	  if (level(v) > 0) {
	    if (seen[v])
	      nbSeen++;
	    else {
	  // if (level(v) > 0 && !seen[v] && !redundantLit(q)) {
	        nbNotSeen++;
		if (VSIDS){
		  varBumpActivity(v, .5);
		  add_tmp.push(q);
		}else
		  conflicted[v]++;
		seen[v] = 1;
		if (level(v) >= maxConflLevel){
		  pathC++;
		}else
		  out_learnt.push(q);
	    }
	  }
	}
	assert(resolventSize == pathC + out_learnt.size() - 1 - nbNotSeen);
	if (pathC > 1 && nbSeen >= resolventSize) {
	  reduceClause(confl, pathC); //printf("b\n");
	}
    }
    out_learnt[0] = ~p;
    
    simplifyConflictClause(out_learnt, out_btlevel, out_lbd);
    assert(out_btlevel >0 || out_learnt.size() == 1);
    if (out_lbd > core_lbd_cut)
      getAllUIP(out_learnt, out_btlevel, out_lbd);


    // for(int i=0; i<out_learnt.size(); i++)
    //   printf("%d ", toInt(out_learnt[i]));
    // printf(", btlevel %d, lbd %d, trail: %d, level: %d, lim0: %d, confl: %llu, starts: %llu, lkUP: %llu, UP: %llu, falseLit1: %d, fsize: %d\n", 
    // 	   out_btlevel, out_lbd, trail.size(), decisionLevel(), trail_lim[0], 
    // 	   conflicts, starts, lk_propagations, propagations, toInt(falseLits[0]), nbFalseLits);
    // for(int i=0; i<conflLits.size(); i++)
    //   printf("%d ", toInt(conflLits[i]));
    // printf("\n%d\n", conflLits.size());

    
    // if (out_lbd > lbdLimitForOriCls) {
    //     for(int i = saved; i < usedClauses.size(); i++)
    //         ca[usedClauses[i]].setUsed(0);
    //     usedClauses.shrink(usedClauses.size() - saved);
    // }
    UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
}

void Solver::simplifyConflictClause(vec<Lit>& out_learnt, int& out_btlevel, int& out_lbd) {
      // Simplify conflict clause:
    int i, j;
    out_learnt.copyTo(analyze_toclear);
    if (ccmin_mode == 2){
        uint32_t abstract_level = 0;
        for (i = 1; i < out_learnt.size(); i++)
            abstract_level |= abstractLevel(var(out_learnt[i])); // (maintain an abstraction of levels involved in conflict)
        
        for (i = j = 1; i < out_learnt.size(); i++)
            if (reason(var(out_learnt[i])) == CRef_Undef || !litRedundant(out_learnt[i], abstract_level))
                out_learnt[j++] = out_learnt[i];
        
    }else if (ccmin_mode == 1){
        for (i = j = 1; i < out_learnt.size(); i++){
            Var x = var(out_learnt[i]);
            
            if (reason(x) == CRef_Undef)
                out_learnt[j++] = out_learnt[i];
            else{
                Clause& c = ca[reason(var(out_learnt[i]))];
                for (int k = c.size() == 2 ? 0 : 1; k < c.size(); k++)
                    if (!seen[var(c[k])] && level(var(c[k])) > 0){
                        out_learnt[j++] = out_learnt[i];
                        break; }
            }
        }
    }else
        i = j = out_learnt.size();
    
    max_literals += out_learnt.size();
    out_learnt.shrink(i - j);
    tot_literals += out_learnt.size();
    
    out_lbd = computeLBD(out_learnt);
    if (out_lbd <= tier2_lbd_cut && out_learnt.size() <= 35) // Try further minimization?
        if (binResMinimize(out_learnt))
            out_lbd = computeLBD(out_learnt); // Recompute LBD if minimized.
    
    // Find correct backtrack level:
    //
    if (out_learnt.size() == 1)
        out_btlevel = 0;
    else{
        int max_i = 1;
        // Find the first literal assigned at the next-highest level:
        for (int i = 2; i < out_learnt.size(); i++)
            if (level(var(out_learnt[i])) > level(var(out_learnt[max_i])))
                max_i = i;
        // Swap-in this literal at index 1:
        Lit p             = out_learnt[max_i];
        out_learnt[max_i] = out_learnt[1];
        out_learnt[1]     = p;
        out_btlevel       = level(var(p));
    }
    
    if (VSIDS){
        for (int i = 0; i < add_tmp.size(); i++){
            Var v = var(add_tmp[i]);
            if (level(v) >= out_btlevel - 1)
                varBumpActivity(v, 1);
        }
        add_tmp.clear();
    }else{
        seen[var(out_learnt[0])] = true;
        for(int i = out_learnt.size() - 1; i >= 0; i--){
            Var v = var(out_learnt[i]);
            CRef rea = reason(v);
            if (rea != CRef_Undef){
                const Clause& reaC = ca[rea];
                for (int i = 0; i < reaC.size(); i++){
                    Lit l = reaC[i];
                    if (!seen[var(l)]){
                        seen[var(l)] = true;
                        almost_conflicted[var(l)]++;
                        analyze_toclear.push(l); } } } } }
    for (int j = 0; j < analyze_toclear.size(); j++) seen[var(analyze_toclear[j])] = 0;    // ('seen[]' is now cleared)
}

// // Precondition: p is false and should be removed from the soft clauses it watches
// bool Solver::shortenSoftClauses(Lit p) {
//   vec<softWatcher>&  ws  = softWatches[p];
//   softWatcher        *i, *j, *end;
//   for (i = j = (softWatcher*)ws, end = i + ws.size();  i != end;){
//     CRef     cr= i->cref;
//     Clause&  c         = ca[cr];
//     assert(~p == c[0]);
//     // Look for new watch:
//     for (int k = 1; k < c.size(); k++)
//       if (value(c[k]) != l_False){
// 	c[0] = c[k]; c[k] = ~p;
// 	softWatches[~c[0]].push(softWatcher(cr));
// 	i++;
// 	goto NextClause;
//       }
//     // Did not find watch: the soft clause c is false under the current partial assignment:
//     *j++ = *i++;
//     falseSoftClauses.push(cr);
//     if (falseSoftClauses.size() >= UB) { //for unweighted MaxSAT
//       softConflictFlag = true;
//       while (i < end)
// 	*j++ = *i++;
//     }
//   NextClause:;
//   }
//   ws.shrink(i - j);
//   return softConflictFlag;
// }

/*_________________________________________________________________________________________________
 |
 |  reduceDB : ()  ->  [void]
 |
 |  Description:
 |    Remove half of the learnt clauses, minus the clauses locked by the current assignment. Locked
 |    clauses are clauses that are reason to some assignment. Binary clauses are never removed.
 |________________________________________________________________________________________________@*/
struct reduceDB_lt {
    ClauseAllocator& ca;
    reduceDB_lt(ClauseAllocator& ca_) : ca(ca_) {}
  bool operator () (CRef x, CRef y) {
    // if (ca[x].touched() > ca[y].touched()) return true;
    // if (ca[x].touched() < ca[y].touched()) return false;
    
    if (ca[x].activity() < ca[y].activity()) return true;
    if (ca[x].activity() > ca[y].activity()) return false;

    if(ca[x].lbd() > ca[y].lbd()) return true;
    if(ca[x].lbd() < ca[y].lbd()) return false;    
    
    // Finally we can use old activity or size, we choose the last one
    
     return ca[x].size() > ca[y].size();
    }
};

bool Solver::simplifyLearnt_local() {
  int learnts_local_size_before = learnts_local.size();
  int savedTrail = trail.size();
    unsigned int nblevels;
    vec<Lit> lits;
    
    int nbSimplified = 0, nbSimplifing = 0, nbShortened=0, ci, cj;

    sort(learnts_local, reduceDB_lt(ca));
    
    int limit = 7*learnts_local.size() / 8;
    
    for (ci = limit, cj = limit; ci < learnts_local.size() ; ci++){
        CRef cr = learnts_local[ci];
        Clause& c = ca[cr];
        
        if (removed(cr)) continue;
        else if ((c.simplified() && !WithNewUB) || c.activity() == 0) {
            learnts_local[cj++] = learnts_local[ci];
            ////
	    // if (c.used() == 0)
	      nbSimplified++;
        }
        else{
            ////
            nbSimplifing++;
            // if (drup_file){
            //     add_oc.clear();
            //     for (int i = 0; i < c.size(); i++) add_oc.push(c[i]); }
	    int oriLength = c.size();
            if (simplifyLearnt(c, cr, lits)) {

                if (drup_file && oriLength!=lits.size()) {
#ifdef BIN_DRUP
                    binDRUP('a', lits , drup_file);
//                    binDRUP('d', add_oc, drup_file);
#else
                    for (int i = 0; i < lits.size(); i++)
                        fprintf(drup_file, "%i ", (var(lits[i]) + 1) * (-2 * sign(lits[i]) + 1));
                    fprintf(drup_file, "0\n");

//                      fprintf(drup_file, "d ");
//                     for (int i = 0; i < add_oc.size(); i++)
//                         fprintf(drup_file, "%i ", (var(add_oc[i]) + 1) * (-2 * sign(add_oc[i]) + 1));
//                     fprintf(drup_file, "0\n");
#endif
                }
               if (lits.size() == 0)
                  return false;
                if (lits.size() == 1){
		  int savedFalseLits = falseLits.size();
                    // when unit clause occur, enqueue and propagate
                    uncheckedEnqueue(lits[0]);
                    if (propagate() != CRef_Undef || softConflictFlag==true){
		      //ok = false;
                        return false;
                    }
                    // delete the clause memory in logic
		    detachClause(cr, true);
                    c.mark(1);
                    ca.free(cr);
		    updateIsetLock(savedFalseLits);
                }
                else {
                    if (c.size() > lits.size())
                        nbShortened++;
                    detachClause(cr, true);
                    for(int i=0; i<lits.size(); i++)
                        c[i]=lits[i];
                    c.shrink(c.size()-lits.size());
                    attachClause(cr);
                    
                    nblevels = computeLBD(c);
                    if (nblevels < c.lbd()){
                        //printf("lbd-before: %d, lbd-after: %d\n", c.lbd(), nblevels);
                        c.set_lbd(nblevels);
                    }
                    
                    if (c.lbd() <= core_lbd_cut){
                        learnts_core.push(cr);
                        c.mark(CORE);
                    }
                    else if (c.lbd() <= tier2_lbd_cut) {
		      learnts_tier2.push(cr);
		      c.mark(TIER2);
		    }
		    else learnts_local[cj++] = learnts_local[ci];
                    c.setSimplified(2);
                }
            }
        }
    }
    learnts_local.shrink(ci - cj);
    
    // printf("c nbLearnts_local %d / %d, nbSimplified: %d, nbSimplifing: %d, of which nbShortened: %d, fixed: %d\n",
    //           learnts_local_size_before, learnts_local.size(), nbSimplified, nbSimplifing, nbShortened, trail.size()- savedTrail);
    
    return true;
}

void Solver::reduceDB()
{
    int     i, j;
    //if (local_learnts_dirty) cleanLearnts(learnts_local, LOCAL);
    //local_learnts_dirty = false;
    // printf("c caSize: %d, caWasted: %d (%4.3f), nbCORE: %d, nbTIER2: %d, conflicts: %llu, hardConfl: %llu\n",
    // 	   ca.size(), ca.wasted(), (float)ca.wasted()/ca.size(), learnts_core.size(), learnts_tier2.size(), conflicts, conflicts-softConflicts);

    // for (i = 0; i < learnts_local.size(); i++) {
    //   Clause& c = ca[learnts_local[i]];
    //   int nb=0;
    //   for(j=0; j<c.size(); j++) {
    // 	if (sign(c[j]) == polarity[var(c[j])]) 
    // 	  nb++;
    //   }
    //   c.touched() = nb;
    // }
    
    sort(learnts_local, reduceDB_lt(ca));
    
    int limit = learnts_local.size() / 2;
    int totalLocalSize=0, removedSize=0;
    for (i = j = 0; i < learnts_local.size(); i++){
        Clause& c = ca[learnts_local[i]];
	totalLocalSize += c.size();
        if (c.mark() == LOCAL)
	  if (c.removable() && !locked(c) && i < limit) {
	    removedSize += c.size();
	    removeClause(learnts_local[i]);
	  }
	  else{
	    if (!c.removable()) limit++;
	    c.removable(true);
	    learnts_local[j++] = learnts_local[i];
	  }
    }
    learnts_local.shrink(i - j);
    // printf("c removedSize: %d(%4.2f), over totalLocalSize: %d (%4.2f), NBremoved: %d, over nbLocalBefore: %d\n",
    // 	   removedSize, (float)removedSize/(i-j), totalLocalSize, (float)totalLocalSize/i, i-j, i);
    // printf("c %d ca size: %d, ca wasted: %d (%4.3f)\n\n",
    // 	   nbClauseReduce, ca.size(), ca.wasted(), (float)ca.wasted()/ca.size()); 
    checkGarbage();
}

// struct reduceTIER2_lt {
//     ClauseAllocator& ca;
//     reduceTIER2_lt(ClauseAllocator& ca_) : ca(ca_) {}
//   bool operator () (CRef x, CRef y) {
    
//     if (ca[x].touched() < ca[y].touched()) return true;
//     if (ca[x].touched() > ca[y].touched()) return false;

//     if(ca[x].lbd() > ca[y].lbd()) return true;
//     if(ca[x].lbd() < ca[y].lbd()) return false;    
    
//     // Finally we can use old activity or size, we choose the last one
    
//      return ca[x].size() > ca[y].size();
//     }
// };

void Solver::reduceDB_Tier2() {
  sort(learnts_tier2, reduceTIER2_lt(ca));
  int i, j;
  int limit = learnts_tier2.size()/2;
  
  //  printf("\n conflicts: %llu, tier2: %d, \n", conflicts, learnts_tier2.size());
  for (i = j = 0; i < learnts_tier2.size(); i++){
    Clause& c = ca[learnts_tier2[i]];
    if (c.mark() == TIER2) {
      assert(c.lbd() > 2);
      if (i < limit){
	learnts_local.push(learnts_tier2[i]);
	c.mark(LOCAL);
	//c.removable(true);
	c.activity() = 0;
	claBumpActivity(c);
	
	//	printf("i: %d, lbd: %d, touched: %u \n ", i, c.lbd(), c.touched());
      }else
	learnts_tier2[j++] = learnts_tier2[i];
    }
  }
  learnts_tier2.shrink(i - j);
  
   // printf("\ntier2: %d, last: %u, lastlbd: %d, core_lbd_cut: %d, core: %d\n",
   // 	  learnts_tier2.size(), ca[learnts_tier2.last()].touched(),
   // 	  ca[learnts_tier2.last()].lbd(), core_lbd_cut, learnts_core.size());
}

struct reduceCORE_lt {
  ClauseAllocator& ca;
  reduceCORE_lt(ClauseAllocator& ca_) : ca(ca_) {}
  bool operator () (CRef x, CRef y) {
    if(ca[x].lbd() > ca[y].lbd()) return true;
    if(ca[x].lbd() < ca[y].lbd()) return false;    
    
    // Finally we can use old activity or size, we choose the last one
    
     return ca[x].size() > ca[y].size();
    }
};

void Solver::reduceDB_core()
{
    int     i, j;
    //if (local_learnts_dirty) cleanLearnts(learnts_local, LOCAL);
    //local_learnts_dirty = false;
    // printf("c caSize: %d, caWasted: %d (%4.3f), nbCORE: %d, nbTIER2: %d, conflicts: %llu, hardConfl: %llu\n",
    // 	   ca.size(), ca.wasted(), (float)ca.wasted()/ca.size(), learnts_core.size(), learnts_tier2.size(), conflicts, conflicts-softConflicts); 
    
    sort(learnts_core, reduceCORE_lt(ca));
 
    int limit = learnts_core.size() / 2;
    int totalLocalSize=0, removedSize=0;
    //int cut = (core_lbd_cut == 3) ? 3 : 4;

    // int meanSize;
    // for (i = 0; i < learnts_core.size(); i++){
    //   Clause& c = ca[learnts_core[i]];
    //   totalLocalSize += c.size();
    // }
    // if (i>0)
    //   meanSize = totalLocalSize/i;
    // else meanSize = 0;
    
    //  printf("\n conflicts: %llu, core: %d, \n", conflicts, learnts_core.size());
    for (i = j = 0; i < learnts_core.size(); i++){
        Clause& c = ca[learnts_core[i]];
	//	totalLocalSize += c.size();
        if (c.mark() == CORE)
	  if ( i < limit && c.lbd() > 2 && c.touched() + coreInactiveLimit < conflicts) {
	    learnts_tier2.push(learnts_core[i]);
	    c.mark(TIER2);
	    
	    //  printf("i: %d, lbd: %d, touched: %u\n", i, c.lbd(), c.touched());
	  }
	  else{
	    // if (!c.removable()) limit++;
	    //c.removable(true);
	    learnts_core[j++] = learnts_core[i];
	  }
    }
    learnts_core.shrink(i - j);
    // printf("c removedSize: %d(%4.2f), over totalCoreSize: %d (%4.2f), NBremoved: %d, over nbCoreBefore: %d\n",
    // 	   removedSize, (float)removedSize/(i-j> 0 ? i-j : 1), totalLocalSize, (float)totalLocalSize/i, i-j, i);
    // printf("c %d ca size: %d, ca wasted: %d (%4.3f)\n\n",
    // 	   nbClauseReduce, ca.size(), ca.wasted(), (float)ca.wasted()/ca.size());

       // printf("core: %d, last: %u, lastlbd: %d, core_lbd_cut: %d\n\n",
       // 	  learnts_core.size(), ca[learnts_core.last()].touched(),
       // 	      ca[learnts_core.last()].lbd(), core_lbd_cut);
}


void Solver::removeSatisfied(vec<CRef>& cs)
{
    int i, j;
    for (i = j = 0; i < cs.size(); i++){
        Clause& c = ca[cs[i]];
        if(c.mark()!=1){
            if (satisfied(c))
                removeClause(cs[i]);
            else
                cs[j++] = cs[i];
        }
    }
    cs.shrink(i - j);
}

void Solver::safeRemoveSatisfied(vec<CRef>& cs, unsigned valid_mark)
{
    int i, j;
    for (i = j = 0; i < cs.size(); i++){
        Clause& c = ca[cs[i]];
        if (c.mark() == valid_mark)
            if (satisfied(c))
                removeClause(cs[i]);
            else
                cs[j++] = cs[i];
    }
    cs.shrink(i - j);
}

void Solver::rebuildOrderHeap()
{
    vec<Var> vs;
    for (Var v = 0; v < nVars(); v++)
        if (decision[v] && value(v) == l_Undef)
            vs.push(v);
    
    order_heap_CHB  .build(vs);
    order_heap_VSIDS.build(vs);
    order_heap_distance.build(vs);

    vs.clear();
    for (Var v = 0; v < nVars(); v++)
      if (value(v) == l_Undef && auxiVar(v))
	vs.push(v);
    orderHeapAuxi.build(vs);
}


/*_________________________________________________________________________________________________
 |
 |  simplify : [void]  ->  [bool]
 |
 |  Description:
 |    Simplify the clause database according to the current top-level assigment. Currently, the only
 |    thing done here is the removal of satisfied clauses, but more things can be put here.
 |________________________________________________________________________________________________@*/
bool Solver::simplify(bool simplifyOriginal)
{
    assert(decisionLevel() == 0);
    
    if (!ok || propagate() != CRef_Undef)
        return ok = false;
    
    if (nAssigns() == simpDB_assigns || (simpDB_props > 0))
        return true;
    
    // Remove satisfied clauses:
    removeSatisfied(learnts_core); // Should clean core first.
    safeRemoveSatisfied(learnts_tier2, TIER2);
    safeRemoveSatisfied(learnts_local, LOCAL);
    if (simplifyOriginal)        // Can be turned off.
        removeSatisfied(clauses);
    //  removeSoftSatisfied(softClauses);
    checkGarbage();
    rebuildOrderHeap();
    
    simpDB_assigns = nAssigns();
    simpDB_props   = clauses_literals + learnts_literals;   // (shouldn't depend on stats really, but it will do for now)
    
    return true;
}

// pathCs[k] is the number of variables assigned at level k,
// it is initialized to 0 at the begining and reset to 0 after the function execution
bool Solver::collectFirstUIP(CRef confl){
  // for(int i = 0; i<=decisionLevel(); i++)
  //   assert(pathCs[i] == 0);
  // for(int i=0; i<trail.size(); i++)
  //   if (level(var(trail[i])) > 0)
  //     assert(seen[var(trail[i])] == 0);
  //  counter++; vec<Var> myVars, myVars2; myVars.clear(), myVars2.clear();
  
    involved_lits.clear();
    int max_level=1;
    Clause& c=ca[confl]; int minLevel=decisionLevel();
    for(int i=0; i<c.size(); i++) {
        Var v=var(c[i]);
        //        assert(!seen[v]);
        if (level(v)>0) {
            seen[v]=1;
            var_iLevel_tmp[v]=1;
            pathCs[level(v)]++;
	    
	    // if (level(v) == 40  && conflicts == 458) {
	    //   seen2[v]=counter; myVars.push(v); }
	    
            if (minLevel>level(v)) {
                minLevel=level(v);
                assert(minLevel>0);
            }
            //    varBumpActivity(v);
        }
    }
    int limit=trail_lim[minLevel-1];
    for(int i=trail.size()-1; i>=limit; i--) {
        Lit p=trail[i]; Var v=var(p);
        if (seen[v]) {
            int currentDecLevel=level(v);
            //      if (currentDecLevel==decisionLevel())
            //      	varBumpActivity(v);
            seen[v]=0;
            if (--pathCs[currentDecLevel]!=0) {
	      
	      // if (currentDecLevel == 40 && conflicts == 458)
	      // 	myVars2.push(v);
	      
	      // if (currentDecLevel == 40 && pathCs[currentDecLevel] == 1 && conflicts == 458) {
	      // 	for(int ii=0; ii<i; ii++)
	      // 	  if (seen2[var(trail[ii])] == counter)
	      // 	    printf("**** ii: %d v: %d****\n", ii, var(trail[ii]));
	      // 	for(int ii=0; ii<myVars.size(); ii++)
	      // 	  printf("*%d %d*", myVars[ii], level(myVars[ii]));
	      // 	printf("\n nb vars: %d\n\n", myVars.size());

	      // 	for(int ii=0; ii<myVars2.size(); ii++)
	      // 	  printf("*%d %d*", myVars2[ii], level(myVars2[ii]));
	      // 	printf("\n nb vars2: %d\n\n", myVars2.size());

	      // 	assert(myVars2.size() == myVars.size());
	      // }
	      
                Clause& rc=ca[reason(v)];
                int reasonVarLevel=var_iLevel_tmp[v]+1;
                if(reasonVarLevel>max_level) max_level=reasonVarLevel;
                if (rc.size()==2 && value(rc[0])==l_False) {
                    // Special case for binary clauses
                    // The first one has to be SAT
                    assert(value(rc[1]) != l_False);
                    Lit tmp = rc[0];
                    rc[0] =  rc[1], rc[1] = tmp;
                }
                for (int j = 1; j < rc.size(); j++){
                    Lit q = rc[j]; Var v1=var(q);
                    if (level(v1) > 0) {
                        if (minLevel>level(v1)) {
                            minLevel=level(v1); limit=trail_lim[minLevel-1]; 	assert(minLevel>0);
                        }
                        if (seen[v1]) {
                            if (var_iLevel_tmp[v1]<reasonVarLevel)
                                var_iLevel_tmp[v1]=reasonVarLevel;
                        }
                        else {
                            var_iLevel_tmp[v1]=reasonVarLevel;
                            //   varBumpActivity(v1);
                            seen[v1] = 1;
                            pathCs[level(v1)]++;
			    
			    // if (level(v1) == 40  && conflicts == 458) {
			    //   seen2[v1]=counter; myVars.push(v1); }
			    
                        }
                    }
                }
            }
            involved_lits.push(p);
        }
    }
    double inc=var_iLevel_inc;
    vec<int> level_incs; level_incs.clear();
    for(int i=0;i<max_level;i++){
        level_incs.push(inc);
        inc = inc/my_var_decay;
    }

    for(int i=0;i<involved_lits.size();i++){
        Var v =var(involved_lits[i]);
        //        double old_act=activity_distance[v];
        //        activity_distance[v] +=var_iLevel_inc * var_iLevel_tmp[v];
        activity_distance[v]+=var_iLevel_tmp[v]*level_incs[var_iLevel_tmp[v]-1];

        if(activity_distance[v]>1e100){
            for(int vv=0;vv<nVars();vv++)
                activity_distance[vv] *= 1e-100;
            var_iLevel_inc*=1e-100;
            for(int j=0; j<max_level; j++) level_incs[j]*=1e-100;
        }
        if (order_heap_distance.inHeap(v))
            order_heap_distance.decrease(v);

        //        var_iLevel_inc *= (1 / my_var_decay);
    }
    var_iLevel_inc=level_incs[level_incs.size()-1];
    return true;
}

CRef Solver::lPropagate() {
  CRef confl =  propagate();
  if (confl != CRef_Undef || softConflictFlag)
    return confl;
  if (UB > 1 && UB == falseLits.size() + 1 && decisionLevel() < hardenLevel) {
      harden();
      confl =  propagate();
  }
  else if (decisionLevel() < hardenLevel)
    hardenLevel = INT32_MAX;
  
  return confl;
}

int Solver::setCounter(CRef cr) {
  int j, k;
  Clause& c=ca[cr];
  counter++;
  for(j=0, k=0; j<c.size(); j++) {
    if (value(c[j]) == l_Undef) {
      seen2[toInt(c[j])] = counter;
      c[k++] = c[j];
    }
  }
  c.shrink(j-k);
  return k;
}

// return the number of literals whose seen2 is equal to counter, i.e. in the previous intersection.
// The seen2 of these literals are incremented for the next iterations
// nb is the number of literals in the new intersection whose seen2 is equal tp the new counter
int Solver::countCommunLiterals(CRef cr) {
  int i, j, nb=0;
  Clause& c=ca[cr];
  for(i=0,j=0; i<c.size(); i++) {
    if (value(c[i]) == l_Undef) {
      if (seen2[toInt(c[i])] == counter) {
	seen2[toInt(c[i])]++;
	nb++;
      }
      c[j++] = c[i];
    }
    else assert(i>1);
  }
  c.shrink(i-j);
  counter++;
  return nb;
}


void Solver::splitClauses(vec<CRef>& cs) {
  vec<Lit> communLits;
  communLits.clear();
  CRef cr=cs[0];
  Clause& c=ca[cr];
  int lbd = c.lbd();
  for(int i=0; i<c.size(); i++) 
    if (seen2[toInt(c[i])] == counter) {
      communLits.push(c[i]);
    }
  Var v = newAuxiVar();
  Lit p = mkLit(v);

  int a, b, clauseType = LOCAL;
  bool toAttache;
  for(int i=0; i<cs.size(); i++) {
    CRef cr1=cs[i]; 
    Clause& c1 = ca[cr1];
    if (lbd > c1.lbd()) lbd = c1.lbd();
    assert(c1.mark() != 1);
    if (c1.mark() == CORE)
      clauseType = CORE;
    else if (c1.mark() == TIER2 && clauseType == LOCAL)
      clauseType = TIER2;
    
    if (seen2[toInt(c1[0])] == counter || seen2[toInt(c1[1])] == counter) {
      detachClause(cr1, true); toAttache=true;
    }
    else toAttache=false;
    
    //   detachClause(cr1, true);
    // int k=0;
    // for(a=0; a<c1.size(); a++) {
    //   if (seen2[toInt(c1[a])] == counter) 
    // 	k++;
    // }
    // if (communLits.size() != k) {
    //   for(int aa=0; aa<c1.size(); aa++)
    // 	if (seen2[toInt(c1[aa])] == counter)
    // 	  printf("%d %llu, ", toInt(c1[aa]), seen2[toInt(c1[aa])]);
    //   printf("\n");
    //   for(int aa=0; aa<communLits.size(); aa++)
    // 	printf("%d %llu, ", toInt(communLits[aa]), seen2[toInt(communLits[aa])]);
    //   printf("****%d %d %d %d, ****\n\n", communLits.size(), k, i, cs.size());
    // }
 
    int k=0;
    for(a=0, b=0; a<c1.size(); a++) {
      if (seen2[toInt(c1[a])] == counter) {
	k++;
      }
      else c1[b++] = c1[a];
    }
    assert(communLits.size() == k);
    assert(b<c1.size() && a>b && a == c1.size());
    
    c1[b++] = ~p;
    c1.shrink(a-b);
    if (b<=1)
      printf("%d, %d, %d, %d, %d\n", b, k, communLits.size(), cs.size(), i);
    assert(b>1);
    if (toAttache)
      attachClause(cr1);
  }

  communLits.push(p);
  CRef cr2 = ca.alloc(communLits, true);
  attachClause(cr2); ca[cr2].mark(clauseType); ca[cr2].set_lbd(lbd);
  if (clauseType == CORE) {
    learnts_core.push(cr2); ca[cr2].touched() = conflicts;
  }
  else if (clauseType == TIER2) {
    learnts_tier2.push(cr2);  ca[cr2].touched() = conflicts;
  }
  else {
    learnts_local.push(cr2); claBumpActivity(ca[cr2]);
  }
  watches.cleanAll();
  watches_bin.cleanAll();

  nbSavedLits += cs.size() * (communLits.size() - 1) - (communLits.size() + 1);
  // printf("communLits: %d, nbCls: %d\n", communLits.size()-1, cs.size());
}

#define splitClauseSize 20
#define limitOfNbClausesToSplit 4

void Solver::identifyClausesToSplit(vec<CRef>& cs) {
  int i=0, j;
  vec<CRef> toSplit;

  removeSatisfied(cs); 

  while (i<cs.size()) {
    CRef cr=cs[i];
    if (ca[cr].size() < splitClauseSize) {
      i++;
      continue;
    }
    toSplit.clear();
    int nbCommunLits = setCounter(cr), minSize=ca[cr].size();
    toSplit.push(cr);
    for(j=i+1; j<cs.size() && 2*nbCommunLits >= UB; j++) {
      CRef cr1 = cs[j];
      int oldMinSize = minSize, oldnbCommunLits = nbCommunLits;
      if (ca[cr1].size() < splitClauseSize)
	continue;
      if (ca[cr1].size() < minSize)
	minSize = ca[cr1].size();
      // intersection
      nbCommunLits = countCommunLiterals(cr1);
      if (nbCommunLits == ca[cr1].size()) {
	//	printf("removed %d clauses\n", toSplit.size());
	for(int a=0; a<toSplit.size(); a++)
	  removeClause(toSplit[a]);
	toSplit.clear();
	break;
      }
      else if (nbCommunLits == ca[cr].size()) {
	removeClause(cr1);
	continue;
      }
      if ( 2*nbCommunLits >= minSize )
	toSplit.push(cr1);
      else {
	//remove the last intersection 
	Clause& c=ca[cr1];
	for(int a=0; a<c.size(); a++) {
	  if (seen2[toInt(c[a])] == counter)
	    seen2[toInt(c[a])]--;
	}
	counter--;
	minSize = oldMinSize; nbCommunLits = oldnbCommunLits;
	break;
      }
    }
    i=j;
    //|| (toSplit.size()>1 && nbCommunLits +1 == minSize))
    if (toSplit.size()>limitOfNbClausesToSplit)
      splitClauses(toSplit);
    // printf("communLits: %d, nbCls: %d, minSize: %d, Leanrts %d\n",
    //	   nbCommunLits, toSplit.size(), minSize, cs.size());
  }
  // printf(" ----------------- starts: %llu, UB: %llu\n", starts, UB);
}

void Solver::hardenForRestart(int nbIsets, int trailRecord) {
  Var vv;
  printf("c harden from start...\n");
  hardenEnable = false;
  if (nbIsets == NON) {
    vv = simplePickAuxiVar();
    while (vv != var_Undef) {
      hardenEnable = true;
      uncheckedEnqueue(softLits[vv]);
      fixedByHardens++;
      vv = simplePickAuxiVar();
      //  printf("level 0: %d", level(vv));
    }
  }
  else {
    vec<Lit> toHarden;
    toHarden.clear();
    for(int i=trailRecord; i< trail.size(); i++) {
      Var v=var(trail[i]);
      assigns[v] = l_Undef;
      if (auxiVar(v)) {
	assert(v>=0 && v<activityLB.size());
	activityLB[v] = (1-stepSizeLB)*activityLB[v];
	insertAuxiVarOrder(v);
	orderHeapAuxi.decrease(v);
	if (inConflicts[v] == NON)
	  toHarden.push(trail[i]);
      }
    }
    trail.shrink(trail.size() - trailRecord);
    qhead = trailRecord;
    //   trail_lim.shrink(1);
    //   resetConflicts(nbIsets);
    bumpConflVars(); //the score of confl vars and non-confl vars is updated differently
    
    if (toHarden.size() == 0)
      return;
    hardenEnable = true;
    for(int i=0; i<toHarden.size(); i++) {
      Lit p = toHarden[i];
      uncheckedEnqueue(p);
      fixedByHardens++; fixedByQuasiConfl++;
    }
  }
}

void Solver::simplelookback(CRef confl, Var falseVar, vec<Lit>& lits, vec<Lit>& out_learnt) {
  int pathC=0;
  out_learnt.clear(); lits.clear();
  if (confl == CRef_Bin) {
    assert(level(var(binConfl[0])) > decisionLevel());
    assert(level(var(binConfl[1])) > decisionLevel());
    seen[var(binConfl[0])] = 1; seen[var(binConfl[1])] = 1;  pathC = 2;
  }
  else {
    Clause& c = ca[confl];
    if (falseVar != var_Undef) {
      if (c.size() == 2 && value(c[0]) == l_False) {
	// Special case for binary clauses: the first one has to be SAT
	assert(value(c[1]) == l_True);
	Lit tmp = c[0];
	c[0] = c[1]; c[1]=tmp;
      }
      assert(!seen[falseVar] && level(falseVar) > decisionLevel());
      out_learnt.push(~softLits[falseVar]); lits.push(~softLits[falseVar]);
    }
    for(int i=(falseVar == var_Undef ? 0 : 1); i<c.size(); i++) {
      Lit q=c[i]; Var v = var(q);
      if (level(v) > 0 && !seen[v]) {
	seen[v]=1;
	if (level(v) > decisionLevel())
	  pathC++;
      }
    }
  }
  int index = trail.size() - 1;
  while (index >= trailRecord) {
    Lit p = trail[index--]; Var v = var(p);
    if (seen[v]) {
      seen[v] = 0; pathC--;
      confl = reason(v);
      if (pathC == 0 && falseVar == var_Undef && lits.size() == 0) {
	out_learnt.push(~p);
	for(index = trail.size() - 1; index >= trailRecord; index--) {
	  Lit q = trail[index]; Var vv = var(q);
	  assert(!seen[vv]);
	  assigns[vv] = l_Undef;
	  if (auxiVar(vv))
	    insertAuxiVarOrder(vv);
	}
	qhead = trailRecord;
	trail.shrink(trail.size() - trailRecord);
	return;
      }
      if (confl == CRef_Undef) {
	lits.push(~p); out_learnt.push(~p);
      }
      else {
	Clause& rc = ca[confl];
	// Special case for binary clauses: the first one has to be SAT
	if (rc.size() == 2 && value(rc[0]) == l_False) {
	  assert(value(rc[1]) == l_True);
	  Lit tmp = rc[0];
	  rc[0] = rc[1], rc[1] = tmp;
	}
	for (int j = 1; j < rc.size(); j++){
	  Lit q = rc[j]; Var vv=var(q);
	  if (level(vv) > 0 && !seen[vv]) {
	    seen[vv] = 1;
	    if (level(vv) > decisionLevel())
	      pathC++;
	  }
	}
      }
    }
  }
}

int Solver::lookaheadForRestart() {
  int lb = UB-falseLits.size();
  if (lb==0) {
    return NON;
  }
  if (lb == 1) {
    if (!orderHeapAuxi.empty())
      hardenForRestart(NON, trail.size());
    return 0;
  }
  if (stepSizeLB > 0.06) stepSizeLB -= 0.000001;
  
  //  int baseLevel = decisionLevel();
  int nbConfl=0;
  trailRecord = trail.size(); 
  UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
  //  newDecisionLevel();
  lastConflLits.clear();
  for(int i=conflLits.size()-1; i>=0; i--)
    if  (conflLits[i] != lit_Undef)
      lastConflLits.push(conflLits[i]);
  for(int i=initConflLits.size()-1; i>=0; i--) {
    Lit p=initConflLits[i];
    if (p != lit_Undef)
      lastConflLits.push(p);
  }
  int nbIsets=0;
  vec<Lit> out_learnt, ps;
#ifdef printTestedVar
  printf("\n\nc **********lookahead: %llu, lb: %d, NbFalseLits: %d, thres: %d, UB: %llu\n", LOOKAHEAD, lb, falseLits.size(), thres, UB);
#endif

  int i, j;
  for(i=0, j=0; i<isetClauses.size(); i++) {
    Clause& c=ca[isetClauses[i]];
    if (c.mark() == LOCAL)
      removeClause(isetClauses[i]);
    else if (c.mark() != 1)
      isetClauses[j++] = isetClauses[i];
  }
  isetClauses.shrink(i-j);

  while (1) {
    Var v = pickAuxiVar();
    if (v == var_Undef)
      break;
#ifdef printTestedVar
    printf("c %d %10.9lf ", v, activityLB[v]);
#endif
    uncheckedEnqueueForLK(softLits[v]);
    CRef confl = propagateForLK();
    if (confl != CRef_Undef || falseVar != var_Undef) {
      isetsLits.init(nbIsets); isetsLits[nbIsets].clear();
      if (confl == CRef_Undef) {
	confl = reason(falseVar); isetsLits[nbIsets].push(softLits[falseVar]);
      }
      simplelookback(confl, falseVar, ps, out_learnt);
      if (ps.size() == 0 && out_learnt.size() == 1) {
      	Lit p=out_learnt[0];
      	printf("c ****unit iset %d\n", var(p));
	
      	resetConflicts_(nbIsets);
	//	bumpConflVars();
	isetsLits[nbIsets].clear(); nbConfl=0; nbIsets=0;
      	uncheckedEnqueue(p);
      	if (propagate() != CRef_Undef  || softConflictFlag==true) {
      	  return NON;
      	}
      	trailRecord = trail.size(); lb = UB-falseLits.size();
      	UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
      	lastConflLits.clear();
      	for(int i=conflLits.size()-1; i>=0; i--)
      	  if  (conflLits[i] != lit_Undef)
      	    lastConflLits.push(conflLits[i]);
      	for(int i=initConflLits.size()-1; i>=0; i--) {
      	  Lit p=initConflLits[i];
      	  if (p != lit_Undef)
      	    lastConflLits.push(p);
      	}
      	continue;
      }
      int nbSeen = 0, csize;
      if (confl == CRef_Bin) {
	csize=2;
	counter++;
	seen2[toInt(binConfl[0])] = counter; seen2[toInt(binConfl[1])] = counter;
      }
      else {
	Clause& c = ca[confl]; csize=c.size();
	if (falseVar != var_Undef && csize <= ps.size()) {
	  counter++;
	  for(int i=0; i<c.size(); i++)
	    seen2[toInt(c[i])] = counter;
	}
      }
      for(int i=0; i<ps.size(); i++)
	if (seen2[toInt(ps[i])] == counter)
	  nbSeen++;
      if (nbSeen < csize) {
	assert(ps.size() > 1);
	CRef cr=ca.alloc(ps, true);
	isetClauses.push(cr);
	attachClause(cr);
      }
      //	  else printf("q\n");
      //	else printf("nnn old %d new %d\n", saved, lits.size());
      lookbackResetTrail(confl, falseVar, nbIsets, out_learnt); nbConfl++;
      setConflict(nbIsets);
      falseVar = var_Undef;
      if (lb==nbConfl) {
	printf("c softConfl at top...\n");
#ifdef printTestedVar
	printf("c ====== maxSuccLB: %d\n", maxSuccLB);
#endif
	UBconflictFlag = true; softConflictFlag = true;
	//	trail_lim.shrink(1);
	nbLKsuccess++; totalPrunedLB += lb; totalPrunedLB2 += lb*lb;
	resetConflicts(nbIsets);
	bumpConflVars();
	return NON; 
      }
    }
  }
  assert(nbIsets == nbConfl);
  if (nbConfl == lb - 1) {
    printf("c quasi softConfl at top...\n");
    quasiSoftConflicts++;
    hardenForRestart(nbIsets, trailRecord);
  }
  else {
    for(int i=trailRecord; i< trail.size(); i++) {
      Var v=var(trail[i]);
      assigns[v] = l_Undef;
      if (auxiVar(v)) {
	assert(v>=0 && v<activityLB.size());
	activityLB[v] = (1-stepSizeLB)*activityLB[v];
	insertAuxiVarOrder(v);
	orderHeapAuxi.decrease(v);
      }
    }
    trail.shrink(trail.size() - trailRecord);
    qhead = trailRecord;
    //   trail_lim.shrink(1);
    //   resetConflicts(nbIsets);
    bumpConflVars(); //the score of confl vars and non-confl vars is updated differently
  }
  for(int i=0; i<involvedLits.size(); i++) {
    involved[var(involvedLits[i])] = 0;
  }
  involvedLits.clear();
  return nbIsets;
}

double Solver::avgAct(vec<CRef>& cs, int& nb0) {
  double act=0;
  nb0=0;
  for(int i=0; i<cs.size(); i++) {
    if (ca[cs[i]].activity() == 0)
      nb0++;
    else act += ca[cs[i]].activity();
  }
  if (act>0)
    return act/cs.size();
  else return 0;
}

/*_________________________________________________________________________________________________
 |
 |  search : (nof_conflicts : int) (params : const SearchParams&)  ->  [lbool]
 |
 |  Description:
 |    Search for a model the specified number of conflicts.
 |
 |  Output:
 |    'l_True' if a partial assigment that is consistent with respect to the clauseset is found. If
 |    all variables are decision variables, this means that the clause set is satisfiable. 'l_False'
 |    if the clause set is unsatisfiable. 'l_Undef' if the bound on number of conflicts is reached.
 |________________________________________________________________________________________________@*/
lbool Solver::search(int& nof_conflicts)
{
    assert(ok);
    int         backtrack_level;
    int         lbd, savedRootNbIsets;
    vec<Lit>    learnt_clause;
    bool        cached = false;
    
    static uint64_t prevUB=0;
    starts++;

    // if (starts > 440)
    //   printf("starts %llu, level %d, falseLits %d\n", starts, decisionLevel(), falseLits.size());

    if (propagate() != CRef_Undef || softConflictFlag)
      return l_False;
    // conflLits.copyTo(initConflLits);
    
    // if (learnts_core.size() > 453 && learnts_core[453] == 2809576)
    //   printf("\n\n***** %llu, %llu *****\n\n", conflicts, starts);

    // if (starts == 57)
    //   printf("*****starts 57, learnts_core %d\n", learnts_core.size() );

    if (prevUB > UB) {
      //   printf("prevUB %llu, UB %llu\n", prevUB, UB);
      // prevUB = UB;
      // for (int ci=0; ci < learnts_local.size(); ci++) {
      // 	if (learnts_local[ci] == 2809576)
      // 	  printf("\n\n***** %llu, %llu *****\n\n", conflicts, starts);
      // 	removeClause(learnts_local[ci]);
      // }
      // learnts_local.clear();
	      
      for (int ci=0; ci < cardinalityC.size(); ci++)
    	removeClause(cardinalityC[ci]);
      cardinalityC.clear();

      for (int ci=0; ci < hardens.size(); ci++)
      	removeClause(hardens[ci]);
      hardens.clear();
      		  
      watches.cleanAll();
      watches_bin.cleanAll();
      checkGarbage();
    }
    // else if (prevUB < UB) {
    //   //  printf("--- prevUB %llu, UB %llu\n", prevUB, UB);
    //    prevUB = UB;
    // }
    
    // else {
    //   int nb0Card;
    //   double actCard = avgAct(cardinalityC, nb0Card);
    //   int nb0Core;
    //   double actCore = avgAct(learnts_core, nb0Core);
    //   int nb0Tier2;
    //   double actTier2 = avgAct(learnts_tier2, nb0Tier2);
    //   int nb0Local;
    //   double actLocal = avgAct(learnts_local, nb0Local);

    //   int nb0Harden;
    //   double actHarden = avgAct(hardens, nb0Harden);

    //   int nb0IsetClause;
    //   double actIsetClause = avgAct(isetClauses, nb0IsetClause);
      
    //   printf("nbCard %d, nb0 %d, actCard %lf;   nbCore %d, nb0 %d, actCore %lf;   actCard-actCore = %lf\n",
    // 	     cardinalityC.size(), nb0Card, actCard, learnts_core.size(), nb0Core, actCore, actCard - actCore);
      
    //   printf("nbTier2 %d, nb0 %d, actTier2 %lf;   nbLocal %d, nb0 %d, actLocal %lf;   cla_inc %lf\n",
    // 	     learnts_tier2.size(), nb0Tier2, actTier2, learnts_local.size(), nb0Local, actLocal, cla_inc);

    //   printf("nbHarden %d, nb0 %d, actHarden %lf;   nbIsetClauses %d, nb0 %d, actIsetClause %lf\n\n",
    // 	     hardens.size(), nb0Harden, actHarden, isetClauses.size(), nb0IsetClause, actIsetClause);
    // }
      
      

    // if (allSoftLits.size() <= 100)
      addCardinalityConstraints();
    
    // simplify, rootNbIsets can be decreased in the clause simplification
    //
    if (subconflicts >= curSimplify * nbconfbeforesimplify){
	// if (starts == 444)
	//   printf("beforeLH: starts %llu, level %d, falseLits %d, trail %d\n",
	// 	 starts, decisionLevel(), falseLits.size(), trail.size());
	rootNbIsets=lookaheadForRestart();
	//	printf("c ****root isets %d, UB %llu, conflLits %d\n", rootNbIsets, UB, conflLits.size());
	bool toSimplify;
	if (qhead < trail.size())
	  toSimplify=false;
	else toSimplify=true;
	  
	if (rootNbIsets == NON ||
	    (qhead < trail.size() && (propagate() != CRef_Undef || softConflictFlag))) {
	  resetConflicts(rootNbIsets); rootNbIsets=0;
	  return l_False;
	}
	savedRootNbIsets = rootNbIsets;
    	// printf("c ### simplifyAll %llu on conflict : %lld and restart: %lld\n",  nbSimplifyAll, conflicts, starts);
	// if (starts == 444)
	//   printf("beforeSimp: starts %llu, level %d, falseLits %d, trail %d\n",
	// 	 starts, decisionLevel(), falseLits.size(), trail.size());
        if (toSimplify) {
	  for(int c = unLockedVars.size()-1; c >= 0; c--) {
	    Var x = unLockedVars[c];
	    incrementIsetLock(inConflicts[x]);
	  }
	  unLockedVars.shrink(unLockedVars.size());
	  nbSimplifyAll++;
	  if (!simplifyAll()) {
	    resetConflicts(savedRootNbIsets);
            return l_False;
	  }
	  curSimplify = (subconflicts / nbconfbeforesimplify) + 1;
	  nbconfbeforesimplify += incSimplify;
	}
	resetConflicts(savedRootNbIsets);
	rootNbIsets=0;
    }

    prevUB = UB;

    // if (UB>=20) {
    //   //  printf("soft learnt splitting...\n");
    //   if (softLearnts.size() > limitOfNbClausesToSplit)
    // 	identifyClausesToSplit(softLearnts);
    //   // printf("hard learnt splitting...\n");
    //   if (hardLearnts.size() > limitOfNbClausesToSplit)
    // 	identifyClausesToSplit(hardLearnts);
    // }

    hardenLevel = INT32_MAX; softLearnts.clear(); hardLearnts.clear();

    // if (starts == 444)
    //   printf("confl %llu, falseLits: %d, level %d+++\n", conflicts, falseLits.size(), decisionLevel());
    
    for (;;){
        CRef confl = lPropagate();
        
        if (confl != CRef_Undef || softConflictFlag || !lookahead()){

	  if (confl == CRef_Undef && !softConflictFlag) {
	    assert(LHconfl != CRef_Undef);
	    confl=LHconfl;
	  }
            // CONFLICT
            if (VSIDS){
                if (--timer == 0 && var_decay < 0.95) timer = 5000, var_decay += 0.01;
            }else
                if (step_size > min_step_size) step_size -= step_size_dec;
            
            conflicts++; nof_conflicts--; subconflicts++;
            // if (conflicts == 100000 && learnts_core.size() < 100) {
	    //   core_lbd_cut = 6; tier2_lbd_cut = 8;
	    // }
            if (decisionLevel() == 0) return l_False;
            
            learnt_clause.clear();

	    // if(subconflicts>10000) DISTANCE=0;
            // else DISTANCE=1;
            // if(VSIDS && DISTANCE && !softConflictFlag)
	    //   collectFirstUIP(confl);

	    DISTANCE=0;

	    softLearnt = false;
            if (softConflictFlag) {
	      softConflicts++;
	      analyzeSoftConflict(learnt_clause, backtrack_level, lbd);
	      softConflictFlag = false; softLearnt = true;
	    }
	    else
	      analyze(confl, learnt_clause, backtrack_level, lbd);
            cancelUntil(backtrack_level);
	    if (backtrack_level == 0 && learnt_clause.size()==0) return l_False;
            
            lbd--;
            if (VSIDS){
                cached = false;
                conflicts_VSIDS++;
                lbd_queue.push(lbd);
                global_lbd_sum += (lbd > 50 ? 50 : lbd); }
            
            if (learnt_clause.size() == 1){
                uncheckedEnqueue(learnt_clause[0]);
            }else{
                CRef cr = ca.alloc(learnt_clause, true);
		if (learnt_clause.size() > splitClauseSize && lbd<=tier2_lbd_cut) {
		  if (softLearnt)
		    softLearnts.push(cr);
		  else  hardLearnts.push(cr);
		}
                ca[cr].set_lbd(lbd);
                if (lbd <= core_lbd_cut){
                    learnts_core.push(cr);
                    ca[cr].mark(CORE);
		    ca[cr].touched() = conflicts;
                }else if (lbd <= tier2_lbd_cut){
                    learnts_tier2.push(cr);
                    ca[cr].mark(TIER2);
                    ca[cr].touched() = conflicts;
                }else{
		  learnts_local.push(cr); }
		claBumpActivity(ca[cr]);
                attachClause(cr);
                uncheckedEnqueue(learnt_clause[0], cr);
            }
            if (drup_file){
#ifdef BIN_DRUP
                binDRUP('a', learnt_clause, drup_file);
#else
                for (int i = 0; i < learnt_clause.size(); i++)
                    fprintf(drup_file, "%i ", (var(learnt_clause[i]) + 1) * (-2 * sign(learnt_clause[i]) + 1));
                fprintf(drup_file, "0\n");
#endif
            }
            
            if (VSIDS) varDecayActivity();
            claDecayActivity();
            
            /*if (--learntsize_adjust_cnt == 0){
             learntsize_adjust_confl *= learntsize_adjust_inc;
             learntsize_adjust_cnt    = (int)learntsize_adjust_confl;
             max_learnts             *= learntsize_inc;
             
             if (verbosity >= 1)
             printf("c | %9d | %7d %8d %8d | %8d %8d %6.0f | %6.3f %% |\n",
             (int)conflicts,
             (int)dec_vars - (trail_lim.size() == 0 ? trail.size() : trail_lim[0]), nClauses(), (int)clauses_literals,
             (int)max_learnts, nLearnts(), (double)learnts_literals/nLearnts(), progressEstimate()*100);
             }*/
            
        }else{
	     if (qhead < trail.size())
	       continue;
            // NO CONFLICT
            bool restart = false;
            if (!VSIDS)
                restart = nof_conflicts <= 0;
            else if (!cached){
	      restart = (lbd_queue.full() && (lbd_queue.avg() * 0.8 > global_lbd_sum / conflicts_VSIDS)) || (nof_conflicts <= 0);
			 cached = true;
            }
            if (restart || !withinBudget()){
                lbd_queue.clear();
                cached = false;
                // Reached bound on number of conflicts:
                progress_estimate = progressEstimate();
                cancelUntil(0);
                return l_Undef; }
            
            // Simplify the set of problem clauses:
            if (decisionLevel() == 0 && !simplify())
                return l_False;
            
            if (learnts_tier2.size() >= tier2Limit){
	      // next_T2_reduce = subconflicts + 10000;
	      //	next_T2_reduce = conflicts + 10000 + 300*nbClauseReduce;;
                reduceDB_Tier2(); }
            if (subconflicts >= next_L_reduce){
	       next_L_reduce = subconflicts + 15000;
	      //next_L_reduce = conflicts + 15000+300*nbClauseReduce;
	      //nbClauseReduce++;
	      reduceDB(); }

	    if (learnts_core.size() >= coreLimit){
	      //next_L_reduce = conflicts + 15000;
	      coreLimit += coreLimit/10;
	      nbClauseReduce++;
	      reduceDB_core(); }
	    
            Lit next = lit_Undef;
            /*while (decisionLevel() < assumptions.size()){
             // Perform user provided assumption:
             Lit p = assumptions[decisionLevel()];
             if (value(p) == l_True){
             // Dummy decision level:
             newDecisionLevel();
             }else if (value(p) == l_False){
             analyzeFinal(~p, conflict);
             return l_False;
             }else{
             next = p;
             break;
             }
             }
             
             if (next == lit_Undef)*/
                // New variable decision:
	    decisions++;
	    next = pickBranchLit();
	    
	    if (next == lit_Undef) {
	      // better solution found
	      feasible = true;
	      assert(falseLits.size() < UB);
	      int nbFixeds = trail_lim.size() == 0 ? 0 : trail_lim[0];
	      int nbFalses = falseLits_lim.size() == 0 ? 0 : falseLits_lim[0];

	      float meanLB=0, dev=0, succRate=0;
	      if (nbLKsuccess>savednbLKsuccess) {
		meanLB= (float)totalPrunedLB/(nbLKsuccess-savednbLKsuccess);
		dev = sqrt((float)totalPrunedLB2/(nbLKsuccess-savednbLKsuccess) - meanLB*meanLB);
	      }
	      if (LOOKAHEAD > savedLOOKAHEAD) 
		succRate = (float) (nbLKsuccess-savednbLKsuccess)/(LOOKAHEAD-savedLOOKAHEAD);
	      
	      printf("c UB=%llu succs, confls=%llu, hconfls=%llu, core %d, tier2 %d, local %d,  %d soft cls unsat (%d at L0), %d fixed vars at L0, softCnfl %d, nbFlyRd %d, nbFixedLH %llu\n",
		     UB, conflicts, conflicts-softConflicts, learnts_core.size(), learnts_tier2.size(), learnts_local.size(),
		     falseLits.size(), nbFalses, nbFixeds, pureSoftConfl, nbFlyReduced, nbFixedByLH);

	      printf("c nbHardens %d (fixed %llu), shorten: %llu, prunedLB %4.2f, dev %4.2f, succRate %4.2f, nbSucc %llu, lk: %llu, shorten: %llu, quasiC: %llu (fixed: %llu)\n\n",
		     nbHardens, fixedByHardens, nbSavedLits, meanLB, dev, succRate, nbLKsuccess-savednbLKsuccess, LOOKAHEAD-savedLOOKAHEAD, nbSavedLits, quasiSoftConflicts, fixedByQuasiConfl);
	      totalPrunedLB=0; totalPrunedLB2=0; savedLOOKAHEAD = LOOKAHEAD; savednbLKsuccess=nbLKsuccess;
	      UB = falseLits.size();
	      checkSolution();
	      noteBestSolution(UB);
	      WithNewUB = true;
	    //  printf("c UB=%llu at conflicts=%llu and hard conflicts=%llu\n",
		//     UB, conflicts, conflicts-softConflicts);
	      model.growTo(nVars());
	      for (int i = 0; i < nVars(); i++) model[i] = value(i);
	      //  softConflictFlag=true;
	      if (UB==0)
		return l_True;
	      else if (infeasibleUB >= UB)
		return l_False;
	      cancelUntil(0);
	      return l_Undef;
	    }
	    else {
	      // Increase decision level and enqueue 'next'
	      falseLits_lim.push(falseLits.size());
	      //    unLockedVars_lim.push(unLockedVars.size());
	      //  assert(!auxiVar(var(next)));
	      newDecisionLevel();
	      uncheckedEnqueue(next);
	    }
	}
    }
}


double Solver::progressEstimate() const
{
    double  progress = 0;
    double  F = 1.0 / nVars();
    
    for (int i = 0; i <= decisionLevel(); i++){
        int beg = i == 0 ? 0 : trail_lim[i - 1];
        int end = i == decisionLevel() ? trail.size() : trail_lim[i];
        progress += pow(F, i) * (end - beg);
    }
    
    return progress / nVars();
}

/*
 Finite subsequences of the Luby-sequence:
 
 0: 1
 1: 1 1 2
 2: 1 1 2 1 1 2 4
 3: 1 1 2 1 1 2 4 1 1 2 1 1 2 4 8
 ...
 
 
 */

static double luby(double y, int x){
    
    // Find the finite subsequence that contains index 'x', and the
    // size of that subsequence:
    int size, seq;
    for (size = 1, seq = 0; size < x+1; seq++, size = 2*size+1);
    
    while (size-1 != x){
        size = (size-1)>>1;
        seq--;
        x = x % size;
    }
    
    return pow(y, seq);
}

bool Solver::uncheckedEnqueueForLK(Lit p, CRef from){
    assert(value(p) == l_Undef);
    Var v = var(p);
    assigns[v] = lbool(!sign(p)); // this makes a lbool object whose value is sign(p)
    // vardata[x] = mkVarData(from, decisionLevel());
    vardata[v].reason = from;
    vardata[v].level = decisionLevel() + 1;
    trail.push_(p);

    if (auxiVar(v) && value(softLits[v]) == l_False) {// a soft clause is falsified
      if (unLockedSoftVarForLK(v))
	return false;
      else {
	int iset = getLockedVarIsetForLK(v);
	decrmentIsetLock(iset);
	unLockedVars.push(v);
	if (getIsetLock(iset)==0) {
	  vec<int>& confls = isets[iset];
	  assert(iset == finalIset[iset]);
	  assert(iset < isets.size() && iset >=0 );
	  for(int j=0; j<confls.size(); j++) {
	    vec<Lit>& lits = isetsLits[confls[j]];
	    for(int i=0; i<lits.size(); i++) {
	       if (value(lits[i]) == l_Undef)
		insertAuxiVarOrder(var(lits[i]));
	    }
	  }
	}
      }
    }
    return true;
}

CRef Solver::propagateForLK() {
  falseVar = var_Undef;
  CRef    confl = CRef_Undef;
  int     num_props = 0;
  watches.cleanAll();
  watches_bin.cleanAll();
  while (qhead < trail.size()) {
    Lit            p = trail[qhead++];     // 'p' is enqueued fact to propagate.
    vec<Watcher>&  ws = watches[p];
    Watcher        *i, *j, *end;
    num_props++;
    // First, Propagate binary clauses
    vec<Watcher>&  wbin = watches_bin[p];
    
    for (int k = 0; k<wbin.size(); k++) {
      Lit imp = wbin[k].blocker;
      if (value(imp) == l_False) {
	binConfl[0] = ~p; binConfl[1]=imp;
	return CRef_Bin;
      }
      if (value(imp) == l_Undef) {
	if (!uncheckedEnqueueForLK(imp, wbin[k].cref)) {
	  falseVar = var(imp);
	  return CRef_Undef;
	}
      }
    }
    for (i = j = (Watcher*)ws, end = i + ws.size(); i != end;) {
	// Try to avoid inspecting the clause:
	Lit blocker = i->blocker;
	if (value(blocker) == l_True) {
	  *j++ = *i++; continue;
	}
	// Make sure the false literal is data[1]:
	CRef     cr = i->cref;
	Clause&  c = ca[cr];
	Lit      false_lit = ~p;
	if (c[0] == false_lit)
	  c[0] = c[1], c[1] = false_lit;
	assert(c[1] == false_lit);
	// If 0th watch is true, then clause is already satisfied.
	// However, 0th watch is not the blocker, make it blocker using a new watcher w
	// why not simply do i->blocker=first in this case?
	Lit     first = c[0];
	//  Watcher w     = Watcher(cr, first);
	if (first != blocker) {
	  i->blocker = first;
	  if (value(first) == l_True){
	    *j++ = *i++; continue;
	  }
	}
	assert(c.lastPoint() >=2);
	if (c.lastPoint() > c.size())
	  c.setLastPoint(2);
	for (int k = c.lastPoint(); k < c.size(); k++) {
	  if (value(c[k]) == l_Undef) {
	    // watcher i is abandonned using i++, because cr watches now ~c[k] instead of p
	    // the blocker is first in the watcher. However,
	    // the blocker in the corresponding watcher in ~first is not c[1]
	    //  Watcher w = Watcher(cr, first); i++;
	    c[1] = c[k]; c[k] = false_lit;
	    watches[~c[1]].push(*i++);
	    c.setLastPoint(k+1);
	    goto NextClause;
	  }
	  else if (value(c[k]) == l_True) {
	    i->blocker = c[k];  *j++ = *i++;
	    c.setLastPoint(k);
	    goto NextClause;
	  }
	}
	for (int k = 2; k < c.lastPoint(); k++) {
	  if (value(c[k]) ==  l_Undef) {
	    // watcher i is abandonned using i++, because cr watches now ~c[k] instead of p
	    // the blocker is first in the watcher. However,
	    // the blocker in the corresponding watcher in ~first is not c[1]
	    //   Watcher w = Watcher(cr, first); i++;
	    c[1] = c[k]; c[k] = false_lit;
	    watches[~c[1]].push(*i++);
	    c.setLastPoint(k+1);
	    goto NextClause;
	  }
	  else if (value(c[k]) == l_True) {
	    i->blocker = c[k];  *j++ = *i++;
	    c.setLastPoint(k);
	    goto NextClause;
	  }
	}
	// Did not find watch -- clause is unit under assignment:
	//	i->blocker = first;
	*j++ = *i++;
	if (value(first) == l_False) {
	  confl = cr;
	  qhead = trail.size();
	  // Copy the remaining watches:
	  while (i < end)
	    *j++ = *i++;
	}
	else {
	  if (!uncheckedEnqueueForLK(first, cr)) {
	    qhead = trail.size();
	    // Copy the remaining watches:
	    while (i < end)
	      *j++ = *i++;
	    falseVar = var(first);
	  }
	}
    NextClause:;
    }
    ws.shrink(i - j);
    // if (confl == CRef_Undef)
    // 	if (shortenSoftClauses(p))
    // 	  break;
  }
  lk_propagations += num_props;
  return confl;
}

int Solver::seeUnlockLits(int iset, int falseVar) {
  vec<int>& myInconfls = isets[iset];
  int nbfalse=0;
  for(int i=0; i<myInconfls.size(); i++) {
    vec<Lit>& lits = isetsLits[myInconfls[i]];
    for(int j=0; j<lits.size(); j++) {
      Var v=var(lits[j]);
      if (value(lits[j]) == l_False && level(v) > decisionLevel()
	  && falseVar != v && !seen[v]) {
	nbfalse++;
	seen[v] = 1;
      }
    }
  }
  // assert(nbfalse == myInconfls.size());
  return nbfalse;
}

void Solver::lookbackResetTrail(CRef confl, Var falseVar, int nbIsets, vec<Lit>& out_learnt, bool last) {
  int pathC=0;
  out_learnt.clear();
  out_learnt.push();
  if (confl == CRef_Bin) {
    assert(level(var(binConfl[0])) > decisionLevel());
    assert(level(var(binConfl[1])) > decisionLevel());
    seen[var(binConfl[0])] = 1; seen[var(binConfl[1])] = 1;  pathC = 2;
    if (VSIDS) {
      varBumpActivity(var(binConfl[0]), .1);
      varBumpActivity(var(binConfl[0]), .1);
    }
  }
  else {
    Clause& c = ca[confl];
    // if (!c.involved()) {
    //   involvedClauses.push(confl);
    //   c.setInvolved(1);
    // }
    if (falseVar != var_Undef) {
      if (c.size() == 2 && value(c[0]) == l_False) {
	// Special case for binary clauses: the first one has to be SAT
	assert(value(c[1]) == l_True);
	Lit tmp = c[0];
	c[0] = c[1]; c[1]=tmp;
      }
      if (inConflicts[falseVar] != NON)
	pathC += seeUnlockLits(getLockedVarIsetForLK(falseVar), falseVar);
      assert(!seen[falseVar] && level(falseVar) > decisionLevel());
      out_learnt.push(softLits[falseVar]);
    }
    for(int i=(falseVar == var_Undef ? 0 : 1); i<c.size(); i++) {
      Lit q=c[i]; Var v = var(q);
      if (level(v) > 0) {
	if (!seen[v]) {
	  seen[v]=1;
	  if (level(v) > decisionLevel())
	    pathC++;
	  else {
	    out_learnt.push(q);
	    if (!involved[var(q)]) {
	      involved[var(q)] = 1;
	      involvedLits.push(q);
	    }
	  }
	  if (VSIDS)
	    varBumpActivity(v, .1);
	}
      } 
    }
  }
  int index = trail.size() - 1;
  while (index >= trailRecord) {
    Lit p = trail[index--];
    Var v = var(p);
    if (seen[v]) {
      seen[v] = 0; pathC--;
      confl = reason(v);
      if (pathC == 0 && falseVar == var_Undef && isetsLits[nbIsets].size() == 0
	  && (!last || (auxiVar(var(p)) && inConflicts[var(p)] == NON && p == softLits[v]))) {
	//printf("y %u %d %d\n", confl, (auxiVar(v) ? toInt(value(softLits[v])) : -7), out_learnt.size());
	out_learnt[0] = ~p; assigns[v] = l_Undef;
	if (last && auxiVar(v) && inConflicts[v] == NON && p == softLits[v])
	  isetsLits[nbIsets].push(p);
	if (auxiVar(v))
	  insertAuxiVarOrder(v);
	for(; index >= trailRecord; index--) {
	  Lit q = trail[index];
	  Var vv = var(q);
	  assert(!seen[vv]);
	  assigns[vv] = l_Undef;
	  if (auxiVar(vv))
	    insertAuxiVarOrder(vv);
	}
	break;
      }
      if (confl == CRef_Undef) {
	isetsLits[nbIsets].push(p); out_learnt.push(~p);
	if (inConflicts[v] != NON)
	  pathC += seeUnlockLits(getLockedVarIsetForLK(v), falseVar);
      }
      else {
	if (auxiVar(v))
	  insertAuxiVarOrder(v);
	Clause& rc = ca[confl];
	// if (!rc.involved()) {
	//   involvedClauses.push(confl);
	//   rc.setInvolved(1);
	// }
	// Special case for binary clauses: the first one has to be SAT
	if (rc.size() == 2 && value(rc[0]) == l_False) {
	  assert(value(rc[1]) == l_True);
	  Lit tmp = rc[0];
	  rc[0] = rc[1], rc[1] = tmp;
	}
	int nbSeen=0;
	int resolventSize=pathC + out_learnt.size();
	for (int j = 1; j < rc.size(); j++){
	  Lit q = rc[j]; Var vv=var(q);
	  if (level(vv) > 0) {
	    if (seen[vv])
	      nbSeen++;
	    else {
	      seen[vv] = 1;
	      if (level(vv) > decisionLevel())
		pathC++;
	      else {
		out_learnt.push(q);
		if (!involved[var(q)]) {
		  involved[var(q)] = 1;
		  involvedLits.push(q);
		}
	      }
	      if (VSIDS)
		varBumpActivity(vv, .1);
	    }
	  }
	}
	if (nbSeen >= resolventSize) {
	  assert(falseVar==var_Undef);
	  reduceClause(confl, pathC);
	  //  printf("x\n");
	}
      }
    }
    else if (auxiVar(v))
      insertAuxiVarOrder(v);
    assigns[v] = l_Undef;
  }
  qhead = trailRecord;
  trail.shrink(trail.size() - trailRecord);
  //  if (isetsLits[nbIsets].size() > 0)
    for(int i=0; i<out_learnt.size(); i++)
      seen[var(out_learnt[i])] = 0;
}

void Solver::bumpConflVars() {
  for(int i=0; i<conflLits.size(); i++) {
    if (conflLits[i] != lit_Undef) {
      Var v = var(conflLits[i]);
      assert(v>=0 && v<activityLB.size());
      double oldAct = activityLB[v];
      // the two equations are equivalent, but the practical precision is different
      // activityLB[v] = stepSizeLB + (1-stepSizeLB)*oldAct;
      activityLB[v] = oldAct + (1-oldAct)*stepSizeLB; 
      insertAuxiVarOrder(v);
      assert(activityLB[v] >= oldAct);
      orderHeapAuxi.increase(v);
    }
  }
}

Var Solver::pickAuxiVar() {
  Var v = var_Undef;
  while(lastConflLits.size() > 0) {
    Lit p=lastConflLits[lastConflLits.size()-1];
    lastConflLits.shrink_(1);
    assert(auxiVar(var(p)));
    if (value(p) == l_Undef && unLockedSoftVarForLK(var(p)))
      return var(p);
  }
  while (v == var_Undef || value(v) != l_Undef || !unLockedSoftVarForLK(v)) {
    if (orderHeapAuxi.empty())
      return var_Undef;
    else {
      v = orderHeapAuxi.removeMin();
      assert(auxiVar(v));
    }
  }
  return v;
}

void Solver::setConflict(int& nbIsets) {
 for(int c = unLockedVars.size()-1; c >= 0; c--) {
    Var x = unLockedVars[c];
    incrementIsetLock(inConflicts[x]);
 }
 unLockedVars.shrink(unLockedVars.size());
  
  vec<int> oldset;
  int i, j, newlock = 1;
  oldset.clear();
  isets.init(nbIsets); isets[nbIsets].clear(); isets[nbIsets].push(nbIsets);
  for(i=0; i<=nbIsets; i++) seen[i]=0;
  finalIset.growTo(nbIsets+1); finalIset[nbIsets] = nbIsets;
  vec<Lit>& newlits = isetsLits[nbIsets]; // new inconsistent set of soft lits
  for(i=0, j=0; i<newlits.size(); i++) {
    Lit p = newlits[i];
    if (inConflicts[var(p)] == NON) {
      newlits[j++] = p; // we only keep the new involved lits in the set
      inConflicts[var(p)] = nbIsets;
    }
    else {
      int iset=getLockedVarIsetForLK(var(p));
      assert(iset<nbIsets && iset>=0);
      if (!seen[iset]) {
	newlock += getIsetLock(iset);
	vec<int>& myInconfls = isets[iset];
	assert(myInconfls.size() > 0);
	for(int k=0; k<myInconfls.size(); k++) {
	  int subIset=myInconfls[k];
	  assert(!seen[subIset]);
	  seen[subIset] = 1;
	  oldset.push(subIset);
	}
	assert(seen[iset]);
      }
    }
  }
  newlits.shrink(i-j);
  
  if (oldset.size() > 0) {
    vec<int>& myInconfls2 = isets[nbIsets];
    for(i=0; i<oldset.size(); i++) {
      int subIset = oldset[i];
      assert(seen[subIset]);
      myInconfls2.push(subIset);
      finalIset[subIset] = nbIsets;
      seen[subIset] = 0;
    }
    for(i=0; i<nbIsets; i++) assert(!seen[i]);
  }
  isetLock.growTo(nbIsets+1);  setIsetLock(nbIsets, newlock);
  nbIsets++;
}

void Solver::resetConflicts(int nbIsets) {
  unLockedVars.shrink(unLockedVars.size());

  conflLits.clear();
  for(int i=0; i<nbIsets; i++) {
    isetLock[i] = 0; finalIset[i] = NON;
    vec<Lit>& lits = isetsLits[i];
    for(int k=0; k<lits.size(); k++) {
      Lit p = lits[k];
      inConflicts[var(p)] = NON; 
      softVarLocked[var(p)] = 0;
      //  unlockReasonForLK[var(p)] = var_Undef;
      conflLits.push(p);
      insertAuxiVarOrder(var(p));
    }
  }
}

void Solver::resetConflicts_(int nbIsets) {
  unLockedVars.shrink(unLockedVars.size());

  for(int i=0; i<nbIsets; i++) {
    isetLock[i] = 0; finalIset[i] = NON;
    vec<Lit>& lits = isetsLits[i];
    for(int k=0; k<lits.size(); k++) {
      Lit p = lits[k];
      inConflicts[var(p)] = NON; 
      softVarLocked[var(p)] = 0;
      //  unlockReasonForLK[var(p)] = var_Undef;
      insertAuxiVarOrder(var(p));
    }
  }
}

Var Solver::simplePickAuxiVar() {
  Var v = var_Undef;
  while (v == var_Undef || value(v) != l_Undef ){ 
    if (orderHeapAuxi.empty())
      return var_Undef;
    else {
      v = orderHeapAuxi.removeMin();
      assert(auxiVar(v));
    }
  }
  return v;
}

void Solver::moreHarden() {
  // if (UB==2) return;
  int nbfixed=0;
  Var vv;
  nbHardens++;
  if (decisionLevel() == 0) {
    vv = simplePickAuxiVar();
    while (vv != var_Undef) {
      hardenEnable = true;
      uncheckedEnqueue(softLits[vv]);
      fixedByHardens++;
      vv = simplePickAuxiVar();
      //  printf("level 0: %d", level(vv));
    }
    //  printf("\n");
  }
  else {
    vv = simplePickAuxiVar();
    if (vv == var_Undef)
      return;
    assert(!softVarLocked[vv]);
    hardenEnable = true;
    // if (falseLits.size() > 0 && level(var(falseLits.last())) < decisionLevel()) {
    //   printf("****\n");
    //   cancelUntil(level(var(falseLits.last())));
    // }
    vec<Lit> ps;
    ps.clear();
    ps.push();
    int nbFalseLits=falseLits.size();
    counter++;
    for(int i=nbFalseLits-1; i>=0; i--) {
      Var v=var(falseLits[i]);
      if (level(v) > 0) {
  	ps.push(falseLits[i]); seen2[v] = counter;
      }
    }
    for(int i=nbFalseLits-1; i>=0; i--) {
      Var v=var(falseLits[i]);
      if (level(v) > 0 && inConflict[v] != NON) {
    	Var u = unlockReason[v];
    	assert(u != var_Undef);
    	if (level(u) > 0 && seen2[u] < counter) {
    	  seen2[u] = counter;
    	  assert(value(softLits[u]) == l_False);
    	  ps.push(softLits[u]);
    	}
      }
    }
    do {
      CRef cr = CRef_Undef;
      ps[0] = softLits[vv];
      assert(inConflict[vv] != NON);
      //    if (inConflict[vv] != NON) {
      Var u = unlockReason[vv];
      assert(u != var_Undef);
      assert(value(softLits[u]) == l_False);
      if (level(u) > 0 && seen2[u] < counter) {
	if (ps.size() > 1) {
	  Lit p2=ps[1];
	  if (level(u) > level(var(p2))) {
	    ps[1] = softLits[u]; ps.push(p2);
	    cr =ca.alloc(ps, true);
	    ps[1] = p2;
	  }
	  else {ps.push(softLits[u]);  cr =ca.alloc(ps, true);}
	}
	else {ps.push(softLits[u]);  cr =ca.alloc(ps, true);}
	ps.shrink(1);
      }
      else cr =ca.alloc(ps, true);
      hardens.push(cr);
      attachClause(cr);
      uncheckedEnqueue(ps[0], cr);
      // if (level(var(ps[0])) != level(var(ps[1])))
      //   printf("%d %d, decLevel: %d, ps: %d, c: %d, c[3]level: %d\n", level(var(ps[0])), level(var(ps[1])), decisionLevel(), ps.size(), ca[cr].size(), level(var(ca[cr][2])));
      assert( level(var(ca[cr][0])) == level(var(ca[cr][1])));
      fixedByHardens++; nbfixed++;
      //    }
      vv = simplePickAuxiVar();
    } while (vv != var_Undef);
    // printf("\n %d %llu\n", decisionLevel(), conflicts);
  }
  // printf("harden level %d, fixes %d, UB: %llu, hardens: %d\n", hardenLevel, nbfixed, UB, hardens.size());
}

void Solver::simplifyQuasiConflictClause(vec<Lit>& out_learnt, int& out_btlevel, int& out_lbd) {
      // Simplify conflict clause:
    int i, j;
    out_learnt.copyTo(analyze_toclear);
    if (ccmin_mode == 2){
        uint32_t abstract_level = 0;
        for (i = 1; i < out_learnt.size(); i++)
            abstract_level |= abstractLevel(var(out_learnt[i])); // (maintain an abstraction of levels involved in conflict)
        
        for (i = j = 1; i < out_learnt.size(); i++)
            if (reason(var(out_learnt[i])) == CRef_Undef || !litRedundant(out_learnt[i], abstract_level))
                out_learnt[j++] = out_learnt[i];
        
    }else if (ccmin_mode == 1){
        for (i = j = 1; i < out_learnt.size(); i++){
            Var x = var(out_learnt[i]);
            
            if (reason(x) == CRef_Undef)
                out_learnt[j++] = out_learnt[i];
            else{
                Clause& c = ca[reason(var(out_learnt[i]))];
                for (int k = c.size() == 2 ? 0 : 1; k < c.size(); k++)
                    if (!seen[var(c[k])] && level(var(c[k])) > 0){
                        out_learnt[j++] = out_learnt[i];
                        break; }
            }
        }
    }else
        i = j = out_learnt.size();
    
    max_literals += out_learnt.size();
    out_learnt.shrink(i - j);
    tot_literals += out_learnt.size();
    
    out_lbd = computeLBD(out_learnt);
    if (out_lbd <= tier2_lbd_cut && out_learnt.size() <= 35) // Try further minimization?
        if (binResMinimize(out_learnt))
            out_lbd = computeLBD(out_learnt); // Recompute LBD if minimized.
    
    // Find correct backtrack level:
    //
    if (out_learnt.size() == 1)
        out_btlevel = 0;
    else{
        int max_i = 1;
        // Find the first literal assigned at the next-highest level:
        for (int i = 2; i < out_learnt.size(); i++)
            if (level(var(out_learnt[i])) > level(var(out_learnt[max_i])))
                max_i = i;
        // Swap-in this literal at index 1:
        Lit p             = out_learnt[max_i];
        out_learnt[max_i] = out_learnt[1];
        out_learnt[1]     = p;
        out_btlevel       = level(var(p));
    }
    
    if (VSIDS){
       add_tmp.clear();
    }
    for (int j = 0; j < analyze_toclear.size(); j++) seen[var(analyze_toclear[j])] = 0;    // ('seen[]' is now cleared)
}

void Solver::analyzeQuasiSoftConflict(vec<Lit>& out_learnt, int& out_btlevel, int& out_lbd)
{
    int pathC = 0;
    Lit p;
    CRef confl;
    // Generate conflict clause:
    //
    out_learnt.push();      // (leave room for the asserting literal)
    int index   = trail.size() - 1;
    //   int saved = usedClauses.size();
    // The last falsified literal is fixed most recently
    assert(falseLits.size() >= UB || UBconflictFlag);
    int nbFalseLits;
    if (falseLits.size() > UB) {
      nbFalseLits = UB;
      falseLits.shrink(falseLits.size() - UB);
    }
    else nbFalseLits = falseLits.size();
    int maxConflLevel = (falseLits.size() > 0) ? level(var(falseLits[nbFalseLits-1])) : 0;
    int debutFalse = falseLits_lim.size() > 0 ? falseLits_lim[0] : falseLits.size();

    // if (constraintRelaxed)
    //   for(int a=debutFalse; a<nbFalseLits; a++) {
    // 	Var v=var(falseLits[a]);
    // 	if (inConflict[v] != NON) {
    // 	  Var u = unlockReason[v];
    // 	  assert(u != var_Undef);
    // 	  assert(level(u) <= maxConflLevel);
    // 	  if (!seen[u]) {
    // 	    seen[u] = 1;
    // 	    assert(value(softLits[u]) == l_False);
    // 	    falseLits.push(softLits[u]);
    // 	  }
    // 	}
    //   }
      
    if (UBconflictFlag) {
      // if (constraintRelaxed)
      // 	for(int a=0; a<conflLits.size(); a++) {
      // 	  p = conflLits[a];
      // 	  if (p !=lit_Undef) {
      // 	    Var v=var(p);
      // 	    if (inConflict[v] != NON) {
      // 	      Var u=unlockReason[v];
      // 	      //  assert(u != var_Undef);
      // 	      if (u != var_Undef && !seen[u]) {
      // 		seen[u] = 1;
      // 		assert(value(softLits[u]) == l_False);
      // 		falseLits.push(softLits[u]);
      // 		if (level(u) > maxConflLevel)
      // 		  maxConflLevel = level(u);
      // 	      }
      // 	    }
      // 	  }
      // 	}
      
     for(int i=0; i<involvedLits.size(); i++) { 
	Lit q = involvedLits[i]; Var v = var(q);
	involved[v] = 0;
	assert(level(v) > 0);
	if (!seen[v] && value(q) == l_False) {
	  seen[v] = 1;
	  falseLits.push(q);
	  if (level(v) > maxConflLevel)
	    maxConflLevel = level(v);
	}
      }
      involvedLits.clear();
    }
    
    for(int a=nbFalseLits; a<falseLits.size(); a++)
      seen[var(falseLits[a])] = 0;
    
    for(int a=debutFalse; a<falseLits.size(); a++) {
      Var v=var(falseLits[a]);
      if (!seen[v] && level(v) > 0) {// && !redundantLit(falseLits[a])) {
	seen[v] = 1;
	// if (VSIDS){
	//   varBumpActivity(v, .5);
	//   add_tmp.push(falseLits[a]);
	// }else
	//   conflicted[v]++;
	if (level(v) >= maxConflLevel)
	  pathC++;
	else
	  out_learnt.push(falseLits[a]);
      }
    }
    falseLits.shrink(falseLits.size() - nbFalseLits);
 
    assert(pathC > 0 || maxConflLevel==0);
    if (maxConflLevel==0) {
      printf("c ***** top quasi confl at level %d*****\n", decisionLevel());
      assert(pathC == 0 && UBconflictFlag);
      UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
      out_btlevel=0; out_lbd=0; out_learnt.clear();
      return;
    }
    while (pathC > 0) {
      while (!seen[var(trail[index--])]);
      p     = trail[index+1];
      confl = reason(var(p));
      seen[var(p)] = 0;
      pathC--;
      // sign(p) returns the last bit of p. p is positive iff sign(p)= 0 or false
      // p should not be UIP if it is a negative auxi literal (i.e., if it represents a false soft clause)
      //if (pathC == 0 && !(auxiVar(var(p)) && sign(p)))
	//if (pathC == 0 && !(auxiVar(var(p))))
      if (pathC == 0)
	break;
      
      assert(confl != CRef_Undef); // (otherwise should be UIP)
      Clause& c = ca[confl];
      
        // For binary clauses, we don't rearrange literals in propagate(), so check and make sure the first is an implied lit.
        if (c.size() == 2 && value(c[0]) == l_False){
	  assert(value(c[1]) == l_True);
	  Lit tmp = c[0];
	  c[0] = c[1], c[1] = tmp; }
        
        int lbd = computeLBD(c);
        if (lbd < c.lbd()){
	  if (lbd == 1)
	    c.setSimplified(0);
	  if (c.simplified() > 0)
	    c.setSimplified(c.simplified()-1);
	  if (c.learnt()) {
	    if (c.lbd() <= 30) c.removable(false); // Protect once from reduction.
	    // move confl into CORE or TIER2 if the new lbd is small enough
	    if  (c.mark() != CORE){
	      if (lbd <= core_lbd_cut){
		learnts_core.push(confl);
		c.mark(CORE);
	      }else if (lbd <= tier2_lbd_cut && c.mark() == LOCAL){
		// Bug: 'cr' may already be in 'learnts_tier2', e.g., if 'cr' was demoted from TIER2
		// to LOCAL previously and if that 'cr' is not cleaned from 'learnts_tier2' yet.
		learnts_tier2.push(confl);
		c.mark(TIER2); }
	    }
	  }
	  c.set_lbd(lbd);
        }
	
        if (c.learnt()) {
	  if (c.mark() == TIER2  || c.mark() == CORE)
	    c.touched() = conflicts;
	  //  else if (c.mark() == LOCAL)
	  claBumpActivity(c);
        }
	
        // else {
	//   if (c.used()==0 && c.simplified()==0) {
	//     // if (c.used()==0 && c.lbd() <= lbdLimitForOriCls) {
	//     usedClauses.push(confl);
	//     c.setUsed(1);
	//   }
        // }
       
	  for (int j = 1; j < c.size(); j++){
	    Lit q = c[j];
	    
	    if (!seen[var(q)] && level(var(q)) > 0) {// && !redundantLit(q)){
	      // if (VSIDS){
	      // 	varBumpActivity(var(q), .5);
	      // 	add_tmp.push(q);
	      // }else
	      // 	conflicted[var(q)]++;
	      seen[var(q)] = 1;
	      if (level(var(q)) >= maxConflLevel){
		pathC++;
	      }else
		out_learnt.push(q);
	    }
	  }
    }
    out_learnt[0] = ~p;
    
    simplifyQuasiConflictClause(out_learnt, out_btlevel, out_lbd);
    assert(out_btlevel >0 || out_learnt.size() == 1);
    
    if (out_lbd > core_lbd_cut)
      getAllUIP(out_learnt, out_btlevel, out_lbd);


    // for(int i=0; i<out_learnt.size(); i++)
    //   printf("%d ", toInt(out_learnt[i]));
    // printf(", btlevel %d, lbd %d, trail: %d, level: %d, lim0: %d, confl: %llu, starts: %llu, lkUP: %llu, UP: %llu, falseLit1: %d, fsize: %d\n", 
    // 	   out_btlevel, out_lbd, trail.size(), decisionLevel(), trail_lim[0], 
    // 	   conflicts, starts, lk_propagations, propagations, toInt(falseLits[0]), nbFalseLits);
    // for(int i=0; i<conflLits.size(); i++)
    //   printf("%d ", toInt(conflLits[i]));
    // printf("\n%d\n", conflLits.size());

    
    // if (out_lbd > lbdLimitForOriCls) {
    //     for(int i = saved; i < usedClauses.size(); i++)
    //         ca[usedClauses[i]].setUsed(0);
    //     usedClauses.shrink(usedClauses.size() - saved);
    // }
    UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
}

void Solver::hardenFromQuasiSoftConflict(int trailRecord, int nbIsets) {
  vec<Lit> toHarden;
  toHarden.clear();
  for(int i=trailRecord; i< trail.size(); i++) {
    Var v=var(trail[i]);
    assigns[v] = l_Undef;
    if (auxiVar(v)) {
      assert(v>=0 && v<activityLB.size());
      activityLB[v] = (1-stepSizeLB)*activityLB[v];
      insertAuxiVarOrder(v);
      orderHeapAuxi.decrease(v);
      if (inConflicts[v] == NON)
	toHarden.push(trail[i]);
    }
  }
  trail.shrink(trail.size() - trailRecord);
  qhead = trailRecord;
  // trail_lim.shrink(1);
  resetConflicts(nbIsets);
  bumpConflVars(); //the score of confl vars and non-confl vars is updated differently
  
  if (toHarden.size() == 0)
    return;
  hardenEnable = true;
  UBconflictFlag = true; softConflictFlag = true;
  
  vec<Lit> learnt_clause;
  int backtrack_level, lbd;
  learnt_clause.clear();
  analyzeQuasiSoftConflict(learnt_clause, backtrack_level, lbd);
  if (learnt_clause.size() > 0) {
    Lit p = learnt_clause[0];
    if (level(var(p)) < decisionLevel()) {
      cancelUntil(level(var(p)));
    }
    assert(level(var(p)) == decisionLevel());
  }
  else {
    cancelUntil(0);
  }
  UBconflictFlag = false; softConflictFlag = false;
  
  if (learnt_clause.size() == 0) 
    for(int i=0; i<toHarden.size(); i++) {
      Lit p = toHarden[i];
      uncheckedEnqueue(p);
      fixedByHardens++; fixedByQuasiConfl++;
    }
  else {
    reduceHardens();
    vec<Lit> ps;
    ps.clear();
    ps.push();
    counter++;
    for(int i=0; i<learnt_clause.size(); i++) {
      Lit p = learnt_clause[i];
      ps.push(p);
      seen2[var(p)] = counter;
    }
    
    for(int i=0; i<toHarden.size(); i++) {
      Lit p = toHarden[i];
      if (!softVarLocked[var(p)]) {
	ps[0] = p;
	CRef cr;
	cr =ca.alloc(ps, true);
	hardens.push(cr);
	attachClause(cr);
	uncheckedEnqueue(p, cr);
	fixedByHardens++; fixedByQuasiConfl++;
      }
    }
  }
}

void Solver::fixByLookahead(vec<Lit>& out_learnt) {
  int btlevel, lbd;
  nbFixedByLH++;
  for(int i=1; i<out_learnt.size(); i++)
    seen[var(out_learnt[i])]=1;
  simplifyQuasiConflictClause(out_learnt, btlevel, lbd);
  cancelUntil(btlevel);
  if (out_learnt.size() == 1)
    uncheckedEnqueue(out_learnt[0]);
  else {
    CRef cr = ca.alloc(out_learnt, true);
    if (out_learnt.size() > splitClauseSize && lbd<=tier2_lbd_cut)
      hardLearnts.push(cr);
    ca[cr].set_lbd(lbd);
    if (lbd <= core_lbd_cut){
      learnts_core.push(cr);
      ca[cr].mark(CORE);
      ca[cr].touched() = conflicts;
    }else if (lbd <= tier2_lbd_cut){
      learnts_tier2.push(cr);
      ca[cr].mark(TIER2);
      ca[cr].touched() = conflicts;
    }else{
      learnts_local.push(cr); }
    claBumpActivity(ca[cr]);
    attachClause(cr);
    uncheckedEnqueue(out_learnt[0], cr);
  }
}

//#define printTestedVar

// The involvedClauses stack stores the hard clauses that make disjoint conflicting soft clauses.
// If Ub is reached, the stack (together with the involved flag of each involved clauses) is cleared 
// when analyzing the soft conflict
// Otherwise, it is cleared here before returning true.
bool Solver::lookahead() {
  static int thres=2;
  static int prevConflicts=0;
  static int maxSuccLB=0;
  static uint64_t prevUB=0;
  static int nbSample=0;
  static double sumLB=0;
  static double sumSQLB=0;
  static double coef = 2;
  static int myLH=0;
  static int mySucc=0;

  hardenEnable = false; LHconfl = CRef_Undef;
  // return true;
  if (UB != prevUB) {
    prevUB = UB; nbSample=0; sumLB=0; sumSQLB=0;
  }

  assert(involvedLits.size() == 0);
  // for(int i=0; i<nVars(); i++)
  //   assert(!involved[i]);
  // if (UB < prevUB) {
  //   maxSuccLB = 0;
  //   // maxSuccLB -= prevUB - UB;
  //   // if (maxSuccLB < 0)
  //   //   maxSuccLB=0;
  //   // printf("c maxSuccLB: %d, UB: %llu \n", maxSuccLB, UB);
  //   prevUB = UB;
  // }

  int lb = UB-falseLits.size();
  if (lb==0) {
    UBconflictFlag = false; softConflictFlag = true;
    return false;
  }
  if (lb == 1) {
    if (!orderHeapAuxi.empty())
      moreHarden();
    return true;
  }
  int sampled=0;
  if (conflicts > prevConflicts) {
    if (drand(random_seed) < 0.01) {
      thres = lb;
      sampled=1;
    }
    else thres = maxSuccLB;
    // if (thres > UB/2)
    //   printf("c %d %llu\n", thres, UB/2);
    //  assert(thres <= UB/2);
    prevConflicts = conflicts;
  }
  if (LOOKAHEAD == nbLKsuccess)
    thres = UB;
  if (lb > thres)
    return true;

  if (stepSizeLB > 0.06) stepSizeLB -= 0.000001;
  
  // int baseLevel = decisionLevel();
  int nbConfl=0;
  trailRecord = trail.size(); 
  UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
  LOOKAHEAD++; //newDecisionLevel();
  lastConflLits.clear();
  for(int i=conflLits.size()-1; i>=0; i--)
    if  (conflLits[i] != lit_Undef)
      lastConflLits.push(conflLits[i]);
  // printf("c %d ", lastConflLits.size());
  for(int i=initConflLits.size()-1; i>=0; i--) {
    Lit p=initConflLits[i];
    if (p != lit_Undef)
      lastConflLits.push(p);
    // else printf("fdf ");
  }
  int nbIsets=0;
  vec<Lit> out_learnt;
#ifdef printTestedVar
  printf("\n\nc **********lookahead: %llu, lb: %d, NbFalseLits: %d, thres: %d, UB: %llu\n", LOOKAHEAD, lb, falseLits.size(), thres, UB);
#endif

  if (!sampled)
    myLH+=2;
  //  printf("\n");
  while (1) {
    Var v = pickAuxiVar();
    if (v == var_Undef)
      break;
#ifdef printTestedVar
    printf("c %d %10.9lf ", v, activityLB[v]);
#endif
    // testedVars.push(v);
    // lastTested[v]=LOOKAHEAD;
    //  Lit p=mkLit(v);
    uncheckedEnqueueForLK(softLits[v]);
    CRef confl = propagateForLK();
    if (confl != CRef_Undef) {  // printf("\n");
      isetsLits.init(nbIsets); isetsLits[nbIsets].clear();
      nbConfl++;
      lookbackResetTrail(confl, var_Undef, nbIsets, out_learnt, nbConfl==lb); 
      if (lb > nbConfl) {
	if (isetsLits[nbIsets].size() == 0) {
	  resetConflicts_(nbIsets);
	  for(int i=0; i<involvedLits.size(); i++) {
	    involved[var(involvedLits[i])] = 0;
	  }
	  involvedLits.clear();
	  UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
	  isetsLits[nbIsets].clear(); nbConfl=0;   nbIsets=0; 
	  fixByLookahead(out_learnt);
	  CRef confl=propagate();
	  if (confl != CRef_Undef  || softConflictFlag==true) {
	    if (confl != CRef_Undef)
	      LHconfl = confl;
	    return false;
	  }
	  trailRecord = trail.size(); lb = UB-falseLits.size();
	  UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
	  lastConflLits.clear();
	  for(int i=conflLits.size()-1; i>=0; i--)
	    if  (conflLits[i] != lit_Undef)
	      lastConflLits.push(conflLits[i]);
	  for(int i=initConflLits.size()-1; i>=0; i--) {
	    Lit p=initConflLits[i];
	    if (p != lit_Undef)
	      lastConflLits.push(p);
	  }
	  continue;
	}
	setConflict(nbIsets);
      }
#ifdef printTestedVar
      printf("£ %d\n", nbConfl);
#endif
      //	indexL=0; indexS=0;
    }
    else if (falseVar != var_Undef) {   //printf("\n");
      isetsLits.init(nbIsets); isetsLits[nbIsets].clear();
      lookbackResetTrail(reason(falseVar), falseVar, nbIsets, out_learnt); nbConfl++;
#ifdef printTestedVar
      printf("$ %d %d\n", falseVar, nbConfl);
#endif
      //	indexL=0; indexS=0;
      // lastTested[falseVar]=LOOKAHEAD;
      // testedVars.push(falseVar);
      if (lb > nbConfl) {
	isetsLits[nbIsets].push(softLits[falseVar]);
	setConflict(nbIsets);
      }
      falseVar = var_Undef;
    }
    if (lb==nbConfl) {
#ifdef printTestedVar
      printf("c ====== maxSuccLB: %d\n", maxSuccLB);
#endif
      if (sampled) {
	nbSample++;
	sumLB += nbConfl; sumSQLB += nbConfl*nbConfl;
	double meanLB = ((double)sumLB)/nbSample;
	double meanSQLB = ((double)sumSQLB)/nbSample;
	double stddev = sqrt(meanSQLB - meanLB*meanLB);
	if (myLH > 0) {
	  int rate = (mySucc * 100)/myLH;
	  if (rate > 75 && (meanLB + coef*stddev) < UB)
	    coef += 0.1;
	  else if (rate <= 60 && (meanLB + coef*stddev) > 1)
	    coef -= 0.1;
	  // if ((meanLB + coef*stddev) > UB+1)
	  //   coef = (UB+1 - meanLB)/stddev;
	  //  printf("rate : %d, coef: %2.1lf, UB: %llu, new thres: %d, mean: %4.2lf, stddev: %4.2lf\n", rate, coef, UB, (int)(meanLB + coef*stddev), meanLB, stddev);
	}
	else {
	  if (coef < 2)
	    coef = 2;
	  //	  printf("no LH\n");
	}
	maxSuccLB = (int) (meanLB + coef*stddev);
	myLH=0; mySucc = 0;
      }
      else { mySucc+=2; }
      // if (lb > maxSuccLB && maxSuccLB<UB/2) {
      // 	// printf("c conflicts: %llu, maxSuccLB: %d, lb: %d, UB: %llu, thres: %d\n", 
      // 	//        conflicts, maxSuccLB, lb, UB, thres);
      // 	maxSuccLB = lb;
      // }
      //The UB is reached, the soft conflict will be analyzed 
      // and the involvedClauses stack will be cleared together with the involved flag
      UBconflictFlag = true; softConflictFlag = true;
      //  trail_lim.shrink(1);
      //  lastConflLits.shrink(lastConflLits.size() - savedConflLits);
      nbLKsuccess++; totalPrunedLB += lb; totalPrunedLB2 += lb*lb;

      // double curMeanLB = (double)totalPrunedLB/(nbLKsuccess-savednbLKsuccess);
      // double curDev = sqrt((float)totalPrunedLB2/(nbLKsuccess-savednbLKsuccess) - curMeanLB*curMeanLB);
      // printf(" %d, %d\n", maxSuccLB, (int)(curMeanLB+2*curDev));
      resetConflicts(nbIsets);
      for(int i=0; i<isetsLits[nbIsets].size(); i++) {
	Lit p=isetsLits[nbIsets][i];
	conflLits.push(p);
	insertAuxiVarOrder(var(p));
      }
      bumpConflVars();
      return false; 
    }
  }

    if (nbConfl == lb - 1) {
      if (!sampled)
	mySucc+=1;
    quasiSoftConflicts++;
    hardenFromQuasiSoftConflict(trailRecord, nbIsets);
    
    // LHsuccQueue.push(1); lastSuccess = 1;
    // if (LHsuccQueue.full() && LHsuccQueue.getsum() > 35 && thres < UB) {
    //   thres++;
    // }
    
  }
  else {
    for(int i=trailRecord; i< trail.size(); i++) {
      Var v=var(trail[i]);
      assigns[v] = l_Undef;
      if (auxiVar(v)) {
	assert(v>=0 && v<activityLB.size());
	activityLB[v] = (1-stepSizeLB)*activityLB[v];
	insertAuxiVarOrder(v);
	orderHeapAuxi.decrease(v);
      }
    }
    trail.shrink(trail.size() - trailRecord);
    qhead = trailRecord;
    //  trail_lim.shrink(1);
    resetConflicts(nbIsets);
    bumpConflVars(); //the score of confl vars and non-confl vars is updated differently
  }
    // printf("c meanLB: %4.2lf, meanSQLB: %4.2lf, stddev: %4.2lf, nbSample: %d, maxSuccLB: %d, UB: %llu, thres: %d\n", 
    //        meanLB, meanSQLB, stddev, nbSample, maxSuccLB, UB, thres);
    // printf("c conflicts: %llu, maxSuccLB: %d, lb: %d, UB: %llu, thres: %d\n", 
    //        conflicts, maxSuccLB, lb, UB, thres);
#ifdef printTestedVar
  printf("\nc @@@@ lb: %d, thres: %d, new thres: %d, @@@@\n", lb, thres, (lb+nbConfl+1)/2);
#endif

  thres = lb-1; //(lb+nbConfl)/2;
  prevConflicts = conflicts;
  // lastConflLits.shrink(lastConflLits.size() - savedConflLits);
  for(int i=0; i<involvedLits.size(); i++) {
    involved[var(involvedLits[i])] = 0;
  }
  involvedLits.clear();
  return true;
}

// for each soft clause of the form 1 2 3, create a new variable non decisional v and
// add a hard equivalence v <--> 1 2 3, meaning: add a hard clause -v 1 2 3
//    then add 3 hard clauses v -1, v -2, v -3
void Solver::addHardClausesForSoftClauses() {
  vec<Lit> lits;
  int nbUnitSoft=0, nbNonUnitSoft=0;
  hardSoftClauses.clear();
  nbOrignalVars = nVars();
  unitSoftLits.clear(); nonUnitSoftLits.clear(); allSoftLits.clear();
  for(int i=0; i<softClauses.size(); i++) {
    lits.clear();
   Clause& c=ca[softClauses[i]];
   int sat=0;
   for (int j=0; j<c.size(); j++) {
     if (value(c[j]) == l_Undef)
       lits.push(c[j]);
     else if (value(c[j]) == l_True)
       sat=1;
   }
   if (sat==0) {
     if (lits.size() == 0)
       solutionCost += 1;
     else if (lits.size() == 1 && softLits[var(lits[0])] == lit_Undef) {
       softLits[var(lits[0])] = lits[0]; nbUnitSoft++;
       unitSoftLits.push(lits[0]); allSoftLits.push(lits[0]);
     }
     else {
       nbNonUnitSoft++;
       Lit p=createHardClausesFromLits(lits);
       allSoftLits.push(p);
     }
   }
  }
  printf("c nb soft clauses: %d, of which %d unit, %d nonUnit and %llu empty\n", 
	 softClauses.size(), nbUnitSoft, nbNonUnitSoft, solutionCost);
  objForSearch = nbUnitSoft + nbNonUnitSoft;
  rebuildOrderHeap();
  allSoftLits.copyTo(allSoftLitsForCardC);

  for(int i=0; i<softClauses.size(); i++) {
    CRef cr=softClauses[i];
    ca[cr].mark(1);
    ca.free(cr);
  }
  softClauses.clear();
  checkGarbage();
}

void Solver::insertAuxiVarOrder(Var x) {
  if (!orderHeapAuxi.inHeap(x) && (auxiVar(x))) orderHeapAuxi.insert(x);
}

void Solver::removeLearntClauses() {
  for(int i=0; i<involvedLits.size(); i++) {
    involved[var(involvedLits[i])] = 0;
  }
  involvedLits.clear();
  for (int i=0; i < learnts_local.size(); i++)
     removeClause(learnts_local[i]);
  learnts_local.clear();
  for (int i=0; i < learnts_tier2.size(); i++)
     removeClause(learnts_tier2[i]);
  learnts_tier2.clear();
  for (int i=0; i < learnts_core.size(); i++)
     removeClause(learnts_core[i]);

  for(int i=0; i<hardens.size(); i++)
    removeClause(hardens[i]);
  hardens.clear();

  for(int i=0; i<cardinalityC.size(); i++)
    removeClause(cardinalityC[i]);
  cardinalityC.clear();

  for(int i=0; i<isetClauses.size(); i++)
    removeClause(isetClauses[i]);
  isetClauses.clear();
    
  learnts_core.clear();
  watches.cleanAll();
  watches_bin.cleanAll();
  checkGarbage();

  dynVars.clear();
  for(int i=nVars() - 1; i>=staticNbVars; i--) {
    decision[i] = false;
    dynVars.push(i);
  }
}

void Solver::cancelUntilBeginning(int begnning) {
  for (int c = trail.size()-1; c >= begnning; c--){
    Var      x  = var(trail[c]);
    if (!VSIDS){
      uint32_t age = conflicts - picked[x];
      if (age > 0){
	double adjusted_reward = ((double) (conflicted[x] + almost_conflicted[x])) / ((double) age);
	double old_activity = activity_CHB[x];
	activity_CHB[x] = step_size * adjusted_reward + ((1 - step_size) * old_activity);
	if (order_heap_CHB.inHeap(x)){
	  if (activity_CHB[x] > old_activity)
	    order_heap_CHB.decrease(x);
	  else
	    order_heap_CHB.increase(x);
	}
      }
#ifdef ANTI_EXPLORATION
      canceled[x] = conflicts;
#endif
    }
    assigns [x] = l_Undef;
    if (phase_saving > 1 || (phase_saving == 1) && c > trail_lim.last())
      polarity[x] = sign(trail[c]);
    insertAuxiVarOrder(x);
    insertVarOrder(x);
    seen[x] = 0;
  }
  // for(int c=begnning; c<trail_lim[0]; c++)
  //   seen[var(trail[c])] = 0;
  qhead = begnning;
  trail.shrink(trail.size() - begnning);
  trail_lim.shrink(trail_lim.size());
  falseLits.shrink(falseLits.size());
  falseLits_lim.shrink(falseLits_lim.size());

  // unLockedVars_lim.shrink(unLockedVars_lim.size());
}

void Solver::setBoundsPipe(int write_fd) {
    bounds_pipe_w = write_fd;
}

uint64_t Solver::getCostLB() const {
    return solutionCost + infeasibleUB + fixedCostBySearch + derivedCost + relaxedCost;
}

uint64_t Solver::getCostUB() const {
    return solutionCost + bestSup + fixedCostBySearch + derivedCost + relaxedCost;
}

void Solver::emitBoundsUpdate() {
    if (bounds_pipe_w < 0)
        return;
    char buf[64];
    int n;
    if (infeasibleUB > 0) {
        n = snprintf(buf, sizeof(buf), "LB %llu\n",
                     (unsigned long long)getCostLB());
        if (n > 0)
            (void)write(bounds_pipe_w, buf, (size_t)n);
    }
    if (bestSolutionFound) {
        n = snprintf(buf, sizeof(buf), "UB %llu\n",
                     (unsigned long long)getCostUB());
        if (n > 0)
            (void)write(bounds_pipe_w, buf, (size_t)n);
    }
}

void Solver::emitTryUpdate(uint64_t try_val) {
    if (bounds_pipe_w < 0)
        return;
    char buf[64];
    int n = snprintf(buf, sizeof(buf), "TRY %llu\n", (unsigned long long)try_val);
    if (n > 0)
        (void)write(bounds_pipe_w, buf, (size_t)n);
}

void Solver::noteBestSolution(uint64_t unsatSoft) {
    if (!bestSolutionFound || unsatSoft < bestSup) {
        bestSolutionFound = true;
        bestSup = unsatSoft;
        emitBoundsUpdate();
    }
}

void Solver::printBestSolution() const {
    if (!bestSolutionFound) {
        printf("c TIMEOUT/INTERRUPT: no feasible solution found yet.\n");
        return;
    }
    uint64_t maxsat = objForSearch - bestSup + (uint64_t)nbSatLitsAtStart;
    uint64_t optimal = solutionCost + bestSup + fixedCostBySearch + derivedCost + relaxedCost;
    printf("c TIMEOUT/INTERRUPT: best solution so far:\n");
    printf("c   unsat soft clauses (search): %llu\n", bestSup);
    printf("c   satisfied soft clauses (maxsat): %llu\n", maxsat);
    printf("c   total weight cost: %llu\n", optimal);
    if (model.size() > 0) {
        printf("v ");
        int lim = nbOriVars > 0 ? nbOriVars : nVars();
        for (int i = 0; i < lim && i < model.size(); i++)
            if (model[i] != l_Undef)
                printf("%s%d ", (model[i] == l_True) ? "" : "-", i + 1);
        printf("0\n");
    }
}

void Solver::checkSolution() {
  int nbFalse=0;
  for(Var v=0; v<nVars(); v++)
    if (auxiVar(v) && value(softLits[v]) == l_False)
      nbFalse++;
  if (nbFalse != falseLits.size()+fixedCostBySearch + relaxedCost)
    printf("c **** error nb of false soft clauses real nbfalse: %d, recorded falseLits: %llu****\n",
	   nbFalse, falseLits.size()+fixedCostBySearch+relaxedCost);

  // printf("c there are %d hard clauses\n", clauses.size());
  for(int i=0; i<clauses.size(); i++)
    if (!satisfied(ca[clauses[i]])) {
      printf("c clause %d non-satisfied: ", i);
      Clause& c=ca[clauses[i]];
      for(int j=0; j<c.size(); j++)
	printf(" %d ", toInt(c[j]));
      printf("\n");
    }
}

//For a set of literals 1 2 3, create a new soft lit x and create
// hard clauses encoding x <-> 1 2 3 (-x 1 2 3, x -1, x -2, x -3)
Lit Solver::createHardClausesFromLits(vec<Lit>& lits) {
    Var vv=newVar(false, false);
    Lit pp = mkLit(vv);
    softLits[vv] = pp;
    nonUnitSoftLits.push(pp);
    lits.push(~pp);
    CRef cr = ca.alloc(lits, false);
    clauses.push(cr);
    attachClause(cr);
    //   hardSoftClauses.push(cr);
    
    lits.pop();
    vec<Lit> ps;   
    ps.clear();
    ps.push(pp);
    ps.push(); // leave a room for the second literal
    for (int ii=0; ii<lits.size(); ii++) {
	 	ps[1] = ~lits[ii];
	 	CRef cr = ca.alloc(ps, false);
	 	clauses.push(cr);
	 	attachClause(cr);
	 	imply[toInt(lits[ii])] = pp;
    }
    return pp;
}

struct unitSoftLits_lt {
    vec2<Lit, vec<Lit> >& conflictLits;
    unitSoftLits_lt(vec2<Lit, vec<Lit> >& conflictLits_) : conflictLits(conflictLits_) {}
  	bool operator () (Lit l1, Lit l2) {
  		return conflictLits[l1].size() < conflictLits[l2].size();
    }
};

void Solver::partition() {
  int nbIsets=0;
  vec<Lit> iset, workingSet, initWorkingSet;

  initConflLits.clear(); initConflLits.push(lit_Undef);
  conflLits.clear(); conflLits.push(lit_Undef);

  // FILE* fp1 = fopen("aaa", "w");
  
  initWorkingSet.clear();
  for(int i=0; i<allSoftLits.size(); i++) {
    Lit p=allSoftLits[i];
    if (value(p) == l_Undef && conflictLits[p].size() > 0) {
      conflicted[var(p)] = 0; picked[var(p)]=0;
      initWorkingSet.push(p);
      vec<Lit>& lits1 = conflictLits[p];
      initConflLits.push(p);
      for(int j=0; j<lits1.size(); j++)
	initConflLits.push(lits1[j]);
      initConflLits.push(lit_Undef);
      
     // for(int j=0; j<lits1.size(); j++)
     //   fprintf(fp1, "%d ", toInt(lits1[j]));
     // fprintf(fp1, "\n");
      
    }
  }
  // for(int i=0; i<initConflLits.size(); i++)
  //   printf("%d ", toInt(initConflLits[i]));
  // printf("\n");
  while (initWorkingSet.size() > 0) {
    workingSet.clear();
    int i, j;
    for(i=0, j=0; i<initWorkingSet.size(); i++) {
      Lit p=initWorkingSet[i];
      vec<Lit>& lits3 = conflictLits[p];
      if (lits3.size() > 0 && !picked[var(p)]) {
	int aa, bb;
	for(aa=0, bb=0; aa<lits3.size(); aa++) {
	  Lit pp = lits3[aa];
	  // eliminate the picked lits from  conflictLits[p]
	  if (!picked[var(pp)] && value(pp) == l_Undef)
	    lits3[bb++] = pp; 
	}
	lits3.shrink(aa-bb);
	if (bb>0) {
	  conflicted[var(p)]=0;
	  workingSet.push(p);
	  initWorkingSet[j++] = p;
	}
	else {
	  conflLits.push(p);
	  conflLits.push(lit_Undef);
	  nbIsets++;
	}
      }
    }
    initWorkingSet.shrink(i-j);
    iset.clear(); 
    while (workingSet.size() > 0) {
      Lit candidate=workingSet[0];
      int min=conflictLits[candidate].size();
      for(int k=1; k<workingSet.size(); k++) {
	Lit q=workingSet[k];
	if (conflictLits[q].size() < min) {
	  candidate=q; min = conflictLits[q].size();
	}
      }
      vec<Lit>& lits2 = conflictLits[candidate];
      for(int ii=0; ii<lits2.size(); ii++) {
	Lit q=lits2[ii];
	if (conflicted[var(q)]==iset.size()) {
	  assert(value(q) == l_Undef && !picked[var(q)]);
	  conflicted[var(q)]++;
	}
      }
      iset.push(candidate); picked[var(candidate)]=1;
      //eliminate lits not conflict with candidate
      int jj, ii;
      for(jj=0, ii=0; jj<workingSet.size(); jj++) {
	Lit q=workingSet[jj];
	if (conflicted[var(q)] < iset.size())
	  conflicted[var(q)]=0;
	else workingSet[ii++]=q;
      }
      workingSet.shrink(jj-ii);
    }
    for(int k=0; k<iset.size(); k++)
      conflLits.push(iset[k]);
    conflLits.push(lit_Undef);
    nbIsets++;
  }

  printf("c init nbIsets: %d\n", nbIsets);
  nbIsets=0;
  
  Lit q = lit_Undef;
  for(int i=0; i<initConflLits.size() - 1; i++) {
    Lit p = initConflLits[i];
    if (p == lit_Undef) {
      q = initConflLits[++i];
      conflictLits[q].clear();
    }
    else conflictLits[q].push(p);
  }

  initConflLits.shrink(initConflLits.size());
  initConflLits.push(lit_Undef);

  // FILE* fp2 = fopen("bbb", "w");
  // for(int i=0; i<unitSoftLits.size(); i++) {
  //   Lit p=unitSoftLits[i];
  //   vec<Lit>& lits6 = conflictLits[p];
  //   for(int j=0; j<lits6.size(); j++)
  //     fprintf(fp2, "%d ", toInt(lits6[j]));
  //   fprintf(fp2, "\n");
  // }

  int i, j;
  for(int pass=0; pass<2; pass++) {
    
  int m, n, debut=0;
  for(i=conflLits.size() - 1; i>=debut;) {
    if (conflLits[i] == lit_Undef) {
      for(j=0; j<conflLits.size(); j++)
	if (conflLits[j] != lit_Undef)
	  conflicted[var(conflLits[j])] = 0;
      iset.clear();
      i--;
    }
    else {
      for(j=i;  conflLits[j] != lit_Undef; j--) {
	Lit p = conflLits[j];
	iset.push(p);
	vec<Lit>& lits4=conflictLits[p];
	for(int a=0; a<lits4.size(); a++)
	  conflicted[var(lits4[a])]++;
      }
      for(m=j-1, n=j-1; m>=debut; m--) {
	Lit q = conflLits[m];
	if (q != lit_Undef && conflicted[var(q)] == iset.size()) {
	  iset.push(q);
	  vec<Lit>& lits5 = conflictLits[q];
	  for(int a=0; a<lits5.size(); a++)
	    conflicted[var(lits5[a])]++;
	}
	else conflLits[n--] = q;
      }
      debut = n+1;
      if (pass == 1 && iset.size() > 1) {
	createHardClausesFromLits(iset);
	for(int k=0; k<iset.size(); k++) 
	  softLits[var(iset[k])] = lit_Undef;
	derivedCost += iset.size() - 1;
	nbIsets++;
	// printf("==== iset : %d \n", iset.size());
	// for(int k=0; k<iset.size(); k++)
	//   // printf("%d ", conflicted[var(iset[k])]);
	//   printf("%d ", toInt(iset[k]));
	// printf("\n++++++\n\n");
	int a, b;
	for(int k=0; k<iset.size(); k++)
	  for(int k1=k+1; k1 <iset.size(); k1++) {
	    Lit p1 = iset[k], p2 = iset[k1];
	    vec<Lit>& lits7 = conflictLits[p1];
	    for(a=0; a<lits7.size(); a++)
	      if (lits7[a] == p2)
		break;
	    if (a == lits7.size())
	      printf("problem a\n");
	    
	    vec<Lit>& lits8 = conflictLits[p2];
	    for(b=0; b<lits8.size(); b++)
	      if (lits8[b] == p1)
		break;
	    
	    if ( b == lits8.size())
	      printf("problem b\n");
	  }
      }
      else {
	for(int k=0; k<iset.size(); k++)
	  initConflLits.push(iset[k]);
	initConflLits.push(lit_Undef);
	nbIsets++;
      }
      i=j;
      assert(conflLits[j] == lit_Undef);
    }
  }
  if (pass == 0) {
    printf("c nbIsets after pass 1: %d\n", nbIsets);
    nbIsets=0;
    conflLits.shrink(conflLits.size());
    
    for(int k=0; k<initConflLits.size(); k++)
      conflLits.push(initConflLits[k]);
  }
  }

  
  for(i=0, j=0; i<unitSoftLits.size(); i++)
    if (softLits[var(unitSoftLits[i])] != lit_Undef)
      unitSoftLits[j++] = unitSoftLits[i];
  unitSoftLits.shrink(i-j);
  printf("c isets %d, derivedCost %llu\n", nbIsets, derivedCost);
  if (i>j)
    rebuildOrderHeap();
  
  for(i=0; i<allSoftLits.size(); i++) {
    Lit p=allSoftLits[i];
    conflicted[var(p)] = 0; picked[var(p)]=0;
  }
  conflLits.clear(); initConflLits.clear();
}

void Solver::addConflictLit(Lit p, Lit q) {
	int i;
	vec<Lit>& lits1=conflictLits[p];
	for(i=0; i<lits1.size(); i++)
		if (lits1[i] == q)
			break;
	if (i==lits1.size())
		lits1.push(q);
	vec<Lit>& lits2=conflictLits[q];
	for(i=0; i<lits2.size(); i++)
		if (lits2[i] == p)
			break;
	if (i==lits2.size())
		lits2.push(p);
}

bool Solver::findConflictSoftLits() {
  CRef confl;
  int initTrail = trail.size(), nbConflLits=0, nbFailedLits=0, nbConfLits2=0;
  int i, j;

  falseLits.clear();
  falseLitsRecord = 0; trailRecord = trail.size();  rootNbIsets = 0;
  UB = unitSoftLits.size()+nonUnitSoftLits.size() + 1;
  for(i=0; i<unitSoftLits.size(); i++) {
	conflictLits[unitSoftLits[i]].clear();
  }
  for(i=0; i<unitSoftLits.size(); i++) {
    Lit p=unitSoftLits[i];
    if (value(p) != l_Undef)
      continue;
    falseLits.clear();
    simpleUncheckEnqueue(p);
    confl = simplePropagate();
    if (confl != CRef_Undef || softConflictFlag){
      cancelUntilTrailRecord(); softConflictFlag=false;
      uncheckedEnqueue(~p);
      if (propagate() != CRef_Undef  || softConflictFlag==true){
	return false;
      }
      trailRecord = trail.size();
      nbFailedLits++;
    }
    else {
      if (falseLits.size() > 0) {
		nbConflLits += falseLits.size();
		for(j=0; j<falseLits.size(); j++)
	  	 addConflictLit(p, falseLits[j]);
      }
    /*  int savedTrailRecord=trailRecord;
      for(j=i+1; j<unitSoftLits.size(); j++) {
      	Lit q = unitSoftLits[j];
      	if (value(q) == l_Undef) {
      		trailRecord = trail.size();
      		falseLitsRecord=falseLits.size();
      		simpleUncheckEnqueue(q);
      		CRef confl1 = simplePropagate();
      		cancelUntilTrailRecord(); softConflictFlag=false;
      		if (confl1 != CRef_Undef || softConflictFlag) {
      			lits.push(q); nbConfLits2++;
      		}
      	}
      }
      trailRecord = savedTrailRecord; falseLitsRecord = 0; */
      cancelUntilTrailRecord();
    }
  }
  printf("c conflLits %d, conflLits2 %d, nbFailedLits %d, fixedVarsBypreproc %d, totalFixedVars %d\n", 
	 nbConflLits, nbConfLits2, nbFailedLits, trail.size()-initTrail, trail.size());
  if (nbConflLits > 0)
	partition();
  return true;
}

void Solver::simpleuncheckedEnqueueForLK(Lit p, CRef from){
    assert(value(p) == l_Undef);
    Var v = var(p);
    assigns[v] = lbool(!sign(p)); // this makes a lbool object whose value is sign(p)
    // vardata[x] = mkVarData(from, decisionLevel());
    vardata[v].reason = from;
    vardata[v].level = decisionLevel() + 1;
    trail.push_(p);
}

CRef Solver::simplepropagateForLK() {
  falseVar = var_Undef;
  CRef    confl = CRef_Undef;
  int     num_props = 0;
  watches.cleanAll();
  watches_bin.cleanAll();
  while (qhead < trail.size()) {
    Lit            p = trail[qhead++];     // 'p' is enqueued fact to propagate.
    vec<Watcher>&  ws = watches[p];
    Watcher        *i, *j, *end;
    num_props++;
    // First, Propagate binary clauses
    vec<Watcher>&  wbin = watches_bin[p];
    
    for (int k = 0; k<wbin.size(); k++) {
      Lit imp = wbin[k].blocker;
      if (value(imp) == l_False) {
	binConfl[0] = ~p; binConfl[1]=imp;
	return CRef_Bin;
	//	return wbin[k].cref;
      }   
      if (value(imp) == l_Undef) {
	simpleuncheckedEnqueueForLK(imp, wbin[k].cref);
	if (auxiVar(var(imp)) && value(softLits[var(imp)]) == l_False && !softVarLocked[var(imp)]) {
	  falseVar = var(imp);
	  return CRef_Undef;
	}
      }
    }
    for (i = j = (Watcher*)ws, end = i + ws.size(); i != end;) {
	// Try to avoid inspecting the clause:
	Lit blocker = i->blocker;
	if (value(blocker) == l_True) {
	  *j++ = *i++; continue;
	}
	// Make sure the false literal is data[1]:
	CRef     cr = i->cref;
	Clause&  c = ca[cr];
	Lit      false_lit = ~p;
	if (c[0] == false_lit)
	  c[0] = c[1], c[1] = false_lit;
	assert(c[1] == false_lit);
	// If 0th watch is true, then clause is already satisfied.
	// However, 0th watch is not the blocker, make it blocker using a new watcher w
	// why not simply do i->blocker=first in this case?
	Lit     first = c[0];
	//  Watcher w     = Watcher(cr, first);
	if (first != blocker && value(first) == l_True){
	  i->blocker = first;
	  *j++ = *i++; continue;
	}
	assert(c.lastPoint() >=2);
	if (c.lastPoint() > c.size())
	  c.setLastPoint(2);
	for (int k = c.lastPoint(); k < c.size(); k++) {
	  if (value(c[k]) != l_False) {
	    // watcher i is abandonned using i++, because cr watches now ~c[k] instead of p
	    // the blocker is first in the watcher. However,
	    // the blocker in the corresponding watcher in ~first is not c[1]
	    Watcher w = Watcher(cr, first); i++;
	    c[1] = c[k]; c[k] = false_lit;
	    watches[~c[1]].push(w);
	    c.setLastPoint(k+1);
	    goto NextClause;
	  }
	}
	for (int k = 2; k < c.lastPoint(); k++) {
	  if (value(c[k]) != l_False) {
	    // watcher i is abandonned using i++, because cr watches now ~c[k] instead of p
	    // the blocker is first in the watcher. However,
	    // the blocker in the corresponding watcher in ~first is not c[1]
	    Watcher w = Watcher(cr, first); i++;
	    c[1] = c[k]; c[k] = false_lit;
	    watches[~c[1]].push(w);
	    c.setLastPoint(k+1);
	    goto NextClause;
	  }
	}
	// Did not find watch -- clause is unit under assignment:
	i->blocker = first;
	*j++ = *i++;
	if (value(first) == l_False) {
	  confl = cr;
	  qhead = trail.size();
	  // Copy the remaining watches:
	  while (i < end)
	    *j++ = *i++;
	}
	else {
	  simpleuncheckedEnqueueForLK(first, cr);
	  if (auxiVar(var(first)) && value(softLits[var(first)]) == l_False 
	      && !softVarLocked[var(first)]) {
	    qhead = trail.size();
	    // Copy the remaining watches:
	    while (i < end)
	      *j++ = *i++;
	    falseVar = var(first);
	  }
	}
    NextClause:;
    }
    ws.shrink(i - j);
    // if (confl == CRef_Undef)
    // 	if (shortenSoftClauses(p))
    // 	  break;
  }
  lk_propagations += num_props;
  return confl;
}

void Solver::simplelookbackResetTrail(CRef confl, bool fromFalseVar) {
  if (confl == CRef_Bin) {
    assert(level(var(binConfl[0])) > decisionLevel());
    assert(level(var(binConfl[1])) > decisionLevel());
    seen[var(binConfl[0])] = 1; seen[var(binConfl[1])] = 1;
  }
  else {
    Clause& c = ca[confl];
    // if (!c.involved()) {
    //   involvedClauses.push(confl);
    //   c.setInvolved(1);
    // }
    if (fromFalseVar && c.size() == 2 && value(c[0]) == l_False) {
      // Special case for binary clauses: the first one has to be SAT
      assert(value(c[1]) == l_True);
      Lit tmp = c[0];
      c[0] = c[1]; c[1]=tmp;
    }  
    for(int i=(fromFalseVar ? 1 : 0); i<c.size(); i++) {
      Lit q=c[i]; Var v = var(q);
      if (!seen[v] && level(v) > decisionLevel())
	seen[v]=1;
    }
  }
  int index = trail.size() - 1;
  while (index >= trailRecord) {
    Lit p = trail[index--];
    Var v = var(p);
    if (seen[v]) {
      seen[v] = 0;
      confl = reason(v);
      if (confl == CRef_Undef) {
	conflLits.push(p);      softVarLocked[v]=1;
      }
      else {
	if (auxiVar(v))
	  insertAuxiVarOrder(v);
	Clause& rc = ca[confl];
	// if (!rc.involved()) {
	//   involvedClauses.push(confl);
	//   rc.setInvolved(1);
	// }
	// Special case for binary clauses: the first one has to be SAT
	if (rc.size() == 2 && value(rc[0]) == l_False) {
	  assert(value(rc[1]) == l_True);
	  Lit tmp = rc[0];
	  rc[0] = rc[1], rc[1] = tmp;
	}
	for (int j = 1; j < rc.size(); j++){
	  Lit q = rc[j]; Var vv=var(q);
	  if (!seen[vv] && level(vv) > decisionLevel()){
	    seen[vv] = 1;
	  }
	}
      }
    }
    else if (auxiVar(v))
      insertAuxiVarOrder(v);
    assigns[v] = l_Undef;
  }
  qhead = trailRecord;
  trail.shrink(trail.size() - trailRecord);
}

bool Solver::detectInitConflicts() {
  vec<Lit> ps;
  //  int baseLevel = decisionLevel();
  int nbConfl=0, nbLits=0;
  trailRecord = trail.size(); 
  UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
  LOOKAHEAD++; //newDecisionLevel();
  lastConflLits.clear(); conflLits.clear();
  int i, point=0;
  bool flag=true;
  do {
    if (flag)
      for (i=0; i< nonUnitSoftLits.size(); i++) {
	Lit p = nonUnitSoftLits[i];
	if (value(p) == l_Undef && !softVarLocked[var(p)])
	  simpleuncheckedEnqueueForLK(softLits[var(p)]);
      }
    flag=false;      conflLits.clear();
    for(i=point; i<unitSoftLits.size(); i++) {
      Lit p=unitSoftLits[i];
      if (value(p) == l_Undef && !softVarLocked[var(p)]) {
	simpleuncheckedEnqueueForLK(softLits[var(p)]);
	CRef confl = simplepropagateForLK();
	if (confl != CRef_Undef) {
	  simplelookbackResetTrail(confl, false); nbConfl++;
	  flag=true; point = i;
	  break;
	}
	else if (falseVar != var_Undef) {
	  simplelookbackResetTrail(reason(falseVar), true); nbConfl++;
	  softVarLocked[falseVar]=1;
	  conflLits.push(softLits[falseVar]);
	  falseVar = var_Undef;
	  flag=true; point = i;
	  break;
	}
      }
    }
    if (flag) {
      ps.clear();
      for(int i=0; i<conflLits.size(); i++) {
	Lit p = conflLits[i];
	softVarLocked[var(p)] = 0;
	ps.push(~p);
      }
      if (ps.size() == 1) {
	uncheckedEnqueue(ps[0]);
	if (propagate() != CRef_Undef  || softConflictFlag==true)
	  return false;
      }
      else {
	CRef cr=ca.alloc(ps, false);
	clauses.push(cr);
	attachClause(cr);
      }
      softVarLocked[var(conflLits[0])] = 1; lastConflLits.push(conflLits[0]);
      nbLits += ps.size();
    }
    if (i == unitSoftLits.size() && point > 0)
      point = 0;
  } while (point > 0 || i < unitSoftLits.size());

  for(int i=0; i<lastConflLits.size(); i++)
    softVarLocked[var(lastConflLits[i])] = 0;
  lastConflLits.clear();
  assert(involvedLits.size() == 0);
  // for(int i=0; i<involvedClauses.size(); i++) {
  //   Clause& c = ca[involvedClauses[i]];
  //   c.setInvolved(0);
  // }
  // involvedClauses.clear();
  for(int i=trailRecord; i< trail.size(); i++) {
    Var v=var(trail[i]);
    assigns[v] = l_Undef;
  }
  trail.shrink(trail.size() - trailRecord);
  qhead = trailRecord;
  // trail_lim.shrink(1);
  printf("c %d conflict sets found with length %d\n", nbConfl, nbLits);
  return true;
}

void Solver::reduceHardens() {
  //  sort(hardens, reduceDB_lt(ca));

  // int limit = hardens.size() / 2;
  int ii, jj;

  // for(ii=0, jj=0; ii<hardens.size(); ii++) {
  //   Clause& c = ca[hardens[ii]];
  //   if (!locked(c) &&  (ii < limit || c.activity() == 0))
  //     removeClause(hardens[ii]);
  //   else hardens[jj++] = hardens[ii];
  // }
  
  for(ii=0, jj=0; ii<hardens.size(); ii++) {
    Clause& c = ca[hardens[ii]];
    if (locked(c))
      hardens[jj++] = hardens[ii];
    else removeClause(hardens[ii]); 
  }
  hardens.shrink(ii-jj);
  checkGarbage();
}

void Solver::harden() {
  int nbfixed=0;
  nbHardens++;
  //  int saved = hardenLevel;
  hardenLevel = decisionLevel();
  if (falseLits.size() == 0 || level(var(falseLits.last())) == 0) {
    // if (decisionLevel() != 0) {
    //   int nbToHarden=0;
    //   for(int i=0; i<allSoftLits.size(); i++) {
    // 	Lit p = allSoftLits[i];
    // 	if (value(p) == l_Undef)
    // 	  nbToHarden++;
    //   }
    //   printf("falseLits %d, level %d, UB %llu, hardenL %d, confl %llu, starts %llu, toH %d\n",
    // 	     falseLits.size(), decisionLevel(), UB, saved, conflicts, starts, nbToHarden);
    // }
    //   assert(decisionLevel() == 0);
    // printf("nbSoftLits: %d\n", allSoftLits.size());
    for(int i=0; i<allSoftLits.size(); i++) {
      Lit p = allSoftLits[i];
      if (value(p) == l_Undef && !softVarLocked[var(p)]) {
	uncheckedEnqueue(p); fixedByHardens++;
      }
    }
  }
  else {
    // assert(level(var(falseLits.last())) == decisionLevel());
    assert(UB == falseLits.size() + 1);
    if (level(var(falseLits.last())) < decisionLevel())
      for(int i=0; i<allSoftLits.size(); i++) {
	Lit p = allSoftLits[i];
	if (value(p) == l_Undef && !softVarLocked[var(p)]) {
	  cancelUntil(level(var(falseLits.last())));
	  break;
	}
      }
    reduceHardens();
    vec<Lit> ps;
    ps.clear();
    ps.push();
    int nbFalseLits=falseLits.size();
    counter++;
    for(int i=nbFalseLits-1; i>=0; i--) {
      Var v=var(falseLits[i]);
      if (level(v) > 0) {
	ps.push(falseLits[i]); seen2[v] = counter;
      }
    }
    // for(int i=nbFalseLits-1; i>=0; i--) {
    //   Var v=var(falseLits[i]);
    //   if (level(v) > 0 && inConflict[v] != NON) {
    // 	Var u = unlockReason[v];
    // 	assert(u != var_Undef);
    // 	if (level(u) > 0 && seen2[u] < counter) {
    // 	  seen2[u] = counter;
    // 	  assert(value(softLits[u]) == l_False);
    // 	  ps.push(softLits[u]);
    // 	}
    //   }
    // }
    assert(ps.size() > 1);
   for(int i=0; i<allSoftLits.size(); i++) {
      Lit p = allSoftLits[i];
      if (value(p) == l_Undef && !softVarLocked[var(p)]) {
	ps[0] = p;
	CRef cr;
	// if (inConflict[var(p)] != NON) {
	//   Var u = unlockReason[var(p)];
	//   assert(u != var_Undef);
	//   if (level(u) > 0 && seen2[u] < counter) {
	//     assert(value(softLits[u]) == l_False);
	//     ps.push(softLits[u]);
	//     cr =ca.alloc(ps, true);
	//     ps.shrink(1);
	//   }
	//   else cr =ca.alloc(ps, true);
	// }
	// else
	  cr =ca.alloc(ps, true);
	hardens.push(cr);
	attachClause(cr);
	uncheckedEnqueue(p, cr);
	fixedByHardens++; nbfixed++;
      }
    }
  }
  // printf("harden level %d, fixes %d, UB: %llu, hardens: %d\n", hardenLevel, nbfixed, UB, hardens.size());
}

void Solver::cleanClausesForNewVars(vec<CRef>& cs) {
  int i, j;
  for (i = j = 0; i < cs.size(); i++){
    CRef cr = cs[i];
    Clause& c = ca[cr];
    bool sat=false;
    if(c.mark()!=1){
      for (int ii = 0; ii < c.size(); ii++){
	Lit p=c[ii];
        if (value(p) == l_True || dynVar(var(p))) {
	  sat = true;
	  break;
        }
	// Lit p=c[ii];
        // if (value(p) == l_True){
	//   sat = true;
	//   break;
        // }
	//	else if (value(p) == l_Undef && dynVar(var(p)) && !seen[var(p)])
	// seen[var(p)] = 1;
      }
      if (sat)
        removeClause(cr);
      // else {
      // 	int li, lj;
      // 	for (li = lj = 0; li < c.size(); li++){
      // 	  Lit p=c[li];
      // 	  if (value(p) != l_False){
      // 	    c[lj++] = p;
      // 	    if (dynVar(var(p)) && !seen[var(p)])
      // 	      seen[var(p)] = 1;
      // 	  }
      // 	  else assert(li>1);
      // 	}
      // 	if (lj==2) {
      // 	  detachClause(cr, true);
      // 	  c.shrink(li - lj);
      // 	  attachClause(cr);
      // 	}
      // 	else {
      // 	  assert(lj>2);
      // 	  c.shrink(li - lj);
      // 	}
      else cs[j++] = cr;
      // }
    }
  }
  cs.shrink(i - j);
}

void Solver::collectDynVars() {
  cleanClausesForNewVars(learnts_core);
  cleanClausesForNewVars(learnts_tier2);
  cleanClausesForNewVars(learnts_local);
  cleanClausesForNewVars(hardens);
  checkGarbage();
  dynVars.clear();
  for(int i=nVars() - 1; i>=staticNbVars; i--) {
    //  decision[i] = true;
    if (seen[i])
      seen[i] = 0;
    else if (value(i) == l_Undef) {
      dynVars.push(i);
      decision[i]=false;
    }
  }
  // for(int i=0; i<nVars(); i++)
  //   if (value(i) == l_Undef || level(i) > 0)
  //     assert(!seen[i]);
}

Var Solver::newAuxiVar(bool sign)
{
  if (dynVars.size() > 0) {
    int v=dynVars.last();
    dynVars.pop();
    Lit p = mkLit(v);
    watches_bin[p].clear();
    watches_bin[~p].clear();
    watches[p].clear();
    watches[~p].clear();
    imply[toInt(p)] = lit_Undef;
    imply[toInt(~p)] = lit_Undef;
    decision[v] = false;
    assigns[v] = l_Undef;
    return v;
  }
    int v = nVars();
    watches_bin.init(mkLit(v, false));
    watches_bin.init(mkLit(v, true ));
    watches  .init(mkLit(v, false));
    watches  .init(mkLit(v, true ));
    assigns  .push(l_Undef);
    vardata  .push(mkVarData(CRef_Undef, 0));
    activity_CHB  .push(0);
    activity_VSIDS.push(rnd_init_act ? drand(random_seed) * 0.00001 : 0);
    
    picked.push(0);
    conflicted.push(0);
    almost_conflicted.push(0);
#ifdef ANTI_EXPLORATION
    canceled.push(0);
#endif
    
    seen     .push(0);
    seen2    .push(0);
    seen2    .push(0);
    polarity .push(sign);
    decision .push(false);
    trail    .capacity(v+1);
    //  setDecisionVar(v, dvar);
    decision[v] = false;

    activity_distance.push(0);
    var_iLevel.push(0);
    var_iLevel_tmp.push(0);
    pathCs.push(0);

    // softWatches.init(mkLit(v, false));
    // softWatches.init(mkLit(v, true));

    // lookaheadCNT.push(0);

    imply.push(lit_Undef);
    imply.push(lit_Undef);

    activityLB.push(0);
    //  lastTested.push(0);
    softLits.push(lit_Undef);

    conflictLits.init(mkLit(v, false));
    conflictLits.init(mkLit(v, true));

    softVarLocked.push(0);
    inConflict.push(NON);
    unlockReason.push(var_Undef);

    inConflicts.push(NON);

    //  unlockReasonForLK.push(var_Undef);
    involved.push(0);
    
    return v;
}

// create cardinality clauses for a set of soft clauses such that the sum of these lits <= k
// using the Sequential Counter method of Sinz
// precondition: activeSoftLits.size() > k > 0
void Solver::addCardinalityConstraints(vec<Lit>& activeSoftLits, int k) {
  vec<Lit> ps, auxiLits1, auxiLits2;
  //auxiLits1 represent x1+x2+...+x_{i-1} and auxiLits2 x1+x2+...+x_i for i=2, ..., n
  // create clause ¬x1 v s11
  Var v = newAuxiVarForCardinality(); Lit s11 = mkLit(v);
  ps.clear(); ps.push(~activeSoftLits[0]); ps.push(s11);
  CRef cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr);
  ca[cr].mark(CORE);
  auxiLits1.clear(); auxiLits1.push(s11); // sum x1
  
  for(int i=1; i<activeSoftLits.size() - 1; i++) {
    auxiLits2.clear();
    for(int j=0; j<k && j<=i; j++) { // sij=0 for j>i
      v = newAuxiVarForCardinality(); Lit s = mkLit(v); auxiLits2.push(s);
    }
    //create clause ¬xi v si1
    ps.clear(); ps.push(~activeSoftLits[i]); ps.push(auxiLits2[0]);
    cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr);
    ca[cr].mark(CORE);
    //create clause ¬s_{i-1,1} v si1
    ps.clear(); ps.push(~auxiLits1[0]); ps.push(auxiLits2[0]);
    cr = ca.alloc(ps, true); cardinalityC.push(cr);  attachClause(cr);
    ca[cr].mark(CORE);
    if (k<=i) {
      //create clause ¬xi v ¬s_{i-1, k} for forbidding overflow
      // there is no overflow for k>=i because s_{i-1, k} is 0
      ps.clear(); ps.push(~activeSoftLits[i]); ps.push(~auxiLits1.last());
      cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr);
      ca[cr].mark(CORE);
    }
    
    for(int j=1; j<k && j<=i; j++) {
      //create clause ¬xi v ¬s_{i-1, j-1} v sij
      ps.clear(); ps.push(~activeSoftLits[i]); ps.push(~auxiLits1[j-1]); ps.push(auxiLits2[j]);
      cr = ca.alloc(ps, true);	cardinalityC.push(cr);	attachClause(cr);
      ca[cr].mark(CORE);
      if (j<i) {
	//create clause ¬s_{i-1, j} v sij
	ps.clear(); ps.push(~auxiLits1[j]); ps.push(auxiLits2[j]);
	cr = ca.alloc(ps, true);	cardinalityC.push(cr);	attachClause(cr);
	ca[cr].mark(CORE);
      }
    }
    auxiLits2.copyTo(auxiLits1);
  }
  //create clause ¬xn v ¬s_{n-1,k}
  ps.clear(); ps.push(~activeSoftLits.last()); ps.push(~auxiLits1.last());
  cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr);
  ca[cr].mark(CORE);
}

inline Var Solver::newAuxiVarForCardinality() {
  // return newAuxiVar();
  Var v=newAuxiVar();
  // dynVarsForCardinality.push(v);
  activity_CHB[v] = 0;
  activity_VSIDS[v] = 0;
  // decision[v] = true;
  assigns[v] = l_Undef;
  assert(!auxiVar(v));
  setDecisionVar(v, true);
  // //  if (!order_heap_CHB.inHeap(v))
  //   order_heap_CHB.update(v);
  //   // if (!order_heap_VSIDS.inHeap(v))
  //   order_heap_VSIDS.update(v); 
  return v;
}

// create clauses for ¬x1 + ¬x2 + ... + ¬xn <= k
// Precondition: n>k>0
// Should be called only at the root of the search tree
void Solver::addCardinalityConstraints() {
  static uint64_t prevUB=0;

  if (UB==1 || UB == prevUB)
    return;
  prevUB = UB;

  if (cardinalityEncMode == CARD_ENC_OFF) {
    if (verbosity >= 1)
      printf("\nc Cardinality: off (soft-conflict only), UB %llu\n", UB);
    return;
  }

  if (cardinalityC.size() > 0) {
    for(int i=0; i<cardinalityC.size(); i++)
      removeClause(cardinalityC[i]);
    cardinalityC.clear();
    
    collectDynVars();
    
    watches.cleanAll();
    watches_bin.cleanAll();
    checkGarbage();
  }
  
  // for(int i=0; i<dynVarsForCardinality.size(); i++)
  //   dynVars.push(dynVarsForCardinality[i]);
  // dynVarsForCardinality.clear();
  
  vec<Lit> activeSoftLits;
  activeSoftLits.clear();
  int nbFalse=0;
  
  for(int i=0; i<allSoftLitsForCardC.size(); i++) {
    if (value(allSoftLitsForCardC[i]) == l_Undef)
      activeSoftLits.push(~allSoftLitsForCardC[i]);
    else if (value(allSoftLitsForCardC[i]) == l_False)
      nbFalse++;
  }
  if (activeSoftLits.size() < 2 || UB - 1 - nbFalse < 1 || activeSoftLits.size() <= UB - 1 - nbFalse
      || activeSoftLits.size()*(UB - 1 - nbFalse) > 10000)
    return;
  int k = UB - 1 - nbFalse;
  bool useSinz = (cardinalityEncMode == CARD_ENC_SINZ)
      || (cardinalityEncMode == CARD_ENC_BOTH_FORCE)
      || (cardinalityEncMode == CARD_ENC_BOTH && activeSoftLits.size() <= 100);
  bool useMto = (cardinalityEncMode == CARD_ENC_MTO)
      || (cardinalityEncMode == CARD_ENC_BOTH)
      || (cardinalityEncMode == CARD_ENC_BOTH_FORCE);
  if (useSinz)
    addCardinalityConstraints(activeSoftLits, k);
  if (useMto)
    addCardinalityConstraintsMTO(activeSoftLits, k);
  const char* enc = "unknown";
  if (cardinalityEncMode == CARD_ENC_BOTH) enc = "Sinz+MTO";
  else if (cardinalityEncMode == CARD_ENC_BOTH_FORCE) enc = "Sinz+MTO forced";
  else if (cardinalityEncMode == CARD_ENC_SINZ) enc = "Sinz";
  else if (cardinalityEncMode == CARD_ENC_MTO) enc = "MTO";
  printf("\nc Cardinality: %d (%s) for UB %llu\n", cardinalityC.size(), enc, UB);

  rebuildOrderHeap();

  //  activeSoftLits.shrink_(activeSoftLits.size() - 9);
  // addCardinalityConstraintsbis(activeSoftLits, 4);
  
  // for(int i=0; i<activeSoftLits.size(); i++)
  //   printf("%d ", var(activeSoftLits[i]));
  // printf("\n\n");
  
  // for(int i=0; i<cardinalityC.size(); i++) {
  //   Clause& c=ca[cardinalityC[i]];
  //   for(int j=0; j<c.size(); j++) {
  //     if (toInt(c[j])%2 == 1)
  // 	printf("-%d ", var(c[j]));
  //     else printf("%d ", var(c[j]));
  //   }
  //   printf("0\n");
  // }
}

void Solver::addCardinalityConstraintsMTO(vec<Lit>& activeSoftLits, int k) {

    int k2 = k;
    int m = activeSoftLits.size(); //Number of variables
    int n = 0; //number of bits
    while (k2) {
        k2 >>= 1;
        ++n;
    }

    vec<Lit>  result(n,lit_Undef);
    nLevelsMTO(activeSoftLits,0,m,result);

    vec<Lit> ps;
    CRef cr;

    for(int i = n-1; i >= 0; i--){
        ps.push(~result[i]);
        if(!bitIsSet(k,i)){
            if(ps.size()==1)
                uncheckedEnqueue(ps[0]);
            else {
                cr = ca.alloc(ps, true);
                cardinalityC.push(cr);
                attachClause(cr); ca[cr].mark(CORE);
            }
            ps.pop();
        }
    }
}

void Solver::nLevelsMTO(vec<Lit> & x, int lIndex, int m, vec<Lit> & result){
    int n = result.size();

    //Base case, leaf
    if(m==1){
        result[0]=x[lIndex];
    }

    //Recursive case, branch in the binary tree
    else{
        vec<Lit> ps;
        CRef cr;

        vec<Lit> left(n,lit_Undef), right(n,lit_Undef);
        int lSize = m/2;
        int rSize = m - m/2;
        nLevelsMTO(x,lIndex, lSize, left);
        nLevelsMTO(x,lIndex+lSize, rSize, right);

        vec<Lit> c(n-1,lit_Undef); //carry

        int h = 0;
        Var v;
        while(h < n-1){

            v = newAuxiVarForCardinality(); c[h] = mkLit(v);
            v = newAuxiVarForCardinality(); result[h] = mkLit(v);

            //====When carry in is false====
            //left and not(carry) -> result
            if(left[h]!=lit_Undef) {
                ps.clear();
                ps.push(~left[h]); ps.push(c[h]); ps.push(result[h]);
                cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
            }

            //right and not(carry) -> result
            if(right[h]!=lit_Undef) {
                ps.clear();
                ps.push(~right[h]);ps.push(c[h]);ps.push(result[h]);
                cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
            }

            //left and right -> carry
            if(left[h]!=lit_Undef && right[h]!=lit_Undef) {
                ps.clear();
                ps.push(~left[h]);ps.push(~right[h]);ps.push(c[h]);
                cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
            }

            //====When carry in is true====
           if(h>0){
                //carryin and not(carry) -> result
                ps.clear();
                ps.push(~c[h-1]); ps.push(c[h]); ps.push(result[h]);
                cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);

                //carryin and left -> carry
                if(left[h]!=lit_Undef){
                    ps.clear();
                    ps.push(~c[h-1]); ps.push(~left[h]); ps.push(c[h]);
                    cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
                }

                //carryin and right -> carry
                if(right[h]!=lit_Undef){
                    ps.clear();
                    ps.push(~c[h-1]); ps.push(~right[h]); ps.push(c[h]);
                    cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
                }

                //carryin and left and right -> result
                if(left[h]!=lit_Undef && right[h]!=lit_Undef) {
                    ps.clear();
                    ps.push(~c[h-1]); ps.push(~left[h]); ps.push(~right[h]); ps.push(result[h]);
                    cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
                }
            }

            ++h;

            //If all bits processed, break
            if(right[h]==lit_Undef && right[h]==lit_Undef)
                break;
        }

        v = newAuxiVarForCardinality(); result[h] = mkLit(v);

        //====Clauses of the uppermost digits====
        // left -> result
        if(left[h]!=lit_Undef) {
            ps.clear();
            ps.push(~left[h]); ps.push(result[h]);
            cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
        }

        // right -> result
        if(right[h]!=lit_Undef) {
            ps.clear();
            ps.push(~right[h]); ps.push(result[h]);
            cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
        }

        // carryin -> result
        if(h>0) {
            ps.clear();
            ps.push(~c[h - 1]); ps.push(result[h]);
            cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
        }

        // not(left) or not(right)
        if(left[h]!=lit_Undef && right[h]!=lit_Undef) {
            ps.clear();
            ps.push(~left[h]); ps.push(~right[h]);
            cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
        }

        // not(left) or not(carryin)
        if(left[h]!=lit_Undef && h>0) {
            ps.clear();
            ps.push(~left[h]); ps.push(~c[h-1]);
            cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
        }

        // not(right) or not(carryin)
        if(right[h]!=lit_Undef && h>0) {
            ps.clear();
            ps.push(~right[h]); ps.push(~c[h-1]);
            cr = ca.alloc(ps, true); cardinalityC.push(cr); attachClause(cr); ca[cr].mark(CORE);
        }

    }
}

// void Solver::cleanClausesForNewVars(vec<CRef>& cs) {
//   int i, j;
//   for (i = j = 0; i < cs.size(); i++){
//     CRef cr = cs[i];
//     Clause& c = ca[cr];
//     bool sat=false;
//     if(c.mark()!=1){
//       for (int ii = 0; ii < c.size(); ii++){
//         if (value(c[ii]) == l_True || dynVar(var(c[ii]))) {
// 	  sat = true;
// 	  break;
//         }
//       }
//       if (sat)
//         removeClause(cr);
//       // else {
//       // 	int li, lj;
//       // 	for (li = lj = 0; li < c.size(); li++){
//       // 	  Lit p=c[li];
//       // 	  if (value(p) != l_False){
//       // 	    c[lj++] = p;
//       // 	  }
//       // 	  else assert(li>1);
//       // 	}
//       // 	if (lj==2) {
//       // 	  detachClause(cr, true);
//       // 	  c.shrink(li - lj);
//       // 	  attachClause(cr);
//       // 	}
//       // 	else {
//       // 	  assert(lj>2);
//       // 	  c.shrink(li - lj);
//       // 	}
//       // 	cs[j++] = cr;
//       // }
//     }
//   }
//   cs.shrink(i - j);
// }

// void Solver::collectDynVars() {
//   cleanClausesForNewVars(learnts_core);
//   cleanClausesForNewVars(learnts_tier2);
//   cleanClausesForNewVars(learnts_local);
//   cleanClausesForNewVars(hardens);
//   checkGarbage();
//   dynVars.clear();
//   for(int i=nVars() - 1; i>=staticNbVars; i--) {
//     // if (seen[i])
//     //   seen[i] = 0;
//     // else
//       dynVars.push(i);
//   }
// }

// static bool switch_mode = false;
// #define switch_time 1800

// #ifdef _MSC_VER_Sleep
// void sleep(int time)
// {
//     Sleep(time * 1000);
//     switch_mode = true;
//     printf("switch_mode = true\n");
// }

// #else

// static void SIGALRM_switch(int signum) { switch_mode = true; }
// #endif

// NOTE: assumptions passed in member-variable 'assumptions'.
lbool Solver::solve_()
{
// #ifdef _MSC_VER_Sleep
//     std::thread t(sleep, switch_time);
//     t.detach();
// #else
//     signal(SIGALRM, SIGALRM_switch);
//     alarm(switch_time);
// #endif
    
    model.clear(); usedClauses.clear();
    conflict.clear();
    if (!ok) return l_False;
    
    solves++;
    
    max_learnts               = nClauses() * learntsize_factor;
    learntsize_adjust_confl   = learntsize_adjust_start_confl;
    learntsize_adjust_cnt     = (int)learntsize_adjust_confl;
    lbool   status            = l_Undef;
    
    if (verbosity >= 1){
        printf("c ============================[ Search Statistics ]==============================\n");
        printf("c | Conflicts |          ORIGINAL         |          LEARNT          | Progress |\n");
        printf("c |           |    Vars  Clauses Literals |    Limit  Clauses Lit/Cl |          |\n");
        printf("c ===============================================================================\n");
    }

    addHardClausesForSoftClauses();
    
    add_tmp.clear(); softConflictFlag=false; next_C_reduce = 0;
    UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
    LOOKAHEAD = 0; involvedLits.clear(); lk_propagations=0; nbLKsuccess=0;
    stepSizeLB = 0.4;  subconflicts = 0;
    totalPrunedLB=0; totalPrunedLB2=0; 	derivedCost=0; feasible=false; infeasibleUB = 0;
    nbHardens=0; fixedByHardens=0; constraintRelaxed = false; nbSavedLits = 0;
    savedLOOKAHEAD=0; savednbLKsuccess=0; rootNbIsets=0;

    // UB = softClauses.size();
    // int initSoftClauses = softClauses.size();
    WithNewUB = false;
    
    if (!simplifyOriginalClauses()){
#ifdef BIN_DRUP
        if (drup_file) binDRUP_flush(drup_file);
#endif
        return l_False;
    }

    if (!findConflictSoftLits()) {
      printf("c problem solved by preprocessing\n");
      return l_False;
    }

    if (!detectInitConflicts()) {
      printf("c problem solved by preprocessing2\n");
      return l_False;
    }
    
    int initNbConlf=0; //simplelookahead();
    int fixedCost=0, nbSatLits=0, i, j;

    allSoftLits.clear();
    for(i=0, j=0; i<unitSoftLits.size(); i++) {
    	Lit p=unitSoftLits[i];
    	if (value(p)==l_Undef) {
	  unitSoftLits[j++] = p; allSoftLits.push(p);
	}
    	else if (value(p)==l_False)
      		fixedCost++;
    	else nbSatLits++;
    }
    unitSoftLits.shrink(i-j);
    for(i=0, j=0; i<nonUnitSoftLits.size(); i++) {
      Lit p=nonUnitSoftLits[i];
      if (value(p)==l_Undef) {
	nonUnitSoftLits[j++] = p; allSoftLits.push(p);
      }
      else if (value(p)==l_False)
	fixedCost++;
      else nbSatLits++;
    }
    nonUnitSoftLits.shrink(i-j);
    assert(unitSoftLits.size() + nonUnitSoftLits.size() == allSoftLits.size());
    
    objForSearch = unitSoftLits.size() + nonUnitSoftLits.size() - initNbConlf;
    fixedCostBySearch=fixedCost;  relaxedCost = initNbConlf;
    bestSolutionFound = false;
    bestSup = objForSearch + 1;
    nbSatLitsAtStart = nbSatLits;
    printf("c fixedCost %d, nbSatLits %d, totalFixedVars %d, objForSearch: %llu\n\n", 
	 	fixedCost, nbSatLits, trail.size(), objForSearch);

    counter++;
    for(i=0, j=0; i<allSoftLitsForCardC.size(); i++) {
      Lit p=allSoftLitsForCardC[i];
      if (value(p) == l_Undef) {
	Lit q= imply[toInt(p)];
	if (softLits[var(p)] == p && seen2[var(p)] < counter) {
	  allSoftLitsForCardC[j++] = p; seen2[var(p)] = counter;
	}
	else if (softLits[var(p)] == lit_Undef && q != lit_Undef && seen2[var(q)] < counter) {
	  allSoftLitsForCardC[j++] = q; seen2[var(q)] = counter;
	}
      }
    }
    allSoftLitsForCardC.shrink(i-j);
    assert(allSoftLitsForCardC.size() == allSoftLits.size());

    staticNbVars = nVars();
    int beginning = trail.size();
    falseLits.clear();
    hardenLevel = INT32_MAX;
    uint64_t inf=0, sup= objForSearch+1; //make sure UB=objForSearch+1 is tested
    uint64_t providedUB = INT32_MAX;
    if (initUB <  INT32_MAX) {
      if (initUB >= solutionCost+fixedCostBySearch+derivedCost + relaxedCost) {
	providedUB = initUB - (solutionCost+fixedCostBySearch+derivedCost + relaxedCost) + 1;
	//	sup=UB; feasible=true;
	printf("c provided UB: %llu\n", providedUB);
      }
      else {
	printf("c provided UB is invalide: initUB %llu, solCost %llu, costbySearch %llu, derivedCost %llu, relaxedCost: %llu\n", initUB, solutionCost, fixedCostBySearch, derivedCost, relaxedCost);
	printf("c search from scratch...\n");
      }
    }
    else
      printf("c no UB provided, search from scratch...\n");
    UB=inf+1;
    int nbVSIDSphase=0, nbLRBphase=0;
    do {
      status            = l_Undef;
      add_tmp.clear(); softConflictFlag=false;
      UBconflictFlag=false; softConflictFlag=false; falseVar = var_Undef;
      emitTryUpdate(UB);
      fflush(stdout);

      if (UB == 1)
	harden();

      VSIDS = true;
      int init = 10000;
      while (status == l_Undef && init > 0 && !feasible && !asynch_interrupt)
        status = search(init);
      printf("c ends of initiationization by VSIDS at %llu conflicts with init %d\n\n", 
	     conflicts, init); 
      //  if (!switch_mode)
	VSIDS = false;
      
      // Search:
      uint64_t phase_allotment=20000000;
      int curr_restarts = 0;
      for(; status == l_Undef && !asynch_interrupt ;) {

	//	uint64_t budget = phase_allotment;
	uint64_t savedUP = propagations;
	uint64_t savedConfl = conflicts;
	uint64_t savedRestarts = starts;
	
        fflush(stdout);

        while (status == l_Undef && propagations - savedUP < phase_allotment && !asynch_interrupt) {
	  if (VSIDS) {
	    int weighted = INT32_MAX;
	    status = search(weighted);
	  }
	  else{
	    int nof_conflicts = luby(restart_inc, curr_restarts) * restart_first;
	    curr_restarts++;
	    status = search(nof_conflicts);
	  }
	}
	if (VSIDS) {
	  nbVSIDSphase++;
	  printf("c VSIDS phase %d: conflicts %llu, phase %llu, starts %llu, UP %llu\n",
		 nbVSIDSphase, conflicts-savedConfl, phase_allotment,
		 starts-savedRestarts, propagations-savedUP);
	}
	else  {
	  nbLRBphase++;
	  printf("c LRB phase %d: conflicts %llu, phase %llu, starts %llu, UP %llu\n",
		 nbLRBphase, conflicts-savedConfl, phase_allotment,
		 starts-savedRestarts, propagations-savedUP);
	}

	// if (status != l_Undef /*|| !withinBudget()*/)
        //     break; //
	//Should break here for correctness in incremental SAT solving.
	
	VSIDS = !VSIDS;
        if (!VSIDS)
            phase_allotment *= 2;

      if (asynch_interrupt)
          goto solve_exit_stats;

 //      int curr_restarts = 0;
//       while (status == l_Undef /*&& withinBudget()*/){
//         if (VSIDS){
// 	  int weighted = INT32_MAX;
// 	  status = search(weighted);
//         }else{
// 	  int nof_conflicts = luby(restart_inc, curr_restarts) * restart_first;
// 	  curr_restarts++;
// 	  status = search(nof_conflicts);
//         }
// 	if (!VSIDS && switch_mode){
// 	  VSIDS = true;
// 	  printf("c Switched to VSIDS.\n");
// 	  fflush(stdout);
// 	  picked.clear();
// 	  conflicted.clear();
// 	  almost_conflicted.clear();
// #ifdef ANTI_EXPLORATION
// 	  canceled.clear();
// #endif
// 	}
      }
      assert(status != l_Undef);
      float meanLB=0, dev=0, succRate=0;
      if (nbLKsuccess>savednbLKsuccess) {
	meanLB= (float)totalPrunedLB/(nbLKsuccess-savednbLKsuccess);
	dev = sqrt((float)totalPrunedLB2/(nbLKsuccess-savednbLKsuccess) - meanLB*meanLB);
      }
      if (LOOKAHEAD > savedLOOKAHEAD) 
	succRate = (float) (nbLKsuccess-savednbLKsuccess)/(LOOKAHEAD-savedLOOKAHEAD);
      if (status == l_False) {
	printf("c UB=%llu fails, cnfls=%llu, hcnfls=%llu, core %d, tier2 %d, local %d, quasiC: %llu (fixed: %llu)\n",
	       UB, conflicts, conflicts-softConflicts, learnts_core.size(), learnts_tier2.size(), learnts_local.size(), quasiSoftConflicts, fixedByQuasiConfl);
	printf("c prunedLB %4.2f, dev %4.2f, succRate %4.2f, nbSucc %llu, nbHardens %d (fixed %llu), lk: %llu, shorten: %llu, pureSo %d, nbFlyRd %d, nbFixedLH %llu\n",
	       meanLB, dev, succRate, 
	       nbLKsuccess-savednbLKsuccess, nbHardens, fixedByHardens, LOOKAHEAD-savedLOOKAHEAD, nbSavedLits, pureSoftConfl, nbFlyReduced, nbFixedByLH);
	if (infeasibleUB < UB) {
	  infeasibleUB = UB;
	  emitBoundsUpdate();
	}
	if (feasible) {
	  sup = UB;
	  break;
	}
	cancelUntilBeginning(beginning);
	next_C_reduce = 0;
	next_L_reduce = 0; next_T2_reduce=0; subconflicts = 0; curSimplify = 1; nbconfbeforesimplify=1000;
	totalPrunedLB=0; totalPrunedLB2=0; savedLOOKAHEAD = LOOKAHEAD; savednbLKsuccess=nbLKsuccess;
	inf = UB;
	if (2*UB < (inf + sup+1)/2)
	  UB = 2*UB;
	else
	  UB = (inf + sup+1)/2;
	if (UB > providedUB)
	  UB = providedUB;
	removeLearntClauses();
	rebuildOrderHeap();
      }
      else if (status == l_True) {
	int nbFixeds = trail_lim.size() == 0 ? 0 : trail_lim[0];
	int nbFalses = falseLits_lim.size() == 0 ? 0 : falseLits_lim[0];
	printf("c UB=%llu succ, confls=%llu and hconfls=%llu with %d soft clauses unsat (%d at level 0) and %d fixed vars at level 0,  prunedLB %4.2f, dev %4.2f, succRate %4.2f, nbSucc %llu, shortened : %llu\n",
	       UB, conflicts, conflicts-softConflicts, falseLits.size(), nbFalses, nbFixeds,  
	       meanLB, dev, succRate, nbLKsuccess, nbSavedLits);
	//assert(UB > falseLits.size());
	checkSolution();
	feasible = true;
	// sup = falseLits.size();
	// UB = (inf + sup+1)/2;
	// cancelUntilBeginning(beginning);
	// next_C_reduce = 0;
	// next_L_reduce = 0; next_T2_reduce=0; subconflicts = 0; curSimplify = 1; nbconfbeforesimplify=1000;
	// removeLearntClauses();
	totalPrunedLB=0; totalPrunedLB2=0; WithNewUB=true; //curSimplify = 1; nbconfbeforesimplify=1000;
	savedLOOKAHEAD = LOOKAHEAD; savednbLKsuccess=nbLKsuccess;
	sup = falseLits.size();
	noteBestSolution(sup);
	cancelUntil(0);
	fixedCostBySearch += falseLits.size(); beginning = trail.size();
	for (int i=0; i < learnts_local.size(); i++)
	  removeClause(learnts_local[i]);
	learnts_local.clear();
	for (int i=0; i < learnts_tier2.size(); i++)
	  removeClause(learnts_tier2[i]);
	learnts_tier2.clear();
	watches.cleanAll();
	watches_bin.cleanAll();
	checkGarbage();

	sup -= falseLits.size(); //reduce the number of false lits at level 0
	if (inf > falseLits.size())
	  inf -= falseLits.size();
	else inf=0;
	UB = (inf + sup+1)/2;
	falseLits.clear();
	rebuildOrderHeap();
	//simplify();
      }
      else printf("c error UB %llu, inf %llu, sup %llu\n", UB, inf, sup);
    } while (UB > inf && !asynch_interrupt);

solve_exit_stats:
      if (verbosity >= 1)
        printf("c ===============================================================================\n");
    
#ifdef BIN_DRUP
    if (drup_file && status == l_False) binDRUP_flush(drup_file);
#endif
    
    if (asynch_interrupt)
        printBestSolution();

    // if (status == l_True){
    //     // Extend & copy model:
    //     model.growTo(nVars());
    //     for (int i = 0; i < nVars(); i++) model[i] = value(i);
    // }else if (status == l_False && conflict.size() == 0)
    //     ok = false;
    if (sup == objForSearch+1) {
      lastOptimalCost = UINT64_MAX;
      printf("c no feasible solution, hardConflicts: %llu\n", conflicts - softConflicts);
    } else {
      lastOptimalCost = solutionCost+sup+fixedCostBySearch+derivedCost + relaxedCost;
      printf("c initCost: %llu, fixedBySearch: %llu, optimal: %llu, maxsat: %llu, hardConflicts: %llu\n",
	     solutionCost, fixedCostBySearch, 
	     lastOptimalCost, 
	     objForSearch-sup + nbSatLits, conflicts - softConflicts);
    }
    printf("c nbLK: %llu, nbSuccLK: %llu(%4.2f%%), nbLKup: %llu(%4.2f%%), hardens %u (fixed %llu), dynVars %d, shorten: %llu\n", 
	   LOOKAHEAD, nbLKsuccess, 100.0*nbLKsuccess/LOOKAHEAD, lk_propagations, 
	   100.0*lk_propagations/propagations, nbHardens, fixedByHardens, nVars()-staticNbVars, nbSavedLits);
    
    // printf("v ");
    // for (int i = 0; i < nVars(); i++)
    //   if (model[i] == l_True)
    // 	printf("%d ", 2*i);
    //   else if (model[i] == l_False)
    // 	printf("%d ", 2*i+1);
    //   // if (model[i] != l_Undef)
    //   // 	printf("%s%s%d", (i==0)?"":" ", (model[i]==l_True)?"":"-", i+1);
    // printf(" 0\n");
    
    cancelUntil(0);
    
    return status;
}

//=================================================================================================
// Writing CNF to DIMACS:
//
// FIXME: this needs to be rewritten completely.

static Var mapVar(Var x, vec<Var>& map, Var& max)
{
    if (map.size() <= x || map[x] == -1){
        map.growTo(x+1, -1);
        map[x] = max++;
    }
    return map[x];
}


void Solver::toDimacs(FILE* f, Clause& c, vec<Var>& map, Var& max)
{
    if (satisfied(c)) return;
    
    for (int i = 0; i < c.size(); i++)
        if (value(c[i]) != l_False)
            fprintf(f, "%s%d ", sign(c[i]) ? "-" : "", mapVar(var(c[i]), map, max)+1);
    fprintf(f, "0\n");
}


void Solver::toDimacs(const char *file, const vec<Lit>& assumps)
{
    FILE* f = fopen(file, "wr");
    if (f == NULL)
        fprintf(stderr, "could not open file %s\n", file), exit(1);
    toDimacs(f, assumps);
    fclose(f);
}


void Solver::toDimacs(FILE* f, const vec<Lit>& assumps)
{
    // Handle case when solver is in contradictory state:
    if (!ok){
        fprintf(f, "p cnf 1 2\n1 0\n-1 0\n");
        return; }
    
    vec<Var> map; Var max = 0;
    
    // Cannot use removeClauses here because it is not safe
    // to deallocate them at this point. Could be improved.
    int cnt = 0;
    for (int i = 0; i < clauses.size(); i++)
        if (!satisfied(ca[clauses[i]]))
            cnt++;
    
    for (int i = 0; i < clauses.size(); i++)
        if (!satisfied(ca[clauses[i]])){
            Clause& c = ca[clauses[i]];
            for (int j = 0; j < c.size(); j++)
                if (value(c[j]) != l_False)
                    mapVar(var(c[j]), map, max);
        }
    
    // Assumptions are added as unit clauses:
    cnt += assumptions.size();
    
    fprintf(f, "p cnf %d %d\n", max, cnt);
    
    for (int i = 0; i < assumptions.size(); i++){
        assert(value(assumptions[i]) != l_False);
        fprintf(f, "%s%d 0\n", sign(assumptions[i]) ? "-" : "", mapVar(var(assumptions[i]), map, max)+1);
    }
    
    for (int i = 0; i < clauses.size(); i++)
        toDimacs(f, ca[clauses[i]], map, max);
    
    if (verbosity > 0)
        printf("c Wrote %d clauses with %d variables.\n", cnt, max);
}


//=================================================================================================
// Garbage Collection methods:

void Solver::relocAll(ClauseAllocator& to)
{
    // All watchers:
    //
    // for (int i = 0; i < watches.size(); i++)
    watches.cleanAll();
    watches_bin.cleanAll();
    for (int v = 0; v < nVars(); v++)
        for (int s = 0; s < 2; s++){
            Lit p = mkLit(v, s);
            // printf(" >>> RELOCING: %s%d\n", sign(p)?"-":"", var(p)+1);
            vec<Watcher>& ws = watches[p];
            for (int j = 0; j < ws.size(); j++)
                ca.reloc(ws[j].cref, to);
            vec<Watcher>& ws_bin = watches_bin[p];
            for (int j = 0; j < ws_bin.size(); j++)
                ca.reloc(ws_bin[j].cref, to);
        }
    
    // All reasons:
    //
    for (int i = 0; i < trail.size(); i++){
        Var v = var(trail[i]);
        
        if (reason(v) != CRef_Undef && (ca[reason(v)].reloced() || locked(ca[reason(v)])))
            ca.reloc(vardata[v].reason, to);
    }
    
    // All learnt:
    //
    for (int i = 0; i < learnts_core.size(); i++)
        ca.reloc(learnts_core[i], to);
    for (int i = 0; i < learnts_tier2.size(); i++)
        ca.reloc(learnts_tier2[i], to);
    for (int i = 0; i < learnts_local.size(); i++)
        ca.reloc(learnts_local[i], to);
    
    // All original:
    //
    int i, j;
    for (i = j = 0; i < clauses.size(); i++)
        if (ca[clauses[i]].mark() != 1){
            ca.reloc(clauses[i], to);
            clauses[j++] = clauses[i]; }
    clauses.shrink(i - j);
    
    // // All original used clauses
    // for (i = j = 0; i < usedClauses.size(); i++)
    //     if (ca[usedClauses[i]].mark() != 1){
    //         ca.reloc(usedClauses[i], to);
    //         usedClauses[j++] = usedClauses[i]; }
    // usedClauses.shrink(i - j);

    // //all soft watchers

    // softWatches.cleanAll();
    // for (int v = 0; v < nVars(); v++)
    //   for (int s = 0; s < 2; s++){
    // 	Lit p = mkLit(v, s);
    // 	// printf(" >>> RELOCING: %s%d\n", sign(p)?"-":"", var(p)+1);
    // 	vec<softWatcher>& ws = softWatches[p];
    // 	for (int j = 0; j < ws.size(); j++)
    // 	  ca.reloc(ws[j].cref, to);
    //   }

    for (i = j = 0; i < softClauses.size(); i++)
        if (ca[softClauses[i]].mark() != 1){
            ca.reloc(softClauses[i], to);
            softClauses[j++] = softClauses[i]; }
    softClauses.shrink(i - j);

    for (i = j = 0; i < hardSoftClauses.size(); i++)
        if (ca[hardSoftClauses[i]].mark() != 1){
            ca.reloc(hardSoftClauses[i], to);
            hardSoftClauses[j++] = hardSoftClauses[i]; }
    hardSoftClauses.shrink(i - j);

    for (i = j = 0; i < falseSoftClauses.size(); i++)
        if (ca[falseSoftClauses[i]].mark() != 1){
            ca.reloc(falseSoftClauses[i], to);
            falseSoftClauses[j++] = falseSoftClauses[i]; }
    falseSoftClauses.shrink(i - j);

    for(i=0, j=0; i<hardens.size(); i++)
      if (ca[hardens[i]].mark() != 1){
	ca.reloc(hardens[i], to);
	hardens[j++] = hardens[i];
      }
    hardens.shrink(i - j);

    for(i=0, j=0; i<softLearnts.size(); i++)
      if (ca[softLearnts[i]].mark() != 1){
	ca.reloc(softLearnts[i], to);
	softLearnts[j++] = softLearnts[i];
      }
    softLearnts.shrink(i - j);

    for(i=0, j=0; i<hardLearnts.size(); i++)
      if (ca[hardLearnts[i]].mark() != 1){
	ca.reloc(hardLearnts[i], to);
	hardLearnts[j++] = hardLearnts[i];
      }
    hardLearnts.shrink(i - j);

    for(i=0, j=0; i<cardinalityC.size(); i++)
      if (ca[cardinalityC[i]].mark() != 1){
	ca.reloc(cardinalityC[i], to);
	cardinalityC[j++] = cardinalityC[i];
      }
    cardinalityC.shrink(i - j);

    for(i=0, j=0; i<isetClauses.size(); i++)
      if (ca[isetClauses[i]].mark() != 1){
	ca.reloc(isetClauses[i], to);
	isetClauses[j++] = isetClauses[i];
      }
    isetClauses.shrink(i - j);
    
    // printf("c **** garbage collection done ****\n");
}


void Solver::garbageCollect()
{
    // Initialize the next region to a size corresponding to the estimated utilization degree. This
    // is not precise but should avoid some unnecessary reallocations for the new region:
    ClauseAllocator to(ca.size() - ca.wasted());
    
    relocAll(to);
    // if (verbosity >= 2)
    // printf("c |  Garbage collection:   %12d bytes => %12d bytes             |\n",
    //        ca.size()*ClauseAllocator::Unit_Size, to.size()*ClauseAllocator::Unit_Size);
    to.moveTo(ca);
}

