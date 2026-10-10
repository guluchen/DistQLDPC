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
 * DistQLDPC engine -- module Search.cc
 *
 * Search driver: search (CDCL + branch-and-bound loop) and solve_ (UB/LB iteration,
 * restarts, DistQLDPC multi-instance controls).
 *
 * Restructured from MaxCDCL src/solver/Solver.cc by DistQLDPC (GH-95, stage 1): code moved
 * verbatim, search unchanged. The copyright and MIT permission notice above apply to the
 * MaxCDCL / Maple_CM / Maple_LCM / MiniSat code contained in this file (see src/solver/LICENSE).
 *
 * Modifications Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC
 * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).
 */

#ifndef DISTQLDPC_ENGINE_UNITY
#error "src/engine/Search.cc is part of the engine unity build; compile src/engine/Engine.cc"
#endif

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
    
    uint64_t& prevUB = srch_prevUB;  // GH-73: was function-local static
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
	      if (stopAtFirstSolution)  // GH-73: feasibility test only; outer loop records it and stops
		return l_True;
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
lbool Solver::solveMain_()   // GH-98: wrapped by solve_() in Xor.cc
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

    if (xorEnabled) xorDetect();   // GH-98

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
	if (strictUB) {  // GH-73: forced cost already exceeds the hard cap: no solution under it
	  lastOptimalCost = UINT64_MAX;
	  printf("c strict UB below forced cost: no solution under the cap\n");
	  cancelUntil(0);
	  return l_False;
	}
	printf("c search from scratch...\n");
      }
    }
    else
      printf("c no UB provided, search from scratch...\n");
    if (initLB > 0) {  // GH-73: start from a lower bound proven by an earlier run on this instance
      uint64_t offs = solutionCost+fixedCostBySearch+derivedCost + relaxedCost;
      if (initLB > offs) {
	inf = initLB - offs;
	infeasibleUB = inf;
	printf("c provided LB: %llu (search units %llu)\n", initLB, inf);
      }
    }
    if (strictUB && initUB < INT32_MAX && inf + 1 > providedUB) {  // GH-73: known LB above the cap
      lastOptimalCost = UINT64_MAX;
      printf("c provided LB above strict UB: no solution under the cap\n");
      cancelUntil(0);
      return l_False;
    }
    UB=inf+1;
    if (strictUB && (UB > providedUB || startAtCap)) UB = providedUB;
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
	if (stopAtFirstSolution) break;  // GH-73: feasibility test only
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
