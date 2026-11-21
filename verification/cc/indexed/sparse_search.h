/* SPDX-License-Identifier: GPL-3.0-or-later
 * Private accelerator for the validated CC half-problem. All indices are per call. */
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
unsigned ccv_gather(unsigned, const unsigned *, const unsigned char *);

struct seats {
    unsigned *offset;
    unsigned *index;
};
struct sparse_search {
    struct seats hrow, hcol, srow, scol, lcol;
};

static void free_seats(struct seats *s) { free(s->offset); free(s->index); }

static void free_sparse(struct sparse_search *v) {
    free_seats(&v->hrow); free_seats(&v->hcol);
    free_seats(&v->srow); free_seats(&v->scol); free_seats(&v->lcol);
}

/* The input matrix is validated as binary and rows * cols <= INT_MAX.
 * Use size_t and an explicit extent check, including on 32-bit targets. */
static int seats_make(struct seats *s, unsigned rows, unsigned cols,
                      const unsigned char *a, int transpose) {
    unsigned outer = transpose ? cols : rows;
    unsigned inner = transpose ? rows : cols;
    size_t nnz = 0;
    if ((uint64_t)outer + 1u > SIZE_MAX / sizeof(unsigned)) return 0;
    s->offset = calloc((size_t)outer + 1u, sizeof(unsigned));
    if (!s->offset) return 0;
    for (unsigned r = 0; r < outer; r++) {
        for (unsigned j = 0; j < inner; j++)
            nnz += a[transpose ? j * cols + r : r * cols + j];
        s->offset[r + 1u] = (unsigned)nnz;
    }
    if (nnz > SIZE_MAX / sizeof(unsigned)) return 0;
    s->index = calloc(nnz ? nnz : 1u, sizeof(unsigned));
    if (!s->index) return 0;
    nnz = 0;
    for (unsigned r = 0; r < outer; r++)
        for (unsigned j = 0; j < inner; j++)
            if (a[transpose ? j * cols + r : r * cols + j])
                s->index[nnz++] = j;
    return 1;
}

static int sparse_init(struct sparse_search *v, const struct ccv_problem *p,
                       unsigned rules) {
    return seats_make(&v->hrow, p->checks, p->n, p->h, 0)
        && seats_make(&v->hcol, p->checks, p->n, p->h, 1)
        && seats_make(&v->lcol, p->logical_rows, p->n, p->logical, 1)
        && (!(rules & CCV_OVERLAP) ||
              (seats_make(&v->srow, p->stabilizers, p->n, p->stabilizer, 0)
            && seats_make(&v->scol, p->stabilizers, p->n, p->stabilizer, 1)));
}

void ccv_flip(unsigned, const unsigned *, unsigned char *);
static void toggle_column(const struct seats *s, unsigned q, unsigned char *bits) {
    unsigned lo=s->offset[q], hi=s->offset[q+1u];
    ccv_flip(hi-lo,s->index+lo,bits);
}

static void sparse_toggle(const struct sparse_search *v,struct ccv_workspace *w,unsigned q) {
    w->selected[q] ^= 1u;
    toggle_column(&v->hcol,q,w->syndrome);
    toggle_column(&v->lcol,q,w->logical_value);
}

/* At the root even disjoint singleton rows can be tight. At a child only
 * rows incident to the added qubit change. The parent's journal remains live
 * until the child exits; earlier tight rows have already forbidden all of
 * their unselected positions. Both row lists are ascending. */
