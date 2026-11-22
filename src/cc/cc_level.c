/* Copyright (C) 2026 Yu-Fang Chen. SPDX-License-Identifier: GPL-3.0-or-later
 * DistQLDPC's connected-cluster weight-level traversal.
 * All column keys are filters: closure always compares physical syndromes. */
#include "cc_level.h"
#include <stddef.h>

static inline void toggle(struct cc_level *s, int q) {
    for (uint32_t i = s->cstart[q]; i < s->cstart[q + 1]; ++i) {
        uint32_t r = s->cr[i];
        uint64_t bit = UINT64_C(1) << (r & 63);
        uint64_t updated = s->syn[r >> 6] ^ bit;
        s->syn[r >> 6] = updated;
        s->nodd += (updated & bit) ? 1 : -1;
    }
    s->synkey ^= s->colkey[q];
    const uint64_t *g = s->gmask + (size_t)q * s->kw;
    for (int i = 0; i < s->kw; ++i) s->gpar[i] ^= g[i];
}

static inline int detected(const struct cc_level *s) {
    uint64_t acc = 0;
    for (int i = 0; i < s->kw; ++i) acc |= s->gpar[i];
    return acc != 0;
}

static inline int closes(const struct cc_level *s, int q) {
    uint32_t begin = s->cstart[q], end = s->cstart[q + 1];
    if (end - begin != (uint32_t)s->nodd) return 0;
    for (uint32_t i = begin; i < end; ++i) {
        uint32_t r = s->cr[i];
        if (((s->syn[r >> 6] >> (r & 63)) & 1) == 0) return 0;
    }
    const uint64_t *g = s->gmask + (size_t)q * s->kw;
    uint64_t acc = 0;
    for (int j = 0; j < s->kw; ++j) acc |= s->gpar[j] ^ g[j];
    return acc != 0;
}

static inline int closing_qubit(const struct cc_level *s) {
    uint64_t i = s->synkey & s->hmask;
    for (;;) {
        int h = s->htab[i];
        if (h < 0) return -1;
        if (s->colkey[h] == s->synkey) {
            for (int q = h; q >= 0; q = s->hnext[q])
                if (s->blk[q] == 0 && closes(s, q)) return q;
            return -1;
        }
        i = (i + 1) & s->hmask;
    }
}

static inline int index_children(struct cc_level *s, int size, uint32_t *children) {
    uint64_t stamp = ++s->stamp;
    int packed = 0, branch = -1;
    for (int wi = 0; wi < s->mw; ++wi) {
        uint64_t odd = s->syn[wi];
        while (odd) {
            int r = 64 * wi + __builtin_ctzll(odd);
            odd &= odd - 1;
            uint32_t count = 0, clash = 0;
            uint32_t begin = s->rstart[r], end = s->rstart[r + 1];
            for (uint32_t i = begin; i < end; ++i) {
                uint32_t q = s->rq[i], free_q = s->blk[q] == 0;
                count += free_q;
                clash |= free_q & (s->mark[q] == stamp);
            }
            if (!count) { ++s->nocand; return 0; }
            if (!clash) {
                if (++packed > s->w - size) { ++s->packprune; return 0; }
                for (uint32_t i = begin; i < end; ++i) s->mark[s->rq[i]] = stamp;
            }
            if (branch < 0) branch = r;
        }
    }
    if (branch < 0) return 0;

    int count = 0;
    for (uint32_t i = s->rstart[branch]; i < s->rstart[branch + 1]; ++i)
        if (!s->blk[s->rq[i]]) children[count++] = s->rq[i];
    return count;
}

static inline void flip(struct cc_level *s, const struct cc_level_policy *policy, int q) {
    toggle(s, q);
    if (policy && policy->redundant_start) {
        for (uint32_t i = policy->redundant_start[q]; i < policy->redundant_start[q + 1]; ++i) {
            const uint32_t row = policy->redundant_rows[i];
            s->syn[row >> 6] ^= UINT64_C(1) << (row & 63);
        }
    }
}

