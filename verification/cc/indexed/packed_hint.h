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
#elif CCV_LANES == 24
    return word(Field(Field(Field(mask,j/12),(j/6)%2),(j/3)%2),j%3);
#else
#error "Unsupported packed representation"
#endif
}
/* Solve the syndrome equations on the union of saturated packed supports.
   If inconsistent, return the original row indices whose XOR witnesses it.
   The extracted kernel re-derives the odd check and the disjoint packing. */
static int erasure_conflict(value rows, value sy, value incident, const uint64_t used[CCV_LANES], int proof[65]) {
    int rank=0;
    unsigned char touched[CCV_WIDTH]={0}, slot[CCV_WIDTH]={0};
    uint64_t basis[64][CCV_LANES];
    unsigned char rhs[64];
    int origin[64]; uint64_t explanation[64];
    for(int block=0;block<CCV_LANES;++block) {
        uint64_t mask=used[block];
        while(mask) {
            int q=63*block+__builtin_ctzll(mask);mask&=mask-1;
            value adj=Field(incident,q);
            for(mlsize_t k=0;k<Wosize_val(adj);++k) {
                int i=Int_val(Field(adj,k));if(touched[i])continue;touched[i]=1;
                value row=Field(rows,i);
                uint64_t r[CCV_LANES];
                for(int j=0;j<CCV_LANES;++j)r[j]=word(row,j)&used[j];
                unsigned char parity=(unsigned char)((mask_word(sy,i/63)>>(i%63))&1u);
                uint64_t deps=0; int inserted=0;
                for(int j=0;j<CCV_LANES && !inserted;++j) while(r[j]) {
                    int col=63*j+__builtin_ctzll(r[j]);
                    int s=slot[col];
                    if(!s) {
                        if(rank>=64)return 0;
                        for(int h=j;h<CCV_LANES;++h)basis[rank][h]=r[h];
                        origin[rank]=i; explanation[rank]=deps|(UINT64_C(1)<<rank);
                        rhs[rank]=parity;slot[col]=(unsigned char)(++rank);inserted=1;break;
                    }
                    for(int h=j;h<CCV_LANES;++h)r[h]^=basis[s-1][h];
                    parity^=rhs[s-1]; deps^=explanation[s-1];
                }
                if(!inserted && parity) {
                    int count=0; proof[count++]=i;
                    while(deps) {
                        proof[count++]=origin[__builtin_ctzll(deps)];
                        deps&=deps-1;
                    }
                    return count;
                }
            }
        }
    }
    return 0;
}

CAMLprim value caml_wide_hash(value mask) {
    static const unsigned rot[24]={0,7,17,26,37,49,4,11,23,35,45,55,2,13,20,28,39,51,6,15,25,33,47,59};
    uint64_t hash=mask_word(mask,0);
    for (int i=1;i<CCV_LANES;i++) {
        uint64_t x=mask_word(mask,i);
        hash^=(x<<rot[i]) | (x>>(63u-rot[i]));
    }
    return Val_long((intnat)(hash&UINT64_C(0x7fffffffffffffff)));
}
CAMLprim value caml_wide_hint(value data, value syndrome, value free_mask, value remaining) {
    CAMLparam4(data, syndrome, free_mask, remaining);
    CAMLlocal5(result, list, cell, combination, other_combination);
    value rows=Field(data,0), incident=Field(data,1);
    int pair_i=-1,pair_j=-1;
    int proof[65], proof_length=0, other[65], other_length=0;
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
    if (Bool_val(Field(data,2)) && Wosize_val(incident)>0 &&
        count==Long_val(remaining) && count>=2 && count<=8) {
        proof_length=erasure_conflict(rows,syndrome,incident,used,proof);
        if(proof_length) goto pack;
    }
    /* A packing one row short needs two more disjoint odd checks.
       Restrict the second elimination to a region that also covers the
       first virtual check's available support. */
    if (Bool_val(Field(data,3)) && Wosize_val(incident)>0 &&
        count+1==Long_val(remaining) && count>=2 && count<=7) {
        proof_length=erasure_conflict(rows,syndrome,incident,used,proof);
        if (proof_length) {
            for (int k=0;k<CCV_LANES;k++) {
                uint64_t support=0;
                for (int j=0;j<proof_length;j++)
                    support^=word(Field(rows,proof[j]),k);
                used[k]|=free_bits[k]&support;
            }
            other_length=erasure_conflict(rows,syndrome,incident,used,other);
            if (other_length) goto pack;
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
    if (proof_length) {
        combination=Val_emptylist;
        while(proof_length) {
            cell=caml_alloc_small(2,0); Field(cell,0)=Val_int(proof[--proof_length]);
            Field(cell,1)=combination; combination=cell;
        }
        if (other_length) {
            other_combination=Val_emptylist;
            while(other_length) {
                cell=caml_alloc_small(2,0); Field(cell,0)=Val_int(other[--other_length]);
                Field(cell,1)=other_combination; other_combination=cell;
            }
            result=caml_alloc_small(3,4); Field(result,0)=list;
            Field(result,1)=combination; Field(result,2)=other_combination;
            CAMLreturn(result);
        }
        result=caml_alloc_small(2,3);
        Field(result,0)=list; Field(result,1)=combination; CAMLreturn(result);
    }
    if (pair_i>=0) {
        result=caml_alloc_small(3,2); Field(result,0)=list;
        Field(result,1)=Val_int(pair_i); Field(result,2)=Val_int(pair_j);
        CAMLreturn(result);
    }
    result=caml_alloc_small(1,1); Field(result,0)=list; CAMLreturn(result);
}
