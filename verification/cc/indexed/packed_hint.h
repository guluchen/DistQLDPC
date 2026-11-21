/* Row-choice advice. The extracted search validates every proposed cut. */
#include <stdint.h>
#define CCV_WIDTH (63 * CCV_LANES)
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

static uint64_t word(value tuple, int i) {
    return ((uint64_t)Long_val(Field(tuple, i))) & UINT64_C(0x7fffffffffffffff);
}
/* The x86-64 Coq 8.18 runtime represents Uint63.t by an OCaml int.
   Each leaf is the checked three-lane record from CCPackedWords. */
static uint64_t mask_word(value mask,int j) {
    #if CCV_LANES == 3
    return word(mask,j);
#elif CCV_LANES == 6
    return word(Field(mask,j/3),j%3);
#elif CCV_LANES == 12
    return word(Field(Field(mask,j/6),(j/3)%2),j%3);
#else
#error "Unsupported packed representation"
#endif
}
CAMLprim value caml_wide_hash(value mask) {
    static const unsigned rot[12]={0,7,17,26,37,49,4,11,23,35,45,55};
    uint64_t hash=mask_word(mask,0);
    for (int i=1;i<CCV_LANES;i++) {
        uint64_t x=mask_word(mask,i);
        hash^=(x<<rot[i]) | (x>>(63u-rot[i]));
    }
    return Val_long((intnat)(hash&UINT64_C(0x7fffffffffffffff)));
}
CAMLprim value caml_wide_hint(value data, value syndrome, value free_mask, value remaining) {
    CAMLparam4(data, syndrome, free_mask, remaining);
    CAMLlocal3(result, list, cell);
    value rows=Field(data,0), incident=Field(data,1);
    int pair_i=-1,pair_j=-1;
    uint64_t used[CCV_LANES] = {0}, free_bits[CCV_LANES];
    int packed[CCV_WIDTH], count = 0, shortest = (CCV_WIDTH + 1), choice = 0;
    int head[(CCV_WIDTH + 1)], ids[CCV_WIDTH], next[CCV_WIDTH], entries=0, largest=0;
    for(int i=0;i<(CCV_WIDTH + 1);i++)head[i]=-1;
    for (int i=0;i<CCV_LANES;i++) free_bits[i]=mask_word(free_mask,i);
    for (int i=0;i<CCV_LANES;i++) {
        uint64_t active=mask_word(syndrome,i);
        while (active) {
            int r=63*i+__builtin_ctzll(active);
            active &= active-1;
            if ((mlsize_t)r>=Wosize_val(rows)) continue;
            value row=Field(rows,r);
            uint64_t support[CCV_LANES], intersects=0;
            int weight=0;
            for (int k=0;k<CCV_LANES;k++) {
                support[k]=word(row,k)&free_bits[k];
                weight+=__builtin_popcountll(support[k]);
                intersects|=support[k]&used[k];
            }
            if (weight<shortest) {shortest=weight;choice=r;}
            if (!weight) goto split;
            ids[entries]=r; next[entries]=head[weight]; head[weight]=entries++;
            if(weight>largest) largest=weight;
            if (!intersects) {
                packed[count++]=r;
                if (count>Long_val(remaining)) goto pack;
                for (int k=0;k<CCV_LANES;k++) used[k]|=support[k];
            }
        }
    }
    /* A second greedy order can produce a stronger disjoint packing.
       The projected supports for any proposed list are checked in Coq. */
    if(entries>Long_val(remaining) && count<=Long_val(remaining)) {
        for(int i=0;i<CCV_LANES;i++) used[i]=0;
        count=0;
        for(int k=1;k<=largest;k++) for(int at=head[k];at>=0;at=next[at]) {
            int r=ids[at]; value row=Field(rows,r);
            uint64_t support[CCV_LANES],intersects=0;
            for(int i=0;i<CCV_LANES;i++) {
                support[i]=word(row,i)&free_bits[i];
                intersects|=support[i]&used[i];
            }
            if(!intersects) {
                packed[count++]=r;
                if(count>Long_val(remaining)) goto pack;
                for(int i=0;i<CCV_LANES;i++) used[i]|=support[i];
            }
        }
    }
    /* When every remaining flip is charged to a packed row, an odd
       redundant check disjoint from the entire packing disproves completion.
       The Coq checker re-derives the sum and tests the whole certificate. */
    if (Wosize_val(incident) > 0 && count == Long_val(remaining) && count >= 2 && count <= 8) {
        for (int at=0; at<entries; ++at) {
            int i=ids[at], pivot=-1;
            value ri=Field(rows,i);
            for (int k=0; k<CCV_LANES; ++k) {
                uint64_t inter=word(ri,k)&used[k];
                if (inter) {pivot=k*63+__builtin_ctzll(inter);break;}
            }
            if (pivot<0) continue;
            value candidates=Field(incident,pivot);
            for (mlsize_t u=0;u<Wosize_val(candidates);++u) {
                int j=Int_val(Field(candidates,u));
                if ((mask_word(syndrome,j/63)>>(j%63))&1u) continue;
                value rj=Field(rows,j); int k=0;
                while(k<CCV_LANES && !((word(ri,k)^word(rj,k))&used[k])) ++k;
                if(k==CCV_LANES) { pair_i=i; pair_j=j; goto pack; }
            }
        }
    }
split:
    result=caml_alloc_small(1,0); Field(result,0)=Val_int(choice); CAMLreturn(result);
pack:
    list=Val_emptylist;
    while (count) {
        cell=caml_alloc_small(2,0); Field(cell,0)=Val_int(packed[--count]);
        Field(cell,1)=list; list=cell;
    }
    if (pair_i>=0) {
        result=caml_alloc_small(3,2); Field(result,0)=list;
        Field(result,1)=Val_int(pair_i); Field(result,2)=Val_int(pair_j);
        CAMLreturn(result);
    }
    result=caml_alloc_small(1,1); Field(result,0)=list; CAMLreturn(result);
}