static int sparse_overlap(const struct ccv_problem *p,struct ccv_workspace *w,
                          unsigned *top,const struct sparse_search *v,
                          unsigned depth,unsigned chosen,int tiebreak) {
    const struct seats *s=&v->srow, *inc=&v->scol;
    unsigned lo=0u, hi=p->stabilizers;
    if (depth>1u) { lo=inc->offset[chosen]; hi=inc->offset[chosen+1u]; }
    for (unsigned j=lo; j<hi; j++) {
        unsigned r=depth==1u ? j : inc->index[j];
        unsigned start=s->offset[r], end=s->offset[r+1u], weight=end-start;
        unsigned ov=ccv_gather(weight,s->index+start,w->selected);
        unsigned limit=weight/2u;
#if CCV_MUTANT == 4
        if(weight) limit=(weight-1u)/2u;
#endif
        /* Among globally minimum logicals choose one preferring 1 at the
         * earliest unequal coordinate. XOR with an even stabilizer preserves
         * a tied weight, so the preferred qubit must be set on an exact tie. */
        int exempt=tiebreak && weight && !(weight&1u) && !w->selected[s->index[start]];
        if(exempt && limit) limit--;
        if(ov>limit) return 0;
        if(ov==limit) for(unsigned i=start;i<end;i++) {
            unsigned q=s->index[i];
            if(!(exempt && i==start) && !w->selected[q] && !forbid(w,q,top,p->n)) return -1;
        }
    }
    return 1;
}
static int sparse_bounds(const struct ccv_problem *p,struct ccv_workspace *w,
                         unsigned remaining,unsigned rules,unsigned *row,
                         struct ccv_stats *stats,const struct sparse_search *v,
                         unsigned *odd_count) {
    const struct seats *s=&v->hrow, *col=&v->hcol;
    unsigned best=p->n,pack=0u,odd=0u;
    *row=p->checks;
    if(rules & CCV_PACK) memset(w->packed,0,p->n);
    for(unsigned i=0u;i<p->checks;i++) if(w->syndrome[i]) {
        unsigned lo=s->offset[i],hi=s->offset[i+1u],count=0u,used=0u;
        odd++;
        for(unsigned j=lo;j<hi;j++) {
            unsigned q=s->index[j];
            if(!w->selected[q] && !w->forbidden[q]) {
                count++;
                if((rules & CCV_PACK) && w->packed[q]) used=1u;
            }
        }
        if(!count) return 0;
        if(*row==p->checks || ((rules & CCV_MRV) && count<best)) { *row=i; best=count; }
        if((rules & CCV_PACK) && !used) {
            pack++;
#if CCV_MUTANT == 2
            if(pack>=remaining) {
#else
            if(pack>remaining) {
#endif
                stats->pack_prunes++;return 0;
            }
            for(unsigned j=lo;j<hi;j++) {
                unsigned q=s->index[j];
                if(!w->selected[q] && !w->forbidden[q]) w->packed[q]=1u;
            }
        }
    }
    *odd_count=odd;
    /* Every odd row above has a free candidate. The exact old charge test
     * is equivalent to existence of a free column hitting ceil(odd/remaining)
     * odd rows. One such column suffices, even if a higher degree exists. */
    if((rules & CCV_CHARGE) && odd) {
#if CCV_MUTANT == 5
        if(odd>remaining) {stats->charge_prunes++;return 0;}
#else
        unsigned need=ccv_ceil_div(odd,remaining);
        if(need<=1u) return 1;
        for(unsigned q=0;q<p->n;q++) if(!w->selected[q] && !w->forbidden[q]) {
            unsigned start=col->offset[q],degree=col->offset[q+1u]-start;
            if(degree>=need && ccv_gather(degree,col->index+start,w->syndrome)>=need) return 1;
        }
        stats->charge_prunes++;return 0;
#endif
    }
    return 1;
}

static int sparse_leaf(const struct ccv_problem *p,struct ccv_workspace *w,unsigned row,
                       unsigned odd,const struct sparse_search *v) {
    const struct seats *s=&v->hrow, *col=&v->hcol;
    for(unsigned j=s->offset[row]; j<s->offset[row+1u]; j++) {
        unsigned q=s->index[j];
        if(w->selected[q] || w->forbidden[q]) continue;
        unsigned lo=col->offset[q], degree=col->offset[q+1u]-lo;
        if(degree!=odd || ccv_gather(degree,col->index+lo,w->syndrome)!=odd) continue;
        unsigned logical=0u;
        for(unsigned i=0u;i<p->logical_rows;i++) logical|=w->logical_value[i]^p->logical[i*p->n+q];
#if CCV_MUTANT == 3
        logical=1u;
#endif
        if(logical) {sparse_toggle(v,w,q);return 1;}
    }
    return 0;
}
