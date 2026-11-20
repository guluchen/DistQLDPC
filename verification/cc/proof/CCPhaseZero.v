(* Why a critical minimum-target phase-0 frame cannot silently finish.
   Pure obligations to instantiate at C branches; not a C loop body proof. *)
From Coq Require Import Bool List Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCache CCV.CCSingleExtension.
Lemma minimum_prefix_weight_bound n hs ls e s :
 minimum n hs ls e ->subset n s e ->weight n s<=weight n e.
Proof. intros Min Sub;pose proof(subset_split n s e Sub);lia. Qed.
Theorem minimum_prefix_kernel_closes n hs ls e s :
 minimum n hs ls e ->subset n s e ->0<weight n s ->kernel n hs s ->
 good n hs ls s /\weight n s=weight n e.
Proof.
 intros Min Sub Pos Ker.
 pose proof(minimum_prefix_weight_bound n hs ls e s Min Sub)as Bound.
 assert(Equal:weight n s=weight n e).
 { destruct(Nat.eq_dec(weight n s)(weight n e))as[Eq|Ne];[assumption|].
   destruct(minimum_prefix_has_odd_row n hs ls e s Min Sub Pos ltac:(lia))as[h[Member Odd]].
   pose proof(Ker h Member);congruence. }
 split;[apply(good_subset_equal_weight n hs ls e s (proj1 Min)Sub Equal)|assumption].
Qed.
Theorem unfinished_prefix_is_proper n hs ls e s :
 minimum n hs ls e ->subset n s e ->~good n hs ls s ->weight n s<weight n e.
Proof.
 intros Min Sub Unfinished.
 pose proof(minimum_prefix_weight_bound n hs ls e s Min Sub)as Bound.
 destruct(Nat.eq_dec(weight n s)(weight n e))as[Eq|Ne];[|lia].
 exfalso;apply Unfinished;apply(good_subset_equal_weight n hs ls e s (proj1 Min)Sub Eq).
Qed.
Theorem critical_phase_zero_has_room n hs ls e s f cap :
 minimum n hs ls e ->compatible n e s f ->0<weight n s ->
 weight n e<=cap ->~good n hs ls s ->
 weight n s<cap /\exists h,In h hs /\parity n h s=true.
Proof.
 intros Min Compat Pos Cap Unfinished.
 pose proof(unfinished_prefix_is_proper n hs ls e s Min (proj1 Compat)Unfinished)as Proper.
 split;[lia|apply(minimum_prefix_has_odd_row n hs ls e s);try assumption;exact(proj1 Compat)].
Qed.
Theorem critical_single_remaining_completes n hs ls e s f cap :
 minimum n hs ls e ->compatible n e s f ->~good n hs ls s ->
 weight n e<=cap ->cap=weight n s+1 ->
 exists q,q<n /\s q=false /\f q=false /\e q=true /\
 (forall i,i<n ->e i=flip s q i) /\good n hs ls(flip s q).
Proof.
 intros Min Compat Unfinished Cap One.
 pose proof(unfinished_prefix_is_proper n hs ls e s Min (proj1 Compat)Unfinished)as Proper.
 assert(Eq:weight n e=weight n s+1)by lia.
 destruct(single_extension_avoids n s e f Compat Eq)as[q[Q[S[F[E Same]]]]].
 exists q;split;[assumption|split;[assumption|split;[assumption|split;[assumption|split;[assumption|]]]]].
 destruct(good_ext n hs ls e(flip s q)ltac:(intros i I;symmetry;apply Same;assumption)(proj1 Min))as[G W].
 assumption.
Qed.
Print Assumptions minimum_prefix_kernel_closes.
Print Assumptions critical_phase_zero_has_room.
Print Assumptions critical_single_remaining_completes.
