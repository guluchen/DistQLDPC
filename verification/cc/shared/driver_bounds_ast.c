/* SPDX-License-Identifier: GPL-3.0-or-later */
#include "../../../src/cc/cc_distance_bounds.h"

int (*const global_lower_body)(bool, int, bool, int) = cc_global_lower;
int (*const next_after_empty_body)(int, bool) = cc_next_after_empty;
bool (*const hit_closes_body)(int, bool, int) = cc_hit_closes;
