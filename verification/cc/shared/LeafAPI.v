(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
Require Import level_ast VerifDetected VerifClosesBody HashLookup HashProbe VerifLookup VerifOneLeft.

Definition extent b := Zlength (keys b).
Definition leaf_answer (accept:Z->Prop) n a :=
  (a = -1 /\ forall q, 0<=q<n -> ~accept q) \/ (0<=a<n /\ accept a).
Record leaf_image (accept:Z->Prop) b v odd qs := {
  actual_bucket : bucket_path b (origin b) qs;
  tested_iff : forall q, 0<=q<extent b -> (usable b v odd q <-> accept q);
  complete_image : forall q, 0<=q<extent b -> accept q -> In q qs;
  image_range : forall q, In q qs -> 0<=q<extent b
}.

Lemma route_supplies_answer b v odd i qs : bucket_path b i qs ->
  exists a, probe_run b v odd i a.
Proof.
  intro path; induction path as [i empty|i qs pos key chain|i qs pos key more IH].
  - exists (-1); constructor;assumption.
  - destruct (chain_complete b v odd _ _ chain) as [a [picked _]].
    exists a;apply probe_found;assumption.
  - destruct IH as [a run];exists a;apply probe_next;assumption.
Qed.

Lemma checked_answer accept b v odd qs : book_safe b v odd ->
  leaf_image accept b v odd qs ->
  exists a, probe_run b v odd (origin b) a /\ leaf_answer accept (extent b) a.
Proof.
  intros safe [route eqv covers valid]. destruct (@route_supplies_answer b v odd _ _ route) as [a run].
  exists a;split;[exact run|]. destruct (Z.eq_dec a (-1)) as [miss|hit].
  - left; split;[exact miss|]. intros q range accepted.
    apply (proj1 (@exhausted_bucket b v odd _ _ _ route run) miss q (covers q range accepted)).
    apply (proj2 (eqv q range));assumption.
  - right. assert (origin_ok:0<=Int64.unsigned (origin b)<Zlength (slots b)).
    { apply within_mask; eapply table_mask_bound;eassumption. }
    pose proof (@lookup_answer_range b v odd _ _ safe run origin_ok) as ranged.
    destruct (probe_result b v odd _ _ run) as [miss|[pos tested]];[contradiction|].
    assert (rr:0<=a<extent b) by (unfold extent;lia). split;[exact rr|apply (proj1 (eqv a rr));exact tested].
Qed.

(* The caller supplies its table representation and physical accept
   predicate. The callee chooses the returned column; its precondition
   contains neither an answer nor a trace of the search for that answer. *)
Definition leaf_api (accept:Z->Prop) : ident * funspec :=
 DECLARE _closing_qubit
 WITH s:val,p:lookup_ptrs,b:lookup_data,v:close_view,odd:Z,qs:list Z
 PRE [tptr level_type]
   PROP(book_safe b v odd; leaf_image accept b v odd qs)
   PARAMS(s) SEP(close_mem Tsh s odd v; book_mem s b p)
 POST [tint] EX a:Z, PROP(leaf_answer accept (extent b) a)
   RETURN(Vint (Int.repr a)) SEP(close_mem Tsh s odd v; book_mem s b p).

Lemma leaf_refines accept : funspec_sub (snd lookup_spec) (snd (leaf_api accept)).
Proof.
  do_funspec_sub. destruct w as [[[[[s p]b]v]odd]qs]; cbn [fst snd]; normalize.
  destruct (@checked_answer accept b v odd qs ltac:(assumption) ltac:(assumption)) as [a [trace ok]].
  Exists (s,p,b,v,odd,a) emp;apply andp_right.
  - entailer!;cancel.
  - apply prop_right;intros rho';normalize;Exists a;entailer!;cancel.
Qed.
Theorem body_leaf_api accept : semax_body Vprog LookupGprog f_closing_qubit (leaf_api accept).
Proof.
  eapply semax_body_funspec_sub;[exact body_closing_qubit|apply leaf_refines|].
  vm_compute;repeat(apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.
