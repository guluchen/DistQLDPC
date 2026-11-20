(* Ghost packing family and byte-array updates used by the C bounds loop. *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCPacking CCV.CCRepresentation CCV.CCBoundsArray CCV.CCMatrix.
Import ListNotations.
Open Scope Z_scope.
Definition family_union n h xs fs rows q :=existsb(fun r=>free_vec n(Z.of_nat r)h xs fs q) rows.
Definition packed_matches n h xs fs rows pk :=
 forall q,(q<Z.to_nat n)%nat ->decode pk q=family_union n h xs fs rows q.
Definition used_prefix t n i h xs fs pk :=
 existsb(fun q=>andb(free_vec n i h xs fs q)(decode pk q))(seq 0(Z.to_nat t)).
Lemma used_prefix_zero n i h xs fs pk : used_prefix 0 n i h xs fs pk=false.
Proof. reflexivity. Qed.
Lemma used_prefix_step t n i h xs fs pk : 0<=t ->
 used_prefix(t+1)n i h xs fs pk=
 orb(used_prefix t n i h xs fs pk)(andb(free_vec n i h xs fs(Z.to_nat t))(decode pk(Z.to_nat t))).
Proof.
 intros T;unfold used_prefix;rewrite Z2Nat.inj_add by lia;rewrite seq_app,existsb_app.
 simpl;rewrite orb_false_r;reflexivity.
Qed.
Lemma packed_family_empty n m h xs fs ys : packed_family n m h xs fs ys [].
Proof. repeat split;try constructor;intros;contradiction. Qed.
Lemma packing_nodup_snoc (rows:list nat) q : NoDup rows ->~In q rows ->NoDup(rows++[q]).
Proof.
 intros ND;induction ND as [|r rows Not ND IH];intros Fresh;simpl.
 - constructor;[simpl;tauto|constructor].
 - constructor.
   + intro Hin;apply in_app_or in Hin;destruct Hin as [Hin|[E|[]]];[contradiction|subst;apply Fresh;left;reflexivity].
   + apply IH;intro Hin;apply Fresh;right;assumption.
Qed.
Lemma packed_family_append n m h xs fs ys rows i pk :
 0<=n ->0<=i<m ->Znth i ys<>0 ->
 packed_family n m h xs fs ys rows ->
 Forall(fun r=>(r<Z.to_nat i)%nat) rows ->
 packed_matches n h xs fs rows pk ->used_prefix n n i h xs fs pk=false ->
 packed_family n m h xs fs ys (rows++[Z.to_nat i]).
Proof.
 intros N I Odd [ND [Rows Disjoint]] Earlier Match Unused.
 assert(Fresh:~In(Z.to_nat i) rows).
 { intro Hin;apply Forall_forall with(x:=Z.to_nat i)in Earlier;[lia|assumption]. }
 assert(NoHit:forall r q,In r rows ->
 In q(repair(Z.to_nat n)(CCValidation.row_vector n i h)(decode xs)(decode fs)) ->
 ~In q(repair(Z.to_nat n)(CCValidation.row_vector n(Z.of_nat r)h)(decode xs)(decode fs))).
 { intros r q Hr Hnew Hold;apply repair_member in Hnew;apply repair_member in Hold.
   destruct Hnew as [Q [Hq [Sq Fq]]];destruct Hold as [_ [Hqr _]].
   assert(U:used_prefix n n i h xs fs pk=true).
   { unfold used_prefix;apply existsb_exists;exists q;split;[apply in_seq;lia|].
     apply andb_true_iff;split.
     - unfold free_vec;rewrite Hq,Sq,Fq;reflexivity.
     - rewrite Match by assumption;unfold family_union;apply existsb_exists;exists r;split;[assumption|].
       unfold free_vec;rewrite Hqr,Sq,Fq;reflexivity. }
   congruence. }
 unfold packed_family;split.
 - apply packing_nodup_snoc;assumption.
 - split.
   + apply Forall_app;split;[assumption|constructor;[split|constructor]];try assumption.
     * apply Z2Nat.inj_lt;lia.
     * rewrite Z2Nat.id by lia;assumption.
   + intros r r' q Hr Hr' Ne Hq Hq';apply in_app_or in Hr;apply in_app_or in Hr'.
     destruct Hr as [Hr|[Er|[]]];destruct Hr' as [Hr'|[Er'|[]]];subst.
     * exact(Disjoint r r' q Hr Hr' Ne Hq Hq').
     * rewrite Z2Nat.id in Hq' by lia;eapply NoHit;eassumption.
     * rewrite Z2Nat.id in Hq by lia;eapply NoHit;eassumption.
     * contradiction.
Qed.
Definition packed_extend n i h xs fs pk :=
 map(fun q=>if free_vec n i h xs fs q then 1 else Znth(Z.of_nat q)pk)(seq 0(Z.to_nat n)).
Lemma packed_extend_length n i h xs fs pk : 0<=n ->Zlength(packed_extend n i h xs fs pk)=n.
Proof. intros N;unfold packed_extend;rewrite Zlength_correct,map_length,seq_length,Z2Nat.id by assumption;reflexivity. Qed.
Lemma packed_extend_at n i h xs fs pk q : 0<=q<n ->
 Znth q(packed_extend n i h xs fs pk)=if free_vec n i h xs fs(Z.to_nat q) then 1 else Znth q pk.
Proof.
 intros Q;unfold packed_extend;rewrite Znth_map by(rewrite Zlength_correct,seq_length,Z2Nat.id by lia;lia).
 rewrite seq_at by assumption;rewrite Z2Nat.id by lia;reflexivity.
Qed.
Lemma packed_extend_bits n i h xs fs pk : 0<=n ->Zlength pk=n ->
 Forall(fun z:Z=>z=0 \/ z=1)pk ->Forall(fun z:Z=>z=0 \/ z=1)(packed_extend n i h xs fs pk).
Proof.
 intros N Len Bits;apply(proj2(Forall_Znth _ _));intros q Q.
 rewrite packed_extend_length in Q by assumption;rewrite packed_extend_at by assumption.
 destruct(free_vec n i h xs fs(Z.to_nat q));[right;reflexivity|apply Forall_Znth;auto;lia].
Qed.
Lemma packed_extend_matches n i h xs fs rows pk :
 0<=n ->0<=i ->packed_matches n h xs fs rows pk ->
 packed_matches n h xs fs (rows++[Z.to_nat i])(packed_extend n i h xs fs pk).
Proof.
 intros N I Match q Q;rewrite decode_at_nat;rewrite packed_extend_at by(apply Nat2Z.inj_lt in Q;rewrite Z2Nat.id in Q by assumption;lia).
 rewrite Nat2Z.id;unfold family_union;rewrite existsb_app;simpl;rewrite Z2Nat.id by assumption.
 destruct(free_vec n i h xs fs q)eqn:F;simpl.
 - rewrite orb_true_r;reflexivity.
 - rewrite orb_false_r. change ((Znth(Z.of_nat q)pk=?1)=family_union n h xs fs rows q).
   rewrite <-Match by assumption;symmetry;apply decode_at_nat.
Qed.
Definition blend (xs ys:list Z) t :=sublist 0 t ys++sublist t(Zlength xs)xs.
Lemma blend_start xs ys : blend xs ys 0=xs.
Proof. unfold blend;list_solve. Qed.
Lemma blend_finish xs ys : Zlength xs=Zlength ys ->blend xs ys(Zlength xs)=ys.
Proof. intros;unfold blend;list_solve. Qed.
Lemma blend_length xs ys t : Zlength xs=Zlength ys ->0<=t<=Zlength xs ->Zlength(blend xs ys t)=Zlength xs.
Proof. intros;unfold blend;list_solve. Qed.
Lemma blend_step xs ys t : Zlength xs=Zlength ys ->0<=t<Zlength xs ->
 upd_Znth t(blend xs ys t)(Znth t ys)=blend xs ys(t+1).
Proof. intros;unfold blend;list_solve. Qed.
Lemma blend_skip xs ys t : Zlength xs=Zlength ys ->0<=t<Zlength xs ->Znth t ys=Znth t xs ->
 blend xs ys t=blend xs ys(t+1).
Proof.
 intros Len T At;rewrite <-blend_step by assumption.
 assert(Old:Znth t(blend xs ys t)=Znth t xs)by(unfold blend;list_solve).
 symmetry;apply upd_Znth_triv.
 - rewrite blend_length by lia;lia.
 - rewrite At;exact Old.
Qed.
Print Assumptions packed_family_append.
Print Assumptions packed_extend_matches.
Print Assumptions blend_step.
