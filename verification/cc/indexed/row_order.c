/* Optional row order for the extracted lower-bound checker. The original
   DistQLDPC CC implementation uses seed-anchored reversed Tanner BFS (GH-183). */
#include <stdint.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

#include "advice_width.h"
enum { max_dimension = CCV_ADVICE_WIDTH };

CAMLprim value caml_ccv_reverse_bfs(value width, value packed_rows) {
    CAMLparam2(width, packed_rows);
    CAMLlocal1(result);
    intnat n = Long_val(width);
    mlsize_t size = caml_string_length(packed_rows);
    if (n < 1 || n > max_dimension || size % (mlsize_t)n != 0 ||
        size / (mlsize_t)n > max_dimension) {
        CAMLreturn(Atom(0));
    }
    int cols = (int)n, rows = (int)(size / (mlsize_t)n);
    const unsigned char *matrix = Bytes_val(packed_rows);
    unsigned char visited_row[max_dimension] = {0}, visited_col[max_dimension] = {0};
    int order[max_dimension], head = 0, tail = 0;
    /* Starting at qubit zero fixes the first connected component. Restart
       from each unseen row so disconnected and empty rows are retained. */
    visited_col[0] = 1;
    for (int r = 0; r < rows; ++r) {
        if (matrix[r * cols]) {
            visited_row[r] = 1;
            order[tail++] = r;
        }
    }
    for (int start = -1; start < rows; ++start) {
        if (start >= 0 && !visited_row[start]) {
            visited_row[start] = 1;
            order[tail++] = start;
        }
        while (head < tail) {
            int current = order[head++];
            for (int q = 0; q < cols; ++q) {
                if (visited_col[q] || !matrix[current * cols + q]) continue;
                visited_col[q] = 1;
                for (int r = 0; r < rows; ++r) {
                    if (!visited_row[r] && matrix[r * cols + q]) {
                        visited_row[r] = 1;
                        order[tail++] = r;
                    }
                }
            }
        }
    }
    result = caml_alloc((mlsize_t)tail, 0);
    for (int i = 0; i < tail; ++i) Field(result,i) = Val_int(order[tail - 1 - i]);
    CAMLreturn(result);
}

/* Only propose original-row pairs. Coq constructs the actual added rows. */
#include <stdlib.h>
#include <string.h>

enum { vector_words = (max_dimension+63)/64 };
typedef struct { uint64_t lane[vector_words]; } check_bits;

CAMLprim value caml_ccv_sparse_pairs(value width, value source, value capacity) {
    CAMLparam3(width,source,capacity);
    CAMLlocal1(result);
    intnat dn=Long_val(width), limit=Long_val(capacity);
    mlsize_t size=caml_string_length(source);
    if (dn<1 || dn>max_dimension || limit<1 || limit>max_dimension ||
        size%(mlsize_t)dn || size/(mlsize_t)dn >= (mlsize_t)limit) CAMLreturn(Atom(0));
    int n=(int)dn, original=(int)(size/(mlsize_t)dn), lanes=(n+63)/64;
    if (original<2) CAMLreturn(Atom(0));
    if (limit>3*original) limit=3*original;
    check_bits *checks=calloc((size_t)limit,sizeof(*checks));
    if (!checks) CAMLreturn(Atom(0));
    unsigned weights[max_dimension]={0};
    int pairs[2*max_dimension],count=original;
    const unsigned char *bytes=Bytes_val(source);
    for (int r=0;r<original;++r) {
        for (int q=0;q<n;++q) if (bytes[r*n+q]) {
            checks[r].lane[q/64] |= UINT64_C(1)<<(q%64);
            ++weights[r];
        }
    }
    for (int a=0;a<original && count<limit;++a) {
        if (!weights[a] || weights[a]>32) continue;
        for (int b=0;b<a && count<limit;++b) {
            if (!weights[b] || weights[b]>32) continue;
            check_bits sum={{0}};
            unsigned w=0;
            for (int k=0;k<lanes;++k) {
                sum.lane[k]=checks[a].lane[k]^checks[b].lane[k];
                w+=(unsigned)__builtin_popcountll(sum.lane[k]);
            }
            if (!w || (w>weights[a] && w>weights[b])) continue;
            int i=0;
            while (i<count && memcmp(checks[i].lane,sum.lane,(size_t)lanes*sizeof(uint64_t))) ++i;
            if (i<count) continue;
            pairs[2*(count-original)]=a;
            pairs[2*(count-original)+1]=b;
            checks[count++]=sum;
        }
    }
    free(checks);
    int entries=2*(count-original);
    result=caml_alloc((mlsize_t)entries,0);
    for (int i=0;i<entries;++i) Field(result,i)=Val_int(pairs[i]);
    CAMLreturn(result);
}
