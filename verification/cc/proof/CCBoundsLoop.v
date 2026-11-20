(* Supporting loop invariants for the C bounds scan; no C body claimed. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCRepresentation CCV.CCBoundsArray CCV.CCPackedArray CCV.VerifToggle.
Open Scope Z_scope.
Definition row_choice n m ys t r best :=
 0<=best<=n /\0<=r<=m /\(r<m ->0<=r<t /\Znth r ys<>0) /\(r=m ->odd_count t ys=0).
Lemma tbytes_zero_repeat n : tbytes(Zrepeat 0 n)=Zrepeat(Vint Int.zero)n.
Proof. unfold tbytes,Zrepeat;rewrite map_repeat;reflexivity. Qed.
Lemma zero_packed_bits n : Forall(fun z:Z=>z=0 \/ z=1)(Zrepeat 0 n).
Proof. unfold Zrepeat;apply Forall_repeat;left;reflexivity. Qed.
Lemma zero_packed_matches n h xs fs : 0<=n ->packed_matches n h xs fs [](Zrepeat 0 n).
Proof.
 intros N q Q;unfold packed_matches,family_union;rewrite decode_at_nat.
 rewrite Znth_Zrepeat by(apply Nat2Z.inj_lt in Q;rewrite Z2Nat.id in Q by assumption;lia).
 reflexivity.
Qed.
Lemma odd_vec_at ys i : 0<=i ->odd_vec ys(Z.to_nat i)=negb(Znth i ys=?0).
Proof. intros;unfold odd_vec;rewrite Z2Nat.id by assumption;reflexivity. Qed.
Lemma odd_count_step_zero t ys : 0<=t ->Znth t ys=0 ->odd_count(t+1)ys=odd_count t ys.
Proof.
 intros T Zero;unfold odd_count;rewrite bitcount_step by assumption.
 rewrite odd_vec_at by assumption;rewrite Zero;unfold bitZ;simpl;lia.
Qed.
Lemma odd_count_step_one t ys : 0<=t ->Znth t ys<>0 ->odd_count(t+1)ys=odd_count t ys+1.
Proof.
 intros T One;unfold odd_count;rewrite bitcount_step by assumption.
 rewrite odd_vec_at by assumption;assert(E:(Znth t ys=?0)=false)by(apply Z.eqb_neq;assumption).
 rewrite E;reflexivity.
Qed.
Lemma row_choice_initial n m ys : 0<=n ->0<=m ->row_choice n m ys 0 m n.
Proof. intros N M;unfold row_choice,odd_count;rewrite bitcount_zero;repeat split;intros;lia. Qed.
Lemma row_choice_skip n m ys t r best :
 0<=t<m ->row_choice n m ys t r best ->Znth t ys=0 ->row_choice n m ys(t+1)r best.
Proof.
 intros T [Best [Range [Odd None]]] Zero;unfold row_choice;split;[exact Best|];split;[exact Range|];split.
 - intros R;destruct(Odd R)as [Old NZ];split;[lia|assumption].
 - intros E;rewrite odd_count_step_zero by(try assumption;lia);apply None;assumption.
Qed.
Lemma row_choice_keep n m ys t r best :
 0<=t<m ->row_choice n m ys t r best ->r<m ->row_choice n m ys(t+1)r best.
Proof.
 intros T [Best [Range [Odd None]]] R;unfold row_choice;split;[exact Best|];split;[exact Range|];split.
 - intros L;destruct(Odd L)as [Old NZ];split;[lia|assumption].
 - intros E;lia.
Qed.
Lemma row_choice_take n m ys t count :
 0<=t<m ->0<=count<=n ->Znth t ys<>0 ->row_choice n m ys(t+1)t count.
Proof. intros T Count Odd;unfold row_choice;repeat split;intros;try lia;assumption. Qed.
Lemma weight_zero_bits n p : CCModel.weight n p=0%nat <->forall q,(q<n)%nat ->p q=false.
Proof.
 induction n as [|n IH];simpl.
 - split;intros;[lia|reflexivity].
 - split.
   + intros W q Q;destruct(p n)eqn:P;[lia|].
     assert(Old:CCModel.weight n p=0%nat)by lia.
     destruct(Nat.eq_dec q n)as [->|Ne];[assumption|apply(proj1 IH Old);lia].
   + intros All;rewrite All by lia;rewrite(proj2 IH)by(intros;apply All;lia);reflexivity.
Qed.
Lemma bitcount_zero_bits t p : 0<=t ->(bitcount t p=0 <->forall q,(q<Z.to_nat t)%nat ->p q=false).
Proof. intros;unfold bitcount;rewrite <-weight_zero_bits;lia. Qed.
Lemma odd_count_zero_row t ys i : 0<=t ->0<=i<t ->odd_count t ys=0 ->Znth i ys=0.
Proof.
 intros T I Count;unfold odd_count in Count;pose proof(proj1(bitcount_zero_bits t(odd_vec ys)T) Count)as All.
 specialize(All(Z.to_nat i)ltac:(apply Z2Nat.inj_lt;lia)).
 rewrite odd_vec_at in All by lia;apply negb_false_iff in All;apply Z.eqb_eq;assumption.
Qed.
Lemma row_choice_final n m ys r best : 0<=m ->row_choice n m ys m r best ->
 (r=m <->odd_count m ys=0) /\(r<m ->Znth r ys<>0).
Proof.
 intros M [Best [Range [Odd None]]];split.
 - split;[assumption|intros Count;destruct(Z.eq_dec r m)as [->|Ne];[reflexivity|]].
   assert(R:0<=r<m)by lia;destruct(Odd ltac:(lia))as [_ Not].
   pose proof(odd_count_zero_row m ys r M R Count);contradiction.
 - intros R;destruct(Odd R);assumption.
Qed.
Print Assumptions zero_packed_matches.
Print Assumptions row_choice_final.

Lemma packing_family_length n m h xs fs ys rows i :
 0<=i ->packed_family n m h xs fs ys rows ->Forall(fun r=>(r<Z.to_nat i)%nat) rows ->
 Z.of_nat(length rows)<=i.
Proof.
 intros I [ND Rest] Earlier.
 assert(Incl:incl rows(seq 0(Z.to_nat i))).
 { intros r Hin;apply in_seq;split;[lia|apply Forall_forall with(x:=r)in Earlier;assumption]. }
 pose proof(NoDup_incl_length ND Incl)as Bound.
 rewrite seq_length in Bound;apply Nat2Z.inj_le in Bound;rewrite Z2Nat.id in Bound by assumption;assumption.
Qed.
Print Assumptions packing_family_length.
