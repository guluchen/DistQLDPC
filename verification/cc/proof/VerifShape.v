Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core.
Open Scope Z_scope.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition Vprog : varspecs. mk_varspecs prog. Defined.
Definition problem_type := Tstruct _ccv_problem noattr.
Definition workspace_type := Tstruct _ccv_workspace noattr.
(* Legal-dimension acceptance only; not a rejection theorem for malformed shapes. *)
Definition shape_spec : ident * funspec :=
 DECLARE _shape
 WITH pp:val,wp:val,sh:share,n:Z,m:Z,l:Z,k:Z,c:Z,f:Z,r:Z
 PRE [tptr problem_type,tptr workspace_type,tuint]
 PROP(readable_share sh;0<n<=107374182;
      0<=m<=2147483647/n;0<l<=2147483647/n;0<=k<=2147483647/n;
      n<=c<=Int.max_unsigned;n<=f<=Int.max_unsigned;0<=r<=63)
 PARAMS(pp;wp;Vint(Int.repr r))
SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh workspace_type [StructField _capacity] (Vint(Int.repr c)) wp;
    field_at sh workspace_type [StructField _frame_capacity] (Vint(Int.repr f)) wp)
 POST [tint] PROP() RETURN(Vint(Int.repr 1))
SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh workspace_type [StructField _capacity] (Vint(Int.repr c)) wp;
    field_at sh workspace_type [StructField _frame_capacity] (Vint(Int.repr f)) wp).
