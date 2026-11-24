(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require NativeBoundAlgebra.
Require Import driver_ast.
Local Open Scope Z_scope.
#[local] Instance DriverC:compspecs. make_compspecs prog. Defined.
Definition Dvars:varspecs. mk_varspecs prog. Defined.
Definition bval (b:bool):=Vint (if b then Int.one else Int.zero).
Definition as_lower (exists_:bool) (w:Z):=if exists_ then w else Int.max_signed.
Definition fits z:=Int.min_signed<=z<=Int.max_signed.
Definition lower_spec:ident*funspec:=
 DECLARE _cc_global_lower WITH hx:bool,x:Z,hz:bool,z:Z
 PRE [tbool,tint,tbool,tint] PROP(fits x;fits z)
 PARAMS(bval hx;Vint (Int.repr x);bval hz;Vint (Int.repr z)) SEP()
 POST [tint] PROP() RETURN(Vint (Int.repr (Z.min (as_lower hx x) (as_lower hz z)))) SEP().
Definition advance_spec:ident*funspec:=
 DECLARE _cc_next_after_empty WITH w:Z,even:bool
 PRE [tint,tbool] PROP(0<=w<Int.max_signed;NativeBoundAlgebra.machine_next w even<=Int.max_signed)
 PARAMS(Vint (Int.repr w);bval even) SEP()
 POST [tint] PROP() RETURN(Vint (Int.repr (NativeBoundAlgebra.machine_next w even))) SEP().
Definition hit_spec:ident*funspec:=
 DECLARE _cc_hit_closes WITH w:Z,h:bool,other:Z
 PRE [tint,tbool,tint] PROP(fits w;fits other)
 PARAMS(Vint (Int.repr w);bval h;Vint (Int.repr other)) SEP()
 POST [tbool] PROP() RETURN(bval (orb (negb h) (Z.leb w other))) SEP().
Definition DGprog:funspecs:=ltac:(with_library prog [lower_spec;advance_spec;hit_spec]).
Lemma fits_selected h x:fits x -> fits (as_lower h x).
Proof. destruct h;unfold fits,as_lower;intros;rep_lia. Qed.
Theorem global_lower_body:semax_body Dvars DGprog f_cc_global_lower lower_spec.
Proof.
 start_function;reassoc_seq.
 forward_if (temp _t'1 (Vint (Int.repr (as_lower hx x)))).
 - destruct hx;[forward;entailer!|discriminate].
 - destruct hx;[discriminate|forward;entailer!].
 - forward;forward_if (temp _t'2 (Vint (Int.repr (as_lower hz z)))).
   + destruct hz;[forward;entailer!|discriminate].
   + destruct hz;[discriminate|forward;entailer!].
   + forward;pose proof (fits_selected hx x H) as X;pose proof (fits_selected hz z H0) as Zs;unfold fits in *.
     forward_if (temp _t'3 (Vint (Int.repr (Z.min (as_lower hx x) (as_lower hz z))))).
     * forward;entailer!;rewrite Z.min_l by rep_lia;reflexivity.
     * forward;entailer!;rewrite Z.min_r by rep_lia;reflexivity.
     * forward.
Qed.
Lemma encoded_add1 x:Int.add (Int.repr x) Int.one=Int.repr (x+1).
Proof.
 unfold Int.add;change (Int.unsigned Int.one) with 1;apply Int.eqm_samerepr.
 apply Int.eqm_add;[apply Int.eqm_sym,Int.eqm_unsigned_repr|apply Int.eqm_refl].
Qed.
Theorem advance_empty_body:semax_body Dvars DGprog f_cc_next_after_empty advance_spec.
Proof.
 start_function;unfold NativeBoundAlgebra.machine_next in *;forward;reassoc_seq.
 forward_if (temp _t'1 (bval (andb even (Z.testbit (w+1) 0)))).
 - destruct even;[|discriminate];forward;entailer!.
   assert (low: forall z, Z.land z 1=Z.b2z (Z.testbit z 0)).
   { intro z;change (Z.land z (Z.ones 1)=Z.b2z (Z.testbit z 0));rewrite Z.land_ones,Z.bit0_mod by lia;reflexivity. }
   rewrite low.
   destruct (Z.testbit (w+1) 0);reflexivity.
 - destruct even;[discriminate|forward;entailer!].
 - destruct (andb even (Z.testbit (w+1) 0)) eqn:B;cbn [bval];apply semax_if_seq;forward_if;try congruence;try discriminate.
   + forward;try solve [entailer!;rep_lia].
     forward;entailer!;rewrite ?encoded_add1;f_equal;f_equal;lia.
   + forward;entailer!;rewrite ?encoded_add1;reflexivity.
Qed.
Theorem hit_stop_body:semax_body Dvars DGprog f_cc_hit_closes hit_spec.
Proof.
 start_function;unfold fits in *.
 forward_if (temp _t'1 (bval (orb (negb h) (Z.leb w other)))).
 - destruct h;[discriminate|forward;entailer!].
 - destruct h;[|congruence];forward;entailer!;unfold bval;cbn [negb orb].
   destruct (zlt other w) as [less|enough].
   + assert (B:(w<=?other)=false) by (apply Z.leb_gt;lia);rewrite B;reflexivity.
   + assert (B:(w<=?other)=true) by (apply Z.leb_le;lia);rewrite B;reflexivity.
 - destruct (orb (negb h) (Z.leb w other));forward;entailer!.
Qed.
