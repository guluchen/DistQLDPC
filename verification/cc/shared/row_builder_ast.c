/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#include "../../../src/cc/cc_row_builder.h"
void (*const append_row_body)(uint32_t *, uint32_t, const uint32_t *, uint32_t, uint32_t *)
    = cc_append_candidate_row;
