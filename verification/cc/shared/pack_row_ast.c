/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#include "../../../src/cc/cc_pack_row.h"

/* Both header definitions are also compiled by HalfSearch::choose_children.
   Exporting their addresses keeps the production bodies in generated Clight. */
void (*const pack_tally_body)(const uint32_t *, uint32_t, const uint32_t *,
                              const uint64_t *, uint64_t, uint32_t *, uint32_t *) = cc_tally_pack_row;
void (*const pack_mark_body)(const uint32_t *, uint32_t, uint64_t *, uint64_t) = cc_mark_pack_row;
