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
 * DistQLDPC engine -- module Inprocessing.cc
 *
 * Inprocessing: learnt-clause vivification (Maple_LCM / Maple_CM simplifyLearnt*,
 * simplePropagate, simpleAnalyze*), failed-literal detection, original-clause minimisation.
 *
 * Restructured from MaxCDCL src/solver/Solver.cc by DistQLDPC (GH-95, stage 1): code moved
 * verbatim, search unchanged. The copyright and MIT permission notice above apply to the
 * MaxCDCL / Maple_CM / Maple_LCM / MiniSat code contained in this file (see src/solver/LICENSE).
 *
 * Modifications Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC
 * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).
 */

#ifndef DISTQLDPC_ENGINE_UNITY
#error "src/engine/Inprocessing.cc is part of the engine unity build; compile src/engine/Engine.cc"
#endif

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
