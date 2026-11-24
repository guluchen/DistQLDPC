/* SPDX-License-Identifier: GPL-3.0-or-later */
#include "../../../src/cc/cc_overlap_policy.h"

void (*cc_overlap_policy_body)(void *, int, bool) = cc_overlap_policy;
