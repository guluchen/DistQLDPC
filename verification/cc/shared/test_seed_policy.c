/* SPDX-License-Identifier: GPL-3.0-or-later */
#include "../../../src/cc/cc_seed_policy.h"
#include <assert.h>

static void check_state(const struct cc_seed_policy *s, int r0, int r1, int r2) {
    const int expected[] = {r0, r1, r2, -1};
    const unsigned inherited[] = {0, 2, 1, 1};
    for (int r = 0; r < 4; ++r) assert(s->current[r] == expected[r]);
    for (int q = 0; q < 4; ++q) {
        unsigned count = inherited[q];
        for (int r = 0; r < 2; ++r)
            if ((q == 0 || q == r + 1) && q != expected[r]) ++count;
        assert(s->overlap.blocked[q] == count);
    }
}

int main(void) {
    const uint32_t columns[] = {0, 3, 6, 9, 11};
    const uint32_t rows[] = {0,1,2, 0,2,3, 1,2,3, 2,3};
    const uint32_t blocks[] = {0,2,4}, qubits[] = {2,1,0,3};
    const int limit[] = {0,0,1,1};
    const int32_t base[] = {1,2,3,-1};
    int32_t current[] = {1,2,3,-1}, fallback[] = {-1,-1,-1,-1};
    uint32_t blocked[] = {2,2,1,1};
    uint64_t events = 0;
    struct cc_seed_policy s = {
        .overlap = {.column_start=columns, .column_row=rows, .exempt=current,
                    .blocked=blocked, .forbidden=&events},
        .limit=limit, .base=base, .fallback=fallback, .current=current, .block_start=blocks, .block_qubit=qubits
    };
    cc_seed_exemption(&s, 0, true);
    check_state(&s,0,0,0);
    assert(events == 0);
    cc_seed_exemption(&s, 0, false);
    check_state(&s,1,2,3);
    assert(events == 1);
    cc_seed_block_done(&s, 0);
    check_state(&s,1,2,2);
    for (int r = 0; r < 4; ++r) assert(fallback[r] == current[r]);
    cc_seed_exemption(&s, 0, true);
    check_state(&s,0,0,0);
    cc_seed_exemption(&s, 0, false);
    check_state(&s,1,2,2);
    cc_seed_block_done(&s, 1);
    check_state(&s,1,2,2);
    assert(events == 2);
    return 0;
}
