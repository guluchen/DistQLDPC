/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#ifndef DISTQLDPC_CC_LEVEL_H
#define DISTQLDPC_CC_LEVEL_H

#include <stdint.h>
#ifndef __cplusplus
#include <stdbool.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* Borrowed storage from HalfSearch. No allocation or change of coordinates.
   The caller clears syndrome, detector and block arrays and initializes
   by_budget for this level. Packing stamps survive between calls. */
struct cc_level {
    int n, w, mw, kw, maxrow;
    const uint32_t *rstart, *rq, *cstart, *cr;
    const uint64_t *gmask, *colkey;
    const int32_t *htab, *hnext;
    uint64_t hmask;
    uint64_t *syn, *gpar, *mark, *by_budget;
    uint32_t *blk, *cand;
    int *cur;
    bool (*poll)(void *);
    void *poll_ctx;
    uint64_t poll_mask, stamp;
    uint64_t nodes, seeds, closed, nocand, packprune, leaf1, leaf2;
    uint64_t parprune;
    uint64_t synkey;
    int nodd, witness_size;
};

/* Optional production policies. The C traversal owns the prefix, leaf checks,
   syndrome, sibling exclusion and rollback. The owner supplies the original
   branch scan and level-local policy updates against the same borrowed arrays. */
struct cc_erasure_sample {
    int class_id;
    double started, test_seconds;
};
struct cc_level_policy {
    void *owner;
    int seed_count;
    const int *seed;
    const uint32_t *block_start, *block;
    const uint32_t *redundant_start, *redundant_rows;
    bool parity;
    int (*choose_children)(void *, int, int, struct cc_erasure_sample *);
    void (*overlap)(void *, int, bool);
    void (*seed_exemption)(void *, int, bool);
    void (*block_done)(void *, int);
    void (*sample_done)(void *, const struct cc_erasure_sample *);
};

enum cc_level_outcome { CC_LEVEL_EMPTY, CC_LEVEL_FOUND, CC_LEVEL_ABORTED, CC_LEVEL_INCONSISTENT };
enum cc_level_outcome cc_run_level(struct cc_level *s, const struct cc_level_policy *policy);

#ifdef __cplusplus
}
#endif
#endif
