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
            std::vector<Var> aux;
            std::vector<Lit> inputs;
            int value = index;
            for (int i = 0; i < length; ++i) {
                int id = value % 8; value /= 8;
                inputs.push_back(mkLit(id / 2, id % 2));
            }
            Lit p = parity(S, inputs, aux);
            for (unsigned base = 0; base < 16; ++base) {
                bool expected_p = false;
                for (size_t i = 0; i < inputs.size(); ++i)
                    expected_p ^= ProbeSolver::lit_value(inputs[i], base);
                int extensions = 0;
                for (unsigned extra = 0; extra < (1u << (S.nVars() - 4)); ++extra) {
                    unsigned assignment = base | (extra << 4);
                    if (!S.holds(assignment)) continue;
                    ++extensions;
                    if (ProbeSolver::lit_value(p, assignment) != expected_p) return 4;
                }
                if (extensions != 1) return 5;
            }
            ++checks;
        }
    }
    printf("{\"status\":\"PASS\",\"signed_chain_cases\":%d,\"base_assignments_per_case\":16}\n", checks);
    return 0;
}
