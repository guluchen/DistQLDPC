/* SPDX-License-Identifier: GPL-3.0-or-later. Not yet VST-proved. */
#include "ccv.h"
unsigned int ccv_bit_xor(unsigned int a, unsigned int b) { return a ^ b; }
/* Precondition b>0. Avoid a+b-1 overflow. */
unsigned int ccv_ceil_div(unsigned int a, unsigned int b) {
    return a / b + (a % b != 0u);
}
unsigned int ccv_dot(unsigned int n, const unsigned char *a, const unsigned char *b) {
    unsigned int i, x = 0u;
    for (i=0u; i<n; i++) x = x ^ ((unsigned int)a[i] & (unsigned int)b[i]);
    return x;
}
unsigned int ccv_weight(unsigned int n, const unsigned char *a) {
    unsigned int i, x = 0u;
    for (i=0u; i<n; i++) x = x + (unsigned int)a[i];
    return x;
}
void ccv_toggle(unsigned int n, unsigned char *a, const unsigned char *b) {
    unsigned int i;
    for (i=0u; i<n; i++) a[i] = (unsigned char)((unsigned int)a[i] ^ (unsigned int)b[i]);
}
