/* Host allocation and OCaml representation adapter for the proved C kernel. */
#include "../ccv.h"
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>

/* The runtime may move OCaml objects during allocation. Allocate the output
   before borrowing any byte pointers. The kernel never calls the runtime. */
CAMLprim value caml_ccv_distance(value dims, value matrices, value limits) {
    CAMLparam3(dims, matrices, limits);
    CAMLlocal2(bits, result);
    struct ccv_problem p;
    struct ccv_workspace w;
    struct ccv_stats stats;
    unsigned int distance, budget, rules;
    int ret;
    intnat n = Long_val(Field(dims, 0));
    intnat m = Long_val(Field(dims, 1));
    intnat l = Long_val(Field(dims, 2));
    intnat k = Long_val(Field(dims, 3));
    intnat b = Long_val(Field(limits, 0));
    intnat mask = Long_val(Field(limits, 1));
    if (n <= 0 || n > (intnat)(INT_MAX / sizeof(struct ccv_frame)) ||
        m < 0 || l <= 0 || k < 0 || m > INT_MAX / n || l > INT_MAX / n ||
        k > INT_MAX / n || b < 0 || (uintnat)b > UINT_MAX || mask < 0 || mask > CCV_ALL)
        caml_invalid_argument("unsupported CC kernel arguments");
    if ((uintnat)(m*n) != caml_string_length(Field(matrices, 0)) ||
        (uintnat)(l*n) != caml_string_length(Field(matrices, 1)) ||
        (uintnat)(k*n) != caml_string_length(Field(matrices, 2)))
        caml_invalid_argument("incorrect CC matrix extent");

    bits = caml_alloc_string((mlsize_t)n);
    p.n = (unsigned int)n;
    p.checks = (unsigned int)m;
    p.logical_rows = (unsigned int)l;
    p.stabilizers = (unsigned int)k;
    p.h = (const unsigned char *)String_val(Field(matrices, 0));
    p.logical = (const unsigned char *)String_val(Field(matrices, 1));
    p.stabilizer = (const unsigned char *)String_val(Field(matrices, 2));
    budget = (unsigned int)b;
    rules = (unsigned int)mask;

    /* Contiguous byte workspace with disjoint slices of the specified lengths.
       Reserve one byte for a zero-row syndrome array as in the file driver. */
    size_t ns = (size_t)n, ms = m > 0 ? (size_t)m : 1u, ls = (size_t)l;
    unsigned char *scratch = calloc(3u * ns + ms + ls, 1u);
    unsigned int *undo = calloc(ns, sizeof *undo);
    struct ccv_frame *frames = calloc(ns, sizeof *frames);
    if (!scratch || !undo || !frames) {
        free(frames); free(undo); free(scratch);
        caml_raise_out_of_memory();
    }
    w.capacity = p.n; w.frame_capacity = p.n;
    w.selected = scratch; w.forbidden = scratch + ns; w.packed = scratch + 2u * ns;
    w.syndrome = scratch + 3u * ns; w.logical_value = w.syndrome + ms;
    w.undo = undo; w.frames = frames;
    ret = ccv_distance(&p, budget, rules, &w, (unsigned char *)Bytes_val(bits), &distance, &stats);
    free(frames); free(undo); free(scratch);
    if (ret != CCV_FOUND && ret != CCV_EMPTY && ret != CCV_UNKNOWN)
        caml_invalid_argument("kernel rejected prepared PCM");
    result = caml_alloc_tuple(2);
    Store_field(result, 0, Val_int(ret));
    Store_field(result, 1, bits);
    CAMLreturn(result);
}
