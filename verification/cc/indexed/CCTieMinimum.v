(* SPDX-License-Identifier: GPL-3.0-or-later *)
From Coq Require Import List Bool Arith Lia Classical.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCOverlap.
Local Open Scope nat_scope.

(* Give earlier coordinates larger significance. This order is shared by
   the seed representatives and every stabilizer tie break. *)
Fixpoint lexrank (n:nat)(e:vector) :=
 match n with 0=>0|S k=>2*lexrank k e+if e k then 1 else 0 end.
Lemma rank_bound n e : lexrank n e<2^n.
Proof. induction n;cbn [lexrank Nat.pow];try lia. destruct(e n);lia. Qed.
Lemma rank_prefix n e f : (forall i,i<n->e i=f i)->lexrank n e=lexrank n f.
Proof. induction n;intro E;cbn [lexrank];auto. rewrite E,IHn by (intros;apply E;lia) || lia. reflexivity. Qed.
Definition prefers n (f e:vector) := exists j, j<n /\ f j=true /\ e j=false /\ forall i,i<j->f i=e i.
Lemma prefer_rank n f e : prefers n f e->lexrank n e<lexrank n f.
Proof.
 induction n;intros [j [J [F [E Pre]]]];[lia|].
 cbn [lexrank]. destruct(Nat.eq_dec j n)as[->|Ne].
 - rewrite F,E,(rank_prefix n f e Pre);lia.
 - assert (prefers n f e) by (exists j;repeat split;auto;lia). specialize(IHn H).
   destruct(e n),(f n);lia.
Qed.
Definition leader n hs ls e := minimum n hs ls e /\ forall f,minimum n hs ls f->lexrank n f<=lexrank n e.
Lemma bounded_max (P:nat->Prop) k : (exists j,j<=k /\ P j) ->
 exists j,j<=k /\ P j /\ forall i,i<=k->P i->i<=j.
Proof. induction k as [|k IH];intros [j [B J]].
 - exists j;repeat split;auto;lia.
 - destruct(classic(P(S k)))as[Yes|No];[exists(S k);repeat split;auto|].
   assert (j<=k) by (destruct(Nat.eq_dec j (S k));try subst;try contradiction;lia).
   destruct(IH (ex_intro _ j (conj H J))) as [m [M [Pm Max]]].
   exists m;repeat split;auto;try lia. intros i I Pi;apply Max;auto.
   destruct(Nat.eq_dec i (S k));try subst;try contradiction;lia.
Qed.
Lemma leader_exists n hs ls : (exists e, minimum n hs ls e) ->exists e,leader n hs ls e.
Proof.
 intros [e E]. set(P:=fun j=>exists f,minimum n hs ls f /\lexrank n f=j).
 assert (Ex:exists j,j<=2^n /\P j).
 { exists (lexrank n e);split;[pose proof(rank_bound n e);lia|exists e;auto]. }
 destruct(bounded_max P (2^n) Ex)as [j [J [[f [M R]] Max]]];exists f;split;auto.
 intros g G;rewrite R;apply Max;[pose proof(rank_bound n g);lia|exists g;auto].
Qed.
Theorem valid_even_tie n hs ls e g q : leader n hs ls e ->stabilizer_valid n hs ls g ->
 q<n ->g q=true ->(forall j,j<q->g j=false) ->
 2*weight n(vinter e g)=weight n g ->e q=true.
Proof.
 intros [M Leader] [K Neutral] Q G Before Tie;destruct(e q)eqn:E;auto.
 exfalso. destruct(xor_good n hs ls e g (proj1 M) K Neutral)as[L Kx].
 assert (W:weight n(vxor e g)=weight n e) by (pose proof(xor_weight_balance n e g);lia).
 assert (Other:minimum n hs ls(vxor e g)).
 { split;[split;[apply(logical_positive n ls);exact L|split;assumption]|rewrite W;exact(proj2 M)]. }
 specialize(Leader _ Other). assert(P:prefers n(vxor e g)e).
 { exists q;repeat split;auto;unfold vxor;try rewrite E,G;auto. intros i I.
   rewrite Before by assumption;destruct(e i);reflexivity. }
 pose proof(prefer_rank n _ _ P);lia.
Qed.
Print Assumptions leader_exists.
Print Assumptions valid_even_tie.
