/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#include "../../../src/cc/cc_candidate_row.h"

int (*const candidate_row_body)(const uint32_t *, uint32_t, const uint32_t *,
                                uint32_t *) = cc_gather_candidates;
