(* Verification interface for the actual C search and API drivers.
   DEFINITIONS ONLY: this file is not a C search/driver body proof.
   H/L describe the generic half problem; CSS logical-quotient construction
   and equivalence to the production C++ implementation remain outside here. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.CCModel CCV.CCValidation CCV.CCRepresentation CCV.CCMatrixModel CCV.VerifToggle.
Import ListNotations.
Open Scope Z_scope.
#[export] Instance CompSpecs : compspecs. make_compspecs prog. Defined.
Definition problem_type :=Tstruct _ccv_problem noattr.
Definition workspace_type :=Tstruct _ccv_workspace noattr.
Definition stats_type :=Tstruct _ccv_stats noattr.
Definition frame_type :=Tstruct _ccv_frame noattr.
Record half_model := {
 model_n:Z;model_m:Z;model_l:Z;model_k:Z;
 model_h:list Z;model_lg:list Z;model_g:list Z
}.
Definition model_h_rows a :=matrix_vectors(model_n a)(model_m a)(model_h a).
Definition model_l_rows a :=matrix_vectors(model_n a)(model_l a)(model_lg a).
Definition model_g_rows a :=matrix_vectors(model_n a)(model_k a)(model_g a).
Definition model_good a e :=CCModel.good(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)e.
Definition model_minimum a e :=CCModel.minimum(Z.to_nat(model_n a))(model_h_rows a)(model_l_rows a)e.
Definition legal_model a :=
 0<model_n a<=107374182 /\
 0<=model_m a<=2147483647/model_n a /\
 0<model_l a<=2147483647/model_n a /\
 0<=model_k a<=2147483647/model_n a /\
 Zlength(model_h a)=(model_m a*model_n a)%Z /\
 Zlength(model_lg a)=(model_l a*model_n a)%Z /\
 Zlength(model_g a)=(model_k a*model_n a)%Z /\
 Forall(fun z:Z=>z=0 \/z=1)(model_h a) /\
 Forall(fun z:Z=>z=0 \/z=1)(model_lg a) /\
 Forall(fun z:Z=>z=0 \/z=1)(model_g a) /\
 kernel_metadata(model_n a)(model_m a)(model_l a)(model_k a)(model_h a)(model_lg a)(model_g a).
Record kernel_pointers := {
 ptr_problem:val;ptr_workspace:val;ptr_h:val;ptr_lg:val;ptr_g:val;
 ptr_selected:val;ptr_forbidden:val;ptr_syndrome:val;ptr_logical_value:val;
 ptr_packed:val;ptr_undo:val;ptr_frames:val;ptr_out:val;ptr_stats:val;
 workspace_capacity:Z;workspace_frame_capacity:Z
}.
Record stats_model := {
 stat_steps:Z;stat_nodes:Z;stat_pack:Z;stat_charge:Z;stat_overlap:Z
}.
Definition legal_stats budget s :=
 0<=stat_steps s<=budget /\budget<=Int.max_unsigned /\
 0<=stat_nodes s<=stat_steps s /\
 0<=stat_pack s<=stat_nodes s /\
 0<=stat_charge s<=stat_nodes s /\
 0<=stat_overlap s<=stat_nodes s.
Definition stats_monotone a b :=
 stat_steps a<=stat_steps b /\stat_nodes a<=stat_nodes b /\
 stat_pack a<=stat_pack b /\stat_charge a<=stat_charge b /\stat_overlap a<=stat_overlap b.
Definition stats_repr p s :=data_at Tsh stats_type
 (Vint(Int.repr(stat_steps s)),(Vint(Int.repr(stat_nodes s)),
 (Vint(Int.repr(stat_pack s)),(Vint(Int.repr(stat_charge s)),Vint(Int.repr(stat_overlap s))))))p.
Definition problem_repr sh a p :=
 (
 field_at sh problem_type[StructField _n](Vint(Int.repr(model_n a)))(ptr_problem p)*
 field_at sh problem_type[StructField _checks](Vint(Int.repr(model_m a)))(ptr_problem p)*
 field_at sh problem_type[StructField _logical_rows](Vint(Int.repr(model_l a)))(ptr_problem p)*
 field_at sh problem_type[StructField _stabilizers](Vint(Int.repr(model_k a)))(ptr_problem p)*
 field_at sh problem_type[StructField _h](ptr_h p)(ptr_problem p)*
 field_at sh problem_type[StructField _logical](ptr_lg p)(ptr_problem p)*
 field_at sh problem_type[StructField _stabilizer](ptr_g p)(ptr_problem p)*
 data_at sh(tarray tuchar((model_m a*model_n a)%Z))(tbytes(model_h a))(ptr_h p)*
 data_at sh(tarray tuchar((model_l a*model_n a)%Z))(tbytes(model_lg a))(ptr_lg p)*
 data_at sh(tarray tuchar((model_k a*model_n a)%Z))(tbytes(model_g a))(ptr_g p))%logic.
Definition workspace_fields sh p :=
 (
 field_at sh workspace_type[StructField _capacity](Vint(Int.repr(workspace_capacity p)))(ptr_workspace p)*
 field_at sh workspace_type[StructField _frame_capacity](Vint(Int.repr(workspace_frame_capacity p)))(ptr_workspace p)*
 field_at sh workspace_type[StructField _selected](ptr_selected p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _forbidden](ptr_forbidden p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _syndrome](ptr_syndrome p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _logical_value](ptr_logical_value p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _packed](ptr_packed p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _undo](ptr_undo p)(ptr_workspace p)*
 field_at sh workspace_type[StructField _frames](ptr_frames p)(ptr_workspace p))%logic.
Definition workspace_extent a p :=
 model_n a<=workspace_capacity p<=Int.max_unsigned /\
 model_n a<=workspace_frame_capacity p<=Int.max_unsigned.
(* Typed memory preconditions include compatible zero-extent addresses.
   They do not certify arbitrary pointers or every NULL zero-buffer calling
   convention admitted by the C header. No malformed-pointer claim is made. *)
Definition workspace_any a p :=
 (
 data_at_ Tsh(tarray tuchar(model_n a))(ptr_selected p)*
 data_at_ Tsh(tarray tuchar(model_n a))(ptr_forbidden p)*
 data_at_ Tsh(tarray tuchar(model_m a))(ptr_syndrome p)*
 data_at_ Tsh(tarray tuchar(model_l a))(ptr_logical_value p)*
 data_at_ Tsh(tarray tuchar(model_n a))(ptr_packed p)*
 data_at_ Tsh(tarray tuint(model_n a))(ptr_undo p)*
 data_at_ Tsh(tarray frame_type(model_n a))(ptr_frames p))%logic.
Definition zero_bytes n :=tbytes(Zrepeat 0 n).
Definition workspace_zero a p :=
 (
 data_at Tsh(tarray tuchar(model_n a))(zero_bytes(model_n a))(ptr_selected p)*
 data_at Tsh(tarray tuchar(model_n a))(zero_bytes(model_n a))(ptr_forbidden p)*
 data_at Tsh(tarray tuchar(model_m a))(zero_bytes(model_m a))(ptr_syndrome p)*
 data_at Tsh(tarray tuchar(model_l a))(zero_bytes(model_l a))(ptr_logical_value p)*
 data_at Tsh(tarray tuchar(model_n a))(zero_bytes(model_n a))(ptr_packed p)*
 data_at_ Tsh(tarray tuint(model_n a))(ptr_undo p)*
 data_at_ Tsh(tarray frame_type(model_n a))(ptr_frames p))%logic.
Definition output_weight a out :=Z.of_nat(CCModel.weight(Z.to_nat(model_n a))(decode out)).
Definition query_result a cap ret out :=
 (ret=(-1) /\out=Zrepeat 0(model_n a)) \/
 (ret=0 /\out=Zrepeat 0(model_n a) /\
   forall e,model_good a e ->cap<Z.of_nat(CCModel.weight(Z.to_nat(model_n a))e)) \/
 (ret=1 /\model_good a(decode out) /\output_weight a out<=cap).
Definition minimum_result a ret out distance :=
 (ret=(-1) /\out=Zrepeat 0(model_n a) /\distance=0) \/
 (ret=0 /\out=Zrepeat 0(model_n a) /\distance=0 /\~exists e,model_good a e) \/
 (ret=1 /\model_minimum a(decode out) /\distance=output_weight a out).
Definition search_spec :ident*funspec :=
 DECLARE _search
 WITH a:half_model,p:kernel_pointers,sh:share,cap:Z,budget:Z,rules:Z,s0:stats_model
 PRE[tptr problem_type,tuint,tuint,tuint,tptr workspace_type,tptr tuchar,tptr stats_type]
 PROP(readable_share sh;legal_model a;workspace_extent a p;legal_stats budget s0;
      0<=cap<=Int.max_unsigned;0<=budget<=Int.max_unsigned;0<=rules<=63)
 PARAMS(ptr_problem p;Vint(Int.repr cap);Vint(Int.repr budget);Vint(Int.repr rules);
        ptr_workspace p;ptr_out p;ptr_stats p)
 SEP(problem_repr sh a p;workspace_fields sh p;workspace_zero a p;
     data_at Tsh(tarray tuchar(model_n a))(zero_bytes(model_n a))(ptr_out p);
     stats_repr(ptr_stats p)s0)
 POST[tint] EX ret:Z,EX out:list Z,EX s1:stats_model,
 PROP(Zlength out=model_n a;Forall(fun z:Z=>z=0 \/z=1)out;
      legal_stats budget s1;stats_monotone s0 s1;query_result a cap ret out)
 RETURN(Vint(Int.repr ret))
 SEP(problem_repr sh a p;workspace_fields sh p;
     (if Z.eq_dec ret 1 then workspace_any a p else workspace_zero a p);
     data_at Tsh(tarray tuchar(model_n a))(tbytes out)(ptr_out p);stats_repr(ptr_stats p)s1).
Definition decide_spec :ident*funspec :=
 DECLARE _ccv_decide
 WITH a:half_model,p:kernel_pointers,sh:share,cap:Z,budget:Z,rules:Z
 PRE[tptr problem_type,tuint,tuint,tuint,tptr workspace_type,tptr tuchar,tptr stats_type]
 PROP(readable_share sh;legal_model a;workspace_extent a p;
      0<=cap<=Int.max_unsigned;0<=budget<=Int.max_unsigned;0<=rules<=63)
 PARAMS(ptr_problem p;Vint(Int.repr cap);Vint(Int.repr budget);Vint(Int.repr rules);
        ptr_workspace p;ptr_out p;ptr_stats p)
 SEP(problem_repr sh a p;workspace_fields sh p;workspace_any a p;
     data_at_ Tsh(tarray tuchar(model_n a))(ptr_out p);data_at_ Tsh stats_type(ptr_stats p))
 POST[tint] EX ret:Z,EX out:list Z,EX s1:stats_model,
 PROP(Zlength out=model_n a;Forall(fun z:Z=>z=0 \/z=1)out;
      legal_stats budget s1;query_result a cap ret out)
 RETURN(Vint(Int.repr ret))
 SEP(problem_repr sh a p;workspace_fields sh p;
     (if Z.eq_dec ret 1 then workspace_any a p else workspace_zero a p);
     data_at Tsh(tarray tuchar(model_n a))(tbytes out)(ptr_out p);stats_repr(ptr_stats p)s1).
Definition distance_spec :ident*funspec :=
 DECLARE _ccv_distance
 WITH a:half_model,p:kernel_pointers,dp:val,sh:share,budget:Z,rules:Z
 PRE[tptr problem_type,tuint,tuint,tptr workspace_type,tptr tuchar,tptr tuint,tptr stats_type]
 PROP(readable_share sh;legal_model a;workspace_extent a p;0<=budget<=Int.max_unsigned;0<=rules<=63)
 PARAMS(ptr_problem p;Vint(Int.repr budget);Vint(Int.repr rules);ptr_workspace p;ptr_out p;dp;ptr_stats p)
 SEP(problem_repr sh a p;workspace_fields sh p;workspace_any a p;
     data_at_ Tsh(tarray tuchar(model_n a))(ptr_out p);data_at_ Tsh tuint dp;data_at_ Tsh stats_type(ptr_stats p))
 POST[tint] EX ret:Z,EX out:list Z,EX d:Z,EX s1:stats_model,
 PROP(Zlength out=model_n a;Forall(fun z:Z=>z=0 \/z=1)out;legal_stats budget s1;
      0<=d<=model_n a;minimum_result a ret out d)
 RETURN(Vint(Int.repr ret))
 SEP(problem_repr sh a p;workspace_fields sh p;
     (if Z.eq_dec ret 1 then workspace_any a p else workspace_zero a p);
     data_at Tsh(tarray tuchar(model_n a))(tbytes out)(ptr_out p);
     data_at Tsh tuint(Vint(Int.repr d))dp;stats_repr(ptr_stats p)s1).
