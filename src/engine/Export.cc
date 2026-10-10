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
 * DistQLDPC engine -- module Export.cc
 *
 * Instance export: toDimacs, toWcnf, toOpb.
 *
 * Restructured from MaxCDCL src/solver/Solver.cc by DistQLDPC (GH-95, stage 1): code moved
 * verbatim, search unchanged. The copyright and MIT permission notice above apply to the
 * MaxCDCL / Maple_CM / Maple_LCM / MiniSat code contained in this file (see src/solver/LICENSE).
 *
 * Modifications Copyright (C) 2025-2026 Yu-Fang Chen <yfc@iis.sinica.edu.tw>, part of DistQLDPC
 * (GPL-3.0-or-later when distributed as this project; see LICENSE, NOTICE, MODIFICATIONS.md).
 */

#ifndef DISTQLDPC_ENGINE_UNITY
#error "src/engine/Export.cc is part of the engine unity build; compile src/engine/Engine.cc"
#endif

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


void Solver::toWcnf(const char* file)
{
    FILE* f = fopen(file, "w");
    if (f == NULL)
        fprintf(stderr, "could not open file %s\n", file), exit(1);
    toWcnf(f);
    fclose(f);
}

void Solver::toWcnf(FILE* f)
{
    if (!ok) {
        fprintf(f, "p wcnf 1 2 %u\n", hardWeight > 0 ? (unsigned)hardWeight : 1u);
        fprintf(f, "%u 1 0\n", hardWeight > 0 ? (unsigned)hardWeight : 1u);
        fprintf(f, "%u -1 0\n", hardWeight > 0 ? (unsigned)hardWeight : 1u);
        return;
    }

    int cnt = 0;
    for (int i = 0; i < softClauses.size(); i++)
        if (!satisfied(ca[softClauses[i]]))
            cnt++;
    for (int i = 0; i < clauses.size(); i++)
        if (!satisfied(ca[clauses[i]]))
            cnt++;

    unsigned top = hardWeight > 0 ? (unsigned)hardWeight : 1u;
    fprintf(f, "p wcnf %d %d %u\n", nVars(), cnt, top);

    for (int i = 0; i < softClauses.size(); i++) {
        Clause& c = ca[softClauses[i]];
        if (satisfied(c))
            continue;
        fprintf(f, "1");
        for (int j = 0; j < c.size(); j++)
            if (value(c[j]) != l_False)
                fprintf(f, " %d", (var(c[j]) + 1) * (sign(c[j]) ? -1 : 1));
        fprintf(f, " 0\n");
    }
    for (int i = 0; i < clauses.size(); i++) {
        Clause& c = ca[clauses[i]];
        if (satisfied(c))
            continue;
        fprintf(f, "%u", top);
        for (int j = 0; j < c.size(); j++)
            if (value(c[j]) != l_False)
                fprintf(f, " %d", (var(c[j]) + 1) * (sign(c[j]) ? -1 : 1));
        fprintf(f, " 0\n");
    }
}

void Solver::toOpb(const char* file)
{
    FILE* f = fopen(file, "w");
    if (f == NULL)
        fprintf(stderr, "could not open file %s\n", file), exit(1);
    toOpb(f);
    fclose(f);
}

void Solver::toOpb(FILE* f)
{
    if (!ok) {
        fprintf(f, "* #variable= 1 #constraint= 2\n");
        fprintf(f, "min: 1 x1 ;\n");
        fprintf(f, "+1 x1 >= 1;\n");
        fprintf(f, "+1 ~x1 >= 1;\n");
        return;
    }

    int ncons = 0;
    for (int i = 0; i < clauses.size(); i++)
        if (!satisfied(ca[clauses[i]]))
            ncons++;

    fprintf(f, "* #variable= %d #constraint= %d\n", nVars(), ncons);
    fprintf(f, "* DistQLDPC symplectic MaxSAT (minimize Pauli weight)\n");

    fprintf(f, "min:");
    bool obj = false;
    for (int i = 0; i < softClauses.size(); i++) {
        Clause& c = ca[softClauses[i]];
        if (satisfied(c))
            continue;
        for (int j = 0; j < c.size(); j++) {
            if (value(c[j]) == l_False)
                continue;
            int v = var(c[j]) + 1;
            if (sign(c[j])) {
                fprintf(f, " +1 x%d", v);
                obj = true;
            } else {
                fprintf(f, " +1 ~x%d", v);
                obj = true;
            }
        }
    }
    if (!obj)
        fprintf(f, " 0 x1");
    fprintf(f, " ;\n");

    for (int i = 0; i < clauses.size(); i++) {
        Clause& c = ca[clauses[i]];
        if (satisfied(c))
            continue;
        bool first = true;
        for (int j = 0; j < c.size(); j++) {
            if (value(c[j]) == l_False)
                continue;
            int v = var(c[j]) + 1;
            if (first) {
                if (sign(c[j])) fprintf(f, "+1 ~x%d", v);
                else fprintf(f, "+1 x%d", v);
                first = false;
            } else {
                if (sign(c[j])) fprintf(f, " +1 ~x%d", v);
                else fprintf(f, " +1 x%d", v);
            }
        }
        fprintf(f, " >= 1;\n");
    }
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
