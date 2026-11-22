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
    uint64_t synkey;
    int nodd, witness_size;
};

enum cc_level_outcome { CC_LEVEL_EMPTY, CC_LEVEL_FOUND, CC_LEVEL_ABORTED, CC_LEVEL_INCONSISTENT };
enum cc_level_outcome cc_run_level(struct cc_level *s);

#ifdef __cplusplus
}
#endif
#endif
