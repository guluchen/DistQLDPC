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
 * DistQLDPC engine -- module SoftConflict.cc
 *
 * MaxSAT soft-conflict analysis: soft conflicts and quasi soft conflicts
 * (analyzeSoftConflict, simplifyConflictClause, analyzeQuasiSoftConflict, simplifyQuasiConflictClause).
 *
 * Restructured from MaxCDCL src/solver/Solver.cc by DistQLDPC (GH-95, stage 1): code moved
 * verbatim, search unchanged. The copyright and MIT permission notice above apply to the
 * MaxCDCL / Maple_CM / Maple_LCM / MiniSat code contained in this file (see src/solver/LICENSE).
 *
 * Modifications Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC
 * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).
 */

#ifndef DISTQLDPC_ENGINE_UNITY
#error "src/engine/SoftConflict.cc is part of the engine unity build; compile src/engine/Engine.cc"
#endif
  

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
