/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#include "../../../src/cc/cc_overlap.h"

/* Force the producer to retain the actual inline policy functions. */
void (*cc_overlap_update_body)(struct cc_overlap_view *, int, bool) = cc_update_overlap;
uint64_t (*cc_overlap_block_body)(const uint32_t *, uint32_t, uint32_t, int32_t, uint32_t *) = cc_block_overlap_row;
void (*cc_overlap_unblock_body)(const uint32_t *, uint32_t, uint32_t, int32_t, uint32_t *) = cc_unblock_overlap_row;
