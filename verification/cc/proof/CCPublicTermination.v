(* The conclusion uses the exact original two-unit global environment.
   The ordinary entry contract includes argument types, disjoint owned
   buffers and the caller's VST function/ghost resources. *)
Require Import VST.floyd.proofauto compcert.cfrontend.Clight compcert.common.Smallstep.
Require Import CCV.CCOwnedSolver CCV.CCBareExecution CCV.CCOriginalNames
 CCV.CCLinkedProgram CCV.CCCertifiedLibrary CCV.CCUniqueExecution CCV.CCInternalPaths.
Theorem original_solver_returns {E:OracleKind} (z:OK_ty) x args m:
 semax_prog.postcondition_allows_exit E tint ->owns_entry z x args m ->
 exists t v m',star Clight.step2 (Clight.globalenv linked_prog)
 (Callstate (Internal(entry_function x)) args Kstop m) t (Returnstate v Kstop m').
Proof.
 intros Exit Owned;destruct(every_owned_entry_returns z x args m Exit Owned) as [t [v [m' Run]]].
 exists t,v,m';apply bare_trace;[exact Run|].
 cbn[old_state old_cont];split;[destruct x;vm_compute;reflexivity|exact I].
Qed.
Print Assumptions original_solver_returns.

Theorem all_original_executions_return {E:OracleKind} (z:OK_ty) x args m:
 semax_prog.postcondition_allows_exit E tint ->owns_entry z x args m ->
 let ge:=Clight.globalenv linked_prog in
 let start:=Callstate (Internal(entry_function x)) args Kstop m in
 exists v m', (exists t,star step2 ge start t (Returnstate v Kstop m')) /\
 (forall t fin,star step2 ge start t fin -> terminal_state ge fin ->fin=Returnstate v Kstop m') /\
 (forall T,~forever step2 ge start T).
Proof.
 intros Exit Owned ge start;destruct(every_owned_entry_returns z x args m Exit Owned) as [t [v [m' Run]]].
 assert (I:star internal_step ge start t (Returnstate v Kstop m')).
 { eapply bare_internal_trace;[exact Run|]. cbn [old_state old_cont];split;[destruct x;vm_compute;reflexivity|exact Logic.I]. }
 exists v,m';split;[exists t;apply internal_path_actual;exact I|].
 split;[eapply finite_maximal_unique|eapply finite_excludes_forever];[exact I|apply returned_terminal|exact I|apply returned_terminal].
Qed.
Print Assumptions all_original_executions_return.