static enum cc_level_outcome dfs(struct cc_level *s, const struct cc_level_policy *policy, int size) {
    ++s->nodes;
    ++s->by_budget[s->w - size];
    if (s->poll && !(s->nodes & s->poll_mask) && s->poll(s->poll_ctx)) return CC_LEVEL_ABORTED;
    if (size == s->w) {
        if (s->nodd || !detected(s)) return CC_LEVEL_EMPTY;
        s->witness_size = size;
        return CC_LEVEL_FOUND;
    }
    if (!s->nodd) {
        ++s->closed;
        if (!detected(s)) return CC_LEVEL_EMPTY;
        s->witness_size = size;
        return CC_LEVEL_INCONSISTENT;
    }
    if (policy && policy->parity && ((s->w - size - s->nodd) & 1)) {
        ++s->parprune;
        return CC_LEVEL_EMPTY;
    }
    if (size == s->w - 1) {
        ++s->leaf1;
        int q = closing_qubit(s);
        if (q < 0) return CC_LEVEL_EMPTY;
        s->cur[size] = q;
        s->witness_size = size + 1;
        return CC_LEVEL_FOUND;
    }

    struct cc_erasure_sample sample = { -1, 0, 0 };
    uint32_t *children = s->cand + (size_t)size * s->maxrow;
    const int count = policy ? policy->choose_children(policy->owner, size, s->nodd, &sample)
                             : index_children(s, size, children);
    const bool update_overlap = policy && policy->overlap && s->w - size > 3;
    int excluded = 0;
    enum cc_level_outcome result = CC_LEVEL_EMPTY;
    for (int i = 0; i < count; ++i) {
        int a = (int)children[i];
        ++s->blk[a];
        flip(s, policy, a);
        if (update_overlap) policy->overlap(policy->owner, a, true);
        s->cur[size] = a;
        if (size == s->w - 2) {
            if (!s->nodd) {
                ++s->closed;
                if (detected(s)) {
                    s->witness_size = size + 1;
                    result = CC_LEVEL_INCONSISTENT;
                }
            } else {
                ++s->leaf2;
                int q = closing_qubit(s);
                if (q >= 0) {
                    s->cur[size + 1] = q;
                    s->witness_size = size + 2;
                    result = CC_LEVEL_FOUND;
                }
            }
        } else {
            result = dfs(s, policy, size + 1);
        }
        if (update_overlap) policy->overlap(policy->owner, a, false);
        flip(s, policy, a);
        --s->blk[a];
        if (result != CC_LEVEL_EMPTY) break;
        ++s->blk[a];
        ++excluded;
    }
    for (int i = 0; i < excluded; ++i) --s->blk[children[i]];
    if (sample.class_id >= 0) policy->sample_done(policy->owner, &sample);
    return result;
}

enum cc_level_outcome cc_run_level(struct cc_level *s, const struct cc_level_policy *policy) {
    const int count = policy ? policy->seed_count : s->n;
    for (int i = 0; i < count; ++i) {
        const int q = policy ? policy->seed[i] : i;
        if (policy && policy->seed_exemption) policy->seed_exemption(policy->owner, q, true);
        enum cc_level_outcome result = CC_LEVEL_EMPTY;
        if (!s->blk[q]) {
            ++s->seeds;
            ++s->blk[q];
            flip(s, policy, q);
            if (policy && policy->overlap) policy->overlap(policy->owner, q, true);
            s->cur[0] = q;
            result = dfs(s, policy, 1);
            if (policy && policy->overlap) policy->overlap(policy->owner, q, false);
            flip(s, policy, q);
            --s->blk[q];
        }
        if (policy && policy->seed_exemption) policy->seed_exemption(policy->owner, q, false);
        if (result != CC_LEVEL_EMPTY) return result;
        if (policy) {
            for (uint32_t j = policy->block_start[i]; j < policy->block_start[i+1]; ++j)
                ++s->blk[policy->block[j]];
            if (policy->block_done) policy->block_done(policy->owner, i);
        } else {
            ++s->blk[q];
        }
    }
    return CC_LEVEL_EMPTY;
}
