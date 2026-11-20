(* Phase-sensitive path invariant matching the C stack protocol.
   This is not yet a refinement proof of the complete Clight while loop. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache.
Import ListNotations.
Definition path_bits (path:list nat) : vector :=fun q=>existsb(Nat.eqb q) path.
Lemma path_bits_true path q : path_bits path q=true <->In q path.
Proof.
 unfold path_bits;rewrite existsb_exists;split.
 - intros [r [R E]];apply Nat.eqb_eq in E;subst;assumption.
 - intros R;exists q;split;[assumption|apply Nat.eqb_refl].
Qed.
Lemma path_bits_false path q : path_bits path q=false <->~In q path.
Proof.
 split;intros H.
 - intros R;apply path_bits_true in R;congruence.
 - destruct(path_bits path q)eqn:E;[apply path_bits_true in E;contradiction|reflexivity].
Qed.
Lemma path_bits_append path q i : path_bits(path++[q])i=setbit(path_bits path)q i.
Proof.
 unfold path_bits,setbit;rewrite existsb_app;simpl;rewrite orb_false_r.
 destruct(Nat.eqb i q);simpl;[apply orb_true_r|apply orb_false_r].
Qed.
Lemma path_push_flip path q : ~In q path ->forall i,
 flip(path_bits path)q i=path_bits(path++[q])i.
Proof.
 intros Fresh i;unfold flip;rewrite path_bits_append;unfold setbit;destruct(Nat.eqb i q)eqn:E;[|reflexivity].
 apply Nat.eqb_eq in E;subst i;apply path_bits_false in Fresh;rewrite Fresh;reflexivity.
Qed.
Lemma path_pop_flip path q : ~In q path ->forall i,
 flip(path_bits(path++[q]))q i=path_bits path i.
Proof.
 intros Fresh i;unfold flip;rewrite path_bits_append;unfold setbit;destruct(Nat.eqb i q)eqn:E;[|reflexivity].
 apply Nat.eqb_eq in E;subst i;apply path_bits_false in Fresh;rewrite Fresh;reflexivity.
Qed.
Lemma path_nodup_snoc (rows:list nat) q : NoDup rows ->~In q rows ->NoDup(rows++[q]).
Proof.
 intros ND;induction ND as [|r rows Not ND IH];intros Fresh;simpl.
 - constructor;[simpl;tauto|constructor].
 - constructor.
   + intro Hin;apply in_app_or in Hin;destruct Hin as [Hin|[E|[]]];[contradiction|subst;apply Fresh;left;reflexivity].
   + apply IH;intro Hin;apply Fresh;right;assumption.
Qed.
Lemma path_nodup_snoc_inv (path:list nat) q : NoDup(path++[q]) ->NoDup path /\~In q path.
Proof.
 induction path as [|a path IH];intros ND;simpl in *.
 - split;[constructor|tauto].
 - inversion ND as [|b tail Not Tail];subst b tail.
   destruct(IH Tail)as [Rest Fresh];split.
   + constructor;[intro Hin;apply Not;apply in_or_app;left;assumption|assumption].
   + intros [E|Hin];[subst a;apply Not;apply in_or_app;right;simpl;auto|contradiction].
Qed.
Lemma path_weight n path : NoDup path ->Forall(fun q=>q<n)path ->weight n(path_bits path)=length path.
Proof.
 intros ND;induction ND as [|q path Fresh ND IH];intros Range.
 - clear Range;unfold path_bits;simpl;induction n;simpl;lia.
 - inversion Range as [|q' path' Q Tail];subst q' path'.
   assert(Equal:forall i,i<n ->path_bits(q::path)i=setbit(path_bits path)q i).
   { intros;unfold path_bits,setbit;simpl;destruct(Nat.eqb i q);reflexivity. }
   rewrite(weight_ext n _ _ Equal),setbit_weight by(auto;apply path_bits_false;assumption).
   rewrite IH by assumption;simpl;lia.
Qed.
Definition phase_path n depth phase chosen path (selected:vector) :=
 NoDup path /\Forall(fun q=>q<n)path /\length path=depth /\
 match phase with
 |0|1=>forall i,i<n ->selected i=path_bits path i
 |2=>chosen<n /\~In chosen path /\forall i,i<n ->selected i=path_bits(path++[chosen])i
 |_=>False end.
Theorem phase_path_weight n depth phase chosen path selected :
 phase_path n depth phase chosen path selected ->
 (phase=0 \/ phase=1 ->weight n selected=depth) /\
 (phase=2 ->weight n selected=depth+1).
Proof.
 intros [ND [Range [Len State]]];split.
 - intros [-> | ->];rewrite(weight_ext n selected(path_bits path) State),path_weight by assumption;assumption.
 - intros ->;destruct State as [Q [Fresh Eq]].
   rewrite(weight_ext n selected(path_bits(path++[chosen])) Eq).
   assert(ExtND:NoDup(path++[chosen])).
   { apply path_nodup_snoc;assumption. }
   assert(ExtRange:Forall(fun i=>i<n)(path++[chosen])).
   { apply Forall_app;split;[assumption|constructor;auto]. }
   rewrite(path_weight n (path++[chosen]) ExtND ExtRange).
   rewrite app_length;simpl;lia.
Qed.
Theorem phase_push n depth chosen path selected q :
 phase_path n depth 1 chosen path selected ->q<n ->selected q=false ->
 phase_path n (depth+1) 0 0 (path++[q])(flip selected q).
Proof.
 intros [ND [Range [Len Eq]]] Q S.
 assert(Fresh:~In q path) by(apply path_bits_false;rewrite <-Eq by assumption;assumption).
 unfold phase_path;split.
 - apply path_nodup_snoc;assumption.
 - split;[apply Forall_app;split;[assumption|constructor;auto]|].
   split;[rewrite app_length;simpl;lia|].
   intros i I;rewrite <- (path_push_flip path q Fresh i);unfold flip;rewrite Eq by assumption;reflexivity.
Qed.
Theorem phase_child_finish n depth chosen path q selected :
 phase_path n (depth+1) 0 chosen (path++[q]) selected ->
 phase_path n depth 2 q path selected.
Proof.
 intros [ND [Range [Len Eq]]];apply path_nodup_snoc_inv in ND;destruct ND as [ND Fresh].
 apply Forall_app in Range;destruct Range as [Range Last];inversion Last as [|x xs Q Rest];subst x xs.
 unfold phase_path;repeat split;try assumption.
 - rewrite app_length in Len;simpl in Len;lia.
Qed.
Theorem phase_pending_undo n depth q path selected :
 phase_path n depth 2 q path selected ->
 phase_path n depth 1 0 path (flip selected q).
Proof.
 intros [ND [Range [Len [Q [Fresh Eq]]]]];unfold phase_path;repeat split;try assumption.
 intros i I;rewrite <- (path_pop_flip path q Fresh i);unfold flip;rewrite Eq by assumption;reflexivity.
Qed.
Theorem phase_root n seed : seed<n ->phase_path n 1 0 0 [seed](path_bits[seed]).
Proof. intros Q;unfold phase_path;split.
 - constructor;[simpl;tauto|constructor].
 - split;[constructor;[assumption|constructor]|].
   split;[reflexivity|intros;reflexivity].
Qed.
Theorem phase_active_minimum_has_odd n hs ls e depth phase chosen path selected :
 phase_path n depth phase chosen path selected ->(phase=0 \/phase=1) ->
 minimum n hs ls e ->subset n selected e ->0<depth ->depth<weight n e ->
 exists h,In h hs /\parity n h selected=true.
Proof.
 intros State Phase Min Sub Pos Less;pose proof(proj1(phase_path_weight _ _ _ _ _ _ State) Phase) as W.
 apply(minimum_prefix_has_odd_row n hs ls e selected);auto;lia.
Qed.
Print Assumptions phase_path_weight.
Print Assumptions phase_push.
Print Assumptions phase_child_finish.
Print Assumptions phase_pending_undo.
Print Assumptions phase_active_minimum_has_odd.
Lemma path_length_bound n path : NoDup path ->Forall(fun q=>q<n)path ->length path<=n.
Proof.
 intros ND Range;assert(Incl:incl path(seq 0 n)).
 { intros q Hin;apply in_seq;split;[lia|apply Forall_forall with(x:=q)in Range;assumption]. }
 pose proof(NoDup_incl_length ND Incl)as Bound;rewrite seq_length in Bound;assumption.
Qed.
Theorem phase_push_frame_capacity n depth chosen path selected q :
 phase_path n depth 1 chosen path selected ->q<n ->selected q=false ->depth<n.
Proof.
 intros State Q Free;pose proof(phase_push n depth chosen path selected q State Q Free)as Child.
 destruct Child as [ND [Range [Len Other]]];pose proof(path_length_bound n(path++[q])ND Range);lia.
Qed.
Print Assumptions phase_push_frame_capacity.
