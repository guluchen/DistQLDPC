(* Restore terminates or reaches a genuinely undefined instruction even
   on arbitrary raw heaps. Its unsigned top strictly decreases on every
   back edge, including if the flag byte aliases the top word. *)
Require Import VST.floyd.proofauto compcert.lib.Maps compcert.cfrontend.Clight.
Require Import CCV.CCZeroByte CCV.CCRestoreEffects CCV.CCStraightWP CCV.CCStructuredRuns
 CCV.CCScanFrames CCV.CCScanCallees CCV.CCActualScans CCV.CCTerminateRestore CCV.ccv_core.
Open Scope Z_scope.
Definition restore_rank (l:Clight.temp_env) m :=
 match PTree.get _top l with
 | Some (Vptr b o) => match Mem.load Mint32 m b (Ptrofs.unsigned o) with
                      | Some (Vint x)=>Z.to_nat (Int.unsigned x) | _=>0%nat end
 | _=>0%nat end.
Ltac top_register := repeat rewrite PTree.gso by discriminate;first[reflexivity|assumption].
Lemma restore_decrement_lt x : 0<Int.unsigned x ->
 Int.unsigned (Int.sub x Int.one)<Int.unsigned x.
Proof.
 intros Pos;unfold Int.sub;rewrite Int.unsigned_one,Int.unsigned_repr;
 pose proof(Int.unsigned_range_2 x);lia.
Qed.
Section Restore.
Variable ge:Clight.genv.
Lemma restore_iteration_lowers e l m I0 :
 I0=assigned rt_loop ->
 straight_wp ge f_restore e rt_iteration
  (fun l' m'=>preserves I0 l l' /\ (restore_rank l' m'<restore_rank l m)%nat)
  (fun l' _=>preserves I0 l l') l m.
Proof.
 intros ->;cbn [rt_iteration rt_decrement rt_clear straight_wp].
 intros v Read. destruct (read_counter_inv _ _ _ _ _ Read) as [bt [ot [Top Load]]].
 split.
 - intro Test;pose proof (Mem.load_type _ _ _ _ _ Load) as Typed.
   destruct (restore_guard_positive _ _ _ _ _ (PTree.gss _ _ _) Typed Test) as [x [-> Positive]].
   intros v2 Read2. destruct(read_counter_inv _ _ _ _ _ Read2) as [b [o [Top2 Load2]]].
   rewrite PTree.gso in Top2 by discriminate;rewrite Top in Top2;injection Top2 as <- <-.
   rewrite Load in Load2;injection Load2 as <-.
   intros m1 t k Store1 v1 E1 v2 E2 v3 E3 v4 E4 m2 u h Store2.
   pose proof (restore_word_write ge f_restore k e (PTree.set _t'5 (Vint x) (PTree.set _t'6 (Vint x) l)) m m1 t bt ot x ltac:(top_register)
               (PTree.gss _ _ _) Store1) as W.
   destruct (restore_byte_write _ _ _ _ _ _ _ _ Store2) as [bf [pos Z0]].
   destruct (store_word_then_zero _ _ _ _ _ _ _ _ W Z0) as [y [New Less]].
   split.
   + intros j Outside;repeat rewrite PTree.gso;try reflexivity;
     intro Eq;subst;apply Outside;vm_compute;tauto.
   + unfold restore_rank; repeat rewrite PTree.gso by discriminate;rewrite Top,Load,New.
     pose proof(restore_decrement_lt x Positive);pose proof(Int.unsigned_range_2 y);lia.
 - intros _ j Outside;rewrite PTree.gso;[reflexivity|].
   intro Eq;subst;apply Outside;vm_compute;tauto.
Qed.
Lemma restore_framed e : framed ge f_restore e rt_loop.
Proof.
 intros before;set (Inv:=fun (l:Clight.temp_env) (_:mem)=>preserves (assigned rt_loop) before l).
 eapply runs_consequence with (P':=Inv)(N':=Inv)(B':=Inv).
 - intros l m Eq;subst;apply preserves_self.
 - eapply runs_loop with(rank:=restore_rank)(mid:=fun l m l' m'=>Inv l' m' /\ (restore_rank l' m'<restore_rank l m)%nat).
   + intros l m Old.
     eapply runs_consequence with
      (P':=straight_wp ge f_restore e rt_iteration
        (fun l' m'=>preserves (assigned rt_loop) l l' /\ (restore_rank l' m'<restore_rank l m)%nat)
        (fun l' _=>preserves (assigned rt_loop) l l')).
     * intros l0 m0 [-> ->];apply restore_iteration_lowers;reflexivity.
     * apply straight_wp_runs.
     * intros l' m' [Fr Less];split;[|exact Less];intros j Outside;rewrite Fr,Old by assumption;reflexivity.
     * intros l' m' Fr j Outside;rewrite Fr,Old by assumption;reflexivity.
   + intros;apply runs_skip.
 - intros;assumption.
 - intros;assumption.
Qed.
Theorem restore_settles : call_settles ge f_restore.
Proof.
 apply structured_function_returns;intros;rewrite rt_body_actual;apply restore_framed.
Qed.
End Restore.
