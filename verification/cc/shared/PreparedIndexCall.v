(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected EpochFreshness PreparedIndexEpoch
 PreparedIndexSweep PreparedIndexFinish PreparedIndexChooser PreparedIndexWhile
 PreparedChoiceCall PreparedArenaContext flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Local Open Scope Z_scope.

Definition call_spec gv s children dep (P:mpred) (Q:scan_exit->mpred) (size:scan_exit->Z)
 (meaning:scan_exit->Prop) : ident*funspec :=
 DECLARE _index_children WITH u:unit
 PRE [tptr level_type,tint,tptr tuint] PROP() PARAMS(s;Vint (Int.repr dep);children) GLOBALS(gv) SEP(P)
 POST [tint] EX result:scan_exit, PROP(meaning result)
    RETURN(Vint (Int.repr (size result))) SEP(Q result).

Section Storage.
Variables (gv:globals) (sh:share) (s sp op cp bp mp children:val) (offsets:list Z) (cols blocks:list int)
 (dep w:Z) (words:list int64) (nc pk:int64) (old:list int) (last:int64) (marks:list int64).
Definition call_before :=
 (counters_header s (Zlength marks) last *
  chooser_storage gv sh s sp op cp bp mp children offsets cols blocks w words marks nc pk old)%logic.
Let stamp:=Int64.repr (advance_tag false (Int64.unsigned last)).
Let header:=counters_header s (Zlength marks) stamp.
Let heap:=chooser_storage gv sh s sp op cp bp mp children offsets cols blocks w words.
Definition call_after result := (header * match result with
 | AllBits r p tags=>heap tags nc pk (RowGather.filled (output_columns offsets cols blocks result) old)
 | EmptyRow tags=>heap tags (Int64.add nc Int64.one) pk old
 | TooManyRows tags=>heap tags nc (Int64.add pk Int64.one) old end)%logic.
Definition call_count result:=Zlength (output_columns offsets cols blocks result).
Variable meaning:scan_exit->Prop.
Let spec:=call_spec gv s children dep call_before call_after call_count meaning.

(* Package a verified complete function-body judgment into the actual API.
   The PCM theorem supplies the execution premise at this instantiation. *)
Theorem body_with_chooser_post :
 (forall Espec:OracleKind,exists result,
   @semax VerifDetected.CompSpecs Espec (func_tycontext f_index_children Vprog index_calls [])
    (initial_index gv sh s sp op cp bp mp children offsets cols blocks dep w words nc pk old last marks)
    (fn_body f_index_children)
    (frame_ret_assert (after_selection gv sh s sp op cp bp mp children offsets cols blocks w words nc pk old result)
       (fun _:environ=>header)) /\ meaning result) ->
 semax_body Vprog index_calls f_index_children spec.
Proof.
 intros body;start_function1;start_function2;start_function3.
 destruct (body Espec) as [result [complete meaningful]].
 eapply semax_post_flipped.
 - eapply semax_pre;[|exact complete]. unfold initial_index,index_locals,call_before;entailer!;cancel.
 - destruct result;cbn [after_selection RA_normal frame_ret_assert function_body_ret_assert];normalize.
 - destruct result;cbn [after_selection RA_break frame_ret_assert function_body_ret_assert];normalize.
 - destruct result;cbn [after_selection RA_continue frame_ret_assert function_body_ret_assert];normalize.
 - intro v;destruct result as [r p tags|tags|tags].
   all: try unfold POSTCONDITION,abbreviate;cbn [after_selection frame_ret_assert RA_return function_body_ret_assert];
      unfold bind_ret;destruct v as [v|];[|normalize].
   all: unfold liftx;cbn;go_lowerx;normalize.
   + Exists (AllBits r p tags);unfold call_after,call_count,heap;entailer!;try cancel;try apply derives_refl.
   + Exists (EmptyRow tags);unfold call_after,call_count,heap;entailer!;try cancel;try apply derives_refl.
   + Exists (TooManyRows tags);unfold call_after,call_count,heap;entailer!;try cancel;try apply derives_refl.
Qed.
End Storage.

Definition caller_locals gv s children dep bits:=
 [temp _s s;temp _children children;temp _size (Vint (Int.repr dep));temp _options (Vint bits);gvars gv].
Definition caller_functions (spec:ident*funspec):funspecs:=[spec].

(* The non-policy arm of the real DFS uses a direct C call and the count
   written by its return; the C++ policy record is never dereferenced. *)
Theorem dfs_calls_index {Espec:OracleKind} gv s children dep bits P Q size meaning :
 Int.and bits (Int.repr 1)=Int.zero -> is_pointer_or_null s -> is_pointer_or_null children ->
 let spec:=call_spec gv s children dep P Q size meaning in
 semax (func_tycontext f_dfs Vprog (caller_functions spec) [])
  (PROPx [] (LOCALx (caller_locals gv s children dep bits) (SEPx [P])))
  choose_count (normal_ret_assert (EX result:scan_exit,PROPx [meaning result]
    (LOCALx (temp _count (Vint (Int.repr (size result)))::caller_locals gv s children dep bits)
       (SEPx [Q result]))))%assert.
Proof.
 intros bare valid out spec;unfold choose_count,caller_locals,spec;abbreviate_semax.
 apply semax_if_seq;forward_if;[solve [congruence|contradiction]|].
 forward_call tt;try solve [entailer!].
 Intros result;forward;Exists result;entailer!;try apply derives_refl.
Qed.
