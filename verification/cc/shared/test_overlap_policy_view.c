/* SPDX-License-Identifier: GPL-3.0-or-later */
#include "../../../src/cc/cc_overlap_policy.h"
#include <assert.h>

int main(void) {
    const uint32_t columns[] = {0, 1, 2, 2}, rows[] = {0, 0};
    const uint32_t offsets[] = {0, 2}, qubits[] = {0, 1};
    uint32_t blocked[] = {3, 0};
    int32_t slack[] = {1}, exempt[] = {0};
    uint64_t tight = 0, extra = 0, forbidden = 0;
    struct cc_overlap_view view = {columns, rows, offsets, qubits, exempt,
                                   slack, blocked, 0, &tight, &extra, &forbidden};
    void (*callback)(void *, int, bool) = cc_overlap_policy;
    callback(&view, 0, true);
    assert(slack[0] == 1 && tight == 0);
    exempt[0] = 1;
    callback(&view, 0, true);
    assert(slack[0] == 0 && blocked[0] == 4 && blocked[1] == 0);
    callback(&view, 0, false);
    assert(slack[0] == 1 && blocked[0] == 3);
    view.exempt = 0;
    callback(&view, 0, true);
    assert(blocked[1] == 1 && tight == 2 && extra == 2 && forbidden == 1);
    callback(&view, 0, false);
    callback(&view, 2, true);
    assert(slack[0] == 1 && blocked[0] == 3 && blocked[1] == 0 && tight == 2);
    return 0;
}
