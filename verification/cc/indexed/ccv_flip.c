/* SPDX-License-Identifier: GPL-3.0-or-later
 * Toggle one parity byte for each incident row. Repeated indices cancel in pairs. */
void ccv_flip(unsigned len, const unsigned *index, unsigned char *bits) {
    for (unsigned i = 0; i < len; i++) {
        unsigned j = index[i];
        bits[j] ^= 1u;
    }
}
