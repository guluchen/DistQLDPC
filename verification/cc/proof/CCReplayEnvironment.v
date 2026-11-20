(* Clight expression evaluation observes composite layouts and symbol
   addresses. It cannot observe the statements in a function body. *)
Require Import VST.floyd.proofauto compcert.cfrontend.Clight compcert.lib.Maps.
Require Import CCV.CCExpandedBody CCV.CCBodyProgram CCV.CCVerificationDriver.
Section Environment.
Variables src dst:Clight.genv.
Hypothesis layout:genv_cenv src=genv_cenv dst.
Hypothesis symbols:forall i,Genv.find_symbol src i=Genv.find_symbol dst i.
Lemma replay_evaluations e l m :
 (forall a v,eval_expr src e l m a v ->eval_expr dst e l m a v) /\
 (forall a b o bf,eval_lvalue src e l m a b o bf ->eval_lvalue dst e l m a b o bf).
Proof.
 apply eval_expr_lvalue_ind;intros;try rewrite layout in *;
 first [solve [econstructor;eassumption] | solve [econstructor;eauto using eq_trans]
       | solve [eapply eval_Evar_global;[eassumption|rewrite <-symbols;assumption]]].
Qed.
Lemma replay_arguments e l m args ts vs :
 eval_exprlist src e l m args ts vs ->eval_exprlist dst e l m args ts vs.
Proof.
 induction 1;[apply eval_Enil|eapply eval_Econs;[eapply(proj1(replay_evaluations _ _ _))| |];eassumption].
Qed.
Lemma replay_alloc e m vs e' m' : alloc_variables src e m vs e' m' ->alloc_variables dst e m vs e' m'.
Proof. induction 1;[constructor|econstructor;[rewrite <-layout|];eassumption]. Qed.
End Environment.
Definition headers f f' := fn_return f=fn_return f' /\ fn_callconv f=fn_callconv f' /\
 fn_params f=fn_params f' /\ fn_vars f=fn_vars f' /\ fn_temps f=fn_temps f'.
Lemma headers_same f : headers f f. Proof. repeat split. Qed.
Lemma headers_body f s : headers (with_body f s) f. Proof. repeat split. Qed.
Lemma replay_entry src dst f f' args m e l m' : genv_cenv src=genv_cenv dst ->
 headers f f' ->function_entry2 src f args m e l m' ->function_entry2 dst f' args m e l m'.
Proof.
 intros Layout [_ [_ [Params [Vars Temps]]]] E;inversion E;subst.
 constructor;rewrite <-?Vars,<-?Params,<-?Temps;try assumption;eapply replay_alloc;eassumption.
Qed.
Lemma headers_type f f':headers f f' ->type_of_function f=type_of_function f'.
Proof. intros [R [CC [P _]]];unfold type_of_function;rewrite R,CC,P;reflexivity. Qed.
Lemma body_layout s d p : genv_cenv (globalenv (body_program s d p))=genv_cenv(globalenv p).
Proof. reflexivity. Qed.
Lemma body_addresses s d p i : Genv.find_symbol (globalenv (body_program s d p)) i =
 Genv.find_symbol (globalenv p) i.
Proof.
 let triv:=constr:(fun _ _:globdef Clight.fundef type=>True) in
 assert (G:Genv.match_genvs triv (Genv.globalenv (body_program s d p)) (Genv.globalenv p)).
 { unfold Genv.globalenv.
   apply Genv.add_globals_match.
   - change (list_forall2 (fun x y=>fst x=fst y /\ True) (map (replace_def s d) (prog_defs p)) (prog_defs p)).
     generalize (prog_defs p);intro defs;induction defs as [|[id gd] defs IH];[apply list_forall2_nil|apply list_forall2_cons;[split;[reflexivity|exact I]|exact IH]].
   - constructor;intros;try reflexivity;unfold Genv.empty_genv;cbn;rewrite !PTree.gempty;constructor. }
 symmetry;exact (Genv.mge_symb G i).
Qed.