Definition Gprog : funspecs := ltac:(with_library prog [shape_spec]).
Lemma body_shape_legal : semax_body Vprog Gprog f_shape shape_spec.
Proof.
 start_function.
 assert (Div:0<=2147483647/n<=Int.max_signed).
 { change (0<=2147483647/n<=2147483647);split;[apply Z.div_pos;lia|apply Z.div_le_upper_bound;lia]. }
 forward.
 forward_if
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _rules (Vint(Int.repr r));temp _n (Vint(Int.repr n));temp _t'1 (Vint Int.zero))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh workspace_type [StructField _capacity] (Vint(Int.repr c)) wp;
    field_at sh workspace_type [StructField _frame_capacity] (Vint(Int.repr f)) wp))%assert.
 { exfalso;lia. }
 { forward;entailer!.
 change (sizeof (Tstruct _ccv_frame noattr)) with 20.
 change (Int64.divu (Int64.repr 2147483647) (Int64.repr 20)) with (Int64.repr 107374182).
 unfold Int64.cmpu,Int64.ltu;rewrite !Int64.unsigned_repr by rep_lia;repeat if_tac;try lia;reflexivity. }
 forward_if
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _rules (Vint(Int.repr r));temp _n (Vint(Int.repr n));temp _t'2 (Vint Int.zero))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh workspace_type [StructField _capacity] (Vint(Int.repr c)) wp;
    field_at sh workspace_type [StructField _frame_capacity] (Vint(Int.repr f)) wp))%assert.
 { exfalso;lia. }
 { forward;entailer!.
 change (sizeof tuint) with 4.
 change (Int64.divu (Int64.repr 2147483647) (Int64.repr 4)) with (Int64.repr 536870911).
 unfold Int64.cmpu,Int64.ltu;rewrite !Int64.unsigned_repr by rep_lia;repeat if_tac;try lia;reflexivity. }
 forward_if
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _rules (Vint(Int.repr r));temp _n (Vint(Int.repr n)))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh workspace_type [StructField _capacity] (Vint(Int.repr c)) wp;
    field_at sh workspace_type [StructField _frame_capacity] (Vint(Int.repr f)) wp))%assert.
 { exfalso;lia. }
 { forward;entailer!. }
 forward.
 forward_if
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _rules (Vint(Int.repr r));temp _n (Vint(Int.repr n));temp _t'3 (Vint Int.zero))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh workspace_type [StructField _capacity] (Vint(Int.repr c)) wp;
    field_at sh workspace_type [StructField _frame_capacity] (Vint(Int.repr f)) wp))%assert.
 { exfalso;lia. }
 { forward. forward. { entailer!. match goal with Hb: Int.repr n=Int.zero |- _ => apply (f_equal Int.unsigned) in Hb;rewrite Int.unsigned_repr in Hb by rep_lia;change (n=0) in Hb;lia end. } entailer!. unfold Int.ltu;rewrite !Int.unsigned_repr by rep_lia;repeat if_tac;try lia;reflexivity. }
 forward_if
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _rules (Vint(Int.repr r));temp _n (Vint(Int.repr n));temp _t'4 (Vint Int.zero))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh workspace_type [StructField _capacity] (Vint(Int.repr c)) wp;
    field_at sh workspace_type [StructField _frame_capacity] (Vint(Int.repr f)) wp))%assert.
 { exfalso;lia. }
 { forward. forward. { entailer!. match goal with Hb: Int.repr n=Int.zero |- _ => apply (f_equal Int.unsigned) in Hb;rewrite Int.unsigned_repr in Hb by rep_lia;change (n=0) in Hb;lia end. } entailer!. unfold Int.ltu;rewrite !Int.unsigned_repr by rep_lia;repeat if_tac;try lia;reflexivity. }
 forward_if
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _rules (Vint(Int.repr r));temp _n (Vint(Int.repr n));temp _t'5 (Vint Int.zero))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh workspace_type [StructField _capacity] (Vint(Int.repr c)) wp;
    field_at sh workspace_type [StructField _frame_capacity] (Vint(Int.repr f)) wp))%assert.
 { exfalso;lia. }
 { forward. forward. { entailer!. match goal with Hb: Int.repr n=Int.zero |- _ => apply (f_equal Int.unsigned) in Hb;rewrite Int.unsigned_repr in Hb by rep_lia;change (n=0) in Hb;lia end. } entailer!. unfold Int.ltu;rewrite !Int.unsigned_repr by rep_lia;repeat if_tac;try lia;reflexivity. }
 forward_if
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _rules (Vint(Int.repr r));temp _n (Vint(Int.repr n)))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh workspace_type [StructField _capacity] (Vint(Int.repr c)) wp;
    field_at sh workspace_type [StructField _frame_capacity] (Vint(Int.repr f)) wp))%assert.
 { exfalso;lia. }
 { forward;entailer!. }
 forward.
 forward_if
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _rules (Vint(Int.repr r));temp _n (Vint(Int.repr n));temp _t'6 (Vint Int.zero))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh workspace_type [StructField _capacity] (Vint(Int.repr c)) wp;
    field_at sh workspace_type [StructField _frame_capacity] (Vint(Int.repr f)) wp))%assert.
 { exfalso;lia. }
 { forward. forward;entailer!. unfold bool2val;destruct(zlt f n);[lia|reflexivity]. }
 forward_if
 (PROP() LOCAL(temp _p pp;temp _w wp;temp _rules (Vint(Int.repr r));temp _n (Vint(Int.repr n));temp _t'7 (Vint Int.zero))
 SEP(field_at sh problem_type [StructField _n] (Vint(Int.repr n)) pp;
    field_at sh problem_type [StructField _checks] (Vint(Int.repr m)) pp;
    field_at sh problem_type [StructField _logical_rows] (Vint(Int.repr l)) pp;
    field_at sh problem_type [StructField _stabilizers] (Vint(Int.repr k)) pp;
    field_at sh workspace_type [StructField _capacity] (Vint(Int.repr c)) wp;
    field_at sh workspace_type [StructField _frame_capacity] (Vint(Int.repr f)) wp))%assert.
 { exfalso;lia. }
 { forward;entailer!;unfold bool2val;destruct(zlt 63 r);[lia|reflexivity]. }
 forward_if.
 { exfalso;lia. }
 { forward;entailer!. }
Qed.
Print Assumptions body_shape_legal.
