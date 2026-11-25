/* SPDX-License-Identifier: GPL-3.0-or-later */
#include "pcm.h"
#include "cc_level.h"
#include <limits.h>
#include <stdlib.h>
#include <string.h>

static int words_for(int bits) {
    if (bits == 0) return 0;
    return 1 + (bits - 1) / 64;
}

static void *matrix_storage(size_t rows, size_t cols, size_t unit) {
    if (rows && cols > SIZE_MAX / rows) return NULL;
    size_t count = rows * cols;
    if (count > SIZE_MAX / unit) return NULL;
    return calloc(count ? count : 1, unit);
}

static bool valid_matrix(const struct cc_pcm_view *a) {
    if (!a || a->rows < 0 || a->columns < 0) return false;
    size_t nr = (size_t)a->rows, nc = (size_t)a->columns;
    if ((nr && nc > SIZE_MAX / nr) || nr * nc != a->bytes ||
        (a->bytes && !a->entries)) return false;
    for (size_t i = 0; i < a->bytes; ++i)
        if (a->entries[i] > 1) return false;
    return true;
}

static uint8_t entry(const struct cc_pcm_view *a, int row, int col) {
    return a->entries[(size_t)row * (size_t)a->columns + (size_t)col];
}

static bool commute(const struct cc_pcm_view *a, const struct cc_pcm_view *b) {
    for (int i = 0; i < a->rows; ++i) {
        for (int j = 0; j < b->rows; ++j) {
            unsigned dot = 0;
            for (int q = 0; q < a->columns; ++q)
                dot ^= (unsigned)(entry(a, i, q) & entry(b, j, q));
            if (dot) return false;
        }
    }
    return true;
}

struct reduction {
    uint64_t *store;
    int *pivot;
    int rank, words;
};

static uint64_t *row_at(struct reduction *r, int i) {
    return r->store + (size_t)i * (size_t)r->words;
}

static bool bit(const uint64_t *row, int q) {
    return (row[q / 64] >> (q % 64)) & UINT64_C(1);
}

static void swap_words(uint64_t *a, uint64_t *b, int words) {
    for (int j = 0; j < words; ++j) {
        uint64_t save = a[j];
        a[j] = b[j];
        b[j] = save;
    }
}

static void xor_words(uint64_t *destination, const uint64_t *pivot, int words) {
    for (int j = 0; j < words; ++j) destination[j] ^= pivot[j];
}

/* Eliminate above and below each pivot. A pivot qubit is equivalent
   modulo the row space to the free coordinates in its reduced row. */
static bool reduce_matrix(const struct cc_pcm_view *a, struct reduction *r) {
    r->words = words_for(a->columns);
    r->store = matrix_storage((size_t)a->rows, (size_t)r->words, sizeof(*r->store));
    r->pivot = matrix_storage(1, (size_t)a->columns, sizeof(*r->pivot));
    if (!r->store || !r->pivot) return false;
    for (int i = 0; i < a->rows; ++i) {
        uint64_t *row = row_at(r, i);
        for (int q = 0; q < a->columns; ++q)
            row[q / 64] |= (uint64_t)entry(a, i, q) << (q % 64);
    }
    for (int q = 0; q < a->columns; ++q) {
        r->pivot[q] = -1;
        int selected = r->rank;
        while (selected < a->rows && !bit(row_at(r, selected), q)) ++selected;
        if (selected == a->rows) continue;
        uint64_t *pivot = row_at(r, r->rank);
        if (selected != r->rank) swap_words(pivot, row_at(r, selected), r->words);
        for (int i = 0; i < a->rows; ++i) {
            uint64_t *row = row_at(r, i);
            if (i == r->rank || !bit(row, q)) continue;
            xor_words(row, pivot, r->words);
        }
        r->pivot[q] = r->rank++;
    }
    return true;
}

/* Every block below has a single owning pointer. The level borrows
   these objects for all weights. calloc also initializes the first epoch. */
struct half {
    struct cc_level level;
    uint32_t *rstart, *rq, *cstart, *cr, *blk, *cand;
    uint64_t *gmask, *keys, *syn, *par, *mark, *budget;
    int32_t *slots, *links;
    int *path;
};

static void release_half(struct half *h) {
    free(h->rstart); free(h->rq); free(h->cstart); free(h->cr);
    free(h->blk); free(h->cand); free(h->gmask); free(h->keys);
    free(h->syn); free(h->par); free(h->mark); free(h->budget);
    free(h->slots); free(h->links); free(h->path);
}

