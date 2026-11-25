/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#ifndef DISTQLDPC_CC_ROW_BUILDER_H
#define DISTQLDPC_CC_ROW_BUILDER_H
#include <stdint.h>

/* Caller allocates the combined row table and checks its 32-bit extent. */
static inline void cc_append_candidate_row(uint32_t *flat, uint32_t start,
        const uint32_t *row, uint32_t length, uint32_t *end) {
    for (uint32_t j = 0; j < length; ++j)
        flat[start + j] = row[j];
    *end = start + length;
}
#endif
