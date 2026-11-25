(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto RawPCMCommutation.
From mathcomp Require Import all_ssreflect all_algebra.
Set Implicit Arguments.
Unset Strict Implicit.
Import GRing.Theory.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

(* Raw row-major byte (i,j) encodes the original matrix coefficient. *)
Definition stores_matrix r n (M:'M['F_2]_(r,n)) bytes:=
 forall (i:'I_r) (q:'I_n),Znth (Z.of_nat i*Z.of_nat n+Z.of_nat q)%coqZ bytes=(M i q!=0).
Definition coefficient r n (M:'M['F_2]_(r,n)) (i:'I_r) (q:nat):'F_2:=
 if (insub q:option 'I_n) is Some j then M i j else 0.
Lemma coefficient_at r n (M:'M['F_2]_(r,n)) i (q:'I_n):coefficient M i q=M i q.
Proof. by rewrite /coefficient valK. Qed.

Lemma bit_add (a b:'F_2):xorb (a!=0) (b!=0)=(a+b!=0).
Proof.
 have cases (v:'F_2):v=0 \/ v= 1.
 { case:v=>j small;case:j small=>[|[|j]] small;[left|right|];try by apply:val_inj.
   by []. }
 have two:(1+1:'F_2)=0 by rewrite -[X in _+X=_](oppr_char2 (char_Fp (erefl:prime 2)) 1) addrN.
 case:(cases a)=>->;case:(cases b)=>->;by rewrite ?add0r ?addr0 ?two ?eqxx ?oner_eq0.
Qed.

Section Product.
Variables ra rb n:nat.
Variables (A:'M['F_2]_(ra,n)) (B:'M['F_2]_(rb,n)) (a b:list bool).
Hypotheses (left_bytes:stores_matrix A a) (right_bytes:stores_matrix B b).
Lemma dot_scan_matches_sum (i:'I_ra) (j:'I_rb) k:(k<=n)%N ->
 dot_prefix a b (Z.of_nat n) (Z.of_nat i) (Z.of_nat j) k =
 ((\sum_(0<=q<k) (coefficient A i q * coefficient B j q))!=0).
Proof.
 elim:k=>[|k ih] small;first by rewrite big_geq // eqxx.
 have in_range:(k<n)%N:=small;pose col:'I_n:=Ordinal in_range.
 cbn [dot_prefix];rewrite big_nat_recr // ih;last exact:ltnW in_range.
 have left:Znth (Z.of_nat i*Z.of_nat n+Z.of_nat k)%coqZ a=(coefficient A i k!=0)
   by rewrite (left_bytes i col) -(coefficient_at A i col).
 have right:Znth (Z.of_nat j*Z.of_nat n+Z.of_nat k)%coqZ b=(coefficient B j k!=0)
   by rewrite (right_bytes j col) -(coefficient_at B j col).
 by rewrite left right -bit_add mulf_eq0 negb_or.
Qed.

Theorem commuting_pcm_bytes:A*m B^T=0 -> orthogonal_bytes a b (Z.of_nat ra) (Z.of_nat rb) (Z.of_nat n).
Proof.
 move=>orth i j ri rj.
 have ia:(Z.to_nat i<ra)%N by apply/ltP;lia.
 have jb:(Z.to_nat j<rb)%N by apply/ltP;lia.
 pose u:'I_ra:=Ordinal ia;pose v:'I_rb:=Ordinal jb.
 have ui:Z.of_nat u = i by rewrite /u /= Z2Nat.id;lia.
 have vj:Z.of_nat v = j by rewrite /v /= Z2Nat.id;lia.
 rewrite -ui -vj Nat2Z.id (dot_scan_matches_sum u v (leqnn n)).
 rewrite big_mkord.
 have ->:(\sum_(q:'I_n) coefficient A u q*coefficient B v q)=0.
 { transitivity ((A*m B^T) u v).
   - rewrite mxE;apply:eq_bigr=>q _;by rewrite !coefficient_at mxE.
   - by rewrite orth mxE. }
 by rewrite eqxx.
Qed.
End Product.

Require Import raw_pcm_ast RawPCMPrimitives.
#[local] Existing Instance RawPCMPrimitives.RawPCMComposites.
Section NativeProduct.
Variables r s n:nat.
Variables (A:'M['F_2]_(r,n)) (B:'M['F_2]_(s,n)) (a b:list bool).
Let nr:=Z.of_nat r. Let ns:=Z.of_nat s. Let width:=Z.of_nat n.
Definition matrix_commute_spec:ident*funspec:=
 DECLARE _commute WITH ap:Values.val,bp:Values.val,ab:Values.val,bb:Values.val,sa:share,sb:share
 PRE [tptr pcm_view_type,tptr pcm_view_type]
 PROP(readable_share sa;readable_share sb;(nr<=Int.max_signed)%coqZ;(ns<=Int.max_signed)%coqZ;
      (width<=Int.max_signed)%coqZ;Zlength a=(nr*width)%coqZ;Zlength b=(ns*width)%coqZ;
      stores_matrix A a;stores_matrix B b;A*m B^T=0)
 PARAMS(ap;bp) SEP(matrix_bytes sa ap ab nr width a;matrix_bytes sb bp bb ns width b)
 POST [tbool] PROP() RETURN(Vint Int.one)
 SEP(matrix_bytes sa ap ab nr width a;matrix_bytes sb bp bb ns width b).

Theorem accept_orthogonal_pcms:semax_body raw_vars commute_calls f_commute matrix_commute_spec.
Proof.
 eapply semax_body_funspec_sub;first exact accept_commuting_views.
 2:{ apply compute_list_norepet_e;vm_compute;reflexivity. }
 do_funspec_sub;destruct w as [[[[[ap bp] ab] bb] sa] sb];cbn [fst snd];normalize.
 have orth:orthogonal_bytes a b nr ns width by apply:commuting_pcm_bytes;eassumption.
 have rbound:(0<=nr)%coqZ by apply Nat2Z.is_nonneg.
 have sbound:(0<=ns)%coqZ by apply Nat2Z.is_nonneg.
 have nbound:(0<=width)%coqZ by apply Nat2Z.is_nonneg.
 Exists (ap,bp,ab,bb,sa,sb,nr,ns,width,a,b) emp;apply andp_right.
 - entailer!;try lia;cancel;try apply derives_refl.
 - apply prop_right;intro rho;normalize;entailer!;cancel;try apply derives_refl.
Qed.
End NativeProduct.
