/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#ifndef DISTQLDPC_CC_SEED_POLICY_H
#define DISTQLDPC_CC_SEED_POLICY_H

#include "cc_overlap_policy.h"

struct cc_seed_policy {
    struct cc_overlap_view overlap;
    const int *limit;
    const int32_t *base;
    int32_t *fallback, *current;
    const uint32_t *block_start, *block_qubit;
};

static inline void cc_seed_overlap(void *owner, int q, bool add) {
    struct cc_seed_policy *state = (struct cc_seed_policy *)owner;
    cc_overlap_policy(&state->overlap, q, add);
}

/* At an empty prefix, a zero-limit row forbids every member except
   its exempt qubit. Move precisely this row's contribution. */
static inline void cc_move_exemption(struct cc_seed_policy *state, uint32_t row, int32_t next) {
    const int32_t old = state->current[row];
    if (old == next) return;
    if (state->limit[row] == 0) {
        --state->overlap.blocked[next];
        *state->overlap.forbidden += state->overlap.blocked[old] == 0;
        ++state->overlap.blocked[old];
    }
    state->current[row] = next;
}

static inline void cc_seed_exemption(void *owner, int seed, bool enter) {
    struct cc_seed_policy *state = (struct cc_seed_policy *)owner;
    for (uint32_t i = state->overlap.column_start[seed]; i < state->overlap.column_start[seed + 1]; ++i) {
        const uint32_t row = state->overlap.column_row[i];
        if (state->base[row] < 0) continue;
        int32_t next = seed;
        if (!enter) {
            next = state->fallback[row];
            if (next < 0) next = state->base[row];
        }
        cc_move_exemption(state, row, next);
    }
}

static inline void cc_seed_block_done(void *owner, int block) {
    struct cc_seed_policy *state = (struct cc_seed_policy *)owner;
    for (uint32_t j = state->block_start[block]; j < state->block_start[block + 1]; ++j) {
        const uint32_t q = state->block_qubit[j];
        for (uint32_t i = state->overlap.column_start[q]; i < state->overlap.column_start[q + 1]; ++i) {
            const uint32_t row = state->overlap.column_row[i];
            if (state->base[row] < 0 || state->fallback[row] >= 0) continue;
            state->fallback[row] = (int32_t)q;
            cc_move_exemption(state, row, (int32_t)q);
        }
    }
}
#endif
