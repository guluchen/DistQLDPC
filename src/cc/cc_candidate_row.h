/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#ifndef DISTQLDPC_CC_CANDIDATE_ROW_H
#define DISTQLDPC_CC_CANDIDATE_ROW_H
#include <stdint.h>

/* The output slice holds one complete row. Preserve the order of its
 * available qubits and leave the unused suffix untouched. */
static inline int cc_gather_candidates(const uint32_t *row, uint32_t length,
                                       const uint32_t *blocked, uint32_t *children) {
    int count = 0;
    for (uint32_t j = 0; j < length; ++j) {
        const uint32_t q = row[j];
        if (blocked[q] == 0) {
            children[count] = q;
            ++count;
        }
    }
    return count;
}
#endif
