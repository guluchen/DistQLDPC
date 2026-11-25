(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VerifDetected EpochFreshness PreparedIndexEpoch PreparedIndexWhile
 PreparedIndexSweep PreparedIndexFinish PreparedIndexChooser PreparedIndexCall PreparedPCMChooser flag_level_ast.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import NativePackingScan LeafMatrix PreparedIndexWords SparseFlipBits SparseSyndrome.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Local Delimit Scope Z_scope with coqZ.
Local Open Scope ring_scope.

(* The same symbol is called at every depth. Only the matrix and its
   row layout are fixed. Each invocation supplies its own prefix,
   scratch slice, mark epoch and block counters. *)
Section Uniform.
Variables m n:nat.
Variables (H:'M['F_2]_(m,n)) (rows:'I_m->seq 'I_n).

Record choice_site:=Site {
  globals_at:globals; const_share:share;
  level_p:Values.val; syndrome_p:Values.val; offsets_p:Values.val; columns_p:Values.val;
  blocks_p:Values.val; marks_p:Values.val; output_p:Values.val;
  row_offsets:seq Z; entries:seq Integers.int; blocked_cells:seq Integers.int;
  call_depth:Z; requested_weight:Z; odd_words:seq int64;
  empty_count:int64; pack_count:int64; spare_cells:seq Integers.int; epoch:int64; marks:seq int64;
  partial:'cV['F_2]_n; allowed:{set 'I_n}; moves:nat; syndrome_count:Z
}.
Record legal_choice (a:choice_site):Prop:= {
 rows_fit:(Z.of_nat m<=Int.max_signed)%coqZ; columns_fit:(0<Z.of_nat n<=Int.max_signed)%coqZ;
 free_cells:forall q:'I_n,Znth (Z.of_nat q) (blocked_cells a)=Int.zero <-> q \in allowed a;
 blocks_width:Zlength (blocked_cells a)=Z.of_nat n; marks_width:Zlength (marks a)=Z.of_nat n;
 row_covers:forall r q,H r q!=0 -> q \in rows r;
 offset_width:Zlength (row_offsets a)=(Z.of_nat m+1)%coqZ;
 row_image:forall r:'I_m,let lo:=Znth (Z.of_nat r) (row_offsets a) in
   let hi:=Znth (Z.of_nat r+1)%coqZ (row_offsets a) in
   (0<=lo<=hi)%coqZ /\ (hi<=Int.max_unsigned)%coqZ /\ (hi<=Zlength (entries a))%coqZ /\
   sublist lo hi (entries a)=encoded rows r;
 depth_moves:(requested_weight a-call_depth a)%coqZ=Z.of_nat (moves a);
 syndrome_image:stores_odd (odd_words a,syndrome_count a) (support (H*m partial a));
 padding_clear:clear_padding (Z.of_nat m) (odd_words a); nonempty_syndrome:(0<syndrome_count a)%coqZ;
 output_room:forall r:'I_m,(Znth (Z.of_nat r+1)%coqZ (row_offsets a)-Znth (Z.of_nat r) (row_offsets a)
                     <=Zlength (spare_cells a))%coqZ;
 output_fits:(Zlength (spare_cells a)<=Int.max_signed)%coqZ; readonly_valid:readable_share (const_share a);
 depth_valid:(1<=call_depth a<=requested_weight a)%coqZ;
 weight_fits:(requested_weight a<=Int.max_signed)%coqZ; word_count_fits:(Zlength (odd_words a)<=Int.max_signed)%coqZ
}.
Definition before_at a:=call_before (globals_at a) (const_share a) (level_p a) (syndrome_p a) (offsets_p a)
 (columns_p a) (blocks_p a) (marks_p a) (output_p a) (row_offsets a) (entries a) (blocked_cells a)
 (requested_weight a) (odd_words a) (empty_count a) (pack_count a) (spare_cells a) (epoch a) (marks a).
