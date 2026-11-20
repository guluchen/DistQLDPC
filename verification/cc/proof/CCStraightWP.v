(* Operational weakest precondition for a loop-free ordinary fragment. A
   defined primitive step must establish its postcondition. Undefined
   operations keep the explicit blocked alternative of the structured rules. *)
Require Import VST.floyd.proofauto compcert.cfrontend.Clight CCV.CCStructuredRuns.
Section Straight.
Variables (ge:Clight.genv) (f:Clight.function) (e:Clight.env).
Fixpoint straight_wp (s:statement) (N B:configuration) : configuration :=
 match s with
 | Sskip=>N | Sbreak=>B
 | Sreturn _=>fun _ _=>True
 | Sset id a=>fun l m=>forall v,eval_expr ge e l m a v -> N (Maps.PTree.set id v l) m
 | Sassign a v=>fun l m=>forall m' t k,
    step2 ge (State f (Sassign a v) k e l m) t (State f Sskip k e l m') -> N l m'
 | Ssequence a b=>straight_wp a (straight_wp b N B) B
 | Sifthenelse c y n=>fun l m=>
    (takes ge e l m c true -> straight_wp y N B l m) /\
    (takes ge e l m c false -> straight_wp n N B l m)
 | _=>fun _ _=>False
 end.
Lemma straight_wp_runs s : forall N B,runs ge f e s (straight_wp s N B) N B.
Proof.
 induction s using statement_ind;intros N B;cbn [straight_wp];
 try solve[unfold runs;intros;contradiction].
 - apply runs_skip.
 - apply runs_assign;intros l m m2 t k W T;exact (W m2 t k T).
 - apply runs_set;intros l m v W T;exact (W v T).
 - eapply runs_seq;[apply IHs1|apply IHs2].
 - apply runs_if.
   + eapply runs_consequence;[|exact (IHs1 N B)| |];[intros l m [[Y F] T];exact (Y T)|intros;assumption|intros;assumption].
   + eapply runs_consequence;[|exact (IHs2 N B)| |];[intros l m [[Y F] T];exact (F T)|intros;assumption|intros;assumption].
 - apply runs_break.
 - apply runs_return.
Qed.
End Straight.
