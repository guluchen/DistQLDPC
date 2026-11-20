/* SPDX-License-Identifier: GPL-3.0-or-later
 * Original plain-C reimplementation of DistQLDPC CC mathematics.
 * No malloc, recursion, STL, floating point, or unvalidated symmetry.
 * Proof obligations are documented in proof/OBLIGATIONS.md. */
#include "ccv.h"
#ifndef CCV_MUTANT
#define CCV_MUTANT 0
#endif
static int shape(const struct ccv_problem *p, const struct ccv_workspace *w,
                 unsigned int rules) {
    unsigned int n=p->n;
    if (n==0u || n>2147483647u/sizeof(struct ccv_frame) ||
        n>2147483647u/sizeof(unsigned int)) return 0;
    if (p->logical_rows==0u || p->checks>2147483647u/n ||
        p->logical_rows>2147483647u/n || p->stabilizers>2147483647u/n) return 0;
    if (w->capacity<n || w->frame_capacity<n || rules>CCV_ALL) return 0;
    return 1;
}
static int validate(const struct ccv_problem *p) {
    unsigned int i,j,q,v;
    for (i=0u;i<p->checks*p->n;i++) if (p->h[i]>1u) return 0;
    for (i=0u;i<p->logical_rows*p->n;i++) if (p->logical[i]>1u) return 0;
    for (i=0u;i<p->stabilizers*p->n;i++) if (p->stabilizer[i]>1u) return 0;
    /* Every supplied stabilizer must preserve H and every logical functional.
     * This check is unconditional: malformed metadata is never silently used. */
    for (i=0u;i<p->stabilizers;i++) {
        for (j=0u;j<p->checks+p->logical_rows;j++) {
            v=0u;
            for (q=0u;q<p->n;q++) {
                if (j<p->checks) v^=p->h[j*p->n+q]&p->stabilizer[i*p->n+q];
                else v^=p->logical[(j-p->checks)*p->n+q]&p->stabilizer[i*p->n+q];
            }
            if (v!=0u) return 0;
        }
    }
    return 1;
}
static void clear(const struct ccv_problem *p, struct ccv_workspace *w,
                  unsigned char *out) {
    unsigned int i;
    for(i=0u;i<p->n;i++) {
        w->selected[i]=0u;w->forbidden[i]=0u;w->packed[i]=0u;out[i]=0u;
    }
    for(i=0u;i<p->checks;i++) w->syndrome[i]=0u;
    for(i=0u;i<p->logical_rows;i++) w->logical_value[i]=0u;
}
static void toggle(const struct ccv_problem *p, struct ccv_workspace *w,
                   unsigned int q) {
    unsigned int i;
    w->selected[q]^=1u;
    for(i=0u;i<p->checks;i++) w->syndrome[i]^=p->h[i*p->n+q];
    for(i=0u;i<p->logical_rows;i++) w->logical_value[i]^=p->logical[i*p->n+q];
}
static int nontrivial(const struct ccv_problem *p, const struct ccv_workspace *w) {
    unsigned int i;
    for(i=0u;i<p->logical_rows;i++) if(w->logical_value[i]!=0u) return 1;
    return 0;
}
static void restore(struct ccv_workspace *w, unsigned int *top, unsigned int mark) {
    while(*top>mark) { *top=*top-1u;w->forbidden[w->undo[*top]]=0u; }
}
static int forbid(struct ccv_workspace *w,unsigned int q,unsigned int *top,
                  unsigned int n) {
    if(w->forbidden[q]==0u) {
        if(*top>=n) return 0; /* defensive UNKNOWN, never an EMPTY */
        w->undo[*top]=q;*top=*top+1u;w->forbidden[q]=1u;
    }
    return 1;
}
/* Return -1 for exhausted scratch (UNKNOWN), 0 prune, 1 survive. */
static int overlap(const struct ccv_problem *p,struct ccv_workspace *w,
                   unsigned int *top) {
    unsigned int i,q,weight,ov,limit;
    for(i=0u;i<p->stabilizers;i++) {
        weight=0u;ov=0u;
        for(q=0u;q<p->n;q++) {
            weight+=p->stabilizer[i*p->n+q];
            ov+=p->stabilizer[i*p->n+q]&w->selected[q];
        }
        limit=weight/2u;
#if CCV_MUTANT == 4
        if(weight>0u) limit=(weight-1u)/2u; /* invalid strict even tie */
#endif
        if(ov>limit) return 0;
        if(ov==limit) for(q=0u;q<p->n;q++)
            if(p->stabilizer[i*p->n+q]!=0u && w->selected[q]==0u)
                if(!forbid(w,q,top,p->n)) return -1;
    }
    return 1;
}
/* Select an odd row, disjoint candidate-set packing, and a uniform cover-dual
 * charge bound. Deliberately simpler than the native fractional charge suite.
 * row==checks denotes no odd row. No sum-of-bounds: use each sound bound alone. */