Definition after_at a:=call_after (globals_at a) (const_share a) (level_p a) (syndrome_p a) (offsets_p a)
 (columns_p a) (blocks_p a) (marks_p a) (output_p a) (row_offsets a) (entries a) (blocked_cells a)
 (requested_weight a) (odd_words a) (empty_count a) (pack_count a) (spare_cells a) (epoch a) (marks a).
Definition length_at a:=call_count (row_offsets a) (entries a) (blocked_cells a).
Definition provenance_at a result:=selection_origin rows H (partial a) (allowed a) (moves a)
   (row_offsets a) (entries a) (blocked_cells a) result /\ Zlength (scan_marks result)=Zlength (marks a).

Definition pcm_index_spec:ident*funspec:=
 DECLARE _index_children WITH a:choice_site
 PRE [tptr level_type,tint,tptr tuint] PROP(legal_choice a)
 PARAMS(level_p a;Vint (Int.repr (call_depth a));output_p a) GLOBALS(globals_at a) SEP(before_at a)
 POST [tint] EX result:scan_exit, PROP(provenance_at a result)
 RETURN(Vint (Int.repr (length_at a result))) SEP(after_at a result).

Theorem pcm_index_body:semax_body Vprog index_calls f_index_children pcm_index_spec.
Proof.
 start_function1;start_function2;start_function3.
 match goal with h:legal_choice ?a |- _ => destruct h as
   [mfit nfit free bwidth mwidth cover owidth csr remain stored pad live capacity outcap share_ok depth cap words_fit];
   have run:=@physical_index_origin_and_extent m n rows H (partial a) (allowed a) (blocked_cells a) (entries a)
     (row_offsets a) (moves a) (call_depth a) (requested_weight a) (odd_words a) (syndrome_count a)
     (marks a) (epoch a) (spare_cells a) mfit nfit free bwidth mwidth cover owidth csr remain stored pad live
     capacity outcap Espec (globals_at a) (const_share a) (level_p a) (syndrome_p a) (offsets_p a)
     (columns_p a) (blocks_p a) (marks_p a) (output_p a) (empty_count a) (pack_count a) share_ok depth cap words_fit end.
 destruct run as [result [complete [physical extent]]].
 eapply semax_post_flipped.
 - eapply semax_pre;[|exact complete]. unfold before_at,initial_index,index_locals,call_before;entailer!;cancel.
 - destruct result;cbn [after_selection RA_normal frame_ret_assert function_body_ret_assert];normalize.
 - destruct result;cbn [after_selection RA_break frame_ret_assert function_body_ret_assert];normalize.
 - destruct result;cbn [after_selection RA_continue frame_ret_assert function_body_ret_assert];normalize.
 - intro v;destruct result as [row used tags|tags|tags].
   all: try unfold POSTCONDITION,abbreviate;cbn [after_selection frame_ret_assert RA_return function_body_ret_assert];
      unfold bind_ret;destruct v as [v|];[|normalize].
   all: unfold liftx;cbn;go_lowerx;normalize.
   + Exists (AllBits row used tags);unfold provenance_at,after_at,length_at,call_after,call_count;entailer!;cancel;try apply derives_refl.
   + Exists (EmptyRow tags);unfold provenance_at,after_at,length_at,call_after,call_count;entailer!;cancel;try apply derives_refl.
   + Exists (TooManyRows tags);unfold provenance_at,after_at,length_at,call_after,call_count;entailer!;cancel;try apply derives_refl.
Qed.

Theorem same_chooser_at_each_call a:
 legal_choice a -> funspec_sub (snd pcm_index_spec)
  (snd (call_spec (globals_at a) (level_p a) (output_p a) (call_depth a)
     (before_at a) (after_at a) (length_at a) (provenance_at a))).
Proof.
 intro certified;do_funspec_sub;destruct w;cbn;normalize.
 Exists a emp;apply andp_right.
 - entailer!;cancel.
 - apply prop_right;intro rho;normalize;Exists x;entailer!;cancel.
Qed.
End Uniform.
