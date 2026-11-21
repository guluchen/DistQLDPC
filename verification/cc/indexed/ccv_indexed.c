/* SPDX-License-Identifier: GPL-3.0-or-later
 * The pinned dense kernel supplies the validated input checks, primitive
 * updates and allocation-free fallback. Keep its original translation unit
 * intact for the published VST proof.
 */
#define ccv_decide ccv_dense_decide
#define ccv_distance ccv_dense_distance
#include "../ccv.c"
#undef ccv_decide
#undef ccv_distance
#include "sparse_search.h"
#include "orbit.h"
#include "short.h"
#include "redundant.h"

static int search_indexed(const struct ccv_problem *p,unsigned int cap,unsigned int budget,
                  unsigned int rules,struct ccv_workspace *w,
                  unsigned char *out,struct ccv_stats *stats,const struct sparse_search *v,unsigned step, const struct short_sums *t) {
    unsigned int seed,i,depth,top,q,row,remaining;
    int finish,ov;
    unsigned odd=0u;
    struct ccv_frame *f;
    if(cap==0u) return CCV_EMPTY;
    if(cap>p->n) cap=p->n;
    for(seed=0u;seed<p->n;seed+=step) {
        uint64_t sig=t && t->col ? t->col[seed] : 0u;
        clear(p,w,out);
        for(i=0u;i<seed;i++) w->forbidden[i]=1u;
        sparse_toggle(v,w,seed);depth=1u;top=0u;
        f=&w->frames[0];f->phase=0u;f->mark=0u;
        while(depth>0u) {
            if(stats->steps>=budget) { clear(p,w,out);return CCV_UNKNOWN; }
            stats->steps++;f=&w->frames[depth-1u];finish=0;
            if(f->phase==0u) {
                stats->nodes++;remaining=cap-depth;
                row=p->checks;
                for(i=0u;i<p->checks;i++) if(w->syndrome[i]!=0u) { row=i;break; }
                if(row==p->checks) {
                    if(nontrivial(p,w)) {
                        for(i=0u;i<p->n;i++) out[i]=w->selected[i];
                        return CCV_FOUND;
                    }
                    finish=1; /* no proper prefix of a minimum target has zero syndrome */
                } else if(remaining==0u) finish=1;
                else if(t && t->col && remaining<=4u &&
                        !short_possible(p,w,v,t,remaining,row,sig)) finish=1;
                if(!finish && (rules&CCV_OVERLAP)!=0u) {
                    ov=sparse_overlap(p,w,&top,v,depth,depth==1u ? seed : w->frames[depth-2u].chosen,t!=NULL);
                    if(ov<0) { clear(p,w,out);return CCV_UNKNOWN; }
                    if(ov==0) { stats->overlap_prunes++;finish=1; }
                }
                if(!finish && !sparse_bounds(p,w,remaining,rules,&row,stats,v,&odd)) finish=1;
                if(!finish && remaining==1u && (rules&CCV_LEAF)!=0u) {
                    if(sparse_leaf(p,w,row,odd,v)) {
                        for(i=0u;i<p->n;i++) out[i]=w->selected[i];
                        return CCV_FOUND;
                    }
                    finish=1;
                }
                if(!finish) { f->row=row;f->next=v->hrow.offset[row];f->phase=1u; }
            } else if(f->phase==1u) {
                q=f->next;
                const unsigned end=v->hrow.offset[f->row+1u];
                while(q<end && (w->selected[v->hrow.index[q]] || w->forbidden[v->hrow.index[q]])) q++;
                if(q==end) finish=1;
                else {
                    f->next=q+1u;
                    q=v->hrow.index[q];
                    f->chosen=q;f->phase=2u;
                    if(t && t->col) sig^=t->col[q];
                    sparse_toggle(v,w,q);
                    w->frames[depth].mark=top;w->frames[depth].phase=0u;depth++;
                }
            } else {
                q=f->chosen;
                if(t && t->col) sig^=t->col[q];
                sparse_toggle(v,w,q);
                if((rules&CCV_EXCL)!=0u && !forbid(w,q,&top,p->n)) {
                    clear(p,w,out);return CCV_UNKNOWN;
                }
                f->phase=1u;
            }
            if(finish) {
#if CCV_MUTANT != 1
                restore(w,&top,f->mark);
#endif
                depth--;
            }
        }
    }
    clear(p,w,out);return CCV_EMPTY;
}
int ccv_decide(const struct ccv_problem *p,unsigned int cap,unsigned int budget,
               unsigned int rules,struct ccv_workspace *w,unsigned char *out,
               struct ccv_stats *s) {
    stats_init(s);
    if(!shape(p,w,rules) || !validate(p)) return CCV_INVALID;
    clear(p,w,out);
    struct sparse_search idx={0};
    const struct sparse_search *v=sparse_init(&idx,p,rules) ? &idx : NULL;
    int result=v ? search_indexed(p,cap,budget,rules,w,out,s,v,1u,NULL) : search(p,cap,budget,rules,w,out,s);
    free_sparse(&idx);
    return result;
}
int ccv_distance(const struct ccv_problem *p,unsigned int budget,unsigned int rules,
                 struct ccv_workspace *w,unsigned char *out,unsigned int *distance,
                 struct ccv_stats *s) {
    unsigned int cap;int result=CCV_EMPTY;
    stats_init(s);
    if(!shape(p,w,rules) || !validate(p)) return CCV_INVALID;
    struct ccv_problem extra=*p;
    struct ccv_workspace local=*w;
    struct augmented hs={NULL,p->checks},gs={NULL,p->stabilizers};
    unsigned char *aux=NULL;
    if(rules & CCV_PACK) {
        hs=pair_rows(p->h,p->checks,p->n);
        if(hs.data) {
            aux=calloc(hs.count,1u);
            if(aux) {extra.h=hs.data;extra.checks=hs.count;local.syndrome=aux;}
        }
    }
    if(rules & CCV_OVERLAP) {
        gs=pair_rows(p->stabilizer,p->stabilizers,p->n);
        if(gs.data){extra.stabilizer=gs.data;extra.stabilizers=gs.count;}
    }
    p=&extra; w=&local;
    struct sparse_search idx={0};
    const struct sparse_search *v=sparse_init(&idx,p,rules) ? &idx : NULL;
    clear(p,w,out);*distance=0u;
    unsigned step=v ? checked_period(p) : 1u;
    struct short_sums sums={0};
    if(v && (rules & CCV_LEAF)) make_sums(&sums,p,v);
    unsigned stride=v && kernel_even(p,v) ? 2u : 1u;
    for(cap=stride;cap<=p->n;cap+=stride) {
        result=v ? search_indexed(p,cap,budget,rules,w,out,s,v,step,&sums) : search(p,cap,budget,rules,w,out,s);
        if(result==CCV_FOUND) *distance=ccv_weight(p->n,out);
        if(result!=CCV_EMPTY) break;
    }
    free(sums.table);free(sums.col);
    free_sparse(&idx);free(aux);free(hs.data);free(gs.data);
    return result;
}
