/* Differential test for the packed C upper-witness descent. */
#define main upper_cli_main
#include "../upper.c"
#undef main

static uint64_t sample_word(uint32_t *seed) {
    uint64_t high=random_u32(seed);
    return (high<<32)|random_u32(seed);
}

int main(void) {
    uint32_t seed=UINT32_C(37289);
    unsigned controls=0, sparse=0, dense=0;
    for(unsigned lanes=1;lanes<=WORDS;lanes++) {
        for(unsigned sample=0;sample<128;sample++) {
            word w={{0}},row={{0}};
            for(unsigned j=0;j<lanes;j++) {
                w.v[j]=sample_word(&seed);
                if(sample%3u==0 || j==lanes-1u || (sample%3u==1 && j%4u==0))
                    row.v[j]=sample_word(&seed);
            }
            row_info info=describe_row(&row,lanes);
            unsigned expected=0;
            for(unsigned j=0;j<lanes;j++)
                expected+=(unsigned)__builtin_popcountll(w.v[j]&row.v[j]);
            if(overlap_weight(&w,&row,lanes,info.occupied)!=expected) return 1;
            if(info.weight!=wt(&row,lanes)) return 1;
            if(info.occupied) sparse++; else dense++;
            controls++;
        }
    }
    if(!sparse || !dense) return 1;
    printf("%u exact overlap checks passed (%u sparse, %u dense).\n",controls,sparse,dense);
    return 0;
}