static int bounds(const struct ccv_problem *p,struct ccv_workspace *w,
                  unsigned int remaining,unsigned int rules,unsigned int *row,
                  struct ccv_stats *stats) {
    unsigned int i,q,count,best=p->n,used,pack=0u,odd=0u,maxdeg=0u,deg,lb;
    *row=p->checks;
    for(q=0u;q<p->n;q++) w->packed[q]=0u;
    for(i=0u;i<p->checks;i++) if(w->syndrome[i]!=0u) {
        odd++;count=0u;used=0u;
        for(q=0u;q<p->n;q++)
            if(p->h[i*p->n+q]!=0u && w->selected[q]==0u && w->forbidden[q]==0u) {
                count++;if(w->packed[q]!=0u) used=1u;
            }
        if(count==0u) return 0;
        if(*row==p->checks || ((rules&CCV_MRV)!=0u && count<best)) { *row=i;best=count; }
        if((rules&CCV_PACK)!=0u && used==0u) {
            pack++;
            for(q=0u;q<p->n;q++) if(p->h[i*p->n+q]!=0u &&
                w->selected[q]==0u && w->forbidden[q]==0u) w->packed[q]=1u;
#if CCV_MUTANT == 2
            if(pack>=remaining) { stats->pack_prunes++;return 0; }
#else
            if(pack>remaining) { stats->pack_prunes++;return 0; }
#endif
        }
    }
    if((rules&CCV_CHARGE)!=0u && odd>0u) {
        for(q=0u;q<p->n;q++) if(w->selected[q]==0u && w->forbidden[q]==0u) {
            deg=0u;
            for(i=0u;i<p->checks;i++) if(w->syndrome[i]!=0u) deg+=p->h[i*p->n+q];
            if(deg>maxdeg) maxdeg=deg;
        }
        if(maxdeg==0u) return 0;
        lb=ccv_ceil_div(odd,maxdeg);
#if CCV_MUTANT == 5
        lb=odd; /* invalid: ignore that one column can repair several rows */
#endif
        if(lb>remaining) { stats->charge_prunes++;return 0; }
    }
    return 1;
}
static int leaf(const struct ccv_problem *p,struct ccv_workspace *w) {
    unsigned int q,i,ok,logical;
    for(q=0u;q<p->n;q++) if(w->selected[q]==0u && w->forbidden[q]==0u) {
        ok=1u;
        for(i=0u;i<p->checks;i++) if(w->syndrome[i]!=p->h[i*p->n+q]) ok=0u;
        if(ok!=0u) {
            logical=0u;
            for(i=0u;i<p->logical_rows;i++) logical|=w->logical_value[i]^p->logical[i*p->n+q];
#if CCV_MUTANT == 3
            logical=1u; /* accept a stabilizer closure */
#endif
            if(logical!=0u) { toggle(p,w,q);return 1; }
        }
    }
    return 0;
}
static int search(const struct ccv_problem *p,unsigned int cap,unsigned int budget,
                  unsigned int rules,struct ccv_workspace *w,
                  unsigned char *out,struct ccv_stats *stats) {
    unsigned int seed,i,depth,top,q,row,remaining;
    int finish,ov;
    struct ccv_frame *f;
    if(cap==0u) return CCV_EMPTY;
    if(cap>p->n) cap=p->n;
    for(seed=0u;seed<p->n;seed++) {
        clear(p,w,out);
        for(i=0u;i<seed;i++) w->forbidden[i]=1u;
        toggle(p,w,seed);depth=1u;top=0u;
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
                if(!finish && (rules&CCV_OVERLAP)!=0u) {
                    ov=overlap(p,w,&top);
                    if(ov<0) { clear(p,w,out);return CCV_UNKNOWN; }
                    if(ov==0) { stats->overlap_prunes++;finish=1; }
                }
                if(!finish && !bounds(p,w,remaining,rules,&row,stats)) finish=1;
                if(!finish && remaining==1u && (rules&CCV_LEAF)!=0u) {
                    if(leaf(p,w)) {
                        for(i=0u;i<p->n;i++) out[i]=w->selected[i];
                        return CCV_FOUND;
                    }
                    finish=1;
                }
                if(!finish) { f->row=row;f->next=0u;f->phase=1u; }
            } else if(f->phase==1u) {
                q=f->next;
                while(q<p->n && (p->h[f->row*p->n+q]==0u ||
                       w->selected[q]!=0u || w->forbidden[q]!=0u)) q++;
                if(q==p->n) finish=1;
                else {
                    f->next=q+1u;f->chosen=q;f->phase=2u;
                    toggle(p,w,q);
                    w->frames[depth].mark=top;w->frames[depth].phase=0u;depth++;
                }
            } else {
                q=f->chosen;toggle(p,w,q);
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
static void stats_init(struct ccv_stats *s) {
    s->steps=0u;s->nodes=0u;s->pack_prunes=0u;s->charge_prunes=0u;s->overlap_prunes=0u;
}
int ccv_decide(const struct ccv_problem *p,unsigned int cap,unsigned int budget,
               unsigned int rules,struct ccv_workspace *w,unsigned char *out,
               struct ccv_stats *s) {
    stats_init(s);
    if(!shape(p,w,rules) || !validate(p)) return CCV_INVALID;
    clear(p,w,out);
    return search(p,cap,budget,rules,w,out,s);
}
int ccv_distance(const struct ccv_problem *p,unsigned int budget,unsigned int rules,
                 struct ccv_workspace *w,unsigned char *out,unsigned int *distance,
                 struct ccv_stats *s) {
    unsigned int cap;int result;
    stats_init(s);
    if(!shape(p,w,rules) || !validate(p)) return CCV_INVALID;
    clear(p,w,out);*distance=0u;
    for(cap=1u;cap<=p->n;cap++) {
        result=search(p,cap,budget,rules,w,out,s);
        if(result==CCV_FOUND) { *distance=ccv_weight(p->n,out);return result; }
        if(result!=CCV_EMPTY) return result;
    }
    return CCV_EMPTY;
}