/* SplitMix64 word mixing as in the native solver's cc_half.cc. */
static uint64_t row_key(int row) {
    uint64_t x = (uint64_t)row + UINT64_C(0x9e3779b97f4a7c15);
    x = (x ^ (x >> 30)) * UINT64_C(0xbf58476d1ce4e5b9);
    x = (x ^ (x >> 27)) * UINT64_C(0x94d049bb133111eb);
    return x ^ (x >> 31);
}

static bool prepare(struct half *h, const struct cc_pcm_view *a,
                    struct reduction *same, bool (*poll)(void *), void *context) {
    const int n = a->columns;
    const size_t nr = (size_t)a->rows, nq = (size_t)n;
    int maxrow = 0;
    size_t edges = 0;
    for (int r = 0; r < a->rows; ++r) {
        int degree = 0;
        for (int q = 0; q < n; ++q) degree += entry(a, r, q);
        if ((size_t)degree > UINT32_MAX - edges) return false;
        edges += (size_t)degree;
        if (maxrow < degree) maxrow = degree;
    }
    size_t slots = 4;
    while (slots / 2 < nq) {
        if (slots > SIZE_MAX / 2) return false;
        slots *= 2;
    }
    int mw = words_for(a->rows), kw = words_for(n - same->rank);
    h->rstart = matrix_storage(1, nr + 1, sizeof(*h->rstart));
    h->cstart = matrix_storage(1, nq + 1, sizeof(*h->cstart));
    h->rq = matrix_storage(1, edges, sizeof(*h->rq));
    h->cr = matrix_storage(1, edges, sizeof(*h->cr));
    h->blk = matrix_storage(1, nq, sizeof(*h->blk));
    h->cand = matrix_storage(nq, (size_t)maxrow, sizeof(*h->cand));
    h->gmask = matrix_storage(nq, (size_t)kw, sizeof(*h->gmask));
    h->keys = matrix_storage(1, nq, sizeof(*h->keys));
    h->syn = matrix_storage(1, (size_t)mw, sizeof(*h->syn));
    h->par = matrix_storage(1, (size_t)kw, sizeof(*h->par));
    h->mark = matrix_storage(1, nq, sizeof(*h->mark));
    h->budget = matrix_storage(1, nq, sizeof(*h->budget));
    h->slots = matrix_storage(1, slots, sizeof(*h->slots));
    h->links = matrix_storage(1, nq, sizeof(*h->links));
    h->path = matrix_storage(1, nq, sizeof(*h->path));
    if (!h->rstart || !h->rq || !h->cstart || !h->cr || !h->blk || !h->cand ||
        !h->gmask || !h->keys || !h->syn || !h->par || !h->mark || !h->budget ||
        !h->slots || !h->links || !h->path) return false;

    uint32_t used = 0;
    for (int r = 0; r < a->rows; ++r) {
        for (int q = 0; q < n; ++q)
            if (entry(a, r, q)) h->rq[used++] = (uint32_t)q;
        h->rstart[r + 1] = used;
    }
    used = 0;
    for (int q = 0; q < n; ++q) {
        for (int r = 0; r < a->rows; ++r) {
            if (!entry(a, r, q)) continue;
            h->cr[used++] = (uint32_t)r;
            h->keys[q] ^= row_key(r);
        }
        h->cstart[q + 1] = used;
        h->links[q] = -1;
    }
    for (size_t i = 0; i < slots; ++i) h->slots[i] = -1;
    cc_build_leaf_index(n, slots - 1, h->keys, h->slots, h->links);

    int label = 0;
    for (int free_col = 0; free_col < n; ++free_col) {
        if (same->pivot[free_col] >= 0) continue;
        for (int q = 0; q < n; ++q) {
            int row = same->pivot[q];
            if (q == free_col || (row >= 0 && bit(row_at(same, row), free_col)))
                h->gmask[(size_t)q * (size_t)kw + (size_t)(label / 64)]
                    |= UINT64_C(1) << (label % 64);
        }
        ++label;
    }
    h->level = (struct cc_level){.n=n, .mw=mw, .kw=kw, .maxrow=maxrow,
        .rstart=h->rstart, .rq=h->rq, .cstart=h->cstart, .cr=h->cr, .gmask=h->gmask,
        .colkey=h->keys, .htab=h->slots, .hnext=h->links, .hmask=slots-1, .syn=h->syn,
        .gpar=h->par, .mark=h->mark, .by_budget=h->budget, .blk=h->blk, .cand=h->cand,
        .cur=h->path, .poll=poll, .poll_ctx=context, .poll_mask=1023};
    return true;
}

