/* SPDX-License-Identifier: GPL-3.0-or-later */
#include "cc_half.h"
#include <cassert>
#include <cstdint>
#include <cstdio>

/* Reusing a workspace at the numeric boundary must give the same charge
   bound, counts and loads as starting from a fresh workspace. */
int main() {
    const uint32_t offsets[] = {0, 2, 4, 6};
    const uint32_t qubits[] = {0, 1, 1, 2, 0, 2};
    unsigned trials = 0;
    for (unsigned mask = 0; mask < 8; ++mask)
        for (int budget = -1; budget < 4; ++budget)
            for (bool raise : {false, true}) {
                distcc::LbWork fresh, reused;
                fresh.reset(3, 3);
                reused.reset(3, 3);
                reused.st = UINT64_MAX;
                for (unsigned q = 0; q < 3; ++q) {
                    reused.mk[q] = (mask & (1u << q)) ? 1 : 0;
                    reused.cnt[q] = 7;
                    reused.load[q] = 25;
                }
                int want = distcc::lb_charge(offsets, qubits, 3, budget, fresh, 0, raise);
                int got = distcc::lb_charge(offsets, qubits, 3, budget, reused, 0, raise);
                assert(want == got && fresh.st == reused.st);
                assert(fresh.cnt == reused.cnt && fresh.load == reused.load && fresh.mk == reused.mk);
                ++trials;
            }
    std::printf("PASS %u charge workspace boundary cases\n", trials);
}
