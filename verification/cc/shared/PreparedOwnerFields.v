(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit EnabledCall OverlapColumnState
 VerifOverlapDispatch PreparedChoiceCall PreparedSampling.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.

Definition function_field (cell:mpred) (fp:val) (spec:funspec):=(cell * func_ptr' spec fp)%logic.
Definition saved_overlap c:=function_field
 (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _overlap] (callback_addr c) (nested_policy (nested c))) (callback_addr c)
 (callback_contract (callback_owner c) (geometry c) (cols c)).

Lemma borrow_choice_owner c cb spec:
 let p:=nested_policy (nested c) in
 (pointers c * function_field (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _choose_children] cb p) cb spec=
   chooser_policy p (callback_owner c) cb spec * saved_overlap c)%logic.
Proof. intros;unfold pointers,callback_fields,chooser_policy,saved_overlap,function_field;apply pred_ext;cancel. Qed.

Lemma borrow_sample_owner c cb before after:
 let p:=nested_policy (nested c) in
 (pointers c * function_field (field_at Tsh (Tstruct _cc_level_policy noattr) [StructField _sample_done] cb p) cb (sample_completed before after)=
   sample_policy p (callback_owner c) cb before after * saved_overlap c)%logic.
Proof. intros;unfold pointers,callback_fields,sample_policy,saved_overlap,function_field;apply pred_ext;cancel. Qed.
