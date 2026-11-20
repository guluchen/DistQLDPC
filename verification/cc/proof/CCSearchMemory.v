(* Spatial packaging for actual search phase1, not a complete search proof. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCFrameShape CCV.CCFrameFields
 CCV.VerifCandidateScan CCV.VerifToggle.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Definition frame_type:=Tstruct _ccv_frame noattr.
Definition problem_type:=Tstruct _ccv_problem noattr.
Definition workspace_type:=Tstruct _ccv_workspace noattr.
Definition active_frame_address p n depth:=
 field_address0(tarray frame_type n)[ArraySubsc(depth-1)](ptr_frames p).
Definition scan_addresses p n depth:VerifCandidateScan.scan_addresses:=
 {|sa_problem:=ptr_problem p;sa_workspace:=ptr_workspace p;sa_h:=ptr_h p;
   sa_selected:=ptr_selected p;sa_forbidden:=ptr_forbidden p;
   sa_frame:=active_frame_address p n depth|}.
Definition frame_words row next chosen mark phase:reptype frame_type:=
 (Vint(Int.repr row),(Vint(Int.repr next),(chosen,(Vint(Int.repr mark),Vint(Int.repr phase))))).
Definition phase1_memory sh p tp n m l top hs ls xs fs ys zs frames:mpred:=
 (field_at sh problem_type[StructField _n](Vint(Int.repr n))(ptr_problem p)*
  field_at sh problem_type[StructField _checks](Vint(Int.repr m))(ptr_problem p)*
  field_at sh problem_type[StructField _logical_rows](Vint(Int.repr l))(ptr_problem p)*
  field_at sh problem_type[StructField _h](ptr_h p)(ptr_problem p)*
  field_at sh problem_type[StructField _logical](ptr_lg p)(ptr_problem p)*
  field_at sh workspace_type[StructField _selected](ptr_selected p)(ptr_workspace p)*
  field_at sh workspace_type[StructField _forbidden](ptr_forbidden p)(ptr_workspace p)*
  field_at sh workspace_type[StructField _syndrome](ptr_syndrome p)(ptr_workspace p)*
  field_at sh workspace_type[StructField _logical_value](ptr_logical_value p)(ptr_workspace p)*
  field_at sh workspace_type[StructField _frames](ptr_frames p)(ptr_workspace p)*
  data_at sh(tarray tuchar(m*n))(tbytes hs)(ptr_h p)*
  data_at sh(tarray tuchar(l*n))(tbytes ls)(ptr_lg p)*
  data_at Tsh(tarray tuchar n)(tbytes xs)(ptr_selected p)*
  data_at Tsh(tarray tuchar n)(tbytes fs)(ptr_forbidden p)*
  data_at Tsh(tarray tuchar m)(tbytes ys)(ptr_syndrome p)*
  data_at Tsh(tarray tuchar l)(tbytes zs)(ptr_logical_value p)*
  data_at Tsh(tarray frame_type n)frames(ptr_frames p)*
  data_at Tsh tuint(Vint(Int.repr top))tp)%logic.
Definition scan_extra sh p tp n m l depth top (row:Z) next chosen mark phase ls ys zs frames:mpred:=
 (field_at sh problem_type[StructField _checks](Vint(Int.repr m))(ptr_problem p)*
  field_at sh problem_type[StructField _logical_rows](Vint(Int.repr l))(ptr_problem p)*
  field_at sh problem_type[StructField _logical](ptr_lg p)(ptr_problem p)*
  field_at sh workspace_type[StructField _syndrome](ptr_syndrome p)(ptr_workspace p)*
  field_at sh workspace_type[StructField _logical_value](ptr_logical_value p)(ptr_workspace p)*
  field_at sh workspace_type[StructField _frames](ptr_frames p)(ptr_workspace p)*
  data_at sh(tarray tuchar(l*n))(tbytes ls)(ptr_lg p)*
  data_at Tsh(tarray tuchar m)(tbytes ys)(ptr_syndrome p)*
  data_at Tsh(tarray tuchar l)(tbytes zs)(ptr_logical_value p)*
  data_at Tsh tuint(Vint(Int.repr top))tp*
  field_at Tsh frame_type[StructField _next](Vint(Int.repr next))(active_frame_address p n depth)*
  field_at Tsh frame_type[StructField _chosen]chosen(active_frame_address p n depth)*
  field_at Tsh frame_type[StructField _mark](Vint(Int.repr mark))(active_frame_address p n depth)*
  field_at Tsh frame_type[StructField _phase](Vint(Int.repr phase))(active_frame_address p n depth)*
  frame_remainder Tsh n(depth-1)frames(ptr_frames p))%logic.
Lemma phase1_scan_memory_split sh p tp n m l depth top row next chosen mark phase hs ls xs fs ys zs frames:
 Zlength frames=n ->1<=depth<=n ->
 Znth(depth-1)frames=frame_words row next chosen mark phase ->
 phase1_memory sh p tp n m l top hs ls xs fs ys zs frames=
 (VerifCandidateScan.scan_memory sh(scan_addresses p n depth)n m row hs xs fs*
  scan_extra sh p tp n m l depth top row next chosen mark phase ls ys zs frames)%logic.
Proof.
 intros Len Depth Frame.
 unfold phase1_memory,frame_type in *.
 pose proof(frame_array_focus Tsh n(depth-1)frames(ptr_frames p)Len ltac:(lia))as Focus.
 unfold CCFrameFields.frame_type in Focus;rewrite Focus.
 rewrite Frame. unfold frame_words.
 pose proof(frame_data_at_fields Tsh(Vint(Int.repr row))(Vint(Int.repr next))chosen
   (Vint(Int.repr mark))(Vint(Int.repr phase))
   (field_address0(tarray(Tstruct _ccv_frame noattr)n)[ArraySubsc(depth-1)](ptr_frames p)))as Shape.
 unfold CCFrameShape.frame_type in Shape.
 (* Normalize the definitionally equal frame-value representation first. *)
 lazymatch goal with|-context[@data_at ?cs Tsh(Tstruct _ccv_frame noattr)?v ?a]=>
   let Cell:=constr:(@data_at cs Tsh(Tstruct _ccv_frame noattr)v a)in
   lazymatch type of Shape with ?Canonical = ?Fields=>
     assert(CellEq:Cell=Canonical)by reflexivity end end.
 rewrite CellEq,Shape.
 unfold VerifCandidateScan.scan_memory,scan_extra,scan_addresses,active_frame_address,frame_fields.
 unfold frame_type,CCFrameShape.frame_type,VerifCandidateScan.frame_type,
   problem_type,workspace_type,VerifCandidateScan.problem_type,VerifCandidateScan.workspace_type.
 cbn[sa_problem sa_workspace sa_h sa_selected sa_forbidden sa_frame].
 apply pred_ext;cancel.
Qed.
Print Assumptions phase1_scan_memory_split.