/* Replay the physical witness on the original check matrix, and reduce
   it modulo the stabilizer basis independently of the packed detectors. */
static bool replay(struct cc_level *s, const struct cc_pcm_view *checks, struct reduction *same) {
    memset(s->blk, 0, (size_t)s->n * sizeof(*s->blk));
    for (int i = 0; i < s->witness_size; ++i) {
        int q = s->cur[i];
        if (q < 0 || q >= s->n || s->blk[q]) return false;
        s->blk[q] = 1;
    }
    for (int r = 0; r < checks->rows; ++r) {
        unsigned syndrome = 0;
        for (int i = 0; i < s->witness_size; ++i)
            syndrome ^= entry(checks, r, s->cur[i]);
        if (syndrome) return false;
    }
    for (int q = 0; q < s->n; ++q) {
        if (same->pivot[q] >= 0) continue;
        unsigned residual = s->blk[q];
        for (int i = 0; i < s->witness_size; ++i) {
            int pivot = same->pivot[s->cur[i]];
            if (pivot >= 0) residual ^= bit(row_at(same, pivot), q);
        }
        if (residual) return true;
    }
    return false;
}

static enum cc_pcm_result run_weights(struct half halves[2], int n,
                                      const struct cc_pcm_view *checks[2], struct reduction *same[2],
                                      uint8_t *witness, int *distance) {
    for (int w = 1; ; ++w) {
        for (int side = 0; side < 2; ++side) {
            struct cc_level *s = &halves[side].level;
            if (s->poll && s->poll(s->poll_ctx)) return CC_PCM_INTERRUPTED;
            s->w = w;
            memset(s->blk, 0, (size_t)n * sizeof(*s->blk));
            enum cc_level_outcome value = cc_run_level(s, NULL);
            if (value == CC_LEVEL_ABORTED) return CC_PCM_INTERRUPTED;
            if (value == CC_LEVEL_EMPTY) continue;
            if (value != CC_LEVEL_FOUND || s->witness_size != w || !replay(s, checks[side], same[side]))
                return CC_PCM_INCONSISTENT;
            memset(witness, 0, (size_t)n);
            for (int i = 0; i < w; ++i) witness[s->cur[i]] = 1;
            *distance = w;
            return side == 0 ? CC_PCM_FOUND_X : CC_PCM_FOUND_Z;
        }
        /* Called only for positive encoded dimension. */
        if (w == n) return CC_PCM_INCONSISTENT;
    }
}

enum cc_pcm_result cc_pcm_distance(const struct cc_pcm_view *hx, const struct cc_pcm_view *hz,
    uint8_t *witness, size_t witness_bytes, int *distance, bool (*poll)(void *), void *context) {
    if (!valid_matrix(hx) || !valid_matrix(hz) || hx->columns != hz->columns ||
        !distance || (size_t)hx->columns > witness_bytes || (hx->columns && !witness))
        return CC_PCM_INVALID;
    int n = hx->columns;
    if (!n) return CC_PCM_NO_LOGICAL;
    if (!commute(hx, hz)) return CC_PCM_INVALID;
    if (poll && poll(context)) return CC_PCM_INTERRUPTED;
    struct reduction x = {0}, z = {0};
    struct half halves[2] = {0};
    const struct cc_pcm_view *checks[2] = {hz, hx};
    struct reduction *same[2] = {&x, &z};
    enum cc_pcm_result result = CC_PCM_RESOURCE;
    if (reduce_matrix(hx, &x) && reduce_matrix(hz, &z)) {
        if (x.rank > n - z.rank) result = CC_PCM_INCONSISTENT;
        else if (x.rank == n - z.rank) result = CC_PCM_NO_LOGICAL;
        else if (prepare(&halves[0], hz, &x, poll, context) &&
                 prepare(&halves[1], hx, &z, poll, context))
            result = run_weights(halves, n, checks, same, witness, distance);
    }
    release_half(&halves[1]); release_half(&halves[0]);
    free(x.pivot); free(x.store); free(z.pivot); free(z.store);
    return result;
}
