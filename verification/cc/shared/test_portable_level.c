/* SPDX-License-Identifier: GPL-3.0-or-later */
#include "cc_level.h"
#include <assert.h>
#include <stdio.h>
#include <stddef.h>

/* The repetition-code checks occupy three different rows of a 128-row
   PCM. Every rotation exercises the normal level entry, including row
   indices on either side of a machine-word boundary. All hash keys
   collide, so every accepted leaf also has to pass the physical check. */
static void repetition(int rotation) {
    const int rows[3] = {rotation, (rotation + 1) % 128, (rotation + 63) % 128};
    uint32_t rstart[129], rq[6], cstart[5] = {0, 1, 3, 5, 6}, cr[6];
    unsigned cursor = 0;
    for (int r = 0; r < 128; ++r) {
        rstart[r] = cursor;
        for (int j = 0; j < 3; ++j) if (r == rows[j]) {
            rq[cursor++] = (unsigned)j;
            rq[cursor++] = (unsigned)(j + 1);
        }
    }
    rstart[128] = cursor;
    cr[0] = cr[1] = (uint32_t)rows[0];
    cr[2] = cr[3] = (uint32_t)rows[1];
    cr[4] = cr[5] = (uint32_t)rows[2];
    const uint64_t logical[4] = {1, 0, 0, 0}, keys[4] = {0};
    const int32_t table[8] = {0, -1, -1, -1, -1, -1, -1, -1};
    const int32_t next[4] = {1, 2, 3, -1};
    for (int w = 1; w <= 4; ++w) {
        uint64_t syn[2] = {0}, par[1] = {0}, mark[4] = {0}, budget[5] = {0};
        uint32_t blocked[4] = {0}, candidates[9] = {0};
        int path[4] = {-1, -1, -1, -1};
        struct cc_level s = {.n=4, .w=w, .mw=2, .kw=1, .maxrow=2,
            .rstart=rstart, .rq=rq, .cstart=cstart, .cr=cr, .gmask=logical,
            .colkey=keys, .htab=table, .hnext=next, .hmask=7, .syn=syn,
            .gpar=par, .mark=mark, .by_budget=budget, .blk=blocked,
            .cand=candidates, .cur=path};
        enum cc_level_outcome status = cc_run_level(&s, NULL);
        assert(syn[0] == 0 && syn[1] == 0 && par[0] == 0 && s.nodd == 0);
        if (w < 4) { assert(status == CC_LEVEL_EMPTY); continue; }
        assert(status == CC_LEVEL_FOUND && s.witness_size == 4);
        unsigned mask = 0;
        for (int i = 0; i < s.witness_size; ++i) {
            assert(path[i] >= 0 && path[i] < 4);
            assert((mask & (1u << path[i])) == 0);
            mask |= 1u << path[i];
        }
        for (int j = 0; j < 3; ++j) assert(((mask >> j) ^ (mask >> (j+1))) % 2 == 0);
        assert((mask & 1) == 1 && mask == 15);
    }
}
int main(void) {
    for (int r=0;r<128;++r) repetition(r);
    puts("PASS 128 PCM row placements x 4 levels, 128 GF(2)-checked witnesses");
    return 0;
}
