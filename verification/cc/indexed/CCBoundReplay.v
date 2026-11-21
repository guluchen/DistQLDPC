(* A proposed pure witness is accepted only after checked bounded C queries. *)
Require Import VST.floyd.proofauto.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCSSBridge CCV.CCCSSResultBridge
 CCV.CCRepresentation CCV.CCSearchSpecs CCV.CCPCMInput CCV.CCRawCSS CCV.CCPCMPair
 CCV.CCPCMFast CCV.CCPCMDetectors CCV.CCPCMAnswer CCV.CCPackedAnswer
 CCV.CCOrbit CCV.CCPackedOrbit CCRawDual.
Import ListNotations. Local Open Scope nat_scope. Local Open Scope bool_scope.

Definition replay_word (ws:list bool) : vector := fun i => nth i ws false.
Definition replay_cap n ws := Nat.pred (weight n (replay_word ws)).
Definition replay_upper n ax az (side:bool) ws :=
 let a := if side then ax else az in
 (length ws =? n) && witness_test n (sliced_h a) (sliced_l a) (replay_word ws).

Definition replay_report n ax az (side:bool) ws (rx rz:Z) :=
 if replay_upper n ax az side ws && Z.eqb rx 0 && Z.eqb rz 0 then
 Some (serialize_pair n (if side then found(replay_word ws,zero_vector)
                         else found(zero_vector,replay_word ws))) else None.

Lemma empty_cap q a cap out : prepare_pcm_half q=Some a ->
 query_result a (Z.of_nat cap) 0 out -> forall e,
 css_logical (Z.to_nat(width q)) (check_rows q) (same_rows q) e ->
 cap<weight (Z.to_nat(width q)) e.
Proof.
 intros P Q. destruct(prepare_pcm_contract q a P)as[_ [C _]].
 pose proof(query_result_is_css _ _ _ _ _ C Q)as H.
 destruct H as [[F _]|[[_ [_ B]]|[F _]]]; try discriminate.
 apply prep_components in P as [_ [_ [_ ->]]];intros e E.
 apply Nat2Z.inj_lt;exact (B e E).
Qed.

(* When an involution is certified on the original rows, an EMPTY query for
   X gives the very same lower bound for Z. The C adviser supplies neither
   an EMPTY result nor the statement that the matrices are dual. *)
Definition paired_lowers q ax az cap (rx rz:Z) ox oz :=
 query_result ax (Z.of_nat cap) rx ox /\
 (query_result az (Z.of_nat cap) rz oz \/
   (rz=rx /\exists p a b, raw_dual_check q p a b=true)).

Theorem replay_exact q ax az side ws rx rz ox oz ans :
 prepare_pcm_half q=Some ax -> prepare_pcm_half(swap_half q)=Some az ->
 paired_lowers q ax az (replay_cap (Z.to_nat(width q)) ws) rx rz ox oz ->
 replay_report (Z.to_nat(width q)) ax az side ws rx rz=Some ans ->
 let n:=Z.to_nat(width q) in let hx:=same_rows q in let hz:=check_rows q in
 match ans with
 | Exact d bx bz =>exists x z,bx=tabulate n x /\ bz=tabulate n z /\ mixed_logical n hx hz x z /\
   d=mixed_weight n x z /\ forall u v,mixed_logical n hx hz u v->d<=mixed_weight n u v
 | _=>False end.
Proof.
 intros X Z [Qx Qz] R n hx hz. unfold replay_report in R;fold n in R.
 destruct (replay_upper n ax az side ws && Z.eqb rx 0 && Z.eqb rz 0)%bool eqn:B;try discriminate.
 rewrite !andb_true_iff,!Z.eqb_eq in B;destruct B as [[U ->] ->].
 pose proof(empty_cap _ _ _ _ X Qx) as LX;fold n hx hz in LX.
 assert(LZ:forall e,css_logical n hx hz e->replay_cap n ws<weight n e).
 { destruct Qz as [D|[_ [p [a [b Gate]]]]].
   - apply(empty_cap (swap_half q) az _ oz Z D).
   - destruct(check_facts _ _ _ _ Gate)as[P [Inv [A B]]].
     intros e E. pose proof(raw_transport n p hx hz) as Tr.
     specialize(Tr e P Inv A B E). specialize(LX _ Tr).
     rewrite orbit_weight in LX by exact P;exact LX. }
 assert(Min:forall u v,mixed_logical n hx hz u v->weight n(replay_word ws)<=mixed_weight n u v).
 { intros u v [Ku [Kv [Nu|Nv]]];destruct(weight_union n u v)as[Wu Wv];
   [specialize(LX u (conj Ku Nu))|specialize(LZ v (conj Kv Nv))];unfold replay_cap in *;lia. }
 unfold replay_upper in U;apply andb_true_iff in U as [_ U].
 destruct side;inversion R;subst ans;cbn in U;apply witness_test_sound in U.
 - apply (proj1(prepared_good q ax X _)) in U as [K NS].
   exists (replay_word ws),zero_vector;repeat split;try reflexivity;try assumption;try apply zero_kernel;
     try(left;exact NS);rewrite(proj1(pure_weights _ _));exact Min.
 - apply (proj1(prepared_good (swap_half q) az Z _)) in U as [K NS].
   exists zero_vector,(replay_word ws);repeat split;try reflexivity;try assumption;try apply zero_kernel;
     try(right;exact NS);rewrite(proj2(pure_weights _ _));exact Min.
Qed.
Print Assumptions replay_exact.
