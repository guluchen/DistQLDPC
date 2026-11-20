(* Combining two exact pure-Pauli queries computes the CSS distance even
   when arbitrary mixed Pauli operators are allowed. *)
From Coq Require Import Bool Arith Lia List.
Require Import CCV.CCModel CCV.CCFunctional CCV.CCCSSBridge.
Local Open Scope nat_scope.
Definition mixed_weight n (x z:vector) := weight n (fun i=>orb (x i) (z i)).
Definition mixed_logical n hx hz x z :=
 kernel n hz x /\ kernel n hx z /\ (~rowspan n hx x \/ ~rowspan n hz z).
Lemma weight_union n x z : weight n x <= mixed_weight n x z /\ weight n z<=mixed_weight n x z.
Proof. unfold mixed_weight;induction n;[simpl;lia|];cbn [weight];destruct (x n),(z n);simpl;lia. Qed.
Lemma pure_weights n e : mixed_weight n e zero_vector=weight n e /\ mixed_weight n zero_vector e=weight n e.
Proof. unfold mixed_weight;split;apply weight_ext;intros i I;unfold zero_vector;destruct (e i);reflexivity. Qed.
Inductive answer (A:Type) := unresolved | empty | found (w:A).
Arguments unresolved {A}. Arguments empty {A}. Arguments found {A}.
Definition half_sound n checks same (a:answer vector):Prop :=
 match a with unresolved=>True | empty=>~exists e,css_logical n checks same e
 |found w=>css_minimum n checks same w end.
Definition join_halves n (x z:answer vector):answer (vector*vector) :=
 match x,z with
 | unresolved,_ | _,unresolved => unresolved
 | empty,empty=>empty | found e,empty=>found(e,zero_vector)
 | empty,found e=>found(zero_vector,e)
 | found a,found b=>if Nat.leb (weight n a) (weight n b)
                    then found(a,zero_vector) else found(zero_vector,b)
 end.
Definition pair_sound n hx hz a :Prop :=
 match a with unresolved=>True |empty=>~exists x z,mixed_logical n hx hz x z
 |found (x,z)=>mixed_logical n hx hz x z /\
  forall u v,mixed_logical n hx hz u v -> mixed_weight n x z<=mixed_weight n u v end.
Theorem combine_pcm_halves n hx hz a b :
 half_sound n hz hx a ->half_sound n hx hz b ->pair_sound n hx hz (join_halves n a b).
Proof.
 assert (X:forall e,css_logical n hz hx e ->mixed_logical n hx hz e zero_vector).
 { intros e [K S];split;[assumption|split;[apply zero_kernel|auto]]. }
 assert (Z:forall e,css_logical n hx hz e ->mixed_logical n hx hz zero_vector e).
 { intros e [K S];split;[apply zero_kernel|split;auto]. }
 assert (Parts:forall u v,mixed_logical n hx hz u v ->css_logical n hz hx u \/css_logical n hx hz v).
 { intros u v [Ku[Kv[Nu|Nv]]];unfold css_logical;auto. }
 destruct a as [| |x], b as [| |z];cbn [half_sound join_halves pair_sound];try tauto.
 - intros NoX NoZ [u[v M]];destruct(Parts u v M);[apply NoX;exists u|apply NoZ;exists v];assumption.
 - intros NoX [Log Min];split;[auto|intros u v M].
   rewrite (proj2(pure_weights n z));destruct(Parts u v M)as [U|V];[exfalso;apply NoX;exists u;exact U|].
   eapply Nat.le_trans;[apply Min;exact V|apply weight_union].
 - intros [Log Min] NoZ;split;[auto|intros u v M].
   rewrite (proj1(pure_weights n x));destruct(Parts u v M)as [U|V];[|exfalso;apply NoZ;exists v;exact V].
   eapply Nat.le_trans;[apply Min;exact U|apply weight_union].
 - intros [LX MX] [LZ MZ];destruct (weight n x <=? weight n z) eqn:E;cbn[pair_sound];
   split;try solve [auto];intros u v M;destruct(Parts u v M)as [U|V];
   pose proof(weight_union n u v) as Bounds;
   rewrite ?(proj1(pure_weights n x)),?(proj2(pure_weights n z));
   try apply Nat.leb_le in E;try apply Nat.leb_gt in E;first [specialize(MX u U)|specialize(MZ v V)];lia.
Qed.
Print Assumptions combine_pcm_halves.
