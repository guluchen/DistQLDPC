(* Physical frame update and phase-sensitive selected cache on activation.
   Pure transitions; actual C store proof is a separate obligation. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCSearchHeap CCV.CCStackInvariant
 CCV.CCActivateCoverage CCV.CCResumeMemory CCV.CCLoopInvariant CCV.CCSearchPhases.
Import ListNotations. Open Scope nat_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition activate_raw(raw:frame_value)(row:nat):frame_value:=
 (Vint(Int.repr(Z.of_nat row)),(Vint Int.zero,(fst(snd(snd raw)),
 (fst(snd(snd(snd raw))),Vint(Int.repr 1))))).
Definition activate_raw_frames(prefix:list ghost_frame)(row:nat)(raw:list frame_value):=
 upd_Znth(Z.of_nat(length prefix))raw(activate_raw(Znth(Z.of_nat(length prefix))raw)row).
Lemma activation_nth_before prefix g row i:i<length prefix ->
 nth i(prefix++[activated_record g row])empty_ghost=nth i(prefix++[g])empty_ghost.
Proof.
 revert i;induction prefix as[|a prefix IH];intros[|i]I;cbn[app nth length]in*;
 try lia;try reflexivity;apply IH;lia.
Qed.
Lemma frame_represents_activation g raw row:ghost_phase g=0 ->frame_represents g raw ->
 frame_represents(activated_record g row)(activate_raw raw row).
Proof.
 intros Phase Rep;unfold frame_represents in Rep;rewrite Phase in Rep.
 destruct Rep as[r[nx[ch Eq]]];subst raw.
 unfold frame_represents,activated_record,activate_raw;cbn.
 exists ch;reflexivity.
Qed.
Theorem activation_physical_stack n prefix g row raw:
 ghost_phase g=0 ->length(prefix++[g])<=n ->physical_stack n(prefix++[g])raw ->
 physical_stack n(prefix++[activated_record g row])(activate_raw_frames prefix row raw).
Proof.
 intros Phase Capacity[Len Cells].
 assert(Top:length prefix<n)by(rewrite app_length in Capacity;cbn[length]in Capacity;lia).
 assert(Bound:(0<=Z.of_nat(length prefix)<Zlength raw)%Z)by(rewrite Len;lia).
 unfold physical_stack,activate_raw_frames;split.
 - rewrite upd_Znth_Zlength by exact Bound;exact Len.
 - intros i I;pose proof(Cells i I)as Cell.
   destruct(Nat.eq_dec i(length prefix))as[->|Ne].
   + destruct(lt_dec(length prefix)(length(prefix++[activated_record g row])))as[Inside|Outside].
     2:{ rewrite app_length in Outside;cbn[length]in Outside;lia. }
     rewrite nth_snoc_last,upd_Znth_same by exact Bound.
     apply frame_represents_activation;[assumption|].
     destruct(lt_dec(length prefix)(length(prefix++[g])))as[InOld|OutOld].
     2:{ rewrite app_length in OutOld;cbn[length]in OutOld;lia. }
     rewrite nth_snoc_last in Cell;exact Cell.
   + assert(IZ:(0<=Z.of_nat i<Zlength raw)%Z)by(rewrite Len;lia).
     rewrite upd_Znth_diff by lia.
     rewrite activation_length.
     destruct(lt_dec i(length(prefix++[g])))as[Active|Inactive].
     * assert(Before:i<length prefix)by(rewrite app_length in Active;cbn[length]in Active;lia).
       rewrite activation_nth_before by assumption;exact Cell.
     * exact Cell.
Qed.

Theorem activated_selected_tracks n seed path prefix g row xs:
 ghost_phase g=0 ->selected_tracks_stack n seed path(prefix++[g])xs ->
 selected_tracks_stack n seed path(prefix++[activated_record g row])xs.
Proof.
 intros Phase Tracks;unfold selected_tracks_stack in Tracks |- *.
 rewrite !rev_app_distr in Tracks |- *;cbn[rev app activated_record ghost_phase ghost_chosen]in*.
 destruct Tracks as[Nonempty[Root State]];rewrite Phase in State.
 split;[assumption|split;[assumption|exact State]].
Qed.
Print Assumptions activation_physical_stack.
Print Assumptions activated_selected_tracks.
