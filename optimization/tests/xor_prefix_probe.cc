// Test actual production clauses, not a copied XOR implementation.
#define main distqldpc_application_main
#include "../../src/core/distqldpc.cc"
#undef main

class ProbeSolver : public SimpSolver {
public:
    bool holds(unsigned assignment) {
        if (!okay()) return false;
        for (int i = 0; i < trail.size(); ++i)
            if (!lit_value(trail[i], assignment)) return false;
        for (int i = 0; i < clauses.size(); ++i) {
            const Clause& c = ca[clauses[i]];
            bool sat = false;
            for (int j = 0; j < c.size(); ++j)
                sat = sat || lit_value(c[j], assignment);
            if (!sat) return false;
        }
        return true;
    }
    static bool lit_value(Lit p, unsigned assignment) {
        return ((assignment >> var(p)) & 1u) != (unsigned)sign(p);
    }
};

int main(int argc, char** argv) {
    if (argc == 2) {
        std::string prefix(argv[1]);
        Matrix hx = load_matrix((prefix + "_Hx.txt").c_str());
        Matrix hz = load_matrix((prefix + "_Hz.txt").c_str());
        Matrix gx = load_matrix((prefix + "_Gx.txt").c_str());
        Matrix gz = load_matrix((prefix + "_Gz.txt").c_str());
        size_t gates[2];
        for (int shared = 0; shared < 2; ++shared) {
            ProbeSolver S; std::vector<Var> aux; StabilizerInstance meta;
            if (!build_stabilizer_instance(S, aux, meta, hx, hz, gx, gz,
                                           0, 0, -1, shared != 0)) return 7;
            gates[shared] = aux.size();
        }
        printf("{\"uncached_gates\":%llu,\"shared_gates\":%llu}\n",
               (unsigned long long)gates[0], (unsigned long long)gates[1]);
        return 0;
    }
    if (argc != 1) return 8;
    int checks = 0;
    for (int length = 1; length <= 3; ++length) {
        int count = 1;
        for (int i = 0; i < length; ++i) count *= 8;
        for (int index = 0; index < count; ++index) {
            ProbeSolver S;
            S.parsing = true;
            S.hardWeight = 1000;
            for (int v = 0; v < 4; ++v) S.newVar();
            XorPrefixCache cache;
            std::vector<Var> aux;
            std::vector<Lit> inputs;
            int value = index;
            for (int i = 0; i < length; ++i) {
                int id = value % 8; value /= 8;
                inputs.push_back(mkLit(id / 2, id % 2));
            }
            Lit p = parity(S, inputs, aux, &cache);
            const size_t gates = aux.size();
            if (parity(S, inputs, aux, &cache) != p || aux.size() != gates) return 2;
            std::vector<Lit> branch = inputs;
            branch.push_back(mkLit((index + 1) % 4, true));
            Lit q = parity(S, branch, aux, &cache);
            if (aux.size() != gates + 1 || S.nVars() >= 24) return 3;
            for (unsigned base = 0; base < 16; ++base) {
                bool expected_p = false, expected_q = false;
                for (size_t i = 0; i < inputs.size(); ++i)
                    expected_p ^= ProbeSolver::lit_value(inputs[i], base);
                for (size_t i = 0; i < branch.size(); ++i)
                    expected_q ^= ProbeSolver::lit_value(branch[i], base);
                int extensions = 0;
                for (unsigned extra = 0; extra < (1u << (S.nVars() - 4)); ++extra) {
                    unsigned assignment = base | (extra << 4);
                    if (!S.holds(assignment)) continue;
                    ++extensions;
                    if (ProbeSolver::lit_value(p, assignment) != expected_p ||
                        ProbeSolver::lit_value(q, assignment) != expected_q) return 4;
                }
                if (extensions != 1) return 5;
            }
            ++checks;
        }
    }
    // Unsigned reversed operands are distinct keys; a new solver has a new cache.
    for (int round = 0; round < 2; ++round) {
        ProbeSolver S; S.parsing = true; S.hardWeight = 1000;
        S.newVar(); S.newVar();
        XorPrefixCache cache; std::vector<Var> aux;
        Lit a = xor2(S, mkLit(0), mkLit(1), aux, &cache);
        Lit b = xor2(S, mkLit(1), mkLit(0), aux, &cache);
        if (a == b || aux.size() != 2 || cache.size() != 2) return 6;
    }
    printf("{\"status\":\"PASS\",\"signed_chain_cases\":%d,\"base_assignments_per_case\":16}\n", checks);
    return 0;
}
