/* Search for disjoint representatives of a single detecting coset. All
   proposed supports and quotient relations are checked by the proof kernel. */
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

enum { limit=756, lanes=(limit+63)/64 };
typedef struct { uint64_t w[lanes]; } bits;
typedef struct { bits row[limit]; unsigned char pivot[limit]; } basis;
typedef struct { int start, step; } line;
typedef struct { bits cls, occupied; int count; line chosen[limit]; } group;

static void toggle(bits *a,const bits *b,int count) {
    for(int j=0;j<count;++j) a->w[j]^=b->w[j];
}
static int set(const bits *a,int q) {return (int)((a->w[q/64]>>(q%64)) & 1u);}
static int nonzero(const bits *a,int count) {
    for(int j=0;j<count;++j) if(a->w[j]) return 1;
    return 0;
}
static void reduce(bits *a,const basis *b,int n,int count) {
    for(int i=n-1;i>=0;--i)
        if(b->pivot[i] && set(a,i)) toggle(a,&b->row[i],count);
}
static int build(basis *b,const unsigned char *rows,int m,int n,int count) {
    int rank=0;
    for(int j=0;j<m;++j) {
        bits a={{0}};
        for(int q=0;q<n;++q) if(rows[j*n+q]) a.w[q/64]|=UINT64_C(1)<<(q%64);
        reduce(&a,b,n,count);
        for(int q=n-1;q>=0;--q) if(set(&a,q)) {
            b->pivot[q]=1; b->row[q]=a; ++rank; break;
        }
    }
    return rank;
}
static int propose(group *g,const basis *h,const bits *col,int n,int m,int d) {
    int count=(n+63)/64, synd_words=(m+63)/64;
    for(int step=1;step<=(n-1)/(d-1);++step) {
        for(int base=0;base<step;++base) {
            bits syndrome={{0}}, word={{0}};
            for(int last=base;last<n;last+=step) {
                toggle(&syndrome,&col[last],synd_words);
                word.w[last/64]^=UINT64_C(1)<<(last%64);
                int drop=last-step*d;
                if(drop>=base) {
                    toggle(&syndrome,&col[drop],synd_words);
                    word.w[drop/64]^=UINT64_C(1)<<(drop%64);
                }
                int start=last-(d-1)*step;
                if(start<base || nonzero(&syndrome,synd_words)) continue;
                int intersects=0;
                for(int j=0;j<count;++j) if(word.w[j]&g->occupied.w[j]) intersects=1;
                if(intersects) continue;
                bits cls=word; reduce(&cls,h,n,count);
                if(!nonzero(&cls,count)) continue;
                if(g->count==0) g->cls=cls;
                if(memcmp(&g->cls,&cls,(size_t)count*sizeof(uint64_t))) continue;
                for(int j=0;j<count;++j) g->occupied.w[j]|=word.w[j];
                g->chosen[g->count++]=(line){start,step};
                if(g->count==d) return 1;
            }
        }
    }
    return 0;
}

CAMLprim value caml_ccv_disjoint_lines(value width,value distance,value checks,value same) {
    CAMLparam4(width,distance,checks,same);
    CAMLlocal1(result);
    intnat dn=Long_val(width),dd=Long_val(distance);
    if(dn<2 || dn>limit || dd<2 || dd>dn) CAMLreturn(Atom(0));
    int n=(int)dn,d=(int)dd,count=(n+63)/64;
    mlsize_t a=caml_string_length(checks), b=caml_string_length(same);
    if(a%(mlsize_t)n || b%(mlsize_t)n || a/(mlsize_t)n>limit || b/(mlsize_t)n>limit)
        CAMLreturn(Atom(0));
    int m=(int)(a/(mlsize_t)n), k=(int)(b/(mlsize_t)n);
    /* Rank cannot reach n-1 with fewer than n-1 total rows. */
    if(m+k<n-1) CAMLreturn(Atom(0));
    basis *hb=calloc(1,sizeof(*hb)),*other=calloc(1,sizeof(*other));
    bits *columns=calloc((size_t)n,sizeof(*columns));
    group g={0};
    int found=0;
    if(hb && other && columns) {
        const unsigned char *hr=Bytes_val(checks), *sr=Bytes_val(same);
        int r1=build(hb,hr,m,n,count),r2=build(other,sr,k,n,count);
        if(n-r1-r2==1) {
            for(int j=0;j<k;++j) for(int q=0;q<n;++q) if(sr[j*n+q])
                columns[q].w[j/64]|=UINT64_C(1)<<(j%64);
            found=propose(&g,hb,columns,n,k,d);
        }
    }
    free(hb);free(other);free(columns);
    if(!found) CAMLreturn(Atom(0));
    result=caml_alloc((mlsize_t)(2*d),0);
    for(int i=0;i<d;++i) {
        Field(result,2*i)=Val_int(g.chosen[i].start);
        Field(result,2*i+1)=Val_int(g.chosen[i].step);
    }
    CAMLreturn(result);
}
