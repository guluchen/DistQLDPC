/* SPDX-License-Identifier: GPL-3.0-or-later
 * Unverified host driver; allocation/parsing are outside the proof boundary.
 * Input: n m l k, then m H rows, l logical rows, k stabilizer rows as bits.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "ccv.h"
static int matrix(unsigned int rows,unsigned int n,unsigned char *a) {
    unsigned int i;int x;
    for(i=0u;i<rows*n;i++) {
        if(scanf("%1d",&x)!=1 || x<0 || x>1) return 0;
        a[i]=(unsigned char)x;
    }
    return 1;
}
int main(int argc,char **argv) {
    struct ccv_problem p;struct ccv_workspace w;struct ccv_stats s;
    unsigned char *h,*l,*k,*out;unsigned int d=0u,rules=CCV_ALL,budget=100000000u,i;int r;
    if(argc>1) {char *end;unsigned long x;errno=0;x=strtoul(argv[1],&end,10);if(errno || *end || x>4294967295ul) return 2;budget=(unsigned int)x;}
    if(argc>2) {char *end;unsigned long x;errno=0;x=strtoul(argv[2],&end,10);if(errno || *end || x>CCV_ALL) return 2;rules=(unsigned int)x;}
    if(scanf("%u %u %u %u",&p.n,&p.checks,&p.logical_rows,&p.stabilizers)!=4) return 2;
    if(p.n==0u || p.n>2147483647u/sizeof(struct ccv_frame) || p.logical_rows==0u || p.checks>2147483647u/p.n || p.logical_rows>2147483647u/p.n || p.stabilizers>2147483647u/p.n) return 2;
    h=calloc(p.checks?p.checks*p.n:1u,1u);l=calloc(p.logical_rows*p.n,1u);k=calloc(p.stabilizers?p.stabilizers*p.n:1u,1u);
    out=calloc(p.n,1u);w.selected=calloc(p.n,1u);w.forbidden=calloc(p.n,1u);w.packed=calloc(p.n,1u);w.syndrome=calloc(p.checks?p.checks:1u,1u);w.logical_value=calloc(p.logical_rows,1u);w.undo=calloc(p.n,sizeof(unsigned int));w.frames=calloc(p.n,sizeof(struct ccv_frame));w.capacity=p.n;w.frame_capacity=p.n;
    if(!h || !l || !k || !out || !w.selected || !w.forbidden || !w.packed || !w.syndrome || !w.logical_value || !w.undo || !w.frames) {r=CCV_UNKNOWN;goto done;}
    p.h=h;p.logical=l;p.stabilizer=k;
    if(!matrix(p.checks,p.n,h) || !matrix(p.logical_rows,p.n,l) || !matrix(p.stabilizers,p.n,k)) {r=CCV_INVALID;goto done;}
    r=ccv_distance(&p,budget,rules,&w,out,&d,&s);
    printf("{\"status\":%d,\"distance\":%u,\"steps\":%u,\"nodes\":%u,\"witness\":[",r,d,s.steps,s.nodes);
    for(i=0u;i<p.n;i++) {if(i) printf(",");printf("%u",(unsigned int)out[i]);}
    printf("]}\n");
done:
    free(h);free(l);free(k);free(out);free(w.selected);free(w.forbidden);free(w.packed);free(w.syndrome);free(w.logical_value);free(w.undo);free(w.frames);
    if(r==CCV_INVALID) return 2;
    if(r==CCV_UNKNOWN) return 3;
    return 0;
}
