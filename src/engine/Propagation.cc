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

/*
 * DistQLDPC engine -- module Propagation.cc
 *
 * Trail and unit propagation: backtracking (cancelUntil, cancelUntilBeginning),
 * uncheckedEnqueue, propagate, and lPropagate (propagation followed by hardening).
 *
 * Restructured from MaxCDCL src/solver/Solver.cc by DistQLDPC (GH-95, stage 1): code moved
 * verbatim, search unchanged. The copyright and MIT permission notice above apply to the
 * MaxCDCL / Maple_CM / Maple_LCM / MiniSat code contained in this file (see src/solver/LICENSE).
 *
 * Modifications Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC
 * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).
 */

#ifndef DISTQLDPC_ENGINE_UNITY
#error "src/engine/Propagation.cc is part of the engine unity build; compile src/engine/Engine.cc"
#endif


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
