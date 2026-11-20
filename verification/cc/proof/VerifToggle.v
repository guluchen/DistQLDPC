Require Import VST.floyd.proofauto.
Require Import CCV.ccv_primitives CCV.CCArray.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition tbytes (xs:list Z) := map (fun z=>Vint(Int.repr z)) xs.
Lemma tbytes_at xs i : 0<=i<Zlength xs -> Znth i (tbytes xs)=Vint(Int.repr(Znth i xs)).
Proof. intros;unfold tbytes;rewrite Znth_map by lia;reflexivity. Qed.
Definition xor_vector (xs ys:list Z) := map (fun p=>Z.lxor (fst p) (snd p)) (combine xs ys).
Lemma xor_vector_length xs ys : Zlength xs=Zlength ys -> Zlength(xor_vector xs ys)=Zlength xs.
Proof. intros;unfold xor_vector;rewrite Zlength_map,Zlength_combine;lia. Qed.
Lemma xor_vector_at xs ys i : Zlength xs=Zlength ys -> 0<=i<Zlength xs ->
 Znth i (xor_vector xs ys)=Z.lxor (Znth i xs) (Znth i ys).
Proof.
 intros;unfold xor_vector;rewrite Znth_map by (rewrite Zlength_combine;lia).
 rewrite Znth_combine by lia;reflexivity.
Qed.
Definition toggle_spec : ident * funspec :=
 DECLARE _ccv_toggle
 WITH pa:val,pb:val,sh:share,xs:list Z,ys:list Z
 PRE [tuint,tptr tuchar,tptr tuchar]
 PROP(readable_share sh;Zlength xs=Zlength ys;Zlength xs<=Int.max_signed;
      Forall (fun z=>z=0 \/ z=1) xs;Forall (fun z=>z=0 \/ z=1) ys)
 PARAMS(Vint(Int.repr(Zlength xs));pa;pb)
 SEP(data_at Tsh (tarray tuchar (Zlength xs)) (tbytes xs) pa;
     data_at sh (tarray tuchar (Zlength ys)) (tbytes ys) pb)
 POST [tvoid] PROP() RETURN()
 SEP(data_at Tsh (tarray tuchar (Zlength xs)) (tbytes (xor_vector xs ys)) pa;
     data_at sh (tarray tuchar (Zlength ys)) (tbytes ys) pb).
Definition Gprog : funspecs := ltac:(with_library prog [toggle_spec]).
Lemma body_toggle : semax_body Vprog Gprog f_ccv_toggle toggle_spec.
Proof.
 start_function.
 assert (Bx:Forall (fun z=>0<=z<=1) xs).
 { eapply Forall_impl;[|eassumption]. intros z Hz;destruct Hz;subst;lia. }
 assert (By:Forall (fun z=>0<=z<=1) ys).
 { eapply Forall_impl;[|eassumption]. intros z Hz;destruct Hz;subst;lia. }
 assert (Len:Zlength(tbytes xs)=Zlength(tbytes(xor_vector xs ys))).
 { unfold tbytes;rewrite !Zlength_map,xor_vector_length by assumption;reflexivity. }
 forward_for_simple_bound (Zlength xs)
 (EX i:Z,
  PROP()
  LOCAL(temp _n (Vint(Int.repr(Zlength xs)));temp _a pa;temp _b pb)
  SEP(data_at Tsh (tarray tuchar (Zlength xs))
       (copy_prefix (tbytes xs) (tbytes(xor_vector xs ys)) i) pa;
      data_at sh (tarray tuchar (Zlength ys)) (tbytes ys) pb)).
 - entailer!;rewrite copy_prefix_start;cancel.
 - assert (X:0<=Znth i xs<=1) by (apply Forall_Znth;auto;lia).
   assert (Y:0<=Znth i ys<=1) by (apply Forall_Znth;auto;lia).
   forward.
   { rewrite copy_prefix_old by (try exact Len;unfold tbytes;rewrite Zlength_map;lia).
     unfold tbytes;rewrite Znth_map by lia;entailer!;rep_lia. }
   forward. { unfold tbytes;rewrite Znth_map by lia;entailer!;rep_lia. }
   forward.
   entailer!.
   rewrite copy_prefix_old by (try exact Len;unfold tbytes;rewrite Zlength_map;lia).
   unfold tbytes. rewrite !Znth_map by lia. simpl.
   assert (BitStore:Vint(Int.zero_ext 8 (Int.xor (Int.repr(Znth i xs)) (Int.repr(Znth i ys))))=
       Znth i (tbytes(xor_vector xs ys))).
   { unfold tbytes;rewrite Znth_map by (rewrite xor_vector_length by assumption;lia).
     rewrite xor_vector_at by auto.
     assert (XX:Znth i xs=0 \/ Znth i xs=1) by (apply Forall_Znth;auto;lia).
     assert (YY:Znth i ys=0 \/ Znth i ys=1) by (apply Forall_Znth;auto;lia).
     destruct XX as [XX|XX];destruct YY as [YY|YY];rewrite XX,YY;reflexivity. }
   fold (tbytes xs) (tbytes (xor_vector xs ys)). rewrite BitStore,copy_prefix_step by (auto;unfold tbytes;rewrite Zlength_map;lia).
   cancel.
 - forward;entailer!;rewrite copy_prefix_full by (try exact Len;unfold tbytes;rewrite Zlength_map;lia);cancel.
Qed.
Print Assumptions body_toggle.
