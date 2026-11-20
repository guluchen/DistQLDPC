(* Split the initialized read-only undo prefix without losing full ownership.
   The complementary share and untouched suffix are framed across restore(). *)
Require Import VST.floyd.proofauto VST.zlist.list_solver.
Require Import CCV.CCJournalArray CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
Section Array.
Context{CS:compspecs}.
#[local] Existing Instance CS.
Definition undo_read_frame sh n(log:list Z)(buf:list val)up:mpred:=
 (data_at(Share.comp sh)(tarray tuint(Zlength log))(tbytes log)up*
 data_at Tsh(tarray tuint(n-Zlength log))(sublist(Zlength log)n buf)
 (field_address0(tarray tuint n)[ArraySubsc(Zlength log)]up))%logic.
Lemma undo_array_split sh n log buf up:
 0<=Zlength log<=n ->Zlength buf=n ->undo_prefix log buf ->
 data_at Tsh(tarray tuint n)buf up=
 (data_at sh(tarray tuint(Zlength log))(tbytes log)up*undo_read_frame sh n log buf up)%logic.
Proof.
 intros Top Len Prefix.
 assert(Whole:buf=sublist 0 n buf)by list_solve.
 assert(Bound:n<=Zlength buf)by lia.
 pose proof(@split2_data_at_Tarray CS Tsh tuint n(Zlength log)buf buf
 (sublist 0(Zlength log)buf)(sublist(Zlength log)n buf)up Top Bound Whole eq_refl eq_refl)as Split.
 unfold tarray. rewrite Split. unfold undo_prefix in Prefix;rewrite Prefix.
 rewrite <-(@data_at_share_join CS sh(Share.comp sh)Tsh(Tarray tuint(Zlength log)noattr)(tbytes log)up)
 by apply comp_join_top.
 unfold undo_read_frame,tarray;apply pred_ext;cancel.
Qed.
Lemma undo_array_join sh n log buf up:
 0<=Zlength log<=n ->Zlength buf=n ->undo_prefix log buf ->
 (data_at sh(tarray tuint(Zlength log))(tbytes log)up*undo_read_frame sh n log buf up)%logic
 |--data_at Tsh(tarray tuint n)buf up.
Proof. intros;rewrite <-(undo_array_split sh n log buf up)by assumption;apply derives_refl. Qed.
End Array.
Print Assumptions undo_array_split.
