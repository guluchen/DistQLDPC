(* Linked C entry with a checked raw-PCM preparation as its input contract. *)
Require Import VST.floyd.proofauto.
Require Import CCV.ccv_core CCV.VerifToggle CCV.CCSearchSpecs CCV.CCSearchContext CCV.CCCSSSpecs
 CCV.CCCSSResultBridge CCV.VerifCSSDistance CCV.VerifLinkedCertificateAPI
 CCV.CCLinkedProgram CCV.CCLibraryFunctions CCV.CCPCMInput.
Import ListNotations. Local Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.

Definition pcm_distance_spec:ident*funspec:=
 DECLARE ccv_core._ccv_distance
 WITH q:raw_half,a:half_model,p:kernel_pointers,dp:val,sh:share,budget:Z,rules:Z
 PRE[tptr problem_type,tuint,tuint,tptr workspace_type,tptr tuchar,tptr tuint,tptr stats_type]
 PROP(prepare_pcm_half q=Some a;readable_share sh;workspace_extent a p;
      0<=budget<=Int.max_unsigned;0<=rules<=63)
 PARAMS(ptr_problem p;Vint(Int.repr budget);Vint(Int.repr rules);ptr_workspace p;ptr_out p;dp;ptr_stats p)
 SEP(problem_repr sh a p;workspace_fields sh p;workspace_any a p;
     data_at_ Tsh(tarray tuchar(model_n a))(ptr_out p);
     data_at_ Tsh tuint dp;data_at_ Tsh stats_type(ptr_stats p))
 POST[tint] EX ret:Z,EX out:list Z,EX d:Z,EX s1:stats_model,
 PROP(Zlength out=model_n a;Forall(fun z:Z=>z=0\/z=1)out;legal_stats budget s1;
      0<=d<=model_n a;css_distance_result a (same_rows q) ret out d)
 RETURN(Vint(Int.repr ret))
 SEP(problem_repr sh a p;workspace_fields sh p;
     (if Z.eq_dec ret 1 then workspace_any a p else workspace_zero a p);
     data_at Tsh(tarray tuchar(model_n a))(tbytes out)(ptr_out p);
     data_at Tsh tuint(Vint(Int.repr d))dp;stats_repr(ptr_stats p)s1).

Lemma cpu_pcm_sub: funspec_sub (snd css_distance_spec)(snd pcm_distance_spec).
Proof.
 do_funspec_sub. destruct w as [[[[[[q a]p]dp]sh]budget]rules];cbn[fst snd];normalize.
 pose proof (prepare_pcm_contract q a ltac:(assumption)) as [Legal [Complete Comm]].
 Exists(a,p,dp,sh,budget,rules,same_rows q)emp;apply andp_right.
 - entailer!;cancel.
 - apply prop_right;intros rho';normalize.
   lazymatch goal with H:css_distance_result a _ ?ret ?out ?d,HS:legal_stats budget ?s |- _ => Exists ret out d s end.
   entailer!;cancel.
Qed.
Lemma body_pcm_distance_linked : semax_body CCSearchContext.Vprog linked_Gprog f_ccv_distance pcm_distance_spec.
Proof.
 eapply semax_body_funspec_sub;[exact body_distance_linked| |].
 - eapply funspec_sub_trans;[exact distance_css_sub|exact cpu_pcm_sub].
 - vm_compute;repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.
Theorem linked_pcm_distance {E:OracleKind} :
 @semax_func E CCSearchContext.Vprog linked_Gprog CCSearchSpecs.CompSpecs (Genv.globalenv linked_prog)
 [(ccv_core._ccv_distance,Internal ccv_core.f_ccv_distance)] [pcm_distance_spec].
Proof.
 prove_semax_prog_setup_globalenv.
 assert(SameContext:tycontext_subVG CCSearchContext.Vprog linked_Gprog CCSearchContext.Vprog linked_Gprog).
 { split;intro i;apply sub_option_refl || apply subsumespec_refl. }
 linked_func_cons body_pcm_distance_linked.
Qed.
Print Assumptions linked_pcm_distance.
