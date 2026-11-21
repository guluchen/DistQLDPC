/* SPDX-License-Identifier: GPL-3.0-or-later. Checked, uniform-block cyclic
 * automorphisms; no dependence on family, filename, known bounds or witnesses. */
struct orbit_basis {
    uint64_t *pivots, *scratch;
    unsigned n, words;
};
static int orbit_storage(struct orbit_basis *b,unsigned n) {
    b->n=n; b->words=(n+63u)/64u;
    /* Only spend a bounded amount on speculative symmetry; a miss uses all roots. */
    if((uint64_t)n*b->words > (UINT64_C(32)<<20)/sizeof(uint64_t)) return 0;
    b->pivots=calloc((size_t)n*b->words,sizeof(uint64_t));
    b->scratch=calloc(b->words,sizeof(uint64_t));
    return b->scratch && b->pivots;
}
static void orbit_free(struct orbit_basis *b) {free(b->pivots);free(b->scratch);}

/* With period=1 insert each unpermuted row. Otherwise reduce every image
 * against that same immutable row space. A missing pivot rejects the period.
 * The permutation is bijective, so inclusion of the image implies equality. */
static int orbit_rows(struct orbit_basis *b,const unsigned char *rows,unsigned count,unsigned period,unsigned stride) {
    for(unsigned r=0;r<count;r++) {
        memset(b->scratch,0,(size_t)b->words*sizeof(uint64_t));
        for(unsigned i=0;i<b->n;i++) if(rows[r*b->n+i]) {
            unsigned pos=i%period;
            unsigned q=(pos>=period-stride) ? i-(period-stride) : i+stride;
            b->scratch[q/64u]|=UINT64_C(1)<<(q%64u);
        }
        int inserted=0;
        for(unsigned j=0;j<b->words && !inserted;j++) while(b->scratch[j]) {
            unsigned bit=(unsigned)__builtin_ctzll(b->scratch[j]);
            unsigned q=j*64u+bit;
            uint64_t *pivot=b->pivots+(size_t)q*b->words;
            if(!(pivot[j]&(UINT64_C(1)<<bit))) {
                if(period!=1u) return 0;
                memcpy(pivot+j,b->scratch+j,(size_t)(b->words-j)*sizeof(uint64_t));
                inserted=1;break;
            }
            for(unsigned k=j;k<b->words;k++) b->scratch[k]^=pivot[k];
        }
    }
    return 1;
}

static unsigned checked_period(const struct ccv_problem *p) {
    unsigned answer=1u;
    if(p->n<32u || !p->checks) return 1u;
    struct orbit_basis h={0},l={0};
    if(orbit_storage(&h,p->n) && orbit_storage(&l,p->n)) {
        orbit_rows(&h,p->h,p->checks,1u,1u);orbit_rows(&l,p->logical,p->logical_rows,1u,1u);
        for(unsigned period=p->n;period>1u;period--)
            if(p->n%period==0u && orbit_rows(&h,p->h,p->checks,period,1u) &&
               orbit_rows(&l,p->logical,p->logical_rows,period,1u)) {answer=period;break;}
        /* A transitive inner block plus verified shifts between those blocks
         * acts transitively inside the larger block. All generators stay within
         * that larger block. Missing evidence always leaves the old block. */
        if(answer>1u) for (;;) {
            unsigned before=answer;
            for(unsigned block=p->n;block>before;block--)
                if(p->n%block==0u && block%before==0u &&
                   orbit_rows(&h,p->h,p->checks,block,before) &&
                   orbit_rows(&l,p->logical,p->logical_rows,block,before)) {
                    answer=block;break;
                }
            if(answer==before) break;
        }
    }
    orbit_free(&h);orbit_free(&l);return answer;
}
