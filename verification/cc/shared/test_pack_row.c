/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#include "../../../src/cc/cc_pack_row.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    const uint64_t tags[] = {1, UINT64_C(0x8000000000000000), UINT64_MAX};
    const uint32_t rows[][4] = {{0, 1, 2, 3}, {3, 1, 2, 0}, {1, 1, 2, 1}};
    unsigned cases = 0;
    for (unsigned a = 0; a < 16; ++a)
    for (unsigned b = 0; b < 16; ++b)
    for (unsigned t = 0; t < 3; ++t)
    for (unsigned row = 0; row < 3; ++row)
    for (unsigned n = 0; n <= 4; ++n) {
        uint32_t blocked[4], count = UINT32_MAX, clash = UINT32_MAX;
        uint64_t marks[4], expected[4];
        unsigned want_count = 0, want_clash = 0;
        for (unsigned q = 0; q < 4; ++q) {
            blocked[q] = a & (1u << q) ? UINT32_MAX : 0;
            marks[q] = b & (1u << q) ? tags[t] : 0;
        }
        memcpy(expected, marks, sizeof marks);
        for (unsigned i = 0; i < n; ++i) {
            unsigned q = rows[row][i];
            if (!blocked[q]) {
                ++want_count;
                if (marks[q] == tags[t]) want_clash = 1;
            }
            expected[q] = tags[t];
        }
        cc_tally_pack_row(rows[row], n, blocked, marks, tags[t], &count, &clash);
        assert(count == want_count && clash == want_clash);
        cc_mark_pack_row(rows[row], n, marks, tags[t]);
        assert(memcmp(marks, expected, sizeof marks) == 0);
        ++cases;
    }
    uint32_t count, clash;
    cc_tally_pack_row(NULL, 0, NULL, NULL, 0, &count, &clash);
    assert(count == 0 && clash == 0);
    cc_mark_pack_row(NULL, 0, NULL, 0);
    printf("%u packing row cases and an empty null slice passed\n", cases);
    return 0;
}
