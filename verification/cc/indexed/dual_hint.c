/* Infer a possible involution between the raw X and Z row sets. Row
   fingerprints only screen proposals. The extracted proof checks the full
   coordinate map and all row images on both original matrices. */
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

enum { limit = 756 };
struct trial {
    int width, rows, seed[limit], seed_length;
    int perm[limit];
    const unsigned char *x;
    uint64_t salt[limit], target[limit], image[limit];
};

static int compare(const void *a, const void *b) {
    uint64_t x=*(const uint64_t *)a, y=*(const uint64_t *)b;
    return (x>y)-(x<y);
}

static int matches(struct trial *t) {
    uint64_t first=0;
    for (int i=0; i<t->seed_length; ++i) first ^= t->salt[t->perm[t->seed[i]]];
    if (!bsearch(&first,t->target,(size_t)t->rows,sizeof(first),compare)) return 0;
    for (int r=0; r<t->rows; ++r) {
        const unsigned char *row=t->x+r*t->width;
        uint64_t h=0;
        for (int q=0; q<t->width; ++q)
            if (row[q]) h ^= t->salt[t->perm[q]];
        t->image[r]=h;
    }
    qsort(t->image,(size_t)t->rows,sizeof(first),compare);
    return !memcmp(t->image,t->target,(size_t)t->rows*sizeof(first));
}

static int candidates(struct trial *t) {
    int n=t->width, half=n/2;
    /* Inversion in the two-block group coordinates. Crossing the wrap of
       the first coordinate adds a shear to the second coordinate. */
    for (int b=1; b<=half; ++b) if (half%b==0) {
        int a=half/b;
        for (int twist=0; twist<(a>1 ? b : 1); ++twist) {
            for (int q=0; q<n; ++q) {
                int x=q%half/b, y=q%b;
                t->perm[q]=(1-q/half)*half+((a-x)%a)*b+
                           ((b-y+(x ? twist : 0))%b);
            }
            if (matches(t)) return 1;
        }
    }
    /* For multi-block circulants also test inversion within each cyclic
       block together with reversal of the block order. */
    for (int b=2; b<n; ++b) if (n%b==0 && n/b<=16) {
        for (int q=0; q<n; ++q)
            t->perm[q]=(n/b-1-q/b)*b+(b-q%b)%b;
        if (matches(t)) return 1;
    }
    return 0;
}

CAMLprim value caml_ccv_dual_hint(value width,value xs,value zs) {
    CAMLparam3(width,xs,zs);
    CAMLlocal1(answer);
    intnat width_n=Long_val(width);
    mlsize_t size=caml_string_length(xs);
    if (width_n<2 || width_n>limit || width_n%2 || size==0 ||
        size!=caml_string_length(zs) || size%(mlsize_t)width_n ||
        size/(mlsize_t)width_n>limit) CAMLreturn(Atom(0));
    struct trial t;
    t.width=(int)width_n; t.rows=(int)(size/(mlsize_t)width_n);
    t.x=Bytes_val(xs);
    const unsigned char *z=Bytes_val(zs);
    uint64_t salt=UINT64_C(0x243f6a8885a308d3);
    for (int q=0; q<t.width; ++q) {
        salt^=salt>>12; salt^=salt<<25; salt^=salt>>27;
        t.salt[q]=salt*UINT64_C(2685821657736338717);
    }
    t.seed_length=0;
    for (int r=0; r<t.rows; ++r) {
        uint64_t h=0;
        int count=0;
        for (int q=0; q<t.width; ++q) {
            if (z[r*t.width+q]) h^=t.salt[q];
            if (!t.seed_length && t.x[r*t.width+q]) t.seed[count++]=q;
        }
        if (!t.seed_length) t.seed_length=count;
        t.target[r]=h;
    }
    qsort(t.target,(size_t)t.rows,sizeof(t.target[0]),compare);
    if (!t.seed_length || !candidates(&t)) CAMLreturn(Atom(0));
    answer=caml_alloc((mlsize_t)t.width,0);
    for (int i=0; i<t.width; ++i) Field(answer,i)=Val_int(t.perm[i]);
    CAMLreturn(answer);
}
