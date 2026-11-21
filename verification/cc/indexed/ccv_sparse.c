/* SPDX-License-Identifier: GPL-3.0-or-later
 * Count occupied positions in one validated slice of a CSR index. */
unsigned ccv_gather(unsigned len, const unsigned *index, const unsigned char *bits) {
    unsigned sum = 0;
    for (unsigned i = 0; i < len; i++)
        sum += bits[index[i]];
    return sum;
}
