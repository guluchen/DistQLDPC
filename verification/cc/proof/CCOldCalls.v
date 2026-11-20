(* A successful direct call in the verification harness resolves to the
   same original internal function at the same block in the bare library. *)
Require Import VST.floyd.proofauto compcert.cfrontend.Clight compcert.lib.Maps.
Require Import CCV.CCOriginalNames CCV.CCLinkedProgram CCV.CCVerificationDriver
 CCV.CCIterationScans CCV.CCReplayEnvironment.
Import ListNotations.
Local Notation src:=(Clight.globalenv driver_prog).
Local Notation dst:=(Clight.globalenv linked_prog).
Definition words_env (e:Clight.env) := forall id b t,PTree.get id e=Some(b,t) ->t=tuint.
Lemma word_alloc ge vs e m e' m' :alloc_variables ge e m vs e' m' ->words_env e ->
 Forall (fun pair:ident*type=>snd pair=tuint) vs ->words_env e'.
Proof.
 induction 1;intros Env Vars;[exact Env|];inversion Vars;subst;apply IHalloc_variables;try assumption.
 intros i b t Get;rewrite PTree.gsspec in Get;destruct(peq i id);[inversion Get;subst;assumption|eapply Env;eassumption].
Qed.
Lemma word_entry f args m e l m':old_fn f=true ->function_entry2 src f args m e l m' ->words_env e.
Proof.
 intros Code Entry;apply andb_true_iff in Code as [_ Vars];inversion Entry;subst.
 eapply word_alloc;[eassumption|intros i b t;rewrite PTree.gempty;discriminate|].
 apply Forall_forall;intros [id t] Member;
 apply (proj1(forallb_forall _ _) Vars) in Member;cbn in Member;destruct(type_eq t tuint);intuition discriminate.
Qed.
Lemma direct_address (g:Clight.genv) e l m i ts ret cc v:words_env e ->
 eval_expr g e l m (Evar i (Tfunction ts ret cc)) v ->
 exists b,v=Vptr b Ptrofs.zero /\ Genv.find_symbol g i=Some b.
Proof.
 intros Words Ev;inversion Ev;subst;
 match goal with H:eval_lvalue _ _ _ _ (Evar _ _) _ _ _ |- _=>inversion H;subst end.
 - match goal with H:PTree.get _ e=Some(_,_) |- _=>pose proof(Words _ _ _ H);discriminate end.
 - match goal with D:deref_loc _ _ _ _ _ _ |- _=>inversion D;subst;try discriminate end;eauto.
Qed.
Local Opaque linked_prog driver_prog.

Lemma target_resolution e l m a v fd:words_env e ->direct_target a=true ->eval_expr src e l m a v ->
 Genv.find_funct src v=Some fd ->Genv.find_funct dst v=Some fd /\ exists f,fd=Internal f /\ old_fn f=true.
Proof.
 intros Words Direct Ev Found;destruct a;try discriminate;
 match goal with ty:type |- _=>destruct ty;try discriminate end.
 apply andb_true_iff in Direct as [Name Target].
 match type of Ev with eval_expr _ _ _ _ (Evar ?i (Tfunction ?ts ?r ?cc)) _=>
 destruct(direct_address _ _ _ _ i ts r cc _ Words Ev) as [b [-> Addr]];
 assert(Diff:i<>driver_id) by (apply Pos.eqb_neq;apply negb_true_iff;exact Name);
 rewrite same_old_address in Addr by assumption;unfold target_name in Target;
 destruct(PTree.get i (AST.prog_defmap linked_prog)) as [[fd'|gv]|] eqn:Def;try discriminate;destruct fd' as [f|];try discriminate;
 destruct (proj1 (Genv.find_def_symbol linked_prog i _) Def) as [b' [Addr' D]] end.
 assert(b'=b)by congruence;subst b'.
 apply Genv.find_funct_ptr_iff in D.
 pose proof(driver_keeps_functions b)as Keeps;rewrite D in Keeps.
 rewrite Genv.find_funct_find_funct_ptr in Found;change(Genv.find_funct_ptr (Genv.globalenv driver_prog) b=Some fd)in Found;rewrite Found in Keeps;
 cbn [sub_option] in Keeps;assert(Eq:fd=Internal f) by congruence;subst fd.
 split;[rewrite Genv.find_funct_find_funct_ptr;exact D|].
 exists f;split;[reflexivity|eapply original_function_code;rewrite Genv.find_funct_find_funct_ptr;exact D].
Qed.
