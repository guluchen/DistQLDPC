/* Search-order advice only. Every returned cut is validated after extraction. */
#include <stdint.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

static uint64_t lane(value a, int j)
{
    return ((uint64_t)Long_val(Field(a, j))) & UINT64_C(0x7fffffffffffffff);
}

CAMLprim value caml_ccv_packed_hint(value rows, value syndrome, value free_mask, value remaining)
{
    CAMLparam4(rows, syndrome, free_mask, remaining);
    CAMLlocal3(result, list, cell);
    uint64_t used[3] = {0, 0, 0};
    uint64_t avail[3] = {lane(free_mask,0), lane(free_mask,1), lane(free_mask,2)};
    int selected[189], count = 0, best = 190, chosen = 0;
    for (int j=0; j<3; ++j) {
        uint64_t w = lane(syndrome,j);
        while (w != 0) {
            int i = j*63 + __builtin_ctzll(w);
            w &= w-1;
            if ((mlsize_t)i >= Wosize_val(rows)) continue;
            value row = Field(rows,i);
            uint64_t a = lane(row,0)&avail[0], b = lane(row,1)&avail[1], c = lane(row,2)&avail[2];
            int size = __builtin_popcountll(a)+__builtin_popcountll(b)+__builtin_popcountll(c);
            if (size < best) { best=size; chosen=i; }
            if (size==0) goto split;
            if (((a&used[0]) | (b&used[1]) | (c&used[2]))==0) {
                selected[count++]=i;
                if (count>Long_val(remaining)) goto pack;
                used[0]|=a; used[1]|=b; used[2]|=c;
            }
        }
    }
split:
    result = caml_alloc_small(1,0);
    Field(result,0) = Val_int(chosen);
    CAMLreturn(result);
pack:
    list=Val_emptylist;
    while (count>0) {
        cell=caml_alloc_small(2,0);
        Field(cell,0)=Val_int(selected[--count]); Field(cell,1)=list;
        list=cell;
    }
    result=caml_alloc_small(1,1); Field(result,0)=list;
    CAMLreturn(result);
}
