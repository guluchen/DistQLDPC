(* The licensed control constructs are exactly the ones occurring in the
   frozen program. A break can cross an added test, but cannot escape a root
   depth iteration. A function return unwinds back to the paired caller. *)
Require Import VST.floyd.proofauto compcert.cfrontend.Clight.
Require Import CCV.CCBoundedMain CCV.CCReplayFrames CCV.CCReplayEnvironment
 CCV.CCSearchFragments CCV.CCCapGuard CCV.CCTerminateMainLoop CCV.CCExpandedBody.
Definition atomic_control (b:bool) s :=
 match s with
 | Sskip|Sassign _ _|Sset _ _|Scall _ _ _|Sreturn _=>true
 | Sbreak=>b | _=>false end.
Inductive stmt_pair : bool -> statement -> statement -> Prop :=
 | pair_atom:forall b s,atomic_control b s=true ->stmt_pair b s s
 | pair_seq:forall b a a' c c',stmt_pair b a a' ->stmt_pair b c c' ->
   stmt_pair b (Ssequence a c) (Ssequence a' c')
 | pair_if:forall b x a a' c c',stmt_pair b a a' ->stmt_pair b c c' ->
   stmt_pair b (Sifthenelse x a c) (Sifthenelse x a' c')
 | pair_loop:forall b a a' c c',stmt_pair true a a' ->stmt_pair true c c' ->
   stmt_pair b (Sloop a c) (Sloop a' c')
 | pair_heads:forall b n,stmt_pair b (bounded_main n) search_main_loop
 | pair_cap_tail:forall b a a',stmt_pair b a a' ->stmt_pair b (Ssequence a cap_check) a'
 | pair_cap_skip:forall b,stmt_pair b cap_check Sskip
 | pair_dead_skip:forall b,stmt_pair b cap_dead Sskip.
Lemma same_statement b s : structured b s=true ->stmt_pair b s s.
Proof.
 revert b;induction s;intros b OK;cbn [structured] in OK;try discriminate;
 try solve[apply pair_atom;exact OK];apply andb_true_iff in OK as [A B];
 first [apply pair_seq|apply pair_if|apply pair_loop];auto.
Qed.
Lemma search_code_pair n:stmt_pair false (body_with (bounded_main n)) (fn_body ccv_core.f_search).
Proof.
 rewrite <-original_search_skeleton.
 unfold body_with,positive_with,tail_with,seeds_with,root_with,VerifRootFrameContinuation.root_frame_then.
 repeat first [apply pair_heads|solve[apply same_statement;reflexivity]|apply pair_seq|apply pair_loop].
Qed.
Lemma distance_code_pair : stmt_pair false (fn_body guarded_distance) (fn_body ccv_core.f_ccv_distance).
Proof.
 cbn [guarded_distance with_body fn_body ccv_core.f_ccv_distance guard_cap_loops].
 repeat first [solve[apply same_statement;reflexivity]|solve[apply pair_cap_tail;apply same_statement;reflexivity]|apply pair_seq|apply pair_loop].
Qed.
Inductive function_pair : Clight.fundef ->Clight.fundef ->Prop :=
 | paired_fn:forall f f',headers f f' ->stmt_pair false (fn_body f)(fn_body f') ->
   function_pair (Internal f) (Internal f')
 | paired_ext:forall ef ts ty cc,function_pair (External ef ts ty cc)(External ef ts ty cc).
Lemma same_fd fd:supported_fd fd=true ->function_pair fd fd.
Proof. destruct fd;intros;constructor;[apply headers_same|apply same_statement;assumption]. Qed.
Lemma paired_type fd fd':function_pair fd fd' ->type_of_fundef fd=type_of_fundef fd'.
Proof. destruct 1;simpl;[apply headers_type;assumption|reflexivity]. Qed.
Inductive paired_cont : bool ->cont->cont->Prop :=
 | pc_stop:paired_cont false Kstop Kstop
 | pc_seq:forall b a a' k k',stmt_pair b a a' ->paired_cont b k k' ->
   paired_cont b (Kseq a k) (Kseq a' k')
 | pc_loop1:forall b a a' c c' k k',stmt_pair true a a' ->stmt_pair true c c' ->
   paired_cont b k k' ->paired_cont true (Kloop1 a c k)(Kloop1 a' c' k')
 | pc_loop2:forall b a a' c c' k k',stmt_pair true a a' ->stmt_pair true c c' ->
   paired_cont b k k' ->paired_cont true (Kloop2 a c k)(Kloop2 a' c' k')
 | pc_call:forall b dst f f' e l k k',headers f f' ->paired_cont b k k' ->
   paired_cont false (Kcall dst f e l k)(Kcall dst f' e l k')
 | pc_back:forall b n k k',paired_cont b k k' ->
   paired_cont false (Kseq (bounded_main n) k)(main_iteration_cont k')
 | pc_cap:forall b k k',paired_cont b k k' ->paired_cont b (Kseq cap_check k) k'.
Lemma pc_unwind b k k':paired_cont b k k' ->paired_cont false (call_cont k)(call_cont k').
Proof. induction 1;simpl;try assumption;eauto using paired_cont. Qed.
Lemma pc_final b k k':paired_cont b k k' ->is_call_cont k ->is_call_cont k'.
Proof. destruct 1;simpl;intuition. Qed.
Inductive paired_state:Clight.state->Clight.state->Prop :=
 | ps_stmt:forall b f f' s s' k k' e l m,headers f f' ->stmt_pair b s s' ->paired_cont b k k' ->
   paired_state (State f s k e l m)(State f' s' k' e l m)
 | ps_enter:forall b f f' n k k' e l m,headers f f' ->paired_cont b k k' ->
   paired_state (State f (Ssequence search_main_iteration (bounded_main n)) k e l m)
    (State f' search_main_iteration (main_iteration_cont k') e l m)
 | ps_in:forall fd fd' args k k' m,function_pair fd fd' ->paired_cont false k k' ->
   paired_state (Callstate fd args k m)(Callstate fd' args k' m)
 | ps_out:forall v k k' m,paired_cont false k k' ->
   paired_state (Returnstate v k m)(Returnstate v k' m).
Lemma ps_stop v m st:paired_state (Returnstate v Kstop m) st ->st=Returnstate v Kstop m.
Proof. inversion 1;subst;match goal with H:paired_cont _ Kstop _ |- _=>inversion H;reflexivity end. Qed.
