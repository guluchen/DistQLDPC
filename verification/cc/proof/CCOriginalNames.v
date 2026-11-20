(* A static certificate for dropping the verification-only main definition.
   Every C call names an internal library function and every addressable
   local is a word. No instruction reads the symbol introduced by the stub. *)
Require Import VST.floyd.proofauto compcert.cfrontend.Clight compcert.lib.Maps.
Require Import CCV.CCLinkedProgram CCV.CCVerificationDriver.
Import ListNotations. Open Scope bool_scope.
Definition target_name i :=
 match PTree.get i (AST.prog_defmap linked_prog) with Some(Gfun(Internal _))=>true|_=>false end.
Fixpoint old_expr x :=
 match x with
 | Evar i _=>negb(Pos.eqb i driver_id)
 | Ederef a _|Eaddrof a _|Eunop _ a _|Ecast a _|Efield a _ _=>old_expr a
 | Ebinop _ a b _=>old_expr a && old_expr b
 | _=>true end.
Definition direct_target x :=
 match x with Evar i (Tfunction _ _ _)=>old_expr x && target_name i|_=>false end.
Fixpoint old_stmt s :=
 match s with
 | Sskip|Sbreak|Sreturn None=>true
 | Sreturn(Some a)|Sset _ a=>old_expr a
 | Sassign a b=> old_expr a && old_expr b
 | Scall _ a xs=>direct_target a && forallb old_expr xs
 | Ssequence a b|Sloop a b=>old_stmt a && old_stmt b
 | Sifthenelse x a b =>old_expr x && (old_stmt a && old_stmt b)
 | _=>false end.
Definition old_fn f :=old_stmt (fn_body f) &&
 forallb (fun pair:ident*type=>if type_eq (snd pair) tuint then true else false) (fn_vars f).
Definition old_definition (d:ident*globdef Clight.fundef type) :=
 match snd d with Gfun(Internal f)=>old_fn f|_=>true end.
Lemma all_original_names:forallb old_definition (prog_defs linked_prog)=true.
Proof. vm_compute;reflexivity. Qed.
Local Opaque linked_prog target_name.
Lemma original_function_code v f:Genv.find_funct (globalenv linked_prog) v=Some(Internal f) ->old_fn f=true.
Proof.
 intro Found;apply Genv.find_funct_inversion in Found as [i InList].
 exact ((proj1 (forallb_forall _ _) all_original_names) (i,Gfun(Internal f)) InList).
Qed.
Lemma same_old_address i: i<>driver_id ->Genv.find_symbol (Genv.globalenv driver_prog) i=Genv.find_symbol (Genv.globalenv linked_prog) i.
Proof.
 intro Diff;rewrite driver_global_extension;unfold Genv.find_symbol.
 cbn [Genv.add_global Genv.genv_symb fst driver_def];apply PTree.gso;assumption.
Qed.
Local Opaque linked_prog.
Section Restricted.
Variables src dst:Clight.genv.
Hypothesis Layouts:genv_cenv src=genv_cenv dst.
Hypothesis Symbols:forall i,i<>driver_id ->Genv.find_symbol src i=Genv.find_symbol dst i.
Lemma restricted_evals e l m:
 (forall a v,eval_expr src e l m a v ->old_expr a=true ->eval_expr dst e l m a v) /\
 (forall a b o bf,eval_lvalue src e l m a b o bf ->old_expr a=true ->eval_lvalue dst e l m a b o bf).
Proof.
 apply eval_expr_lvalue_ind;intros;cbn [old_expr] in *;
 repeat match goal with H:_ && _=true |- _=>apply andb_true_iff in H as [? ?] end;
 try rewrite Layouts in *;
 first [solve [econstructor;eauto]|
  eapply eval_Evar_global;[eassumption|rewrite <-Symbols;[assumption|apply Pos.eqb_neq;apply negb_true_iff;assumption]]].
Qed.
Lemma restricted_args e l m xs ts vs:eval_exprlist src e l m xs ts vs ->
 forallb old_expr xs=true ->eval_exprlist dst e l m xs ts vs.
Proof.
 induction 1;intro Clean;[apply eval_Enil|].
 apply andb_true_iff in Clean as [A Tail];eapply eval_Econs;[apply (proj1(restricted_evals _ _ _));eassumption|eassumption|auto].
Qed.
End Restricted.
Local Notation src:=(globalenv driver_prog).
Local Notation dst:=(globalenv linked_prog).
Lemma old_evaluations e l m:
 (forall a v,eval_expr src e l m a v ->old_expr a=true ->eval_expr dst e l m a v) /\
 (forall a b o bf,eval_lvalue src e l m a b o bf ->old_expr a=true ->eval_lvalue dst e l m a b o bf).
Proof.
 apply (restricted_evals src dst);[unfold Clight.globalenv;cbn [genv_cenv];unfold driver_prog;reflexivity|apply same_old_address].
Qed.
Lemma old_arguments e l m xs ts vs:eval_exprlist src e l m xs ts vs ->
 forallb old_expr xs=true ->eval_exprlist dst e l m xs ts vs.
Proof.
 apply (restricted_args src dst);[unfold Clight.globalenv;cbn [genv_cenv];unfold driver_prog;reflexivity|apply same_old_address].
Qed.
