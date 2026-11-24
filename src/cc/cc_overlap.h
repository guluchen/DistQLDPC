/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later */
#ifndef DISTQLDPC_CC_OVERLAP_H
#define DISTQLDPC_CC_OVERLAP_H

#include <stdbool.h>
#include <stdint.h>

/* The native traversal uses reference counts and has no xorunit trail.
   Each tight stabilizer contributes one block to every nonexempt member. */
struct cc_overlap_view {
    const uint32_t *column_start, *column_row;
    const uint32_t *row_start, *row_qubit;
    const int32_t *exempt;
    int32_t *slack;
    uint32_t *blocked;
    uint32_t first_extra_row;
    uint64_t *tight, *tight_extra, *forbidden;
};

static inline uint64_t cc_block_overlap_row(const uint32_t *qubits, uint32_t begin,
                                            uint32_t end, int32_t exempt, uint32_t *blocked) {
    uint64_t newly_blocked = 0;
    for (uint32_t i = begin; i < end; ++i) {
        const uint32_t q = qubits[i];
        if ((int32_t)q == exempt) continue;
        newly_blocked += blocked[q] == 0;
        ++blocked[q];
    }
    return newly_blocked;
}

static inline void cc_unblock_overlap_row(const uint32_t *qubits, uint32_t begin,
                                          uint32_t end, int32_t exempt, uint32_t *blocked) {
    for (uint32_t i = begin; i < end; ++i) {
        const uint32_t q = qubits[i];
        if ((int32_t)q != exempt) --blocked[q];
    }
}

static inline void cc_update_overlap(struct cc_overlap_view *view, int q, bool add) {
    for (uint32_t i = view->column_start[q]; i < view->column_start[q + 1]; ++i) {
        const uint32_t row = view->column_row[i];
        const int32_t exempt = view->exempt ? view->exempt[row] : -1;
        if (exempt == q) continue;
        if (add) {
            if (--view->slack[row] == 0) {
                ++*view->tight;
                if (row >= view->first_extra_row) ++*view->tight_extra;
                *view->forbidden += cc_block_overlap_row(view->row_qubit, view->row_start[row],
                                                         view->row_start[row + 1], exempt, view->blocked);
            }
        } else if (view->slack[row]++ == 0) {
            cc_unblock_overlap_row(view->row_qubit, view->row_start[row], view->row_start[row + 1],
                                   exempt, view->blocked);
        }
    }
}
#endif
