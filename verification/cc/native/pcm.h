/* SPDX-License-Identifier: GPL-3.0-or-later */
#ifndef DISTQLDPC_NATIVE_PCM_H
#define DISTQLDPC_NATIVE_PCM_H
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* Unpacked binary row-major entries. Empty matrices have zero bytes. */
struct cc_pcm_view {
    int rows;
    int columns;
    const uint8_t *entries;
    size_t bytes;
};
enum cc_pcm_result {
    CC_PCM_FOUND_X, CC_PCM_FOUND_Z, CC_PCM_NO_LOGICAL,
    CC_PCM_INTERRUPTED, CC_PCM_INVALID, CC_PCM_RESOURCE, CC_PCM_INCONSISTENT
};
/* witness has columns bytes. A finite result writes its indicator vector
   and its distance. Every other result leaves both output buffers untouched.
   Output buffers must be disjoint from each other and the inputs. */
enum cc_pcm_result cc_pcm_distance(const struct cc_pcm_view *hx,
    const struct cc_pcm_view *hz, uint8_t *witness, size_t witness_bytes,
    int *distance, bool (*poll)(void *), void *context);
#endif
