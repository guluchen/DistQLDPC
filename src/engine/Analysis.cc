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
 * DistQLDPC engine -- module Analysis.cc
 *
 * Hard-conflict analysis: first-UIP learning, minimisation (litRedundant, binResMinimize),
 * analyzeFinal, on-the-fly clause reduction, all-UIP and first-UIP collection helpers.
 *
 * Restructured from MaxCDCL src/solver/Solver.cc by DistQLDPC (GH-95, stage 1): code moved
 * verbatim, search unchanged. The copyright and MIT permission notice above apply to the
 * MaxCDCL / Maple_CM / Maple_LCM / MiniSat code contained in this file (see src/solver/LICENSE).
 *
 * Modifications Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC
 * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).
 */

#ifndef DISTQLDPC_ENGINE_UNITY
#error "src/engine/Analysis.cc is part of the engine unity build; compile src/engine/Engine.cc"
#endif

void Solver::reduceClause(CRef cr, int pathC) {
  if (ca[cr].xorc()) return;   // GH-98: XOR clauses are not strengthened
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
