/* Test linkage for private pruning predicates. */
#include "../ccv_indexed.c"
unsigned period_of(const struct ccv_problem *p) { return checked_period(p); }
int verify_combinations(const struct ccv_problem *p,unsigned gate_bits,unsigned *count) {
 struct sparse_search v={0};struct short_sums t={0};struct ccv_workspace w={0};
 if(!sparse_init(&v,p,CCV_ALL))return -1;
 make_sums(&t,p,&v);if(!t.table)return -2;
 if(gate_bits==0u) {t.mask=0u; t.table[0]=1u;}
 w.syndrome=calloc(p->checks?p->checks:1u,1);
 if(!w.syndrome)return -3;
 for(unsigned trial=0;trial<6500;trial++){
   unsigned rem=1u+trial%4u,n=p->n;
   unsigned q[4];unsigned k=(trial/4u)%(rem+1u);
   uint64_t state=mix_word(trial+123u),sig=0;
   memset(w.syndrome,0,p->checks);
   for(unsigned j=0;j<k;j++){
     state=mix_word(state+1u);q[j]=(unsigned)(state%n);
     sig^=t.col[q[j]];toggle_column(&v.hcol,q[j],w.syndrome);
   }
   for(unsigned j=0;j<p->checks;j++) if(w.syndrome[j]){
     if(!short_possible(p,&w,&v,&t,rem,j,sig))return 0;
     ++*count;
   }
 }
 free(w.syndrome);free(t.table);free(t.col);free_sparse(&v);return 1;
}
