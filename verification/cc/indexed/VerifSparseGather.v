(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import gather_ast.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition vals (xs:list Z) := map (fun z => Vint (Int.repr z)) xs.
Definition gather (bits ix:list Z) :=
  fold_right (fun j acc => Znth j bits + acc) 0 ix.
Lemma gather_app b xs ys : gather b (xs++ys)=gather b xs+gather b ys.
Proof. induction xs; simpl; unfold gather in *; simpl in *; lia. Qed.
Definition gather_spec : ident*funspec :=
 DECLARE _ccv_gather
 WITH ip:val,bp:val,ix:list Z,bits:list Z,sh:share
 PRE [tuint,tptr tuint,tptr tuchar]
 PROP(readable_share sh; Zlength ix<=Int.max_signed;
      Zlength bits<=Int.max_signed;
      Forall (fun j=>0<=j<Zlength bits) ix;
      Forall (fun z=>0<=z<=1) bits)
 PARAMS(Vint(Int.repr(Zlength ix));ip;bp)
 SEP(data_at sh (tarray tuint (Zlength ix)) (vals ix) ip;
     data_at sh (tarray tuchar (Zlength bits)) (vals bits) bp)
 POST [tuint] PROP() RETURN(Vint(Int.repr(gather bits ix)))
 SEP(data_at sh (tarray tuint (Zlength ix)) (vals ix) ip;
     data_at sh (tarray tuchar (Zlength bits)) (vals bits) bp).
Definition Gprog : funspecs := ltac:(with_library prog [gather_spec]).
Lemma body_gather : semax_body Vprog Gprog f_ccv_gather gather_spec.
Proof.
 start_function. forward.
 forward_for_simple_bound (Zlength ix)
   (EX i:Z, PROP()
    LOCAL(temp _len (Vint(Int.repr(Zlength ix)));temp _index ip;temp _bits bp;
          temp _sum (Vint(Int.repr(gather bits (sublist 0 i ix)))))
    SEP(data_at sh (tarray tuint (Zlength ix)) (vals ix) ip;
        data_at sh (tarray tuchar (Zlength bits)) (vals bits) bp)).
 - entailer!.
 - assert (Ix:0<=Znth i ix<Zlength bits) by (apply Forall_Znth;auto;lia).
   assert (B:0<=Znth (Znth i ix) bits<=1) by (apply Forall_Znth;auto;lia).
   unfold vals. forward. forward.
   { entailer!; rep_lia. }
   forward. entailer!. f_equal.
   rewrite (sublist_split 0 i (i+1)) by lia.
   rewrite gather_app,(sublist_one i) by lia.
   unfold gather;simpl;rewrite Z.add_0_r;reflexivity.
 - forward. entailer!. autorewrite with sublist;reflexivity.
Qed.
Print Assumptions body_gather.
