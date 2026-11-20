(* Compact names for the declarations in the CompCert link. The following
   equalities certify both the external ABI and every internal body/spec. *)
Require Import VST.floyd.proofauto CCV.CCBodyLifts CCV.CCBodyProgram CCV.CCExpandedBody
 CCV.ccv_core CCV.ccv_primitives CCV.CCLinkedProgram CCV.CCSearchContext CCV.CCSearchSpecs CCV.CCDeclarationOrder.
Import ListNotations.
Definition external_row (n:nat):Clight.fundef:=snd(nth n (prog_funct linked_prog) (ccv_core._main,Internal ccv_core.f_search)).
Definition decl___compcert_i64_sar:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 12%nat) in exact v).
Definition decl___compcert_i64_smod:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 13%nat) in exact v).
Definition decl___compcert_i64_smulh:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 14%nat) in exact v).
Definition decl___compcert_i64_shl:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 15%nat) in exact v).
Definition decl___compcert_i64_shr:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 16%nat) in exact v).
Definition decl___compcert_i64_sdiv:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 17%nat) in exact v).
Definition decl___compcert_i64_stod:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 18%nat) in exact v).
Definition decl___compcert_i64_stof:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 19%nat) in exact v).
Definition decl___compcert_i64_umod:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 20%nat) in exact v).
Definition decl___compcert_i64_umulh:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 21%nat) in exact v).
Definition decl___compcert_i64_udiv:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 22%nat) in exact v).
Definition decl___compcert_i64_utod:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 23%nat) in exact v).
Definition decl___compcert_i64_utof:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 24%nat) in exact v).
Definition decl___compcert_i64_dtos:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 25%nat) in exact v).
Definition decl___compcert_i64_dtou:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 26%nat) in exact v).
Definition decl___compcert_va_composite:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 27%nat) in exact v).
Definition decl___compcert_va_int64:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 28%nat) in exact v).
Definition decl___compcert_va_int32:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 29%nat) in exact v).
Definition decl___compcert_va_float64:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 30%nat) in exact v).
Definition decl___builtin_write16_reversed:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 31%nat) in exact v).
Definition decl___builtin_write32_reversed:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 32%nat) in exact v).
Definition decl___builtin_clz:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 33%nat) in exact v).
Definition decl___builtin_clzl:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 34%nat) in exact v).
Definition decl___builtin_clzll:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 35%nat) in exact v).
Definition decl___builtin_ctz:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 36%nat) in exact v).
Definition decl___builtin_ctzl:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 37%nat) in exact v).
Definition decl___builtin_ctzll:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 38%nat) in exact v).
Definition decl___builtin_sqrt:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 39%nat) in exact v).
Definition decl___builtin_sel:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 40%nat) in exact v).
Definition decl___builtin_ais_annot:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 41%nat) in exact v).
Definition decl___builtin_annot_intval:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 42%nat) in exact v).
Definition decl___builtin_annot:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 43%nat) in exact v).
Definition decl___builtin_memcpy_aligned:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 44%nat) in exact v).
Definition decl___builtin_membar:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 45%nat) in exact v).
Definition decl___builtin_expect:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 46%nat) in exact v).
Definition decl___builtin_unreachable:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 47%nat) in exact v).
Definition decl___builtin_debug:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 48%nat) in exact v).
Definition decl___builtin_bswap64:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 49%nat) in exact v).
Definition decl___builtin_bswap:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 50%nat) in exact v).
Definition decl___builtin_bswap16:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 51%nat) in exact v).
Definition decl___builtin_bswap32:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 52%nat) in exact v).
Definition decl___builtin_read16_reversed:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 53%nat) in exact v).
Definition decl___builtin_read32_reversed:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 54%nat) in exact v).
Definition decl___builtin_fsqrt:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 55%nat) in exact v).
Definition decl___builtin_fabs:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 56%nat) in exact v).
Definition decl___builtin_fabsf:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 57%nat) in exact v).
Definition decl___builtin_fmsub:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 58%nat) in exact v).
Definition decl___builtin_fmin:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 59%nat) in exact v).
Definition decl___builtin_fmax:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 60%nat) in exact v).
Definition decl___builtin_fmadd:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 61%nat) in exact v).
Definition decl___builtin_fnmsub:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 62%nat) in exact v).
Definition decl___builtin_fnmadd:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 63%nat) in exact v).
Definition decl___builtin_va_copy:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 64%nat) in exact v).
Definition decl___builtin_va_start:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 65%nat) in exact v).
Definition decl___builtin_va_arg:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 66%nat) in exact v).
Definition decl___builtin_va_end:Clight.fundef:=ltac:(let v:=eval vm_compute in (external_row 67%nat) in exact v).
Definition compact_functions(search distance:statement):list(ident*Clight.fundef):=[
 (ccv_core._overlap,Internal ccv_core.f_overlap);
 (ccv_primitives._ccv_weight,Internal ccv_primitives.f_ccv_weight);
 (ccv_primitives._ccv_ceil_div,Internal ccv_primitives.f_ccv_ceil_div);
 (ccv_primitives._ccv_dot,Internal ccv_primitives.f_ccv_dot);
 (ccv_core._ccv_distance,Internal (with_body ccv_core.f_ccv_distance distance));
 (ccv_core._ccv_decide,Internal ccv_core.f_ccv_decide);
 (ccv_primitives._ccv_toggle,Internal ccv_primitives.f_ccv_toggle);
 (ccv_primitives._ccv_bit_xor,Internal ccv_primitives.f_ccv_bit_xor);
 (ccv_core._clear,Internal ccv_core.f_clear);
 (ccv_core._search,Internal (with_body ccv_core.f_search search));
 (ccv_core._shape,Internal ccv_core.f_shape);
 (ccv_core._stats_init,Internal ccv_core.f_stats_init);
 (ccv_core.___compcert_i64_sar,decl___compcert_i64_sar);
 (ccv_core.___compcert_i64_smod,decl___compcert_i64_smod);
 (ccv_core.___compcert_i64_smulh,decl___compcert_i64_smulh);
 (ccv_core.___compcert_i64_shl,decl___compcert_i64_shl);
 (ccv_core.___compcert_i64_shr,decl___compcert_i64_shr);
 (ccv_core.___compcert_i64_sdiv,decl___compcert_i64_sdiv);
 (ccv_core.___compcert_i64_stod,decl___compcert_i64_stod);
 (ccv_core.___compcert_i64_stof,decl___compcert_i64_stof);
 (ccv_core.___compcert_i64_umod,decl___compcert_i64_umod);
 (ccv_core.___compcert_i64_umulh,decl___compcert_i64_umulh);
 (ccv_core.___compcert_i64_udiv,decl___compcert_i64_udiv);
 (ccv_core.___compcert_i64_utod,decl___compcert_i64_utod);
 (ccv_core.___compcert_i64_utof,decl___compcert_i64_utof);
 (ccv_core.___compcert_i64_dtos,decl___compcert_i64_dtos);
 (ccv_core.___compcert_i64_dtou,decl___compcert_i64_dtou);
 (ccv_core.___compcert_va_composite,decl___compcert_va_composite);
 (ccv_core.___compcert_va_int64,decl___compcert_va_int64);
 (ccv_core.___compcert_va_int32,decl___compcert_va_int32);
 (ccv_core.___compcert_va_float64,decl___compcert_va_float64);
 (ccv_core.___builtin_write16_reversed,decl___builtin_write16_reversed);
 (ccv_core.___builtin_write32_reversed,decl___builtin_write32_reversed);
 (ccv_core.___builtin_clz,decl___builtin_clz);
 (ccv_core.___builtin_clzl,decl___builtin_clzl);
 (ccv_core.___builtin_clzll,decl___builtin_clzll);
 (ccv_core.___builtin_ctz,decl___builtin_ctz);
 (ccv_core.___builtin_ctzl,decl___builtin_ctzl);
 (ccv_core.___builtin_ctzll,decl___builtin_ctzll);
 (ccv_core.___builtin_sqrt,decl___builtin_sqrt);
 (ccv_core.___builtin_sel,decl___builtin_sel);
 (ccv_core.___builtin_ais_annot,decl___builtin_ais_annot);
 (ccv_core.___builtin_annot_intval,decl___builtin_annot_intval);
 (ccv_core.___builtin_annot,decl___builtin_annot);
 (ccv_core.___builtin_memcpy_aligned,decl___builtin_memcpy_aligned);
 (ccv_core.___builtin_membar,decl___builtin_membar);
 (ccv_core.___builtin_expect,decl___builtin_expect);
 (ccv_core.___builtin_unreachable,decl___builtin_unreachable);
 (ccv_core.___builtin_debug,decl___builtin_debug);
 (ccv_core.___builtin_bswap64,decl___builtin_bswap64);
 (ccv_core.___builtin_bswap,decl___builtin_bswap);
 (ccv_core.___builtin_bswap16,decl___builtin_bswap16);
 (ccv_core.___builtin_bswap32,decl___builtin_bswap32);
 (ccv_core.___builtin_read16_reversed,decl___builtin_read16_reversed);
 (ccv_core.___builtin_read32_reversed,decl___builtin_read32_reversed);
 (ccv_core.___builtin_fsqrt,decl___builtin_fsqrt);
 (ccv_core.___builtin_fabs,decl___builtin_fabs);
 (ccv_core.___builtin_fabsf,decl___builtin_fabsf);
 (ccv_core.___builtin_fmsub,decl___builtin_fmsub);
 (ccv_core.___builtin_fmin,decl___builtin_fmin);
 (ccv_core.___builtin_fmax,decl___builtin_fmax);
 (ccv_core.___builtin_fmadd,decl___builtin_fmadd);
 (ccv_core.___builtin_fnmsub,decl___builtin_fnmsub);
 (ccv_core.___builtin_fnmadd,decl___builtin_fnmadd);
 (ccv_core.___builtin_va_copy,decl___builtin_va_copy);
 (ccv_core.___builtin_va_start,decl___builtin_va_start);
 (ccv_core.___builtin_va_arg,decl___builtin_va_arg);
 (ccv_core.___builtin_va_end,decl___builtin_va_end);
 (ccv_core._leaf,Internal ccv_core.f_leaf);
 (ccv_core._toggle,Internal ccv_core.f_toggle);
 (ccv_core._bounds,Internal ccv_core.f_bounds);
 (ccv_core._restore,Internal ccv_core.f_restore);
 (ccv_core._nontrivial,Internal ccv_core.f_nontrivial);
 (ccv_core._forbid,Internal ccv_core.f_forbid);
 (ccv_core._validate,Internal ccv_core.f_validate)].
