/* A bounded, untrusted upper-witness search on raw CSS matrices. */
#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "advice_width.h"
#define MAX_N CCV_ADVICE_WIDTH
#define WORDS ((MAX_N+63)/64)
#define POOL 32
typedef struct { uint64_t v[WORDS]; } word;
typedef struct { word *r; unsigned count, n, lanes; } matrix;

static unsigned bit(const word *w,unsigned q) {return (unsigned)((w->v[q/64]>>(q%64))&1u);}
static void flip(word *w,unsigned q) {w->v[q/64]^=UINT64_C(1)<<(q%64);}
static void add(word *u,const word *v,unsigned lanes) {
    for(unsigned i=0;i<lanes;i++) u->v[i]^=v->v[i];
}
static unsigned wt(const word *w,unsigned lanes) {
    unsigned total=0;
    for(unsigned i=0;i<lanes;i++) total+=(unsigned)__builtin_popcountll(w->v[i]);
    return total;
}
static int read_pcm(matrix *m, const char *path) {
    /* The proved parser handles arbitrary valid sizes when this adviser declines. */
    FILE *in=fopen(path,"r");
    if(!in) return 0;
    word row={{0}};unsigned col=0;int c,comment=0,ok=1;
    for(;;) {
        c=fgetc(in);
        if(c=='\n' || c==EOF) {
            if(col) {
                if(col!=m->n || m->count>=2u*m->n){ok=0;break;}
                m->r[m->count++]=row;memset(&row,0,sizeof(row));
            }
            if(c==EOF)break;
            col=0;comment=0;
        } else if(!comment) {
            if(c=='#')comment=1;
            else if(c=='0'||c=='1'){
                if(col==m->n){ok=0;break;}
                if(c=='1') flip(&row,col);
                col++;
            } else if(!isspace((unsigned char)c)){ok=0;break;}
        }
    }
    if(ferror(in))ok=0;
    fclose(in);return ok;
}
static uint32_t random_u32(uint32_t *state) {
    uint32_t x=*state;x^=x<<13;x^=x>>17;x^=x<<5;*state=x;return x;
}
static unsigned rref(word *rows,unsigned count,const unsigned *order,unsigned n,
                     unsigned lanes,unsigned *pivot,unsigned char *occupied) {
    unsigned rank=0;
    for(unsigned i=0;i<n && rank<count;i++) {
        unsigned q=order[i],r=rank;
        while(r<count && !bit(rows+r,q))r++;
        if(r==count)continue;
        word tmp=rows[r];rows[r]=rows[rank];rows[rank]=tmp;
        for(r=0;r<count;r++) if(r!=rank && bit(rows+r,q))add(rows+r,rows+rank,lanes);
        pivot[rank++]=q;occupied[q]=1;
    }
    return rank;
}
static int logical(word w,const word *basis,unsigned rank,const unsigned *pivot,unsigned lanes) {
    for(unsigned i=0;i<rank;i++) if(bit(&w,pivot[i])) add(&w,basis+i,lanes);
    return wt(&w,lanes)!=0;
}
static void descend(word *w,const matrix *g,const unsigned *weights,unsigned *weight) {
    for(unsigned pass=0;pass<4;pass++) {
        int changed=0;
        for(unsigned r=0;r<g->count;r++) {
            if(weights[r]>=2u*(*weight))continue;
            unsigned overlap=0;
            for(unsigned j=0;j<g->lanes;j++)overlap+=(unsigned)__builtin_popcountll(w->v[j]&g->r[r].v[j]);
            if(2u*overlap>weights[r]) {
                add(w,g->r+r,g->lanes);*weight-=2u*overlap-weights[r];changed=1;
            }
        }
        if(!changed)break;
    }
}
static void consider(word w,const matrix *g,const word *basis,unsigned rank,const unsigned *gp,
                     unsigned *best,word *answer) {
    unsigned d=wt(&w,g->lanes);
    if(d && d<*best && logical(w,basis,rank,gp,g->lanes)) {*best=d;*answer=w;}
}
static unsigned propose(const matrix *h,const matrix *g,word *answer,unsigned rounds) {
    word *rows=calloc(h->count+1u,sizeof(word)),*basis=calloc(g->count+1u,sizeof(word));
    unsigned *weights=calloc(g->count+1u,sizeof(unsigned));
    if(!rows||!basis||!weights){free(rows);free(basis);free(weights);return h->n+1u;}
    unsigned order[MAX_N]={0},piv[MAX_N],gp[MAX_N],best=h->n+1u;
    unsigned char used[MAX_N]={0};
    unsigned n=h->n,l=h->lanes;uint32_t state=UINT32_C(462119);
    for(unsigned i=0;i<n;i++)order[i]=i;
    for(unsigned j=0;j<g->count;j++) weights[j]=wt(g->r+j,l);
    memcpy(basis,g->r,g->count*sizeof(word));
    unsigned grank=rref(basis,g->count,order,n,l,gp,used);
    for(unsigned rep=0;rep<rounds;rep++) {
        if(rep)for(unsigned j=n-1;j>0;j--){
            unsigned k=random_u32(&state)%(j+1u),v=order[j];order[j]=order[k];order[k]=v;
        }
        memcpy(rows,h->r,h->count*sizeof(word));memset(used,0,n);
        unsigned rank=rref(rows,h->count,order,n,l,piv,used);
        word pool[POOL];unsigned sizes[POOL],kept=0;
        for(unsigned f=0;f<n;f++) if(!used[f]) {
            word v={{0}};flip(&v,f);
            for(unsigned i=0;i<rank;i++)if(bit(rows+i,f))flip(&v,piv[i]);
            unsigned d=wt(&v,l);
            descend(&v,g,weights,&d);
            if(!d)continue;
            consider(v,g,basis,grank,gp,&best,answer);
            for(unsigned i=0;i<kept;i++) {
                word pair=pool[i];add(&pair,&v,l);
                consider(pair,g,basis,grank,gp,&best,answer);
            }
            unsigned pos=0;
            while(pos<kept && sizes[pos]<=d)pos++;
            if(pos<POOL) {
                if(kept<POOL)kept++;
                for(unsigned j=kept-1;j>pos;j--){pool[j]=pool[j-1];sizes[j]=sizes[j-1];}
                pool[pos]=v;sizes[pos]=d;
            }
        }
    }
    free(rows);free(basis);free(weights);return best;
}
int main(int argc,char **argv) {
    if(argc!=4 && argc!=5)return 2;
    char *end;long width=strtol(argv[1],&end,10);
    if(*end || width<1 || width>MAX_N)return 3;
    unsigned n=(unsigned)width;
    /* Small matrices admit more shuffled information sets at low cost. */
    unsigned rounds=n<=189u ? 64u : 8u;
    if(argc==5) {
        long requested=strtol(argv[4],&end,10);
        if(*end || requested<1 || requested>4096) return 2;
        rounds=(unsigned)requested;
    }
    matrix x={calloc(2u*n,sizeof(word)),0,n,(n+63u)/64u};
    matrix z={calloc(2u*n,sizeof(word)),0,n,(n+63u)/64u};
    if(!x.r || !z.r || !read_pcm(&x,argv[2]) || !read_pcm(&z,argv[3])){free(x.r);free(z.r);return 3;}
    word wx={{0}},wz={{0}};
    unsigned dx=propose(&z,&x,&wx,rounds),dz=propose(&x,&z,&wz,rounds);
    free(x.r);free(z.r);if(dx>n && dz>n)return 3;
    const word *w=dx<=dz?&wx:&wz;puts(dx<=dz?"X":"Z");
    for(unsigned i=0;i<n;i++)putchar(bit(w,i)?'1':'0');
    putchar('\n');return 0;
}
