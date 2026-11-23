/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#ifndef DISTQLDPC_CC_EPOCH_H
#define DISTQLDPC_CC_EPOCH_H
#include <stddef.h>
#include <stdint.h>

/* Zero denotes an unused slot. Before issuing a tag for a second time,
   invalidate every array that shares that counter. */
static inline void cc_clear_tags(uint64_t *tags, size_t n) {
    for (size_t i = 0; i < n; ++i) tags[i] = 0;
}

static inline uint64_t cc_next_tag(uint64_t last, uint64_t *tags, size_t n) {
    if (last == UINT64_MAX) {
        cc_clear_tags(tags, n);
        return 1;
    }
    return last + 1;
}

/* The erasure policy uses consecutive tags for peeled and affected
   qubits. Both tags must stay distinct from the unused value. */
#ifdef __cplusplus
extern "C" {
#endif
uint64_t cc_next_tag_pair(uint64_t last, uint64_t *qubits, size_t nq,
                          uint64_t *rows, size_t nr, uint64_t *slots, size_t ns);
#ifdef __cplusplus
}
#endif
#endif
