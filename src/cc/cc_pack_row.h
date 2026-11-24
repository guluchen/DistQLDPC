/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#ifndef DISTQLDPC_CC_PACK_ROW_H
#define DISTQLDPC_CC_PACK_ROW_H
#include <stdint.h>

static inline void cc_tally_pack_row(const uint32_t *row, uint32_t length,
                                     const uint32_t *blocked, const uint64_t *marks,
                                     uint64_t stamp, uint32_t *count, uint32_t *clash) {
    uint32_t available = 0, intersects = 0;
    for (uint32_t j = 0; j < length; ++j) {
        const uint32_t q = row[j];
        const uint32_t free_q = blocked[q] == 0;
        available += free_q;
        intersects |= free_q & (uint32_t)(marks[q] == stamp);
    }
    *count = available;
    *clash = intersects;
}

static inline void cc_mark_pack_row(const uint32_t *row, uint32_t length,
                                    uint64_t *marks, uint64_t stamp) {
    for (uint32_t j = 0; j < length; ++j) marks[row[j]] = stamp;
}
#endif
