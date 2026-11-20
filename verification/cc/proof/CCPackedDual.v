(* Carry a lower bound across Pauli halves only after verifying an isometry.
   The image rows are serialized in permutation order in one list traversal. *)
From Coq Require Import List Bool Arith Lia.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCSSBridge CCV.CCPCMDetectors
 CCV.CCQuotientCertificate CCV.CCOrbit CCV.CCPackedWords CCV.CCPackedLayout
 CCV.CCPackedOrbit.
Import ListNotations. Local Open Scope nat_scope.

Definition maps_into n (p:list nat) source (targets:list vector) :=
  let b:=build_basis n (map (packv n) source) [] in
  forallb (fun r=>is_empty (reduce b (encode(map r p)))) targets.

Lemma maps_into_sound n p source targets : n<=189 ->length p=n ->
  maps_into n p source targets=true ->
  forall r, In r targets ->forall e,kernel n source e ->parity n (perm_vector n p r) e=false.
Proof.
  intros N Len;unfold maps_into;set (b:=build_basis _ _ _).
  assert (B:basis_ok n source b).
  { unfold b;apply build_basis_ok;[|constructor].
    apply Forall_forall;intros x InX;apply in_map_iff in InX as [r [<- I]];intros e K.
    rewrite packv_parity by exact N;apply K;exact I. }
  rewrite forallb_forall;intros All r InR e K;specialize(All r InR);apply empty_none in All.
  rewrite <-(tab_perm n p r Len) in All.
  change (reduce b (packv n (perm_vector n p r))=none) in All.
  pose proof(reduce_parity n source b (packv n (perm_vector n p r)) e B K) as E.
  rewrite All,packv_parity in E by exact N.
  rewrite <-E;unfold packed_parity;rewrite qcert_parity_comm.
  rewrite (parity_ext n e (decode none) zero_vector) by (intros;apply decode_none).
  rewrite qcert_parity_comm;apply qcert_zero_dot.
Qed.

Definition dual_check n hx lx hz lz p inv :=
  (n<=?189) && indices_ok n p inv && maps_into n inv hz hx && maps_into n p lx lz.
Theorem dual_transports n hx lx hz lz p inv :
  dual_check n hx lx hz lz p inv=true ->
  forall e,good n hz lz e ->good n hx lx (perm_vector n p e) /\
                            weight n (perm_vector n p e)=weight n e.
Proof.
  unfold dual_check;rewrite !andb_true_iff,Nat.leb_le;intros [[[N Idx] H] L].
  destruct(inverse_checked n p inv Idx) as [P Inv].
  assert (LP:length p=n /\length inv=n).
  { unfold indices_ok in Idx;rewrite !andb_true_iff,!Nat.eqb_eq in Idx;tauto. }
  pose proof (maps_into_sound n inv hz hx N (proj2 LP) H) as Hs.
  pose proof (maps_into_sound n p lx lz N (proj1 LP) L) as Ls.
  intros e [Pos [K [l [Lin Odd]]]];rewrite orbit_weight by exact P;split;[|reflexivity].
  split;[rewrite orbit_weight by exact P;assumption|];split.
  - intros h Hin;pose proof(Hs h Hin e K) as Z.
    rewrite <-(orbit_parity n p (perm_vector n inv h) e P) in Z.
    rewrite qcert_parity_comm in Z |- *;erewrite parity_ext in Z;[exact Z|].
    intros i I;unfold perm_vector;now rewrite Inv.
  - destruct(existsb(fun r=>parity n r (perm_vector n p e)) lx) eqn:Hit.
    + apply existsb_exists in Hit;exact Hit.
    + exfalso;pose proof(existsb_parity_false n lx _ Hit) as Neutral.
      pose proof(Ls l Lin _ Neutral) as Z;rewrite orbit_parity,Odd in Z by exact P;discriminate.
Qed.