Definition compact_specs:funspecs:=[
 VerifOverlap.overlap_spec;
 VerifWeight.weight_spec;
 VerifPrimitives.ceil_div_spec;
 VerifDot.dot_spec;
 CCSearchSpecs.distance_spec;
 CCSearchSpecs.decide_spec;
 VerifToggle.toggle_spec;
 VerifPrimitives.bit_xor_spec;
 VerifClear.clear_spec;
 CCSearchSpecs.search_spec;
 VerifShape.shape_spec;
 VerifStats.stats_init_spec;
 (ccv_core.___compcert_i64_sar,vacuous_funspec decl___compcert_i64_sar);
 (ccv_core.___compcert_i64_smod,vacuous_funspec decl___compcert_i64_smod);
 (ccv_core.___compcert_i64_smulh,vacuous_funspec decl___compcert_i64_smulh);
 (ccv_core.___compcert_i64_shl,vacuous_funspec decl___compcert_i64_shl);
 (ccv_core.___compcert_i64_shr,vacuous_funspec decl___compcert_i64_shr);
 (ccv_core.___compcert_i64_sdiv,vacuous_funspec decl___compcert_i64_sdiv);
 (ccv_core.___compcert_i64_stod,vacuous_funspec decl___compcert_i64_stod);
 (ccv_core.___compcert_i64_stof,vacuous_funspec decl___compcert_i64_stof);
 (ccv_core.___compcert_i64_umod,vacuous_funspec decl___compcert_i64_umod);
 (ccv_core.___compcert_i64_umulh,vacuous_funspec decl___compcert_i64_umulh);
 (ccv_core.___compcert_i64_udiv,vacuous_funspec decl___compcert_i64_udiv);
 (ccv_core.___compcert_i64_utod,vacuous_funspec decl___compcert_i64_utod);
 (ccv_core.___compcert_i64_utof,vacuous_funspec decl___compcert_i64_utof);
 (ccv_core.___compcert_i64_dtos,vacuous_funspec decl___compcert_i64_dtos);
 (ccv_core.___compcert_i64_dtou,vacuous_funspec decl___compcert_i64_dtou);
 (ccv_core.___compcert_va_composite,vacuous_funspec decl___compcert_va_composite);
 (ccv_core.___compcert_va_int64,vacuous_funspec decl___compcert_va_int64);
 (ccv_core.___compcert_va_int32,vacuous_funspec decl___compcert_va_int32);
 (ccv_core.___compcert_va_float64,vacuous_funspec decl___compcert_va_float64);
 (ccv_core.___builtin_write16_reversed,vacuous_funspec decl___builtin_write16_reversed);
 (ccv_core.___builtin_write32_reversed,vacuous_funspec decl___builtin_write32_reversed);
 (ccv_core.___builtin_clz,vacuous_funspec decl___builtin_clz);
 (ccv_core.___builtin_clzl,vacuous_funspec decl___builtin_clzl);
 (ccv_core.___builtin_clzll,vacuous_funspec decl___builtin_clzll);
 (ccv_core.___builtin_ctz,vacuous_funspec decl___builtin_ctz);
 (ccv_core.___builtin_ctzl,vacuous_funspec decl___builtin_ctzl);
 (ccv_core.___builtin_ctzll,vacuous_funspec decl___builtin_ctzll);
 (ccv_core.___builtin_sqrt,vacuous_funspec decl___builtin_sqrt);
 (ccv_core.___builtin_sel,vacuous_funspec decl___builtin_sel);
 (ccv_core.___builtin_ais_annot,vacuous_funspec decl___builtin_ais_annot);
 (ccv_core.___builtin_annot_intval,vacuous_funspec decl___builtin_annot_intval);
 (ccv_core.___builtin_annot,vacuous_funspec decl___builtin_annot);
 (ccv_core.___builtin_memcpy_aligned,vacuous_funspec decl___builtin_memcpy_aligned);
 (ccv_core.___builtin_membar,vacuous_funspec decl___builtin_membar);
 (ccv_core.___builtin_expect,vacuous_funspec decl___builtin_expect);
 (ccv_core.___builtin_unreachable,vacuous_funspec decl___builtin_unreachable);
 (ccv_core.___builtin_debug,vacuous_funspec decl___builtin_debug);
 (ccv_core.___builtin_bswap64,vacuous_funspec decl___builtin_bswap64);
 (ccv_core.___builtin_bswap,vacuous_funspec decl___builtin_bswap);
 (ccv_core.___builtin_bswap16,vacuous_funspec decl___builtin_bswap16);
 (ccv_core.___builtin_bswap32,vacuous_funspec decl___builtin_bswap32);
 (ccv_core.___builtin_read16_reversed,vacuous_funspec decl___builtin_read16_reversed);
 (ccv_core.___builtin_read32_reversed,vacuous_funspec decl___builtin_read32_reversed);
 (ccv_core.___builtin_fsqrt,vacuous_funspec decl___builtin_fsqrt);
 (ccv_core.___builtin_fabs,vacuous_funspec decl___builtin_fabs);
 (ccv_core.___builtin_fabsf,vacuous_funspec decl___builtin_fabsf);
 (ccv_core.___builtin_fmsub,vacuous_funspec decl___builtin_fmsub);
 (ccv_core.___builtin_fmin,vacuous_funspec decl___builtin_fmin);
 (ccv_core.___builtin_fmax,vacuous_funspec decl___builtin_fmax);
 (ccv_core.___builtin_fmadd,vacuous_funspec decl___builtin_fmadd);
 (ccv_core.___builtin_fnmsub,vacuous_funspec decl___builtin_fnmsub);
 (ccv_core.___builtin_fnmadd,vacuous_funspec decl___builtin_fnmadd);
 (ccv_core.___builtin_va_copy,vacuous_funspec decl___builtin_va_copy);
 (ccv_core.___builtin_va_start,vacuous_funspec decl___builtin_va_start);
 (ccv_core.___builtin_va_arg,vacuous_funspec decl___builtin_va_arg);
 (ccv_core.___builtin_va_end,vacuous_funspec decl___builtin_va_end);
 VerifLeaf.leaf_spec;
 VerifCoreToggle.core_toggle_spec;
 VerifBounds.bounds_spec;
 VerifRestore.restore_spec;
 VerifNontrivial.nontrivial_spec;
 VerifForbid.forbid_spec;
 VerifValidate.validate_spec].
Lemma compact_library_correct s d:prog_funct (proof_library s d)=compact_functions s d.
Proof. reflexivity. Qed.
Lemma compact_specs_correct:compact_specs=linked_Gprog.
Proof. reflexivity. Qed.
