/* SPDX-License-Identifier: GPL-3.0-or-later */
#include "pcm.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

static struct cc_pcm_view view(int m, int n, const uint8_t *p) {
    return (struct cc_pcm_view){m, n, p, (size_t)m * (size_t)n};
}

static unsigned parity(unsigned x) {
    unsigned p = 0;
    while (x) { p ^= 1; x &= x - 1; }
    return p;
}

static unsigned weight(unsigned x) {
    unsigned w = 0;
    while (x) { ++w; x &= x - 1; }
    return w;
}

/* Independent finite oracle: explicitly enumerate the row span and
   all vectors. These small cases have exactly two rows per matrix. */
static bool logical(unsigned v, const unsigned opposite[2], const unsigned same[2]) {
    return v && !parity(v & opposite[0]) && !parity(v & opposite[1]) &&
        v != same[0] && v != same[1] && v != (same[0] ^ same[1]);
}

static unsigned exhaustive(int n) {
    unsigned count = 0, mask = (1u << n) - 1u;
    for (unsigned x = 0; x < (1u << (2*n)); ++x) {
        for (unsigned z = 0; z < (1u << (2*n)); ++z) {
            unsigned xr[2] = {x & mask, x >> n}, zr[2] = {z & mask, z >> n};
            uint8_t xb[6], zb[6], witness[3] = {9,9,9};
            bool legal = true;
            for (int i = 0; i < 2; ++i) {
                for (int j = 0; j < 2; ++j) if (parity(xr[i] & zr[j])) legal = false;
                for (int q = 0; q < n; ++q) {
                    xb[i*n+q] = (uint8_t)((xr[i] >> q) & 1);
                    zb[i*n+q] = (uint8_t)((zr[i] >> q) & 1);
                }
            }
            struct cc_pcm_view hx = view(2, n, xb), hz = view(2, n, zb);
            int answer = -1;
            enum cc_pcm_result code = cc_pcm_distance(&hx, &hz, witness, sizeof(witness), &answer, NULL, NULL);
            if (!legal) { assert(code == CC_PCM_INVALID && answer == -1 && witness[0] == 9); continue; }
            ++count;
            unsigned best = (unsigned)n+1;
            for (unsigned v = 1; v <= mask; ++v) {
                if (logical(v, zr, xr) || logical(v, xr, zr))
                    if (best > weight(v)) best = weight(v);
            }
            if (best > (unsigned)n) {
                assert(code == CC_PCM_NO_LOGICAL && answer == -1 && witness[0] == 9);
                continue;
            }
            assert(code == CC_PCM_FOUND_X || code == CC_PCM_FOUND_Z);
            unsigned physical = 0;
            for (int q = 0; q < n; ++q) {
                assert(witness[q] <= 1);
                physical |= (unsigned)witness[q] << q;
            }
            assert(best == weight(physical) && answer == (int)best);
            assert(code == CC_PCM_FOUND_X ? logical(physical, zr, xr) : logical(physical, xr, zr));
        }
    }
    return count;
}

static bool interrupt(void *counter) { return --*(int *)counter == 0; }

/* Generalized Shor codes give different X and Z distances and go
   through true recursion before the last-two-qubit shortcut. */
static void shor(int blocks, int width) {
    int n = blocks*width;
    uint8_t xb[4*25] = {0}, zb[20*25] = {0}, witness[25];
    for (int i = 0; i < blocks-1; ++i)
        for (int q = 0; q < 2*width; ++q) xb[i*n+i*width+q] = 1;
    for (int i = 0; i < blocks; ++i)
        for (int j = 0; j < width-1; ++j) {
            int offset = (i*(width-1)+j)*n + i*width + j;
            zb[offset] = zb[offset+1] = 1;
        }
    struct cc_pcm_view hx = view(blocks-1, n, xb), hz = view(blocks*(width-1), n, zb);
    int d = -1;
    enum cc_pcm_result result = cc_pcm_distance(&hx, &hz, witness, (size_t)n, &d, NULL, NULL);
    assert(result == (width <= blocks ? CC_PCM_FOUND_X : CC_PCM_FOUND_Z));
    assert(d == (width < blocks ? width : blocks));
    int total = 0, odd_blocks = 0, full_blocks = 0;
    for (int i = 0; i < blocks; ++i) {
        int used = 0;
        for (int j = 0; j < width; ++j) used += witness[i*width+j];
        total += used; odd_blocks += used % 2; full_blocks += (used == width);
    }
    assert(total == d && (result == CC_PCM_FOUND_X ? full_blocks == 1 : odd_blocks == blocks));
    int countdown = 3;
    d = -1; memset(witness, 9, sizeof(witness));
    assert(cc_pcm_distance(&hx, &hz, witness, (size_t)n, &d, interrupt, &countdown) == CC_PCM_INTERRUPTED);
    assert(d == -1 && witness[0] == 9);
}

static void dimensions(void) {
    uint8_t id[65*65] = {0}, w[65];
    struct cc_pcm_view x = view(0, 65, NULL), z = view(64, 65, id);
    for (int i = 0; i < 65; ++i) id[i*65+i] = 1;
    int d = -1;
    assert(cc_pcm_distance(&x, &z, w, sizeof(w), &d, NULL, NULL) == CC_PCM_FOUND_X);
    assert(w[64] == 1 && d == 1);
    z = view(65, 65, id); d = -1;
    assert(cc_pcm_distance(&x, &z, w, sizeof(w), &d, NULL, NULL) == CC_PCM_NO_LOGICAL && d == -1);
    id[0] = 2;
    assert(cc_pcm_distance(&x, &z, w, sizeof(w), &d, NULL, NULL) == CC_PCM_INVALID);
    id[0] = 1; --z.bytes;
    assert(cc_pcm_distance(&x, &z, w, sizeof(w), &d, NULL, NULL) == CC_PCM_INVALID);
    x = view(0, 0, NULL); z = view(1, 0, NULL);
    assert(cc_pcm_distance(&x, &z, NULL, 0, &d, NULL, NULL) == CC_PCM_NO_LOGICAL);
}

int main(void) {
    unsigned legal = 0;
    for (int n = 0; n <= 3; ++n) legal += exhaustive(n);
    dimensions();
    for (int i = 2; i <= 5; ++i)
        for (int j = 2; j <= 5; ++j) shor(i,j);
    printf("PASS %u legal two-row PCM pairs, all noncommuting pairs rejected, "
           "16 Shor geometries with replay and interrupt checks, and boundary cases\n", legal);
    return 0;
}
