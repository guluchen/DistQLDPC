/* SPDX-License-Identifier: GPL-3.0-or-later
 * Experimental redundant parity/stabilizer rows as in DistQLDPC GH-181.
 * Only nonzero XORs no heavier than the heavier parent are considered. */
struct augmented {
    unsigned char *data;
    unsigned count;
};
static struct augmented pair_rows(const unsigned char *in,unsigned m,unsigned n) {
    struct augmented out={NULL,m};
    if(m<2 || m>2048 || n>2048 || (uint64_t)m*n>UINT64_C(8000000)) return out;
    struct seats support={0};
    if(!seats_make(&support,m,n,in,0)) {free_seats(&support);return out;}
    unsigned char *tmp=malloc(n);
    if(!tmp) {free_seats(&support);return out;}
    for(unsigned a=0;a<m && out.count<3u*m;a++) {
        unsigned wa=support.offset[a+1u]-support.offset[a];
        if(!wa || wa>32)continue;
        for(unsigned b=0;b<a && out.count<3u*m;b++) {
            unsigned wb=support.offset[b+1u]-support.offset[b],overlap=0u;
            if(!wb || wb>32)continue;
            for(unsigned j=support.offset[a];j<support.offset[a+1u];j++) overlap+=in[b*n+support.index[j]];
            unsigned wnew=wa+wb-2u*overlap;
            if(!wnew || wnew>(wa>wb ? wa : wb))continue;
            for(unsigned j=0;j<n;j++)tmp[j]=in[a*n+j]^in[b*n+j];
            const unsigned char *all=out.data ? out.data : in;
            unsigned k=0;
            while(k<out.count && memcmp(tmp,all+k*n,n)) k++;
            if(k<out.count)continue;
            if(!out.data) {
                out.data=malloc((size_t)m*3u*n);
                if(!out.data) goto done;
                memcpy(out.data,in,(size_t)m*n);
            }
            memcpy(out.data+out.count*n,tmp,n);out.count++;
        }
    }
done:
    free(tmp);free_seats(&support);return out;
}
