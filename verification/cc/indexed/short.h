/* SPDX-License-Identifier: GPL-3.0-or-later
 * A missing bit certifies that a syndrome cannot be the sum of <=2 columns.
 * Collisions leave search enabled. The table is private to a half and stores
 * no bound, seed, precomputed witness, or case-specific constant. */
struct short_sums {
    uint64_t *col;
    unsigned char *table;
    unsigned mask;
};
static uint64_t mix_word(uint64_t k) {
    k=(k^(k>>30))*UINT64_C(0xbf58476d1ce4e5b9);
    k=(k^(k>>27))*UINT64_C(0x94d049bb133111eb);
    return k^(k>>31);
}
static void insert_sum(const struct short_sums *t,uint64_t x) {
    unsigned i=(unsigned)mix_word(x)&t->mask;
    t->table[i>>3]|=(unsigned char)(1u<<(i&7u));
}
static int possible_sum(const struct short_sums *t,uint64_t x) {
    unsigned i=(unsigned)mix_word(x)&t->mask;
    return (t->table[i>>3]&(1u<<(i&7u)))!=0;
}
static void make_sums(struct short_sums *t,const struct ccv_problem *p,const struct sparse_search *v) {
    if(p->n<32u || p->n>2048u) return;
    unsigned bits=1024u;
    while(bits<p->n*p->n*4u) bits*=2u;
    t->mask=bits-1u;
    t->col=calloc(p->n,sizeof(uint64_t));
    t->table=calloc(bits/8u,sizeof(unsigned char));
    if(!t->col || !t->table) {free(t->col);free(t->table);t->col=NULL;t->table=NULL;return;}
    insert_sum(t,0);
    for(unsigned q=0;q<p->n;q++) {
        for(unsigned j=v->hcol.offset[q];j<v->hcol.offset[q+1u];j++)
            t->col[q]^=mix_word(UINT64_C(0x9e3779b97f4a7c15)+v->hcol.index[j]);
        insert_sum(t,t->col[q]);
        for(unsigned a=0;a<q;a++) insert_sum(t,t->col[q]^t->col[a]);
    }
}
/* A nonzero syndrome has an odd row. Any repair must contain a column of
 * this row. Remove that hypothetical column before testing the remainder.
 * Check against all row entries, even forbidden ones; this remains a superset. */
static int three_possible(const struct short_sums *t,const struct seats *rows,unsigned r,uint64_t sig) {
    for(unsigned j=rows->offset[r];j<rows->offset[r+1u];j++)
        if(possible_sum(t,sig^t->col[rows->index[j]])) return 1;
    return 0;
}
static int short_possible(const struct ccv_problem *p,const struct ccv_workspace *w,
                          const struct sparse_search *v,const struct short_sums *t,
                          unsigned remaining,unsigned row,uint64_t sig) {
    if(remaining<=2u) return possible_sum(t,sig);
    if(remaining==3u) return three_possible(t,&v->hrow,row,sig);
    for(unsigned j=v->hrow.offset[row];j<v->hrow.offset[row+1u];j++) {
        unsigned q=v->hrow.index[j],r=0u;
        while(r<p->checks && p->h[r*p->n+q]==w->syndrome[r]) r++;
        if(r==p->checks || three_possible(t,&v->hrow,r,sig^t->col[q])) return 1;
    }
    return 0;
}
static int kernel_even(const struct ccv_problem *p,const struct sparse_search *v) {
    for(unsigned q=0;q<p->n;q++)
        if(((v->hcol.offset[q+1u]-v->hcol.offset[q])&1u)==0u) return 0;
    return 1;
}
