(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq VerifDetected
 VerifLowestBit PreparedIndexAdvance PreparedIndexIteration PreparedIndexBitBody
 PreparedIndexWordStep PreparedIndexWhile WordScan ClightSelect flag_level_ast.
Local Open Scope Z_scope.

Definition all_words:statement:=ltac:(native_fragment (counts_on _wi) f_index_children).
Definition syndrome_memory s sp words :=
 (field_at Tsh level_type [StructField _mw] (Vint (Int.repr (Zlength words))) s *
  field_at Tsh level_type [StructField _syn] sp s *
  data_at Tsh (tarray tulong (Zlength words)) (map Vlong words) sp)%logic.

Section Words.
Variables (offsets:list Z) (cols blocks:list int) (stamp:int64) (dep w:Z).
Let valid:=row_state_ok blocks dep w.
Let safe:=safe_index_row offsets cols blocks.
Let word_exit:=scan_bits offsets cols blocks stamp.
Lemma exhausted_bits_valid wi bits b p ms b' p' tags:
 Forall (fun i=>safe (64*wi+i)) bits -> valid b p ms ->
 word_exit wi dep w bits b p ms=AllBits b' p' tags -> valid b' p' tags.
Proof.
 intros guarded;revert b p ms;induction guarded as [|i rest ok tail ih];intros b p ms initial;cbn [word_exit scan_bits].
 - intro done;inversion done;subst;exact initial.
 - destruct (run_row _ _ _ _ _ _ _ _) as [| |q next] eqn:E;[discriminate|discriminate|].
   apply ih. exact (step_stays_in_range offsets cols blocks stamp dep w (64*wi+i) b p ms q next ok initial E).
Qed.

Fixpoint sweep wi (plan:list (list Z)) b p ms :=
 match plan with
 | nil=>AllBits b p ms
 | bits::later=>match word_exit wi dep w bits b p ms with
   | AllBits branch packed tags=>sweep (wi+1) later branch packed tags
   | stop=>stop
   end
 end.
Lemma plans_for_words words:exists plan,List.Forall2 scan_word words plan.
Proof. induction words;[exists nil;constructor|].
 destruct (scan_finite a) as [bits run];destruct IHwords as [tail correct].
 exists (bits::tail);constructor;assumption.
Qed.

Context {Espec:OracleKind}.
Variables (gv:globals) (sh:share) (s sp op cp bp mp:val) (words:list int64) (plan:list(list Z)) (nc pk:int64).
Let size:=Zlength words.
Let parts:=word_heap gv sh s op cp bp mp offsets cols blocks w.
Let syn:=syndrome_memory s sp words.
Let memory ms a b:=syn::parts ms a b.
Let livevars b p:=[temp _s s;temp _stamp (Vlong stamp);temp _size (Vint (Int.repr dep));
   temp _branch (Vint (Int.repr b));temp _packed (Vint (Int.repr p));gvars gv].
Definition sweep_entry b p ms:=PROPx [] (LOCALx (livevars b p) (SEPx (memory ms nc pk))).
Let cut ms a b:=function_body_ret_assert tint
   (PROPx [] (LOCALx [temp ret_temp (Vint Int.zero)] (SEPx (memory ms a b)))).
Definition sweep_post result:=match result with
 | AllBits b p ms=>normal_ret_assert (sweep_entry b p ms)
 | EmptyRow ms=>cut ms (Int64.add nc Int64.one) pk
 | TooManyRows ms=>cut ms nc (Int64.add pk Int64.one)
 end.
Let suffix i:=sublist i size plan.
Definition sweep_inv (final:scan_exit) (after:bool):=
 (EX i:Z, EX b:Z, EX p:Z, EX ms:list int64,
  PROPx [if after then 0<=i<size else 0<=i<=size;valid b p ms;
       let j:=if after then i+1 else i in sweep j (suffix j) b p ms=final]
   (LOCALx (temp _wi (Vint (Int.repr i))::livevars b p) (SEPx (memory ms nc pk))))%assert.

Theorem compiled_word_sweep b p ms :
 readable_share sh -> 1<=dep<=w -> w<=Int.max_signed -> size<=Int.max_signed ->
 Zlength plan=size ->
 (forall i,0<=i<size -> scan_word (Znth i words) (Znth i plan) /\
    Forall (fun bit=>safe (64*i+bit)) (Znth i plan)) ->
 valid b p ms ->
 semax (func_tycontext f_index_children Vprog LowGprog []) (sweep_entry b p ms)
 all_words (sweep_post (sweep 0 plan b p ms)).
Proof.
 intros readable depth cap length plansize layout initial.
 remember (sweep 0 plan b p ms) as final eqn:answer.
 unfold all_words,sweep_entry,livevars;abbreviate_semax;forward.
 forward_loop (sweep_inv final false) continue:(sweep_inv final true) break:(RA_normal (sweep_post final)).
 - unfold sweep_inv;Exists 0 b p ms;unfold livevars,suffix,memory,parts,word_heap.
   rewrite sublist_same by lia;pose proof (Zlength_nonneg words);unfold size in *;entailer!;try apply derives_refl.
 - unfold sweep_inv;Intros i before packed tags.
   assert (range:0<=i<=size) by assumption.
   assert (good:valid before packed tags) by assumption.
   assert (promise:sweep i (suffix i) before packed tags=final) by assumption.
   unfold livevars,memory,syn,syndrome_memory;cbn [app];Intros;forward;forward_if.
   + { assert (active:0<=i<size) by (unfold size in *;rep_lia).
       destruct (layout i active) as [runs limits].
       assert (uncons:suffix i=Znth i plan::suffix (i+1)).
       { unfold suffix;rewrite (sublist_split i (i+1) size plan),(sublist_one i) by lia;reflexivity. }
       rewrite uncons in promise;cbn [sweep] in promise.
       unfold_abbrev'.
       match goal with |- semax _ _ (Ssequence ?load ?body) _ => change body with odd_loop end.
       eapply semax_seq' with (P':=PROPx [] (LOCALx (word_locals gv s stamp i dep (Znth i words) before packed)
             (SEPx (memory tags nc pk)))).
       { reassoc_seq;do 2 forward;unfold word_locals,memory,parts,word_heap,syn,syndrome_memory;
         entailer!;try cancel;try apply derives_refl. }
       pose proof (@compiled_odd_word s op cp bp mp offsets cols blocks stamp i dep w nc pk Espec gv sh
          (Znth i words) (Znth i plan) before packed tags readable (proj1 active) depth cap runs limits good) as run.
       pose proof (@semax_frame VerifDetected.CompSpecs Espec _ _ odd_loop _ (fun _:environ=>syn)
         ltac:(hnf;intros;auto) run) as saved.
       set (outcome:=word_exit i dep w (Znth i plan) before packed tags) in promise.
       fold (word_exit i dep w (Znth i plan) before packed tags) in saved.
       fold outcome in saved.
       destruct outcome as [new count next|stopped|stopped] eqn:which.
       all: eapply semax_post_flipped;[eapply semax_pre;[|exact saved];
         unfold word_locals,scanning,memory,parts,word_heap,syn,syndrome_memory;go_lowerx;normalize;cancel|..].
       all: try unfold POSTCONDITION,abbreviate;try rewrite <-promise;
          cbn [RA_normal RA_continue RA_break RA_return sweep_post cut_word cut
              frame_ret_assert loop1_ret_assert overridePost normal_ret_assert function_body_ret_assert];
          try solve [intro v;apply andp_left2;apply FF_left|apply andp_left2;apply FF_left|normalize].
       all: try solve [intro v;unfold bind_ret;destruct v;[|normalize];
         unfold syn,memory,parts,word_heap;go_lowerx;normalize;try cancel;try tauto;try apply derives_refl].
       all: try (destruct (sweep (i+1) (suffix (i+1)) new count next) eqn:answer_tail;
           cbn [RA_normal RA_continue RA_break RA_return sweep_post cut_word cut
              frame_ret_assert loop1_ret_assert overridePost normal_ret_assert function_body_ret_assert];
           try solve [intro v;apply andp_left2;apply FF_left|apply andp_left2;apply FF_left|normalize]).
       all: assert (ok:valid new count next) by
         (eapply exhausted_bits_valid;[exact limits|exact good|exact which]).
       all: unfold sweep_inv;Exists i new count next;unfold scanning,word_locals,livevars,memory,parts,word_heap;
          go_lowerx;normalize;try cancel;try tauto;try apply derives_refl.
       all: apply andp_right;[apply prop_right;unfold liftx in *;simpl in *;intuition|cancel]. }
   + assert (last:i=size) by (unfold size in *;rep_lia).
     subst i;unfold suffix in promise;rewrite sublist_nil in promise by lia;cbn [sweep] in promise.
     forward;rewrite <-promise;cbn [RA_normal sweep_post normal_ret_assert overridePost loop1_ret_assert for_ret_assert].
     cbn [RA_break];unfold sweep_entry,livevars,memory,parts,word_heap,syn,syndrome_memory;entailer!;try cancel;try apply derives_refl.
 - unfold sweep_inv;Intros i before packed tags;unfold livevars;forward;Exists (i+1) before packed tags.
   unfold livevars,memory,parts,word_heap;entailer!;try apply derives_refl.
 all: try solve [apply andp_left2;apply derives_refl|apply derives_refl].
Qed.
End Words.
