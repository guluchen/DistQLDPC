Require Import VST.floyd.proofauto.
Require Import flip_ast.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition values (xs:list Z) := map (fun z=>Vint(Int.repr z)) xs.
Definition flip_one (xs:list Z) (j:Z) := upd_Znth j xs (Z.lxor (Znth j xs) 1).
Definition flips (xs ix:list Z) :=fold_left flip_one ix xs.
Definition binary (xs:list Z) := Forall (fun z=>z=0 \/ z=1) xs.
Lemma flips_length xs ix : Zlength(flips xs ix)=Zlength xs.
Proof. revert xs;induction ix;intros;simpl;auto. unfold flips in *;simpl;rewrite IHix;unfold flip_one;apply Zlength_upd_Znth. Qed.
Lemma flips_bits xs ix : binary xs -> binary(flips xs ix).
Proof. revert xs;induction ix;intros xs H;[exact H|]. unfold flips in *;simpl;apply IHix.
 unfold flip_one,binary;apply Forall_upd_Znth;[assumption|].
 destruct (zlt a 0);[rewrite Znth_underflow by lia;right;reflexivity|].
 destruct (zlt a (Zlength xs)).
 - assert (B:Znth a xs=0 \/ Znth a xs=1) by (apply Forall_Znth;auto;lia).
   destruct B as [B|B];rewrite B;vm_compute;auto.
 - rewrite Znth_overflow by lia;right;reflexivity.
Qed.
Lemma flips_snoc xs ix j : flips xs (ix++[j])=flip_one (flips xs ix) j.
Proof. unfold flips;rewrite fold_left_app;reflexivity. Qed.
Definition flip_spec : ident*funspec :=
 DECLARE _ccv_flip
 WITH ip:val,bp:val,ix:list Z,xs:list Z,sh:share
 PRE [tuint,tptr tuint,tptr tuchar]
 PROP(readable_share sh;Zlength ix<=Int.max_signed;Zlength xs<=Int.max_signed;
      Forall(fun j=>0<=j<Zlength xs) ix;binary xs)
 PARAMS(Vint(Int.repr(Zlength ix));ip;bp)
 SEP(data_at sh (tarray tuint (Zlength ix)) (values ix) ip;
     data_at Tsh (tarray tuchar (Zlength xs)) (values xs) bp)
 POST [tvoid] PROP() RETURN()
 SEP(data_at sh (tarray tuint (Zlength ix)) (values ix) ip;
     data_at Tsh (tarray tuchar (Zlength xs)) (values(flips xs ix)) bp).
Definition Gprog : funspecs := ltac:(with_library prog [flip_spec]).
Lemma body_flip : semax_body Vprog Gprog f_ccv_flip flip_spec.
Proof.
 start_function.
 forward_for_simple_bound (Zlength ix)
   (EX i:Z,PROP()
    LOCAL(temp _len (Vint (Int.repr(Zlength ix)));temp _index ip;temp _bits bp)
    SEP(data_at sh (tarray tuint (Zlength ix)) (values ix) ip;
        data_at Tsh (tarray tuchar (Zlength xs)) (values(flips xs (sublist 0 i ix))) bp)).
 - entailer!.
 - set (ys:=flips xs (sublist 0 i ix)).
   assert (Len:Zlength ys=Zlength xs) by apply flips_length.
   assert (Ix:0<=Znth i ix<Zlength xs) by (apply Forall_Znth;auto;lia).
   assert (By:binary ys) by (apply flips_bits;assumption).
   assert (Bi:Znth (Znth i ix) ys=0 \/ Znth (Znth i ix) ys=1) by (apply Forall_Znth;auto;lia).
   unfold values. forward. forward.
   {entailer!;destruct Bi as [Bi|Bi];rewrite Bi;rep_lia. }
   forward. entailer!.
   rewrite (sublist_split 0 i (i+1)) by lia.
   rewrite (sublist_one i),flips_snoc by lia;fold ys. unfold flip_one,values.
   rewrite <-upd_Znth_map by lia.
   destruct Bi as [Bi|Bi];rewrite Bi;cancel.
 - forward. entailer!. autorewrite with sublist;cancel.
Qed.
Print Assumptions body_flip.
