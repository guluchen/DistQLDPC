/* SPDX-License-Identifier: GPL-3.0-or-later */
#include "../../../src/cc/cc_seed_policy.h"

void (*cc_seed_overlap_body)(void *, int, bool) = cc_seed_overlap;
void (*cc_seed_exemption_body)(void *, int, bool) = cc_seed_exemption;
void (*cc_seed_block_done_body)(void *, int) = cc_seed_block_done;
