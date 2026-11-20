(* Actual phase-1 scan statements, with kernel-checked source identities.
   These layout facts are not yet a Hoare proof of the scan or full search. *)
From Coq Require Import List.
From compcert Require Import Clight.
Require Import CCV.ccv_core CCV.CCSearchFragments.
Import ListNotations.
Definition scan_setup_path :=phase_one_path++[SeqFirst].
Definition scan_loop_path :=phase_one_path++[SeqNext;SeqFirst].
Definition scan_tail_path :=phase_one_path++[SeqNext;SeqNext].
Definition scan_setup :=search_fragment scan_setup_path.
Definition scan_loop :=search_fragment scan_loop_path.
Definition scan_tail :=search_fragment scan_tail_path.
Lemma scan_loop_is_actual :statement_at scan_loop_path(fn_body f_search)=Some scan_loop.
Proof. reflexivity. Qed.
Lemma scan_loop_shape :exists body incr,scan_loop=Sloop body incr.
Proof. eexists;eexists;reflexivity. Qed.
Lemma phase_one_layout :search_phase_one=Ssequence scan_setup(Ssequence scan_loop scan_tail).
Proof. reflexivity. Qed.
Print Assumptions phase_one_layout.
