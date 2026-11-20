(* The source skeleton with only the selected root's depth loop abstracted.
   Instantiating it with the original loop is literal Clight equality. *)
Require Import VST.floyd.proofauto CCV.ccv_core CCV.CCSearchFragments
 CCV.VerifRootMask CCV.VerifRootToggle CCV.VerifClearRawTop CCV.VerifRootPreparation CCV.VerifRootSeedBody
 CCV.VerifRootFrameContinuation CCV.VerifSeedLoop CCV.VerifSearchCore
 CCV.VerifSearchSeedInit CCV.VerifSearchCleanup CCV.VerifSearchEntry.
Definition root_with main := Ssequence raw_top_clear_call (Ssequence root_mask_block
 (Ssequence root_toggle_call (root_frame_then main))).
Definition seeds_with main := Sloop
 (Ssequence (Ssequence seed_limit_read seed_limit_test) (root_with main)) seed_increment.
Definition tail_with main := Ssequence (Ssequence search_seed_init (seeds_with main)) search_cleanup.
Definition positive_with main := Ssequence search_clamp (tail_with main).
Definition body_with main := Ssequence search_cap_zero (positive_with main).
Definition with_body f body :=
 Clight.mkfunction (fn_return f) (fn_callconv f) (fn_params f) (fn_vars f) (fn_temps f) body.
Lemma original_search_skeleton : body_with search_main_loop=fn_body f_search.
Proof. reflexivity. Qed.
