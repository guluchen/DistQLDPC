(* Exact substatements of the frozen actual C search AST.
   Layout/substatement facts only: these are not Hoare proofs of these blocks. *)
From Coq Require Import List.
From compcert Require Import Integers Ctypes Cop Clight.
Require Import CCV.ccv_core.
Import ListNotations.
Inductive statement_edge :=SeqFirst|SeqNext|ThenBranch|ElseBranch|LoopBody|LoopIncrement.
Fixpoint statement_at (path:list statement_edge)(s:statement):option statement :=
 match path with
 |[]=>Some s
 |edge::tail=>match edge,s with
  |SeqFirst,Ssequence a b=>statement_at tail a
  |SeqNext,Ssequence a b=>statement_at tail b
  |ThenBranch,Sifthenelse e a b=>statement_at tail a
  |ElseBranch,Sifthenelse e a b=>statement_at tail b
  |LoopBody,Sloop a b=>statement_at tail a
  |LoopIncrement,Sloop a b=>statement_at tail b
  |_,_=>None end end.
Definition search_fragment path :=match statement_at path(fn_body f_search)with Some s=>s|None=>Sskip end.
Definition cap_zero_path:list statement_edge :=[SeqFirst].
Definition search_cap_zero :=search_fragment cap_zero_path.
Lemma cap_zero_is_actual :statement_at cap_zero_path(fn_body f_search)=Some search_cap_zero.
Proof. reflexivity. Qed.
Definition clamp_path:list statement_edge :=[SeqNext;SeqFirst].
Definition search_clamp :=search_fragment clamp_path.
Lemma clamp_is_actual :statement_at clamp_path(fn_body f_search)=Some search_clamp.
Proof. reflexivity. Qed.
Definition seed_loop_path:list statement_edge :=[SeqNext;SeqNext;SeqFirst;SeqNext].
Definition search_seed_loop :=search_fragment seed_loop_path.
Lemma seed_loop_is_actual :statement_at seed_loop_path(fn_body f_search)=Some search_seed_loop.
Proof. reflexivity. Qed.
Definition main_loop_path:list statement_edge :=[SeqNext;SeqNext;SeqFirst;SeqNext;LoopBody;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext].
Definition search_main_loop :=search_fragment main_loop_path.
Lemma main_loop_is_actual :statement_at main_loop_path(fn_body f_search)=Some search_main_loop.
Proof. reflexivity. Qed.
Definition main_iteration_path:list statement_edge :=[SeqNext;SeqNext;SeqFirst;SeqNext;LoopBody;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;LoopBody;SeqNext].
Definition search_main_iteration :=search_fragment main_iteration_path.
Lemma main_iteration_is_actual :statement_at main_iteration_path(fn_body f_search)=Some search_main_iteration.
Proof. reflexivity. Qed.
Definition fuel_guard_path:list statement_edge :=[SeqNext;SeqNext;SeqFirst;SeqNext;LoopBody;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;LoopBody;SeqNext;SeqFirst;SeqNext].
Definition search_fuel_guard :=search_fragment fuel_guard_path.
Lemma fuel_guard_is_actual :statement_at fuel_guard_path(fn_body f_search)=Some search_fuel_guard.
Proof. reflexivity. Qed.
Definition phase_dispatch_path:list statement_edge :=[SeqNext;SeqNext;SeqFirst;SeqNext;LoopBody;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;LoopBody;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext].
Definition search_phase_dispatch :=search_fragment phase_dispatch_path.
Lemma phase_dispatch_is_actual :statement_at phase_dispatch_path(fn_body f_search)=Some search_phase_dispatch.
Proof. reflexivity. Qed.
Definition phase_zero_path:list statement_edge :=[SeqNext;SeqNext;SeqFirst;SeqNext;LoopBody;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;LoopBody;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;ThenBranch].
Definition search_phase_zero :=search_fragment phase_zero_path.
Lemma phase_zero_is_actual :statement_at phase_zero_path(fn_body f_search)=Some search_phase_zero.
Proof. reflexivity. Qed.
Definition phase_nonzero_path:list statement_edge :=[SeqNext;SeqNext;SeqFirst;SeqNext;LoopBody;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;LoopBody;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;ElseBranch].
Definition search_phase_nonzero :=search_fragment phase_nonzero_path.
Lemma phase_nonzero_is_actual :statement_at phase_nonzero_path(fn_body f_search)=Some search_phase_nonzero.
Proof. reflexivity. Qed.
Definition phase_one_path:list statement_edge :=[SeqNext;SeqNext;SeqFirst;SeqNext;LoopBody;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;LoopBody;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;ElseBranch;SeqNext;ThenBranch].
Definition search_phase_one :=search_fragment phase_one_path.
Lemma phase_one_is_actual :statement_at phase_one_path(fn_body f_search)=Some search_phase_one.
Proof. reflexivity. Qed.
Definition phase_two_path:list statement_edge :=[SeqNext;SeqNext;SeqFirst;SeqNext;LoopBody;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;LoopBody;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqFirst;SeqNext;ElseBranch;SeqNext;ElseBranch].
Definition search_phase_two :=search_fragment phase_two_path.
Lemma phase_two_is_actual :statement_at phase_two_path(fn_body f_search)=Some search_phase_two.
Proof. reflexivity. Qed.
Definition finish_path:list statement_edge :=[SeqNext;SeqNext;SeqFirst;SeqNext;LoopBody;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;LoopBody;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext;SeqNext].
Definition search_finish :=search_fragment finish_path.
Lemma finish_is_actual :statement_at finish_path(fn_body f_search)=Some search_finish.
Proof. reflexivity. Qed.
Print Assumptions phase_zero_is_actual.
Print Assumptions phase_one_is_actual.
Print Assumptions phase_two_is_actual.
