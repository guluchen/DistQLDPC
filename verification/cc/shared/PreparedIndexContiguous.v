(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected VerifChildVisit VerifClosesBody VerifFlipBody
 NativeFlipPayload PreparedFlip PreparedChooserStorage PreparedIndexWhile PreparedIndexChildrenView
 PreparedIndexSyndromeLoan PreparedIndexFinish PreparedIndexCall PreparedChoiceCall PreparedIndexLink
 PreparedUniformIndex PreparedSeedDispatch PreparedPCMChooser PreparedIndexReuse PreparedCallerLocals
 PreparedInitializeScan PreparedSelectedReturn PreparedChooseReturn PreparedSampling flag_level_ast.
From mathcomp Require Import all_ssreflect all_algebra.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Local Open Scope ring_scope.

Section ChoiceAndSearch.
Variable Espec:OracleKind.
#[local] Existing Instance Espec.
Variables m n:nat.
Variables (H:'M['F_2]_(m,n)) (rows:'I_m->seq 'I_n) (a:@choice_site n)
 (flip dfs:funspec) (keyp pathp:Values.val) (keys:seq int64) (t:packed_support)
 (path:seq Integers.int) (options:Integers.int) (ptr:Values.val) (extra:mpred) (post:ret_assert).
Let D:=func_tycontext f_dfs prepared_vars (index_callees H rows flip dfs) nil.
Let s:=level_p a.
Let buf:=output_p a.
Let d:=call_depth a.
Let stride:=Zlength (spare_cells a).
Let before:=caller_locals (globals_at a) s buf d options.
Let held:=[::temp _policy nullval;lvar _sample sample_type ptr].
Let own:=child_fields s pathp (blocks_p a) (requested_weight a) (blocked_cells a) path.
Let packed:=packed_mem s keyp Bare keys t.
Let work:=reusable_index (globals_at a) (const_share a) s (offsets_p a) (columns_p a) (marks_p a)
                 (row_offsets a) (entries a) (Zlength (odd_words a)) (Z.of_nat n).
Let picks:=output_columns (row_offsets a) (entries a) (blocked_cells a).
Let row z:=child_array buf (map Int.unsigned (picks z)).

Local Definition choice_facts (r:scan_exit*mpred) : seq Prop :=
 [::provenance_at H rows a r.1;(row r.1 * r.2 |-- ready_row buf stride)%logic].

Theorem choose_and_search:
 legal_choice H rows a -> syndrome_p a=psyn (words_at t) -> odd_words a=syndrome (words_at t) ->
 Int.and options (Int.repr 1)=Int.zero -> is_pointer_or_null s -> is_pointer_or_null buf ->
 (forall z spare,provenance_at H rows a z -> (row z * spare |-- ready_row buf stride)%logic ->
    semax D (PROPx nil (LOCALx (plain_chosen_loc s buf d (length_at a z) options ptr)
        (SEPx [::own;row z;spare;packed;work;extra]))) selected_subtree post) ->
 semax D (PROPx nil (LOCALx (before++held)
      (SEPx [::own;ready_row buf stride;packed;work;extra]))) choose_search_return post.
Proof.
 move=>ok sp words direct valid out subtree.
 change choose_search_return with (Ssequence choose_count selected_subtree).
 pose A:=(scan_exit*mpred)%type.
 pose regs (r:A):=temp _count (Vint (Int.repr (length_at a r.1)))::before.
 pose after (r:A):=[::own;row r.1;r.2;packed;work].
 have call:semax D (PROPx nil (LOCALx before (SEPx [::own;ready_row buf stride;packed;work])))
   choose_count (normal_ret_assert (EX r:A,PROPx (choice_facts r) (LOCALx (regs r) (SEPx (after r))))).
 { eapply semax_post';last exact:(@choose_in_reusable_storage Espec m n H rows a flip dfs keyp pathp keys
                                t path options ok sp words direct valid out).
   Intros z spare;Exists (z,spare);unfold choice_facts,regs,after,row,picks;cbn [fst snd].
   unfold before,own,packed,work,s,buf,d,stride;go_lowerx;normalize;try cancel;try apply derives_refl.
   all: try (apply andp_right;[apply prop_right;cbn;tauto|cancel]). }
 have stable:closed_wrt_modvars choose_count (LOCALx held (SEPx [::extra]))
   by unfold held,choose_count;auto 100 with closed.
 pose proof (@keep_caller_locals_for_answer A Espec VerifDetected.CompSpecs D choose_count nil before
    [::own;ready_row buf stride;packed;work] held [::extra] choice_facts regs after stable call) as keep.
 eapply semax_seq';first exact keep.
 Intros r;destruct r as [z spare];unfold choice_facts,regs,after;cbn [fst snd];Intros.
 eapply semax_pre;last apply (subtree z spare);try assumption.
 unfold held,before,caller_locals,plain_chosen_loc;cbn [app];go_lowerx;normalize;cancel;try apply derives_refl.
 all: match goal with |- ?G=> fail 1 "remaining join" G end.
Qed.
End ChoiceAndSearch.
