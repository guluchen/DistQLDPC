(* Recover the real statistics-word load from the VST ownership predicate.
   This is a pointwise memory bridge, not the full semax/termination adequacy. *)
Require Import VST.floyd.proofauto.
Require Import VST.veric.res_predicates VST.veric.juicy_mem.
Require Import VST.veric.assert_lemmas VST.veric.juicy_mem_lemmas.
Require Import CCV.ccv_core CCV.CCSearchSpecs CCV.CCStatsFields.
Import ListNotations. Open Scope Z_scope.
#[export] Existing Instance CCSearchSpecs.CompSpecs.
Local Transparent mpred Nveric Sveric.
Lemma stats_repr_steps_mapsto ps s:
 stats_repr ps s |-- mapsto Tsh tuint ps(Vint(Int.repr(stat_steps s)))*TT.
Proof.
 rewrite stats_repr_fields;unfold stats_fields.
 assert_PROP(field_compatible stats_type[StructField _steps]ps)as Compatible by entailer!.
 assert(Address:field_address stats_type[StructField _steps]ps=ps).
 { rewrite field_address_offset by exact Compatible.
   change(offset_val 0 ps=ps).
   apply isptr_offset_val_zero;unfold field_compatible in Compatible;tauto. }
 pose proof(mapsto_field_at Tsh stats_type[StructField _steps]
 (Vint(Int.repr(stat_steps s)))(Vint(Int.repr(stat_steps s)))ps
 ltac:(reflexivity)ltac:(reflexivity)Compatible(JMeq_refl _))as Cell.
 rewrite <-Cell,Address;cancel;apply TT_right.
Qed.
Lemma stats_repr_steps_address b ofs s R:
 stats_repr(Vptr b ofs)s*R |--
 address_mapsto Mint32(Vint(Int.repr(stat_steps s)))Tsh(b,Ptrofs.unsigned ofs)*TT.
Proof.
 assert(Scalar:mapsto Tsh tuint(Vptr b ofs)(Vint(Int.repr(stat_steps s))) |--
 address_mapsto Mint32(Vint(Int.repr(stat_steps s)))Tsh(b,Ptrofs.unsigned ofs)).
 { unfold mapsto,tuint,access_mode,type_is_volatile,attr_of_type,noattr;cbn[attr_volatile].
   destruct(readable_share_dec Tsh)as[Read|Unread].
   - apply orp_left;[apply andp_left2;apply derives_refl|normalize;discriminate].
   - exfalso;apply Unread;apply readable_share_top. }
 sep_apply(stats_repr_steps_mapsto(Vptr b ofs)s).
 sep_apply Scalar;cancel;apply TT_right.
Qed.
Theorem stats_repr_steps_load b ofs s (R:mpred)(jm:juicy_mem):
 predicates_hered.app_pred((stats_repr(Vptr b ofs)s*R)%logic)(m_phi jm) ->
 Mem.loadv Mint32(m_dry jm)(Vptr b ofs)=Some(Vint(Int.repr(stat_steps s))).
Proof.
 intros Owned.
 pose proof(stats_repr_steps_address b ofs s R)as Ent.
 rewrite derives_eq in Ent;specialize(Ent(m_phi jm)Owned).
 change(Mem.load Mint32(m_dry jm)b(Ptrofs.unsigned ofs)=Some(Vint(Int.repr(stat_steps s)))).
 apply core_load_load';eapply mapsto_core_load;exact Ent.
Qed.
Print Assumptions stats_repr_steps_mapsto.
Print Assumptions stats_repr_steps_load.
