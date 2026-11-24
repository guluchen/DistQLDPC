/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#ifndef DISTQLDPC_CC_DISTANCE_BOUNDS_H
#define DISTQLDPC_CC_DISTANCE_BOUNDS_H

#include <limits.h>
#include <stdbool.h>

/* A missing logical half has no finite distance. */
static inline int cc_global_lower(bool has_x, int x_lower, bool has_z, int z_lower) {
    const int x = has_x ? x_lower : INT_MAX;
    const int z = has_z ? z_lower : INT_MAX;
    return x < z ? x : z;
}

/* Called only on an EMPTY verdict. Odd weights can also be excluded when
   every physical column has odd weight. */
static inline int cc_next_after_empty(int weight, bool even_only) {
    int next = weight + 1;
    if (even_only && (next & 1)) ++next;
    return next;
}

/* The current half already proves weight is minimal there. */
static inline bool cc_hit_closes(int weight, bool other_exists, int other_lower) {
    return !other_exists || other_lower >= weight;
}

#endif
