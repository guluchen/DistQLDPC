/* SPDX-License-Identifier: GPL-3.0-or-later */
#include <assert.h>
#include <stdio.h>
#include "../../../src/cc/cc_distance_bounds.h"

int main(void) {
    unsigned cases = 0;
    const int bounds[] = {-1, 0, 1, 2, 3, 8, 9, INT_MAX - 1, INT_MAX};
    const int count = (int)(sizeof(bounds) / sizeof(bounds[0]));
    for (int i = 0; i < count; ++i) {
        for (int j = 0; j < count; ++j) {
            for (int mask = 0; mask < 4; ++mask) {
                int lower = INT_MAX;
                if ((mask & 1) && bounds[i] < lower) lower = bounds[i];
                if ((mask & 2) && bounds[j] < lower) lower = bounds[j];
                assert(cc_global_lower(mask & 1, bounds[i], mask & 2, bounds[j]) == lower);
                int other = (mask & 2) ? bounds[j] : INT_MAX;
                assert(cc_hit_closes(bounds[i], mask & 2, bounds[j]) == (other >= bounds[i]));
                ++cases;
            }
        }
    }
    for (int w = 0; w < 500; ++w) {
        assert(cc_next_after_empty(w, false) == w + 1);
        assert(cc_next_after_empty(w, true) == 2 * (w / 2 + 1));
        ++cases;
    }
    assert(cc_next_after_empty(INT_MAX-1, false) == INT_MAX);
    assert(cc_next_after_empty(INT_MAX-2, true) == INT_MAX-1);
    printf("PASS %u bound updates and 2 upper-edge cases\n", cases);
}
