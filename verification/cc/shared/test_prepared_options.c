/* SPDX-License-Identifier: GPL-3.0-or-later */
#include "../../../src/cc/cc_level.h"
#include <assert.h>
#include <stddef.h>
#include <stdio.h>

struct observation {
    struct cc_level *state;
    int polls, seed_in, seed_out, overlap_in, overlap_out, finished;
    unsigned extra;
};

static bool poll_now(void *owner) {
    ++((struct observation *)owner)->polls;
    return true;
}

static void seed(void *owner, int q, bool enter) {
    struct observation *o = owner;
    assert(q == 0 && o->state->syn[0] == 0 && o->state->blk[0] == 0);
    if (enter) ++o->seed_in;
    else ++o->seed_out;
}

static void overlap(void *owner, int q, bool enter) {
    struct observation *o = owner;
    assert(q == 0 && o->state->syn[0] == o->extra && o->state->blk[0] == 1);
    if (enter) ++o->overlap_in;
    else ++o->overlap_out;
}

static void finished(void *owner, int index) {
    struct observation *o = owner;
    assert(index == 0 && o->state->blk[0] == 1 && o->state->syn[0] == 0);
    ++o->finished;
}

/* Exercise all 64 independent on/off choices on the same real root. Early
   FOUND and ABORTED exits both restore the root and skip the orbit update. */
static void check(unsigned flags, bool hit, bool prepared) {
    struct cc_level s = {0};
    struct cc_level_policy p = {0};
    struct observation o = {.state = &s, .extra = !!(flags & CC_USE_REDUNDANT)};
    uint32_t blocks[1] = {0};
    const uint32_t empty_column[] = {0, 0}, starts[] = {0, 1}, members[] = {0};
    const uint64_t key[] = {1}, logical[] = {hit};
    const int order[] = {0};
    int path[] = {-1};
    uint64_t syn[] = {0}, response[] = {0}, budgets[] = {0, 0};
    s.n = s.w = s.mw = s.kw = 1;
    s.cstart = empty_column;
    s.colkey = key;
    s.gmask = logical;
    s.syn = syn;
    s.gpar = response;
    s.by_budget = budgets;
    s.blk = blocks;
    s.cur = path;
    s.poll = (flags & CC_USE_POLL) ? poll_now : NULL;
    s.poll_ctx = &o;

    p.owner = &o;
    p.seed = order;
    p.seed_count = 1;
    p.block_start = starts;
    p.block = members;
    p.redundant_start = (flags & CC_USE_REDUNDANT) ? starts : NULL;
    p.redundant_rows = members;
    p.parity = !!(flags & CC_USE_PARITY);
    p.overlap = (flags & CC_USE_OVERLAP) ? overlap : NULL;
    p.seed_exemption = (flags & CC_USE_SEED_EXEMPTION) ? seed : NULL;
    p.block_done = (flags & CC_USE_BLOCK_DONE) ? finished : NULL;

    const enum cc_level_outcome result = prepared ? cc_run_prepared_level(&s, &p, flags)
                                                  : cc_run_level(&s, &p);
    enum cc_level_outcome expected = CC_LEVEL_EMPTY;
    if (flags & CC_USE_POLL) expected = CC_LEVEL_ABORTED;
    else if (hit) expected = CC_LEVEL_FOUND;
    assert(result == expected);
    assert(s.synkey == 0 && syn[0] == 0 && response[0] == 0 && !s.nodd);
    assert(s.seeds == 1 && s.nodes == 1 && budgets[0] == 1);
    assert(s.witness_size == (result == CC_LEVEL_FOUND));
    assert(blocks[0] == (unsigned)(result == CC_LEVEL_EMPTY));
    assert(o.polls == !!(flags & CC_USE_POLL));
    assert(o.seed_in == !!(flags & CC_USE_SEED_EXEMPTION) && o.seed_out == o.seed_in);
    assert(o.overlap_in == !!(flags & CC_USE_OVERLAP) && o.overlap_out == o.overlap_in);
    assert(o.finished == ((result == CC_LEVEL_EMPTY) && (flags & CC_USE_BLOCK_DONE)));
}

int main(void) {
    for (unsigned i = 0; i < 64; ++i) {
        unsigned flags = (i << 1) | CC_USE_POLICY;
        for (int hit = 0; hit < 2; ++hit)
            for (int prepared = 0; prepared < 2; ++prepared) check(flags, hit, prepared);
    }
    puts("PASS 256 prepared and legacy root outcomes");
    return 0;
}
