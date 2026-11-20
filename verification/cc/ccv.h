/* SPDX-License-Identifier: GPL-3.0-or-later
 * DistQLDPC plain-C CC verification fork. Implementation, not yet VST-proved.
 * Copyright (C) 2026 Yu-Fang Chen. */
#ifndef CCV_H
#define CCV_H
#define CCV_EXCL 1u
#define CCV_PACK 2u
#define CCV_LEAF 4u
#define CCV_OVERLAP 8u
#define CCV_CHARGE 16u
#define CCV_MRV 32u
#define CCV_ALL 63u
#define CCV_INVALID (-2)
#define CCV_UNKNOWN (-1)
#define CCV_EMPTY 0
#define CCV_FOUND 1
struct ccv_problem {
    unsigned int n, checks, logical_rows, stabilizers;
    const unsigned char *h, *logical, *stabilizer;
};
struct ccv_frame {
    unsigned int row, next, chosen, mark, phase;
};
struct ccv_workspace {
    unsigned int capacity, frame_capacity;
    unsigned char *selected, *forbidden, *syndrome, *logical_value, *packed;
    unsigned int *undo;
    struct ccv_frame *frames;
};
struct ccv_stats {
    unsigned int steps, nodes, pack_prunes, charge_prunes, overlap_prunes;
};
/* Caller memory contract: problem/workspace/stats objects and output scalars
 * live and disjoint from matrices and all writable arrays. Input matrices may
 * alias one another (all read-only). Writable arrays are pairwise disjoint:
 * selected,forbidden,packed,witness: n bytes; syndrome: checks bytes;
 * logical_value: logical_rows bytes; undo: n unsigned ints; frames: n frames.
 * capacity/frame_capacity >=n. All row-major matrices have their stated extent.
 * Zero-length matrices may have null pointers. No arbitrary-pointer validation.
 * Shapes/bit values/stabilizer kernel membership are checked at runtime.
 * Products and frame/undo extents must fit a 32-bit signed byte offset.
 * n>=1; logical_rows>=1. H/L define a single nontrivial-logical search problem.
 * FOUND supplies 1<=weight<=cap, H e=0,L e!=0. EMPTY means no such e exists.
 * UNKNOWN (budget exhausted) makes no lower-bound claim. INVALID is rejection.
 * Non-FOUND witness bytes and distance are zero after shape validation; INVALID
 * outputs are unspecified. Workspace is scratch, not a resumable checkpoint.
 * Whole call budget counts state-machine iterations, not time; includes all
 * levels for distance(). Fixed-loop validation/pruning work is not fuelled.
 */
int ccv_decide(const struct ccv_problem *, unsigned int cap, unsigned int budget,
               unsigned int rules, struct ccv_workspace *, unsigned char *,
               struct ccv_stats *);
int ccv_distance(const struct ccv_problem *, unsigned int budget,
                 unsigned int rules, struct ccv_workspace *, unsigned char *,
                 unsigned int *, struct ccv_stats *);
/* Small proof-facing primitives. A bit is an unsigned char in {0,1}. */
unsigned int ccv_bit_xor(unsigned int a, unsigned int b);
unsigned int ccv_ceil_div(unsigned int a, unsigned int b);
unsigned int ccv_dot(unsigned int n, const unsigned char *, const unsigned char *);
unsigned int ccv_weight(unsigned int n, const unsigned char *);
void ccv_toggle(unsigned int n, unsigned char *, const unsigned char *);
#endif
