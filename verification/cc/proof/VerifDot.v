(* SPDX-License-Identifier: GPL-3.0-or-later. Candidate until checker PASS. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_primitives CCV.CCModel.
Open Scope Z_scope.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition dbytes (xs:list Z) := map (fun z=>Vint(Int.repr z)) xs.
Fixpoint word_dot_nat (k:nat) (xs ys:list Z) : int :=
 match k with
 | O=>Int.zero
 | S j=>Int.xor (word_dot_nat j xs ys)
          (Int.and (Int.repr(nth j xs 0)) (Int.repr(nth j ys 0)))
 end.
Definition word_dot (i:Z) xs ys := word_dot_nat (Z.to_nat i) xs ys.
Lemma word_dot_step i xs ys : 0<=i ->
 word_dot (i+1) xs ys=Int.xor (word_dot i xs ys)
             (Int.and (Int.repr(Znth i xs)) (Int.repr(Znth i ys))).
Proof.
 intros Hi;unfold word_dot;rewrite Z2Nat.inj_add by lia.
 change (Z.to_nat 1) with 1%nat;rewrite Nat.add_1_r;cbn [word_dot_nat].
 unfold Znth;repeat rewrite if_false by lia;reflexivity.
Qed.
Lemma nth_binary xs : Forall (fun z:Z=>z=0 \/ z=1) xs ->
 forall k,nth k xs 0=0 \/ nth k xs 0=1.
Proof.
 intros H;induction H;intros k;destruct k;simpl;try (left;reflexivity);auto.
Qed.
Theorem word_dot_GF2 k xs ys : Forall (fun z:Z=>z=0 \/ z=1) xs ->
 Forall (fun z:Z=>z=0 \/ z=1) ys ->
 word_dot_nat k xs ys=Int.repr
 (if CCModel.parity k (fun i=>nth i xs 0=?1) (fun i=>nth i ys 0=?1) then 1 else 0).
Proof.
 intros Hx Hy;induction k as [|j IH];cbn [word_dot_nat CCModel.parity];[reflexivity|].
 rewrite IH.
 destruct (nth_binary xs Hx j) as [X|X];destruct (nth_binary ys Hy j) as [Y|Y];
 rewrite X,Y;destruct (CCModel.parity j (fun i=>nth i xs 0=?1) (fun i=>nth i ys 0=?1));reflexivity.
Qed.
Definition dot_spec : ident * funspec :=
 DECLARE _ccv_dot
 WITH pa:val,pb:val,sha:share,shb:share,xs:list Z,ys:list Z
 PRE [tuint,tptr tuchar,tptr tuchar]
 PROP(readable_share sha;readable_share shb;Zlength xs=Zlength ys;
      Zlength xs<=Int.max_signed;
      Forall (fun z=>z=0 \/ z=1) xs;Forall (fun z=>z=0 \/ z=1) ys)
 PARAMS(Vint(Int.repr(Zlength xs));pa;pb)
 SEP(data_at sha (tarray tuchar (Zlength xs)) (dbytes xs) pa;
     data_at shb (tarray tuchar (Zlength ys)) (dbytes ys) pb)
 POST [tuint] PROP() RETURN(Vint(word_dot (Zlength xs) xs ys))
 SEP(data_at sha (tarray tuchar (Zlength xs)) (dbytes xs) pa;
     data_at shb (tarray tuchar (Zlength ys)) (dbytes ys) pb).
Definition Gprog : funspecs := ltac:(with_library prog [dot_spec]).
Lemma body_dot : semax_body Vprog Gprog f_ccv_dot dot_spec.
Proof.
 start_function.
 assert (Bx:Forall (fun z=>0<=z<=1) xs).
 { eapply Forall_impl;[|eassumption]. intros z Hz;destruct Hz;subst;lia. }
 assert (By:Forall (fun z=>0<=z<=1) ys).
 { eapply Forall_impl;[|eassumption]. intros z Hz;destruct Hz;subst;lia. }
 forward.
 forward_for_simple_bound (Zlength xs)
 (EX i:Z,
  PROP()
  LOCAL(temp _n (Vint(Int.repr(Zlength xs)));temp _a pa;temp _b pb;
        temp _x (Vint(word_dot i xs ys)))
  SEP(data_at sha (tarray tuchar (Zlength xs)) (dbytes xs) pa;
      data_at shb (tarray tuchar (Zlength ys)) (dbytes ys) pb)).
 - entailer!.
 - assert (X:0<=Znth i xs<=1) by (apply Forall_Znth;auto;lia).
   assert (Y:0<=Znth i ys<=1) by (apply Forall_Znth;auto;lia).
   unfold dbytes.
   forward. { entailer!;rep_lia. }
   forward. { entailer!;rep_lia. }
   forward.
   entailer!. rewrite word_dot_step by lia.
   unfold Int.and;rewrite !Int.unsigned_repr by rep_lia;reflexivity.
 - forward;entailer!.
Qed.
Print Assumptions word_dot_GF2.
Print Assumptions body_dot.
