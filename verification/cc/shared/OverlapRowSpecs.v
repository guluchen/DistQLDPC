(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver VST.floyd.reassoc_seq.
Require Import OverlapRowState SiblingCounters overlap_ast.
#[local] Instance OverlapSpecs:compspecs. make_compspecs prog. Defined.
Definition Ovars:varspecs. mk_varspecs prog. Defined.
Definition array32 (xs:list int) p := if Z.eq_dec (Zlength xs) 0 then emp else
 data_at Tsh (tarray tuint (Zlength xs)) (map Vint xs) p.
Lemma stored_array xs p:0<Zlength xs -> array32 xs p=data_at Tsh (tarray tuint (Zlength xs)) (map Vint xs) p.
Proof. unfold array32;destruct Z.eq_dec;intros;[lia|reflexivity]. Qed.
Definition valid_input (qs base:list int) lo hi := 0<=lo<=hi /\ hi<=Zlength qs /\ hi<=Int.max_unsigned /\
 Forall (fun q=>Int.unsigned q<Zlength base) qs.
Definition block_spec:ident*funspec :=
 DECLARE _cc_block_overlap_row WITH rp:val,bp:val,skip:int,qs:list int,base:list int,lo:Z,hi:Z
 PRE [tptr tuint,tuint,tuint,tint,tptr tuint]
 PROP(valid_input qs base lo hi;is_pointer_or_null rp;is_pointer_or_null bp)
 PARAMS(rp;Vint (Int.repr lo);Vint (Int.repr hi);Vint skip;bp)
 SEP(array32 qs rp;array32 base bp)
 POST [tulong] PROP() RETURN(Vlong (Int64.repr (snd (row_state skip qs base lo hi))))
 SEP(array32 qs rp;array32 (fst (row_state skip qs base lo hi)) bp).
Definition unblock_spec:ident*funspec :=
 DECLARE _cc_unblock_overlap_row WITH rp:val,bp:val,skip:int,qs:list int,base:list int,lo:Z,hi:Z
 PRE [tptr tuint,tuint,tuint,tint,tptr tuint]
 PROP(valid_input qs base lo hi;is_pointer_or_null rp;is_pointer_or_null bp)
 PARAMS(rp;Vint (Int.repr lo);Vint (Int.repr hi);Vint skip;bp)
 SEP(array32 qs rp;array32 base bp)
 POST [tvoid] PROP() RETURN()
 SEP(array32 qs rp;array32 (row_return skip qs base lo hi) bp).
Definition OGprog:funspecs:=ltac:(with_library prog [block_spec;unblock_spec]).
