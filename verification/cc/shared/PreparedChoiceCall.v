(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected ClightSelect SiblingCounters
 VerifChildVisit VerifEnabledSiblings PreparedSeedDispatch PreparedSampling.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition invokes_choice (s:statement):=match s with
 | Ssequence (Sifthenelse _ _ _) (Sset id _) => Pos.eqb id _count
 | _=>false end.
Definition choose_count:statement:=ltac:(native_fragment invokes_choice f_dfs).
Definition choice_input:=val->val->mpred.
Definition choice_output:=val->val->list Z->mpred.
Definition choose_callback depth odd children n (P:choice_input) (Q:choice_output):funspec:=
 WITH owner:val,ptr:val PRE [tptr tvoid,tint,tint,tptr sample_type]
 PROP(is_pointer_or_null owner;isptr ptr)
 PARAMS(owner;Vint (Int.repr depth);Vint (Int.repr odd);ptr) SEP(P owner ptr)
 POST [tint] EX xs:list Z,PROP(Zlength xs<=Int.max_signed;NoDup xs;in_array n xs)
 RETURN(Vint (Int.repr (Zlength xs))) SEP(child_array children xs;Q owner ptr xs).
Definition chooser_policy p owner cb spec:=
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _owner] owner p *
  field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _choose_children] cb p * func_ptr' spec cb)%logic.
Definition choice_loc s p ptr depth bits:=
 [temp _s s;temp _policy p;lvar _sample sample_type ptr;temp _size (Vint (Int.repr depth));temp _options (Vint bits)].

(* Ghost [children] names the same output slice as the C++ owner. A count
   returned by the callback must match the array it has actually produced. *)
Theorem choose_from_owner {Espec:OracleKind} s p owner cb ptr depth odd bits children n P Q (frame:mpred):
 Int.and bits Int.one<>Int.zero -> is_pointer_or_null owner -> isptr ptr ->
 let spec:=choose_callback depth odd children n P Q in
 semax (func_tycontext f_dfs prepared_vars [] [])
 (PROPx [] (LOCALx (choice_loc s p ptr depth bits)
 (SEPx [field_at Tsh level_type [StructField _nodd] (Vint (Int.repr odd)) s;chooser_policy p owner cb spec;P owner ptr;frame])))
 choose_count (normal_ret_assert (EX xs:list Z, PROPx [Zlength xs<=Int.max_signed;NoDup xs;in_array n xs]
 (LOCALx (temp _count (Vint (Int.repr (Zlength xs)))::choice_loc s p ptr depth bits)
 (SEPx [field_at Tsh level_type [StructField _nodd] (Vint (Int.repr odd)) s;chooser_policy p owner cb spec;
   child_array children xs;Q owner ptr xs;frame])))%assert).
Proof.
 intros enabled owner_ok sample_ok spec;unfold choose_count,choice_loc,chooser_policy,spec;abbreviate_semax;Intros.
 change Int.one with (Int.repr 1) in enabled.
 apply semax_if_seq;forward_if;[|solve [congruence|contradiction]];do 3 forward;forward_call (owner,ptr);try solve [entailer!].
 Intros xs;do 2 forward;Exists xs;entailer!;try apply derives_refl.
Qed.
