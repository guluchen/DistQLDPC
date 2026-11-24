(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import SeedExemptionState SeedColumnModel SeedPolicyView SeedTransferTrace.
Local Open Scope Z_scope.

Definition live_choices (n:Z) (base:list int) (st:moving_state) :=
 Zlength (exempts st)=Zlength base /\ Zlength (reference_counts st)=n /\
 forall k,0<=k<Zlength base -> 0<=Int.signed (Znth k base) ->
  0<=Int.signed (Znth k (exempts st))<n.

Lemma change_live_choice n base limits st row next :
 live_choices n base st -> 0<=row<Zlength base -> 0<=Int.signed (Znth row base) ->
 0<=next<n -> n<=Int.max_signed ->
 live_choices n base (replace_exemption limits st row next).
Proof.
 intros [extent [counts valid]] within active selected cap.
 pose proof (valid row within active) as old.
 pose proof (replace_shape limits st row next ltac:(lia) ltac:(lia) ltac:(lia)) as [rows qubits].
 split;[lia|];split;[lia|];intros k pos enabled.
 destruct (Z.eq_dec k row) as [->|different].
 - rewrite row_always_selects_current by lia;rewrite Int.signed_repr by rep_lia;exact selected.
 - rewrite other_exempt_unchanged by lia;apply valid;assumption.
Qed.

Definition usable_defaults n base fallback :=
 Zlength fallback=Zlength base /\
 forall k,0<=k<Zlength base -> 0<=Int.signed (Znth k base) ->
 Int.signed (Znth k base)<n /\ Int.signed (Znth k fallback)<n.
Lemma valid_choice n base fallback q enter row :
 usable_defaults n base fallback -> 0<=q<n -> 0<=row<Zlength base ->
 0<=Int.signed (Znth row base) -> 0<=seed_choice base fallback row q enter<n.
Proof.
 intros [_ defaults] seed pos enabled;specialize (defaults row pos enabled).
 unfold seed_choice;destruct enter;[assumption|];unfold clear_seed;destruct Z_lt_dec;lia.
Qed.
Lemma visit_rows_have_valid_choices n base fallback q enter limits rows st :
 usable_defaults n base fallback -> 0<=q<n -> n<=Int.max_signed ->
 Forall (fun word=>Int.unsigned word<Zlength base) rows ->
 live_choices n base st ->
 live_choices n base (fold_left (visit_seed_row limits base fallback q enter) rows st).
Proof.
 intros def inside cap valid;revert st;induction valid as [|word rows bound valid IH];intros st table;
  cbn [fold_left];[assumption|apply IH].
 unfold visit_seed_row;destruct Z_lt_dec;[assumption|].
 pose proof (Int.unsigned_range_2 word).
 apply change_live_choice;try assumption;try lia;apply valid_choice;try assumption;lia.
Qed.
Lemma slice_indices {A} {D:Inhabitant A} (data:list A) (P:A->Prop) lo hi:
 0<=lo<=hi -> hi<=Zlength data ->
 (forall k,lo<=k<hi -> P (Znth k data)) -> Forall P (sublist lo hi data).
Proof.
 intros span cap each;apply Forall_forall;intros x found;destruct (In_Znth _ _ found) as [k [pos eqx]].
 rewrite Zlength_sublist in pos by lia;rewrite Znth_sublist in eqx by lia;rewrite <-eqx;apply each;lia.
Qed.

(* Discharge the C entry/exit column contracts from once-validated arrays.
   Scanning the same row several times is allowed. *)
Theorem csr_seed_column_safe n g limits enter q st :
 0<=q<n -> n<=Int.max_signed -> q+1<Zlength (col_starts g) ->
 0<=index_at g q<=index_at g (q+1) -> index_at g (q+1)<=Zlength (col_rows g) ->
 (forall k,index_at g q<=k<index_at g (q+1) ->
    Int.unsigned (Znth k (col_rows g))<Zlength (base_order g)) ->
 Zlength limits=Zlength (base_order g) ->
 usable_defaults n (base_order g) (first_block g) -> live_choices n (base_order g) st ->
 column_safe g limits enter q st /\
 live_choices n (base_order g) (prefix g limits enter q st (index_at g (q+1))).
Proof.
 intros seed cap room span slots indices lengths defaults table.
 assert (prefix_ok:forall j,index_at g q<=j<=index_at g (q+1) ->
   live_choices n (base_order g) (prefix g limits enter q st j)).
 { intros j inside;unfold prefix,visited_seed_rows;apply visit_rows_have_valid_choices;try assumption.
   apply slice_indices;try lia;intros k pos;apply indices;lia. }
 split;[|apply prefix_ok;lia].
 split;[lia|];do 3 (split;[assumption|]);intros j inside.
 specialize (indices j inside);pose proof (Int.unsigned_range_2 (Znth j (col_rows g))).
 destruct (prefix_ok j ltac:(lia)) as [rows [qubits valid]].
 pose proof (proj1 defaults) as fallback_length.
 split;[lia|];split;[lia|];intro enabled.
 pose proof (valid_choice n (base_order g) (first_block g) q enter
    (Int.unsigned (Znth j (col_rows g))) defaults seed
    (conj (proj1 (Int.unsigned_range_2 _)) indices) enabled) as choice.
 specialize (valid _ (conj (proj1 (Int.unsigned_range_2 _)) indices) enabled).
 repeat split;lia.
Qed.
