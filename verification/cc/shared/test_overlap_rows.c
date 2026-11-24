/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#include "../../../src/cc/cc_overlap.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    const uint32_t rows[] = {0, 2, 1, 3, 0, 2, 1};
    unsigned cases = 0;
    for (uint32_t lo = 0; lo <= 7; ++lo)
        for (uint32_t hi = lo; hi <= 7; ++hi)
            for (int32_t exempt = -1; exempt < 4; ++exempt)
                for (unsigned state = 0; state < 81; ++state) {
                    uint32_t before[4], blocked[4], expected[4], count = 0;
                    for (unsigned q = 0, digits = state; q < 4; ++q, digits /= 3) {
                        before[q] = digits % 3;
                        unsigned multiplicity = 0;
                        for (uint32_t j = lo; j < hi; ++j) multiplicity += rows[j] == q;
                        if ((int32_t)q == exempt) multiplicity = 0;
                        expected[q] = before[q] + multiplicity;
                        count += before[q] == 0 && multiplicity > 0;
                    }
                    memcpy(blocked, before, sizeof blocked);
                    assert(cc_block_overlap_row(rows, lo, hi, exempt, blocked) == count);
                    assert(memcmp(blocked, expected, sizeof blocked) == 0);
                    cc_unblock_overlap_row(rows, lo, hi, exempt, blocked);
                    assert(memcmp(blocked, before, sizeof blocked) == 0);
                    ++cases;
                }
    assert(cc_block_overlap_row(NULL, 0, 0, -1, NULL) == 0);
    cc_unblock_overlap_row(NULL, 0, 0, -1, NULL);
    printf("PASS %u row cases and empty null range\n", cases);
}
