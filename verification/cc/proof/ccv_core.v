From Coq Require Import String List ZArith.
From compcert Require Import Coqlib Integers Floats AST Ctypes Cop Clight Clightdefs.
Import Clightdefs.ClightNotations.
Local Open Scope Z_scope.
Local Open Scope string_scope.
Local Open Scope clight_scope.

Module Info.
  Definition version := "3.13".
  Definition build_number := "".
  Definition build_tag := "".
  Definition build_branch := "".
  Definition arch := "x86".
  Definition model := "64".
  Definition abi := "standard".
  Definition bitsize := 64.
  Definition big_endian := false.
  Definition source_file := "ccv.c".
  Definition normalized := true.
End Info.

Definition ___builtin_ais_annot : ident := $"__builtin_ais_annot".
Definition ___builtin_annot : ident := $"__builtin_annot".
Definition ___builtin_annot_intval : ident := $"__builtin_annot_intval".
Definition ___builtin_bswap : ident := $"__builtin_bswap".
Definition ___builtin_bswap16 : ident := $"__builtin_bswap16".
Definition ___builtin_bswap32 : ident := $"__builtin_bswap32".
Definition ___builtin_bswap64 : ident := $"__builtin_bswap64".
Definition ___builtin_clz : ident := $"__builtin_clz".
Definition ___builtin_clzl : ident := $"__builtin_clzl".
Definition ___builtin_clzll : ident := $"__builtin_clzll".
Definition ___builtin_ctz : ident := $"__builtin_ctz".
Definition ___builtin_ctzl : ident := $"__builtin_ctzl".
Definition ___builtin_ctzll : ident := $"__builtin_ctzll".
Definition ___builtin_debug : ident := $"__builtin_debug".
Definition ___builtin_expect : ident := $"__builtin_expect".
Definition ___builtin_fabs : ident := $"__builtin_fabs".
Definition ___builtin_fabsf : ident := $"__builtin_fabsf".
Definition ___builtin_fmadd : ident := $"__builtin_fmadd".
Definition ___builtin_fmax : ident := $"__builtin_fmax".
Definition ___builtin_fmin : ident := $"__builtin_fmin".
Definition ___builtin_fmsub : ident := $"__builtin_fmsub".
Definition ___builtin_fnmadd : ident := $"__builtin_fnmadd".
Definition ___builtin_fnmsub : ident := $"__builtin_fnmsub".
Definition ___builtin_fsqrt : ident := $"__builtin_fsqrt".
Definition ___builtin_membar : ident := $"__builtin_membar".
Definition ___builtin_memcpy_aligned : ident := $"__builtin_memcpy_aligned".
Definition ___builtin_read16_reversed : ident := $"__builtin_read16_reversed".
Definition ___builtin_read32_reversed : ident := $"__builtin_read32_reversed".
Definition ___builtin_sel : ident := $"__builtin_sel".
Definition ___builtin_sqrt : ident := $"__builtin_sqrt".
Definition ___builtin_unreachable : ident := $"__builtin_unreachable".
Definition ___builtin_va_arg : ident := $"__builtin_va_arg".
Definition ___builtin_va_copy : ident := $"__builtin_va_copy".
Definition ___builtin_va_end : ident := $"__builtin_va_end".
Definition ___builtin_va_start : ident := $"__builtin_va_start".
Definition ___builtin_write16_reversed : ident := $"__builtin_write16_reversed".
Definition ___builtin_write32_reversed : ident := $"__builtin_write32_reversed".
Definition ___compcert_i64_dtos : ident := $"__compcert_i64_dtos".
Definition ___compcert_i64_dtou : ident := $"__compcert_i64_dtou".
Definition ___compcert_i64_sar : ident := $"__compcert_i64_sar".
Definition ___compcert_i64_sdiv : ident := $"__compcert_i64_sdiv".
Definition ___compcert_i64_shl : ident := $"__compcert_i64_shl".
Definition ___compcert_i64_shr : ident := $"__compcert_i64_shr".
Definition ___compcert_i64_smod : ident := $"__compcert_i64_smod".
Definition ___compcert_i64_smulh : ident := $"__compcert_i64_smulh".
Definition ___compcert_i64_stod : ident := $"__compcert_i64_stod".
Definition ___compcert_i64_stof : ident := $"__compcert_i64_stof".
Definition ___compcert_i64_udiv : ident := $"__compcert_i64_udiv".
Definition ___compcert_i64_umod : ident := $"__compcert_i64_umod".
Definition ___compcert_i64_umulh : ident := $"__compcert_i64_umulh".
Definition ___compcert_i64_utod : ident := $"__compcert_i64_utod".
Definition ___compcert_i64_utof : ident := $"__compcert_i64_utof".
Definition ___compcert_va_composite : ident := $"__compcert_va_composite".
Definition ___compcert_va_float64 : ident := $"__compcert_va_float64".
Definition ___compcert_va_int32 : ident := $"__compcert_va_int32".
Definition ___compcert_va_int64 : ident := $"__compcert_va_int64".
Definition _best : ident := $"best".
Definition _bounds : ident := $"bounds".
Definition _budget : ident := $"budget".
Definition _cap : ident := $"cap".
Definition _capacity : ident := $"capacity".
Definition _ccv_ceil_div : ident := $"ccv_ceil_div".
Definition _ccv_decide : ident := $"ccv_decide".
Definition _ccv_distance : ident := $"ccv_distance".
Definition _ccv_frame : ident := $"ccv_frame".
Definition _ccv_problem : ident := $"ccv_problem".
Definition _ccv_stats : ident := $"ccv_stats".
Definition _ccv_weight : ident := $"ccv_weight".
Definition _ccv_workspace : ident := $"ccv_workspace".
Definition _charge_prunes : ident := $"charge_prunes".
Definition _checks : ident := $"checks".
Definition _chosen : ident := $"chosen".
Definition _clear : ident := $"clear".
Definition _count : ident := $"count".
Definition _deg : ident := $"deg".
Definition _depth : ident := $"depth".
Definition _distance : ident := $"distance".
Definition _f : ident := $"f".
Definition _finish : ident := $"finish".
Definition _forbid : ident := $"forbid".
Definition _forbidden : ident := $"forbidden".
Definition _frame_capacity : ident := $"frame_capacity".
Definition _frames : ident := $"frames".
Definition _h : ident := $"h".
Definition _i : ident := $"i".
Definition _j : ident := $"j".
Definition _lb : ident := $"lb".
Definition _leaf : ident := $"leaf".
Definition _limit : ident := $"limit".
Definition _logical : ident := $"logical".
Definition _logical_rows : ident := $"logical_rows".
Definition _logical_value : ident := $"logical_value".
Definition _main : ident := $"main".
Definition _mark : ident := $"mark".
Definition _maxdeg : ident := $"maxdeg".
Definition _n : ident := $"n".
Definition _next : ident := $"next".
Definition _nodes : ident := $"nodes".
Definition _nontrivial : ident := $"nontrivial".
Definition _odd : ident := $"odd".
Definition _ok : ident := $"ok".
Definition _out : ident := $"out".
Definition _ov : ident := $"ov".
Definition _overlap : ident := $"overlap".
Definition _overlap_prunes : ident := $"overlap_prunes".
Definition _p : ident := $"p".
Definition _pack : ident := $"pack".
Definition _pack_prunes : ident := $"pack_prunes".
Definition _packed : ident := $"packed".
Definition _phase : ident := $"phase".
Definition _q : ident := $"q".
Definition _remaining : ident := $"remaining".
Definition _restore : ident := $"restore".
Definition _result : ident := $"result".
Definition _row : ident := $"row".
Definition _rules : ident := $"rules".
Definition _s : ident := $"s".
Definition _search : ident := $"search".
Definition _seed : ident := $"seed".
Definition _selected : ident := $"selected".
Definition _shape : ident := $"shape".
Definition _stabilizer : ident := $"stabilizer".
Definition _stabilizers : ident := $"stabilizers".
Definition _stats : ident := $"stats".
Definition _stats_init : ident := $"stats_init".
Definition _steps : ident := $"steps".
Definition _syndrome : ident := $"syndrome".
Definition _toggle : ident := $"toggle".
Definition _top : ident := $"top".
Definition _undo : ident := $"undo".
Definition _used : ident := $"used".
Definition _v : ident := $"v".
Definition _validate : ident := $"validate".
Definition _w : ident := $"w".
Definition _weight : ident := $"weight".
Definition _t'1 : ident := 128%positive.
Definition _t'10 : ident := 137%positive.
Definition _t'11 : ident := 138%positive.
Definition _t'12 : ident := 139%positive.
Definition _t'13 : ident := 140%positive.
Definition _t'14 : ident := 141%positive.
Definition _t'15 : ident := 142%positive.
Definition _t'16 : ident := 143%positive.
Definition _t'17 : ident := 144%positive.
Definition _t'18 : ident := 145%positive.
Definition _t'19 : ident := 146%positive.
Definition _t'2 : ident := 129%positive.
Definition _t'20 : ident := 147%positive.
Definition _t'21 : ident := 148%positive.
Definition _t'22 : ident := 149%positive.
Definition _t'23 : ident := 150%positive.
Definition _t'24 : ident := 151%positive.
Definition _t'25 : ident := 152%positive.
Definition _t'26 : ident := 153%positive.
Definition _t'27 : ident := 154%positive.
Definition _t'28 : ident := 155%positive.
Definition _t'29 : ident := 156%positive.
Definition _t'3 : ident := 130%positive.
Definition _t'30 : ident := 157%positive.
Definition _t'31 : ident := 158%positive.
Definition _t'32 : ident := 159%positive.
Definition _t'33 : ident := 160%positive.
Definition _t'34 : ident := 161%positive.
Definition _t'35 : ident := 162%positive.
Definition _t'36 : ident := 163%positive.
Definition _t'37 : ident := 164%positive.
Definition _t'38 : ident := 165%positive.
Definition _t'39 : ident := 166%positive.
Definition _t'4 : ident := 131%positive.
Definition _t'40 : ident := 167%positive.
Definition _t'41 : ident := 168%positive.
Definition _t'42 : ident := 169%positive.
Definition _t'43 : ident := 170%positive.
Definition _t'44 : ident := 171%positive.
Definition _t'45 : ident := 172%positive.
Definition _t'46 : ident := 173%positive.
Definition _t'47 : ident := 174%positive.
Definition _t'48 : ident := 175%positive.
Definition _t'49 : ident := 176%positive.
Definition _t'5 : ident := 132%positive.
Definition _t'50 : ident := 177%positive.
Definition _t'51 : ident := 178%positive.
Definition _t'6 : ident := 133%positive.
Definition _t'7 : ident := 134%positive.
Definition _t'8 : ident := 135%positive.
Definition _t'9 : ident := 136%positive.

Definition f_shape := {|
  fn_return := tint;
  fn_callconv := cc_default;
  fn_params := ((_p, (tptr (Tstruct _ccv_problem noattr))) ::
                (_w, (tptr (Tstruct _ccv_workspace noattr))) ::
                (_rules, tuint) :: nil);
  fn_vars := nil;
  fn_temps := ((_n, tuint) :: (_t'7, tint) :: (_t'6, tint) :: (_t'5, tint) ::
               (_t'4, tint) :: (_t'3, tint) :: (_t'2, tint) ::
               (_t'1, tint) :: (_t'13, tuint) :: (_t'12, tuint) ::
               (_t'11, tuint) :: (_t'10, tuint) :: (_t'9, tuint) ::
               (_t'8, tuint) :: nil);
  fn_body :=
(Ssequence
  (Sset _n
    (Efield
      (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
        (Tstruct _ccv_problem noattr)) _n tuint))
  (Ssequence
    (Ssequence
      (Ssequence
        (Sifthenelse (Ebinop Oeq (Etempvar _n tuint)
                       (Econst_int (Int.repr 0) tuint) tint)
          (Sset _t'1 (Econst_int (Int.repr 1) tint))
          (Sset _t'1
            (Ecast
              (Ebinop Ogt (Etempvar _n tuint)
                (Ebinop Odiv (Econst_int (Int.repr 2147483647) tuint)
                  (Esizeof (Tstruct _ccv_frame noattr) tulong) tulong) tint)
              tbool)))
        (Sifthenelse (Etempvar _t'1 tint)
          (Sset _t'2 (Econst_int (Int.repr 1) tint))
          (Sset _t'2
            (Ecast
              (Ebinop Ogt (Etempvar _n tuint)
                (Ebinop Odiv (Econst_int (Int.repr 2147483647) tuint)
                  (Esizeof tuint tulong) tulong) tint) tbool))))
      (Sifthenelse (Etempvar _t'2 tint)
        (Sreturn (Some (Econst_int (Int.repr 0) tint)))
        Sskip))
    (Ssequence
      (Ssequence
        (Ssequence
          (Ssequence
            (Ssequence
              (Sset _t'12
                (Efield
                  (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                    (Tstruct _ccv_problem noattr)) _logical_rows tuint))
              (Sifthenelse (Ebinop Oeq (Etempvar _t'12 tuint)
                             (Econst_int (Int.repr 0) tuint) tint)
                (Sset _t'3 (Econst_int (Int.repr 1) tint))
                (Ssequence
                  (Sset _t'13
                    (Efield
                      (Ederef
                        (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                        (Tstruct _ccv_problem noattr)) _checks tuint))
                  (Sset _t'3
                    (Ecast
                      (Ebinop Ogt (Etempvar _t'13 tuint)
                        (Ebinop Odiv (Econst_int (Int.repr 2147483647) tuint)
                          (Etempvar _n tuint) tuint) tint) tbool)))))
            (Sifthenelse (Etempvar _t'3 tint)
              (Sset _t'4 (Econst_int (Int.repr 1) tint))
              (Ssequence
                (Sset _t'11
                  (Efield
                    (Ederef
                      (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                      (Tstruct _ccv_problem noattr)) _logical_rows tuint))
                (Sset _t'4
                  (Ecast
                    (Ebinop Ogt (Etempvar _t'11 tuint)
                      (Ebinop Odiv (Econst_int (Int.repr 2147483647) tuint)
                        (Etempvar _n tuint) tuint) tint) tbool)))))
          (Sifthenelse (Etempvar _t'4 tint)
            (Sset _t'5 (Econst_int (Int.repr 1) tint))
            (Ssequence
              (Sset _t'10
                (Efield
                  (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                    (Tstruct _ccv_problem noattr)) _stabilizers tuint))
              (Sset _t'5
                (Ecast
                  (Ebinop Ogt (Etempvar _t'10 tuint)
                    (Ebinop Odiv (Econst_int (Int.repr 2147483647) tuint)
                      (Etempvar _n tuint) tuint) tint) tbool)))))
        (Sifthenelse (Etempvar _t'5 tint)
          (Sreturn (Some (Econst_int (Int.repr 0) tint)))
          Sskip))
      (Ssequence
        (Ssequence
          (Ssequence
            (Ssequence
              (Sset _t'8
                (Efield
                  (Ederef
                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                    (Tstruct _ccv_workspace noattr)) _capacity tuint))
              (Sifthenelse (Ebinop Olt (Etempvar _t'8 tuint)
                             (Etempvar _n tuint) tint)
                (Sset _t'6 (Econst_int (Int.repr 1) tint))
                (Ssequence
                  (Sset _t'9
                    (Efield
                      (Ederef
                        (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                        (Tstruct _ccv_workspace noattr)) _frame_capacity
                      tuint))
                  (Sset _t'6
                    (Ecast
                      (Ebinop Olt (Etempvar _t'9 tuint) (Etempvar _n tuint)
                        tint) tbool)))))
            (Sifthenelse (Etempvar _t'6 tint)
              (Sset _t'7 (Econst_int (Int.repr 1) tint))
              (Sset _t'7
                (Ecast
                  (Ebinop Ogt (Etempvar _rules tuint)
                    (Econst_int (Int.repr 63) tuint) tint) tbool))))
          (Sifthenelse (Etempvar _t'7 tint)
            (Sreturn (Some (Econst_int (Int.repr 0) tint)))
            Sskip))
        (Sreturn (Some (Econst_int (Int.repr 1) tint)))))))
|}.

Definition f_validate := {|
  fn_return := tint;
  fn_callconv := cc_default;
  fn_params := ((_p, (tptr (Tstruct _ccv_problem noattr))) :: nil);
  fn_vars := nil;
  fn_temps := ((_i, tuint) :: (_j, tuint) :: (_q, tuint) :: (_v, tuint) ::
               (_t'30, tuint) :: (_t'29, tuint) :: (_t'28, tuchar) ::
               (_t'27, (tptr tuchar)) :: (_t'26, tuint) :: (_t'25, tuint) ::
               (_t'24, tuchar) :: (_t'23, (tptr tuchar)) :: (_t'22, tuint) ::
               (_t'21, tuint) :: (_t'20, tuchar) :: (_t'19, (tptr tuchar)) ::
               (_t'18, tuint) :: (_t'17, tuint) :: (_t'16, tuint) ::
               (_t'15, tuint) :: (_t'14, tuchar) :: (_t'13, tuint) ::
               (_t'12, (tptr tuchar)) :: (_t'11, tuchar) :: (_t'10, tuint) ::
               (_t'9, (tptr tuchar)) :: (_t'8, tuchar) :: (_t'7, tuint) ::
               (_t'6, (tptr tuchar)) :: (_t'5, tuchar) :: (_t'4, tuint) ::
               (_t'3, tuint) :: (_t'2, (tptr tuchar)) :: (_t'1, tuint) ::
               nil);
  fn_body :=
(Ssequence
  (Ssequence
    (Sset _i (Econst_int (Int.repr 0) tuint))
    (Sloop
      (Ssequence
        (Ssequence
          (Sset _t'29
            (Efield
              (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                (Tstruct _ccv_problem noattr)) _checks tuint))
          (Ssequence
            (Sset _t'30
              (Efield
                (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                  (Tstruct _ccv_problem noattr)) _n tuint))
            (Sifthenelse (Ebinop Olt (Etempvar _i tuint)
                           (Ebinop Omul (Etempvar _t'29 tuint)
                             (Etempvar _t'30 tuint) tuint) tint)
              Sskip
              Sbreak)))
        (Ssequence
          (Sset _t'27
            (Efield
              (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                (Tstruct _ccv_problem noattr)) _h (tptr tuchar)))
          (Ssequence
            (Sset _t'28
              (Ederef
                (Ebinop Oadd (Etempvar _t'27 (tptr tuchar))
                  (Etempvar _i tuint) (tptr tuchar)) tuchar))
            (Sifthenelse (Ebinop Ogt (Etempvar _t'28 tuchar)
                           (Econst_int (Int.repr 1) tuint) tint)
              (Sreturn (Some (Econst_int (Int.repr 0) tint)))
              Sskip))))
      (Sset _i
        (Ebinop Oadd (Etempvar _i tuint) (Econst_int (Int.repr 1) tint)
          tuint))))
  (Ssequence
    (Ssequence
      (Sset _i (Econst_int (Int.repr 0) tuint))
      (Sloop
        (Ssequence
          (Ssequence
            (Sset _t'25
              (Efield
                (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                  (Tstruct _ccv_problem noattr)) _logical_rows tuint))
            (Ssequence
              (Sset _t'26
                (Efield
                  (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                    (Tstruct _ccv_problem noattr)) _n tuint))
              (Sifthenelse (Ebinop Olt (Etempvar _i tuint)
                             (Ebinop Omul (Etempvar _t'25 tuint)
                               (Etempvar _t'26 tuint) tuint) tint)
                Sskip
                Sbreak)))
          (Ssequence
            (Sset _t'23
              (Efield
                (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                  (Tstruct _ccv_problem noattr)) _logical (tptr tuchar)))
            (Ssequence
              (Sset _t'24
                (Ederef
                  (Ebinop Oadd (Etempvar _t'23 (tptr tuchar))
                    (Etempvar _i tuint) (tptr tuchar)) tuchar))
              (Sifthenelse (Ebinop Ogt (Etempvar _t'24 tuchar)
                             (Econst_int (Int.repr 1) tuint) tint)
                (Sreturn (Some (Econst_int (Int.repr 0) tint)))
                Sskip))))
        (Sset _i
          (Ebinop Oadd (Etempvar _i tuint) (Econst_int (Int.repr 1) tint)
            tuint))))
    (Ssequence
      (Ssequence
        (Sset _i (Econst_int (Int.repr 0) tuint))
        (Sloop
          (Ssequence
            (Ssequence
              (Sset _t'21
                (Efield
                  (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                    (Tstruct _ccv_problem noattr)) _stabilizers tuint))
              (Ssequence
                (Sset _t'22
                  (Efield
                    (Ederef
                      (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                      (Tstruct _ccv_problem noattr)) _n tuint))
                (Sifthenelse (Ebinop Olt (Etempvar _i tuint)
                               (Ebinop Omul (Etempvar _t'21 tuint)
                                 (Etempvar _t'22 tuint) tuint) tint)
                  Sskip
                  Sbreak)))
            (Ssequence
              (Sset _t'19
                (Efield
                  (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                    (Tstruct _ccv_problem noattr)) _stabilizer (tptr tuchar)))
              (Ssequence
                (Sset _t'20
                  (Ederef
                    (Ebinop Oadd (Etempvar _t'19 (tptr tuchar))
                      (Etempvar _i tuint) (tptr tuchar)) tuchar))
                (Sifthenelse (Ebinop Ogt (Etempvar _t'20 tuchar)
                               (Econst_int (Int.repr 1) tuint) tint)
                  (Sreturn (Some (Econst_int (Int.repr 0) tint)))
                  Sskip))))
          (Sset _i
            (Ebinop Oadd (Etempvar _i tuint) (Econst_int (Int.repr 1) tint)
              tuint))))
      (Ssequence
        (Ssequence
          (Sset _i (Econst_int (Int.repr 0) tuint))
          (Sloop
            (Ssequence
              (Ssequence
                (Sset _t'18
                  (Efield
                    (Ederef
                      (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                      (Tstruct _ccv_problem noattr)) _stabilizers tuint))
                (Sifthenelse (Ebinop Olt (Etempvar _i tuint)
                               (Etempvar _t'18 tuint) tint)
                  Sskip
                  Sbreak))
              (Ssequence
                (Sset _j (Econst_int (Int.repr 0) tuint))
                (Sloop
                  (Ssequence
                    (Ssequence
                      (Sset _t'16
                        (Efield
                          (Ederef
                            (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                            (Tstruct _ccv_problem noattr)) _checks tuint))
                      (Ssequence
                        (Sset _t'17
                          (Efield
                            (Ederef
                              (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                              (Tstruct _ccv_problem noattr)) _logical_rows
                            tuint))
                        (Sifthenelse (Ebinop Olt (Etempvar _j tuint)
                                       (Ebinop Oadd (Etempvar _t'16 tuint)
                                         (Etempvar _t'17 tuint) tuint) tint)
                          Sskip
                          Sbreak)))
                    (Ssequence
                      (Sset _v (Econst_int (Int.repr 0) tuint))
                      (Ssequence
                        (Ssequence
                          (Sset _q (Econst_int (Int.repr 0) tuint))
                          (Sloop
                            (Ssequence
                              (Ssequence
                                (Sset _t'15
                                  (Efield
                                    (Ederef
                                      (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                      (Tstruct _ccv_problem noattr)) _n
                                    tuint))
                                (Sifthenelse (Ebinop Olt (Etempvar _q tuint)
                                               (Etempvar _t'15 tuint) tint)
                                  Sskip
                                  Sbreak))
                              (Ssequence
                                (Sset _t'1
                                  (Efield
                                    (Ederef
                                      (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                      (Tstruct _ccv_problem noattr)) _checks
                                    tuint))
                                (Sifthenelse (Ebinop Olt (Etempvar _j tuint)
                                               (Etempvar _t'1 tuint) tint)
                                  (Ssequence
                                    (Sset _t'9
                                      (Efield
                                        (Ederef
                                          (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                          (Tstruct _ccv_problem noattr)) _h
                                        (tptr tuchar)))
                                    (Ssequence
                                      (Sset _t'10
                                        (Efield
                                          (Ederef
                                            (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                            (Tstruct _ccv_problem noattr)) _n
                                          tuint))
                                      (Ssequence
                                        (Sset _t'11
                                          (Ederef
                                            (Ebinop Oadd
                                              (Etempvar _t'9 (tptr tuchar))
                                              (Ebinop Oadd
                                                (Ebinop Omul
                                                  (Etempvar _j tuint)
                                                  (Etempvar _t'10 tuint)
                                                  tuint) (Etempvar _q tuint)
                                                tuint) (tptr tuchar)) tuchar))
                                        (Ssequence
                                          (Sset _t'12
                                            (Efield
                                              (Ederef
                                                (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                (Tstruct _ccv_problem noattr))
                                              _stabilizer (tptr tuchar)))
                                          (Ssequence
                                            (Sset _t'13
                                              (Efield
                                                (Ederef
                                                  (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                  (Tstruct _ccv_problem noattr))
                                                _n tuint))
                                            (Ssequence
                                              (Sset _t'14
                                                (Ederef
                                                  (Ebinop Oadd
                                                    (Etempvar _t'12 (tptr tuchar))
                                                    (Ebinop Oadd
                                                      (Ebinop Omul
                                                        (Etempvar _i tuint)
                                                        (Etempvar _t'13 tuint)
                                                        tuint)
                                                      (Etempvar _q tuint)
                                                      tuint) (tptr tuchar))
                                                  tuchar))
                                              (Sset _v
                                                (Ebinop Oxor
                                                  (Etempvar _v tuint)
                                                  (Ebinop Oand
                                                    (Etempvar _t'11 tuchar)
                                                    (Etempvar _t'14 tuchar)
                                                    tint) tuint))))))))
                                  (Ssequence
                                    (Sset _t'2
                                      (Efield
                                        (Ederef
                                          (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                          (Tstruct _ccv_problem noattr))
                                        _logical (tptr tuchar)))
                                    (Ssequence
                                      (Sset _t'3
                                        (Efield
                                          (Ederef
                                            (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                            (Tstruct _ccv_problem noattr))
                                          _checks tuint))
                                      (Ssequence
                                        (Sset _t'4
                                          (Efield
                                            (Ederef
                                              (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                              (Tstruct _ccv_problem noattr))
                                            _n tuint))
                                        (Ssequence
                                          (Sset _t'5
                                            (Ederef
                                              (Ebinop Oadd
                                                (Etempvar _t'2 (tptr tuchar))
                                                (Ebinop Oadd
                                                  (Ebinop Omul
                                                    (Ebinop Osub
                                                      (Etempvar _j tuint)
                                                      (Etempvar _t'3 tuint)
                                                      tuint)
                                                    (Etempvar _t'4 tuint)
                                                    tuint)
                                                  (Etempvar _q tuint) tuint)
                                                (tptr tuchar)) tuchar))
                                          (Ssequence
                                            (Sset _t'6
                                              (Efield
                                                (Ederef
                                                  (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                  (Tstruct _ccv_problem noattr))
                                                _stabilizer (tptr tuchar)))
                                            (Ssequence
                                              (Sset _t'7
                                                (Efield
                                                  (Ederef
                                                    (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                    (Tstruct _ccv_problem noattr))
                                                  _n tuint))
                                              (Ssequence
                                                (Sset _t'8
                                                  (Ederef
                                                    (Ebinop Oadd
                                                      (Etempvar _t'6 (tptr tuchar))
                                                      (Ebinop Oadd
                                                        (Ebinop Omul
                                                          (Etempvar _i tuint)
                                                          (Etempvar _t'7 tuint)
                                                          tuint)
                                                        (Etempvar _q tuint)
                                                        tuint) (tptr tuchar))
                                                    tuchar))
                                                (Sset _v
                                                  (Ebinop Oxor
                                                    (Etempvar _v tuint)
                                                    (Ebinop Oand
                                                      (Etempvar _t'5 tuchar)
                                                      (Etempvar _t'8 tuchar)
                                                      tint) tuint))))))))))))
                            (Sset _q
                              (Ebinop Oadd (Etempvar _q tuint)
                                (Econst_int (Int.repr 1) tint) tuint))))
                        (Sifthenelse (Ebinop One (Etempvar _v tuint)
                                       (Econst_int (Int.repr 0) tuint) tint)
                          (Sreturn (Some (Econst_int (Int.repr 0) tint)))
                          Sskip))))
                  (Sset _j
                    (Ebinop Oadd (Etempvar _j tuint)
                      (Econst_int (Int.repr 1) tint) tuint)))))
            (Sset _i
              (Ebinop Oadd (Etempvar _i tuint) (Econst_int (Int.repr 1) tint)
                tuint))))
        (Sreturn (Some (Econst_int (Int.repr 1) tint)))))))
|}.

Definition f_clear := {|
  fn_return := tvoid;
  fn_callconv := cc_default;
  fn_params := ((_p, (tptr (Tstruct _ccv_problem noattr))) ::
                (_w, (tptr (Tstruct _ccv_workspace noattr))) ::
                (_out, (tptr tuchar)) :: nil);
  fn_vars := nil;
  fn_temps := ((_i, tuint) :: (_t'8, tuint) :: (_t'7, (tptr tuchar)) ::
               (_t'6, (tptr tuchar)) :: (_t'5, (tptr tuchar)) ::
               (_t'4, tuint) :: (_t'3, (tptr tuchar)) :: (_t'2, tuint) ::
               (_t'1, (tptr tuchar)) :: nil);
  fn_body :=
(Ssequence
  (Ssequence
    (Sset _i (Econst_int (Int.repr 0) tuint))
    (Sloop
      (Ssequence
        (Ssequence
          (Sset _t'8
            (Efield
              (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                (Tstruct _ccv_problem noattr)) _n tuint))
          (Sifthenelse (Ebinop Olt (Etempvar _i tuint) (Etempvar _t'8 tuint)
                         tint)
            Sskip
            Sbreak))
        (Ssequence
          (Ssequence
            (Sset _t'7
              (Efield
                (Ederef (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                  (Tstruct _ccv_workspace noattr)) _selected (tptr tuchar)))
            (Sassign
              (Ederef
                (Ebinop Oadd (Etempvar _t'7 (tptr tuchar))
                  (Etempvar _i tuint) (tptr tuchar)) tuchar)
              (Econst_int (Int.repr 0) tuint)))
          (Ssequence
            (Ssequence
              (Sset _t'6
                (Efield
                  (Ederef
                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                    (Tstruct _ccv_workspace noattr)) _forbidden
                  (tptr tuchar)))
              (Sassign
                (Ederef
                  (Ebinop Oadd (Etempvar _t'6 (tptr tuchar))
                    (Etempvar _i tuint) (tptr tuchar)) tuchar)
                (Econst_int (Int.repr 0) tuint)))
            (Ssequence
              (Ssequence
                (Sset _t'5
                  (Efield
                    (Ederef
                      (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                      (Tstruct _ccv_workspace noattr)) _packed (tptr tuchar)))
                (Sassign
                  (Ederef
                    (Ebinop Oadd (Etempvar _t'5 (tptr tuchar))
                      (Etempvar _i tuint) (tptr tuchar)) tuchar)
                  (Econst_int (Int.repr 0) tuint)))
              (Sassign
                (Ederef
                  (Ebinop Oadd (Etempvar _out (tptr tuchar))
                    (Etempvar _i tuint) (tptr tuchar)) tuchar)
                (Econst_int (Int.repr 0) tuint))))))
      (Sset _i
        (Ebinop Oadd (Etempvar _i tuint) (Econst_int (Int.repr 1) tint)
          tuint))))
  (Ssequence
    (Ssequence
      (Sset _i (Econst_int (Int.repr 0) tuint))
      (Sloop
        (Ssequence
          (Ssequence
            (Sset _t'4
              (Efield
                (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                  (Tstruct _ccv_problem noattr)) _checks tuint))
            (Sifthenelse (Ebinop Olt (Etempvar _i tuint)
                           (Etempvar _t'4 tuint) tint)
              Sskip
              Sbreak))
          (Ssequence
            (Sset _t'3
              (Efield
                (Ederef (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                  (Tstruct _ccv_workspace noattr)) _syndrome (tptr tuchar)))
            (Sassign
              (Ederef
                (Ebinop Oadd (Etempvar _t'3 (tptr tuchar))
                  (Etempvar _i tuint) (tptr tuchar)) tuchar)
              (Econst_int (Int.repr 0) tuint))))
        (Sset _i
          (Ebinop Oadd (Etempvar _i tuint) (Econst_int (Int.repr 1) tint)
            tuint))))
    (Ssequence
      (Sset _i (Econst_int (Int.repr 0) tuint))
      (Sloop
        (Ssequence
          (Ssequence
            (Sset _t'2
              (Efield
                (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                  (Tstruct _ccv_problem noattr)) _logical_rows tuint))
            (Sifthenelse (Ebinop Olt (Etempvar _i tuint)
                           (Etempvar _t'2 tuint) tint)
              Sskip
              Sbreak))
          (Ssequence
            (Sset _t'1
              (Efield
                (Ederef (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                  (Tstruct _ccv_workspace noattr)) _logical_value
                (tptr tuchar)))
            (Sassign
              (Ederef
                (Ebinop Oadd (Etempvar _t'1 (tptr tuchar))
                  (Etempvar _i tuint) (tptr tuchar)) tuchar)
              (Econst_int (Int.repr 0) tuint))))
        (Sset _i
          (Ebinop Oadd (Etempvar _i tuint) (Econst_int (Int.repr 1) tint)
            tuint))))))
|}.

Definition f_toggle := {|
  fn_return := tvoid;
  fn_callconv := cc_default;
  fn_params := ((_p, (tptr (Tstruct _ccv_problem noattr))) ::
                (_w, (tptr (Tstruct _ccv_workspace noattr))) ::
                (_q, tuint) :: nil);
  fn_vars := nil;
  fn_temps := ((_i, tuint) :: (_t'17, tuchar) :: (_t'16, (tptr tuchar)) ::
               (_t'15, (tptr tuchar)) :: (_t'14, tuint) :: (_t'13, tuchar) ::
               (_t'12, tuint) :: (_t'11, (tptr tuchar)) :: (_t'10, tuchar) ::
               (_t'9, (tptr tuchar)) :: (_t'8, (tptr tuchar)) ::
               (_t'7, tuint) :: (_t'6, tuchar) :: (_t'5, tuint) ::
               (_t'4, (tptr tuchar)) :: (_t'3, tuchar) ::
               (_t'2, (tptr tuchar)) :: (_t'1, (tptr tuchar)) :: nil);
  fn_body :=
(Ssequence
  (Ssequence
    (Sset _t'15
      (Efield
        (Ederef (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
          (Tstruct _ccv_workspace noattr)) _selected (tptr tuchar)))
    (Ssequence
      (Sset _t'16
        (Efield
          (Ederef (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
            (Tstruct _ccv_workspace noattr)) _selected (tptr tuchar)))
      (Ssequence
        (Sset _t'17
          (Ederef
            (Ebinop Oadd (Etempvar _t'16 (tptr tuchar)) (Etempvar _q tuint)
              (tptr tuchar)) tuchar))
        (Sassign
          (Ederef
            (Ebinop Oadd (Etempvar _t'15 (tptr tuchar)) (Etempvar _q tuint)
              (tptr tuchar)) tuchar)
          (Ebinop Oxor (Etempvar _t'17 tuchar)
            (Econst_int (Int.repr 1) tuint) tuint)))))
  (Ssequence
    (Ssequence
      (Sset _i (Econst_int (Int.repr 0) tuint))
      (Sloop
        (Ssequence
          (Ssequence
            (Sset _t'14
              (Efield
                (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                  (Tstruct _ccv_problem noattr)) _checks tuint))
            (Sifthenelse (Ebinop Olt (Etempvar _i tuint)
                           (Etempvar _t'14 tuint) tint)
              Sskip
              Sbreak))
          (Ssequence
            (Sset _t'8
              (Efield
                (Ederef (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                  (Tstruct _ccv_workspace noattr)) _syndrome (tptr tuchar)))
            (Ssequence
              (Sset _t'9
                (Efield
                  (Ederef
                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                    (Tstruct _ccv_workspace noattr)) _syndrome (tptr tuchar)))
              (Ssequence
                (Sset _t'10
                  (Ederef
                    (Ebinop Oadd (Etempvar _t'9 (tptr tuchar))
                      (Etempvar _i tuint) (tptr tuchar)) tuchar))
                (Ssequence
                  (Sset _t'11
                    (Efield
                      (Ederef
                        (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                        (Tstruct _ccv_problem noattr)) _h (tptr tuchar)))
                  (Ssequence
                    (Sset _t'12
                      (Efield
                        (Ederef
                          (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                          (Tstruct _ccv_problem noattr)) _n tuint))
                    (Ssequence
                      (Sset _t'13
                        (Ederef
                          (Ebinop Oadd (Etempvar _t'11 (tptr tuchar))
                            (Ebinop Oadd
                              (Ebinop Omul (Etempvar _i tuint)
                                (Etempvar _t'12 tuint) tuint)
                              (Etempvar _q tuint) tuint) (tptr tuchar))
                          tuchar))
                      (Sassign
                        (Ederef
                          (Ebinop Oadd (Etempvar _t'8 (tptr tuchar))
                            (Etempvar _i tuint) (tptr tuchar)) tuchar)
                        (Ebinop Oxor (Etempvar _t'10 tuchar)
                          (Etempvar _t'13 tuchar) tint)))))))))
        (Sset _i
          (Ebinop Oadd (Etempvar _i tuint) (Econst_int (Int.repr 1) tint)
            tuint))))
    (Ssequence
      (Sset _i (Econst_int (Int.repr 0) tuint))
      (Sloop
        (Ssequence
          (Ssequence
            (Sset _t'7
              (Efield
                (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                  (Tstruct _ccv_problem noattr)) _logical_rows tuint))
            (Sifthenelse (Ebinop Olt (Etempvar _i tuint)
                           (Etempvar _t'7 tuint) tint)
              Sskip
              Sbreak))
          (Ssequence
            (Sset _t'1
              (Efield
                (Ederef (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                  (Tstruct _ccv_workspace noattr)) _logical_value
                (tptr tuchar)))
            (Ssequence
              (Sset _t'2
                (Efield
                  (Ederef
                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                    (Tstruct _ccv_workspace noattr)) _logical_value
                  (tptr tuchar)))
              (Ssequence
                (Sset _t'3
                  (Ederef
                    (Ebinop Oadd (Etempvar _t'2 (tptr tuchar))
                      (Etempvar _i tuint) (tptr tuchar)) tuchar))
                (Ssequence
                  (Sset _t'4
                    (Efield
                      (Ederef
                        (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                        (Tstruct _ccv_problem noattr)) _logical
                      (tptr tuchar)))
                  (Ssequence
                    (Sset _t'5
                      (Efield
                        (Ederef
                          (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                          (Tstruct _ccv_problem noattr)) _n tuint))
                    (Ssequence
                      (Sset _t'6
                        (Ederef
                          (Ebinop Oadd (Etempvar _t'4 (tptr tuchar))
                            (Ebinop Oadd
                              (Ebinop Omul (Etempvar _i tuint)
                                (Etempvar _t'5 tuint) tuint)
                              (Etempvar _q tuint) tuint) (tptr tuchar))
                          tuchar))
                      (Sassign
                        (Ederef
                          (Ebinop Oadd (Etempvar _t'1 (tptr tuchar))
                            (Etempvar _i tuint) (tptr tuchar)) tuchar)
                        (Ebinop Oxor (Etempvar _t'3 tuchar)
                          (Etempvar _t'6 tuchar) tint)))))))))
        (Sset _i
          (Ebinop Oadd (Etempvar _i tuint) (Econst_int (Int.repr 1) tint)
            tuint))))))
|}.

Definition f_nontrivial := {|
  fn_return := tint;
  fn_callconv := cc_default;
  fn_params := ((_p, (tptr (Tstruct _ccv_problem noattr))) ::
                (_w, (tptr (Tstruct _ccv_workspace noattr))) :: nil);
  fn_vars := nil;
  fn_temps := ((_i, tuint) :: (_t'3, tuint) :: (_t'2, tuchar) ::
               (_t'1, (tptr tuchar)) :: nil);
  fn_body :=
(Ssequence
  (Ssequence
    (Sset _i (Econst_int (Int.repr 0) tuint))
    (Sloop
      (Ssequence
        (Ssequence
          (Sset _t'3
            (Efield
              (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                (Tstruct _ccv_problem noattr)) _logical_rows tuint))
          (Sifthenelse (Ebinop Olt (Etempvar _i tuint) (Etempvar _t'3 tuint)
                         tint)
            Sskip
            Sbreak))
        (Ssequence
          (Sset _t'1
            (Efield
              (Ederef (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                (Tstruct _ccv_workspace noattr)) _logical_value
              (tptr tuchar)))
          (Ssequence
            (Sset _t'2
              (Ederef
                (Ebinop Oadd (Etempvar _t'1 (tptr tuchar))
                  (Etempvar _i tuint) (tptr tuchar)) tuchar))
            (Sifthenelse (Ebinop One (Etempvar _t'2 tuchar)
                           (Econst_int (Int.repr 0) tuint) tint)
              (Sreturn (Some (Econst_int (Int.repr 1) tint)))
              Sskip))))
      (Sset _i
        (Ebinop Oadd (Etempvar _i tuint) (Econst_int (Int.repr 1) tint)
          tuint))))
  (Sreturn (Some (Econst_int (Int.repr 0) tint))))
|}.

Definition f_restore := {|
  fn_return := tvoid;
  fn_callconv := cc_default;
  fn_params := ((_w, (tptr (Tstruct _ccv_workspace noattr))) ::
                (_top, (tptr tuint)) :: (_mark, tuint) :: nil);
  fn_vars := nil;
  fn_temps := ((_t'6, tuint) :: (_t'5, tuint) :: (_t'4, tuint) ::
               (_t'3, tuint) :: (_t'2, (tptr tuint)) ::
               (_t'1, (tptr tuchar)) :: nil);
  fn_body :=
(Sloop
  (Ssequence
    (Ssequence
      (Sset _t'6 (Ederef (Etempvar _top (tptr tuint)) tuint))
      (Sifthenelse (Ebinop Ogt (Etempvar _t'6 tuint) (Etempvar _mark tuint)
                     tint)
        Sskip
        Sbreak))
    (Ssequence
      (Ssequence
        (Sset _t'5 (Ederef (Etempvar _top (tptr tuint)) tuint))
        (Sassign (Ederef (Etempvar _top (tptr tuint)) tuint)
          (Ebinop Osub (Etempvar _t'5 tuint) (Econst_int (Int.repr 1) tuint)
            tuint)))
      (Ssequence
        (Sset _t'1
          (Efield
            (Ederef (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
              (Tstruct _ccv_workspace noattr)) _forbidden (tptr tuchar)))
        (Ssequence
          (Sset _t'2
            (Efield
              (Ederef (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                (Tstruct _ccv_workspace noattr)) _undo (tptr tuint)))
          (Ssequence
            (Sset _t'3 (Ederef (Etempvar _top (tptr tuint)) tuint))
            (Ssequence
              (Sset _t'4
                (Ederef
                  (Ebinop Oadd (Etempvar _t'2 (tptr tuint))
                    (Etempvar _t'3 tuint) (tptr tuint)) tuint))
              (Sassign
                (Ederef
                  (Ebinop Oadd (Etempvar _t'1 (tptr tuchar))
                    (Etempvar _t'4 tuint) (tptr tuchar)) tuchar)
                (Econst_int (Int.repr 0) tuint))))))))
  Sskip)
|}.

Definition f_forbid := {|
  fn_return := tint;
  fn_callconv := cc_default;
  fn_params := ((_w, (tptr (Tstruct _ccv_workspace noattr))) ::
                (_q, tuint) :: (_top, (tptr tuint)) :: (_n, tuint) :: nil);
  fn_vars := nil;
  fn_temps := ((_t'7, tuint) :: (_t'6, tuint) :: (_t'5, (tptr tuint)) ::
               (_t'4, tuint) :: (_t'3, (tptr tuchar)) :: (_t'2, tuchar) ::
               (_t'1, (tptr tuchar)) :: nil);
  fn_body :=
(Ssequence
  (Ssequence
    (Sset _t'1
      (Efield
        (Ederef (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
          (Tstruct _ccv_workspace noattr)) _forbidden (tptr tuchar)))
    (Ssequence
      (Sset _t'2
        (Ederef
          (Ebinop Oadd (Etempvar _t'1 (tptr tuchar)) (Etempvar _q tuint)
            (tptr tuchar)) tuchar))
      (Sifthenelse (Ebinop Oeq (Etempvar _t'2 tuchar)
                     (Econst_int (Int.repr 0) tuint) tint)
        (Ssequence
          (Ssequence
            (Sset _t'7 (Ederef (Etempvar _top (tptr tuint)) tuint))
            (Sifthenelse (Ebinop Oge (Etempvar _t'7 tuint)
                           (Etempvar _n tuint) tint)
              (Sreturn (Some (Econst_int (Int.repr 0) tint)))
              Sskip))
          (Ssequence
            (Ssequence
              (Sset _t'5
                (Efield
                  (Ederef
                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                    (Tstruct _ccv_workspace noattr)) _undo (tptr tuint)))
              (Ssequence
                (Sset _t'6 (Ederef (Etempvar _top (tptr tuint)) tuint))
                (Sassign
                  (Ederef
                    (Ebinop Oadd (Etempvar _t'5 (tptr tuint))
                      (Etempvar _t'6 tuint) (tptr tuint)) tuint)
                  (Etempvar _q tuint))))
            (Ssequence
              (Ssequence
                (Sset _t'4 (Ederef (Etempvar _top (tptr tuint)) tuint))
                (Sassign (Ederef (Etempvar _top (tptr tuint)) tuint)
                  (Ebinop Oadd (Etempvar _t'4 tuint)
                    (Econst_int (Int.repr 1) tuint) tuint)))
              (Ssequence
                (Sset _t'3
                  (Efield
                    (Ederef
                      (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                      (Tstruct _ccv_workspace noattr)) _forbidden
                    (tptr tuchar)))
                (Sassign
                  (Ederef
                    (Ebinop Oadd (Etempvar _t'3 (tptr tuchar))
                      (Etempvar _q tuint) (tptr tuchar)) tuchar)
                  (Econst_int (Int.repr 1) tuint))))))
        Sskip)))
  (Sreturn (Some (Econst_int (Int.repr 1) tint))))
|}.

Definition f_overlap := {|
  fn_return := tint;
  fn_callconv := cc_default;
  fn_params := ((_p, (tptr (Tstruct _ccv_problem noattr))) ::
                (_w, (tptr (Tstruct _ccv_workspace noattr))) ::
                (_top, (tptr tuint)) :: nil);
  fn_vars := nil;
  fn_temps := ((_i, tuint) :: (_q, tuint) :: (_weight, tuint) ::
               (_ov, tuint) :: (_limit, tuint) :: (_t'2, tint) ::
               (_t'1, tint) :: (_t'19, tuint) :: (_t'18, tuint) ::
               (_t'17, tuchar) :: (_t'16, tuint) :: (_t'15, (tptr tuchar)) ::
               (_t'14, tuchar) :: (_t'13, (tptr tuchar)) ::
               (_t'12, tuchar) :: (_t'11, tuint) :: (_t'10, (tptr tuchar)) ::
               (_t'9, tuint) :: (_t'8, tuchar) :: (_t'7, (tptr tuchar)) ::
               (_t'6, tuchar) :: (_t'5, tuint) :: (_t'4, (tptr tuchar)) ::
               (_t'3, tuint) :: nil);
  fn_body :=
(Ssequence
  (Ssequence
    (Sset _i (Econst_int (Int.repr 0) tuint))
    (Sloop
      (Ssequence
        (Ssequence
          (Sset _t'19
            (Efield
              (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                (Tstruct _ccv_problem noattr)) _stabilizers tuint))
          (Sifthenelse (Ebinop Olt (Etempvar _i tuint) (Etempvar _t'19 tuint)
                         tint)
            Sskip
            Sbreak))
        (Ssequence
          (Sset _weight (Econst_int (Int.repr 0) tuint))
          (Ssequence
            (Sset _ov (Econst_int (Int.repr 0) tuint))
            (Ssequence
              (Ssequence
                (Sset _q (Econst_int (Int.repr 0) tuint))
                (Sloop
                  (Ssequence
                    (Ssequence
                      (Sset _t'18
                        (Efield
                          (Ederef
                            (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                            (Tstruct _ccv_problem noattr)) _n tuint))
                      (Sifthenelse (Ebinop Olt (Etempvar _q tuint)
                                     (Etempvar _t'18 tuint) tint)
                        Sskip
                        Sbreak))
                    (Ssequence
                      (Ssequence
                        (Sset _t'15
                          (Efield
                            (Ederef
                              (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                              (Tstruct _ccv_problem noattr)) _stabilizer
                            (tptr tuchar)))
                        (Ssequence
                          (Sset _t'16
                            (Efield
                              (Ederef
                                (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                (Tstruct _ccv_problem noattr)) _n tuint))
                          (Ssequence
                            (Sset _t'17
                              (Ederef
                                (Ebinop Oadd (Etempvar _t'15 (tptr tuchar))
                                  (Ebinop Oadd
                                    (Ebinop Omul (Etempvar _i tuint)
                                      (Etempvar _t'16 tuint) tuint)
                                    (Etempvar _q tuint) tuint) (tptr tuchar))
                                tuchar))
                            (Sset _weight
                              (Ebinop Oadd (Etempvar _weight tuint)
                                (Etempvar _t'17 tuchar) tuint)))))
                      (Ssequence
                        (Sset _t'10
                          (Efield
                            (Ederef
                              (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                              (Tstruct _ccv_problem noattr)) _stabilizer
                            (tptr tuchar)))
                        (Ssequence
                          (Sset _t'11
                            (Efield
                              (Ederef
                                (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                (Tstruct _ccv_problem noattr)) _n tuint))
                          (Ssequence
                            (Sset _t'12
                              (Ederef
                                (Ebinop Oadd (Etempvar _t'10 (tptr tuchar))
                                  (Ebinop Oadd
                                    (Ebinop Omul (Etempvar _i tuint)
                                      (Etempvar _t'11 tuint) tuint)
                                    (Etempvar _q tuint) tuint) (tptr tuchar))
                                tuchar))
                            (Ssequence
                              (Sset _t'13
                                (Efield
                                  (Ederef
                                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                    (Tstruct _ccv_workspace noattr))
                                  _selected (tptr tuchar)))
                              (Ssequence
                                (Sset _t'14
                                  (Ederef
                                    (Ebinop Oadd
                                      (Etempvar _t'13 (tptr tuchar))
                                      (Etempvar _q tuint) (tptr tuchar))
                                    tuchar))
                                (Sset _ov
                                  (Ebinop Oadd (Etempvar _ov tuint)
                                    (Ebinop Oand (Etempvar _t'12 tuchar)
                                      (Etempvar _t'14 tuchar) tint) tuint)))))))))
                  (Sset _q
                    (Ebinop Oadd (Etempvar _q tuint)
                      (Econst_int (Int.repr 1) tint) tuint))))
              (Ssequence
                (Sset _limit
                  (Ebinop Odiv (Etempvar _weight tuint)
                    (Econst_int (Int.repr 2) tuint) tuint))
                (Ssequence
                  (Sifthenelse (Ebinop Ogt (Etempvar _ov tuint)
                                 (Etempvar _limit tuint) tint)
                    (Sreturn (Some (Econst_int (Int.repr 0) tint)))
                    Sskip)
                  (Sifthenelse (Ebinop Oeq (Etempvar _ov tuint)
                                 (Etempvar _limit tuint) tint)
                    (Ssequence
                      (Sset _q (Econst_int (Int.repr 0) tuint))
                      (Sloop
                        (Ssequence
                          (Ssequence
                            (Sset _t'9
                              (Efield
                                (Ederef
                                  (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                  (Tstruct _ccv_problem noattr)) _n tuint))
                            (Sifthenelse (Ebinop Olt (Etempvar _q tuint)
                                           (Etempvar _t'9 tuint) tint)
                              Sskip
                              Sbreak))
                          (Ssequence
                            (Ssequence
                              (Sset _t'4
                                (Efield
                                  (Ederef
                                    (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                    (Tstruct _ccv_problem noattr))
                                  _stabilizer (tptr tuchar)))
                              (Ssequence
                                (Sset _t'5
                                  (Efield
                                    (Ederef
                                      (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                      (Tstruct _ccv_problem noattr)) _n
                                    tuint))
                                (Ssequence
                                  (Sset _t'6
                                    (Ederef
                                      (Ebinop Oadd
                                        (Etempvar _t'4 (tptr tuchar))
                                        (Ebinop Oadd
                                          (Ebinop Omul (Etempvar _i tuint)
                                            (Etempvar _t'5 tuint) tuint)
                                          (Etempvar _q tuint) tuint)
                                        (tptr tuchar)) tuchar))
                                  (Sifthenelse (Ebinop One
                                                 (Etempvar _t'6 tuchar)
                                                 (Econst_int (Int.repr 0) tuint)
                                                 tint)
                                    (Ssequence
                                      (Sset _t'7
                                        (Efield
                                          (Ederef
                                            (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                            (Tstruct _ccv_workspace noattr))
                                          _selected (tptr tuchar)))
                                      (Ssequence
                                        (Sset _t'8
                                          (Ederef
                                            (Ebinop Oadd
                                              (Etempvar _t'7 (tptr tuchar))
                                              (Etempvar _q tuint)
                                              (tptr tuchar)) tuchar))
                                        (Sset _t'2
                                          (Ecast
                                            (Ebinop Oeq
                                              (Etempvar _t'8 tuchar)
                                              (Econst_int (Int.repr 0) tuint)
                                              tint) tbool))))
                                    (Sset _t'2
                                      (Econst_int (Int.repr 0) tint))))))
                            (Sifthenelse (Etempvar _t'2 tint)
                              (Ssequence
                                (Ssequence
                                  (Sset _t'3
                                    (Efield
                                      (Ederef
                                        (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                        (Tstruct _ccv_problem noattr)) _n
                                      tuint))
                                  (Scall (Some _t'1)
                                    (Evar _forbid (Tfunction
                                                    (Tcons
                                                      (tptr (Tstruct _ccv_workspace noattr))
                                                      (Tcons tuint
                                                        (Tcons (tptr tuint)
                                                          (Tcons tuint Tnil))))
                                                    tint cc_default))
                                    ((Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                                     (Etempvar _q tuint) ::
                                     (Etempvar _top (tptr tuint)) ::
                                     (Etempvar _t'3 tuint) :: nil)))
                                (Sifthenelse (Eunop Onotbool
                                               (Etempvar _t'1 tint) tint)
                                  (Sreturn (Some (Eunop Oneg
                                                   (Econst_int (Int.repr 1) tint)
                                                   tint)))
                                  Sskip))
                              Sskip)))
                        (Sset _q
                          (Ebinop Oadd (Etempvar _q tuint)
                            (Econst_int (Int.repr 1) tint) tuint))))
                    Sskip)))))))
      (Sset _i
        (Ebinop Oadd (Etempvar _i tuint) (Econst_int (Int.repr 1) tint)
          tuint))))
  (Sreturn (Some (Econst_int (Int.repr 1) tint))))
|}.

Definition f_bounds := {|
  fn_return := tint;
  fn_callconv := cc_default;
  fn_params := ((_p, (tptr (Tstruct _ccv_problem noattr))) ::
                (_w, (tptr (Tstruct _ccv_workspace noattr))) ::
                (_remaining, tuint) :: (_rules, tuint) ::
                (_row, (tptr tuint)) ::
                (_stats, (tptr (Tstruct _ccv_stats noattr))) :: nil);
  fn_vars := nil;
  fn_temps := ((_i, tuint) :: (_q, tuint) :: (_count, tuint) ::
               (_best, tuint) :: (_used, tuint) :: (_pack, tuint) ::
               (_odd, tuint) :: (_maxdeg, tuint) :: (_deg, tuint) ::
               (_lb, tuint) :: (_t'9, tint) :: (_t'8, tuint) ::
               (_t'7, tint) :: (_t'6, tint) :: (_t'5, tint) ::
               (_t'4, tint) :: (_t'3, tint) :: (_t'2, tint) ::
               (_t'1, tint) :: (_t'49, tuint) :: (_t'48, tuint) ::
               (_t'47, (tptr tuchar)) :: (_t'46, tuint) :: (_t'45, tuint) ::
               (_t'44, tuchar) :: (_t'43, (tptr tuchar)) ::
               (_t'42, tuchar) :: (_t'41, tuint) :: (_t'40, (tptr tuchar)) ::
               (_t'39, tuchar) :: (_t'38, (tptr tuchar)) ::
               (_t'37, tuchar) :: (_t'36, (tptr tuchar)) :: (_t'35, tuint) ::
               (_t'34, tuint) :: (_t'33, tuint) :: (_t'32, tuchar) ::
               (_t'31, (tptr tuchar)) :: (_t'30, tuchar) :: (_t'29, tuint) ::
               (_t'28, (tptr tuchar)) :: (_t'27, tuchar) ::
               (_t'26, (tptr tuchar)) :: (_t'25, (tptr tuchar)) ::
               (_t'24, tuint) :: (_t'23, tuchar) :: (_t'22, (tptr tuchar)) ::
               (_t'21, tuint) :: (_t'20, tuchar) :: (_t'19, (tptr tuchar)) ::
               (_t'18, tuchar) :: (_t'17, (tptr tuchar)) :: (_t'16, tuint) ::
               (_t'15, tuchar) :: (_t'14, tuint) :: (_t'13, (tptr tuchar)) ::
               (_t'12, tuchar) :: (_t'11, (tptr tuchar)) :: (_t'10, tuint) ::
               nil);
  fn_body :=
(Ssequence
  (Sset _best
    (Efield
      (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
        (Tstruct _ccv_problem noattr)) _n tuint))
  (Ssequence
    (Sset _pack (Econst_int (Int.repr 0) tuint))
    (Ssequence
      (Sset _odd (Econst_int (Int.repr 0) tuint))
      (Ssequence
        (Sset _maxdeg (Econst_int (Int.repr 0) tuint))
        (Ssequence
          (Ssequence
            (Sset _t'49
              (Efield
                (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                  (Tstruct _ccv_problem noattr)) _checks tuint))
            (Sassign (Ederef (Etempvar _row (tptr tuint)) tuint)
              (Etempvar _t'49 tuint)))
          (Ssequence
            (Ssequence
              (Sset _q (Econst_int (Int.repr 0) tuint))
              (Sloop
                (Ssequence
                  (Ssequence
                    (Sset _t'48
                      (Efield
                        (Ederef
                          (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                          (Tstruct _ccv_problem noattr)) _n tuint))
                    (Sifthenelse (Ebinop Olt (Etempvar _q tuint)
                                   (Etempvar _t'48 tuint) tint)
                      Sskip
                      Sbreak))
                  (Ssequence
                    (Sset _t'47
                      (Efield
                        (Ederef
                          (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                          (Tstruct _ccv_workspace noattr)) _packed
                        (tptr tuchar)))
                    (Sassign
                      (Ederef
                        (Ebinop Oadd (Etempvar _t'47 (tptr tuchar))
                          (Etempvar _q tuint) (tptr tuchar)) tuchar)
                      (Econst_int (Int.repr 0) tuint))))
                (Sset _q
                  (Ebinop Oadd (Etempvar _q tuint)
                    (Econst_int (Int.repr 1) tint) tuint))))
            (Ssequence
              (Ssequence
                (Sset _i (Econst_int (Int.repr 0) tuint))
                (Sloop
                  (Ssequence
                    (Ssequence
                      (Sset _t'46
                        (Efield
                          (Ederef
                            (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                            (Tstruct _ccv_problem noattr)) _checks tuint))
                      (Sifthenelse (Ebinop Olt (Etempvar _i tuint)
                                     (Etempvar _t'46 tuint) tint)
                        Sskip
                        Sbreak))
                    (Ssequence
                      (Sset _t'22
                        (Efield
                          (Ederef
                            (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                            (Tstruct _ccv_workspace noattr)) _syndrome
                          (tptr tuchar)))
                      (Ssequence
                        (Sset _t'23
                          (Ederef
                            (Ebinop Oadd (Etempvar _t'22 (tptr tuchar))
                              (Etempvar _i tuint) (tptr tuchar)) tuchar))
                        (Sifthenelse (Ebinop One (Etempvar _t'23 tuchar)
                                       (Econst_int (Int.repr 0) tuint) tint)
                          (Ssequence
                            (Sset _odd
                              (Ebinop Oadd (Etempvar _odd tuint)
                                (Econst_int (Int.repr 1) tint) tuint))
                            (Ssequence
                              (Sset _count (Econst_int (Int.repr 0) tuint))
                              (Ssequence
                                (Sset _used (Econst_int (Int.repr 0) tuint))
                                (Ssequence
                                  (Ssequence
                                    (Sset _q (Econst_int (Int.repr 0) tuint))
                                    (Sloop
                                      (Ssequence
                                        (Ssequence
                                          (Sset _t'45
                                            (Efield
                                              (Ederef
                                                (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                (Tstruct _ccv_problem noattr))
                                              _n tuint))
                                          (Sifthenelse (Ebinop Olt
                                                         (Etempvar _q tuint)
                                                         (Etempvar _t'45 tuint)
                                                         tint)
                                            Sskip
                                            Sbreak))
                                        (Ssequence
                                          (Ssequence
                                            (Ssequence
                                              (Sset _t'40
                                                (Efield
                                                  (Ederef
                                                    (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                    (Tstruct _ccv_problem noattr))
                                                  _h (tptr tuchar)))
                                              (Ssequence
                                                (Sset _t'41
                                                  (Efield
                                                    (Ederef
                                                      (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                      (Tstruct _ccv_problem noattr))
                                                    _n tuint))
                                                (Ssequence
                                                  (Sset _t'42
                                                    (Ederef
                                                      (Ebinop Oadd
                                                        (Etempvar _t'40 (tptr tuchar))
                                                        (Ebinop Oadd
                                                          (Ebinop Omul
                                                            (Etempvar _i tuint)
                                                            (Etempvar _t'41 tuint)
                                                            tuint)
                                                          (Etempvar _q tuint)
                                                          tuint)
                                                        (tptr tuchar))
                                                      tuchar))
                                                  (Sifthenelse (Ebinop One
                                                                 (Etempvar _t'42 tuchar)
                                                                 (Econst_int (Int.repr 0) tuint)
                                                                 tint)
                                                    (Ssequence
                                                      (Sset _t'43
                                                        (Efield
                                                          (Ederef
                                                            (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                                            (Tstruct _ccv_workspace noattr))
                                                          _selected
                                                          (tptr tuchar)))
                                                      (Ssequence
                                                        (Sset _t'44
                                                          (Ederef
                                                            (Ebinop Oadd
                                                              (Etempvar _t'43 (tptr tuchar))
                                                              (Etempvar _q tuint)
                                                              (tptr tuchar))
                                                            tuchar))
                                                        (Sset _t'1
                                                          (Ecast
                                                            (Ebinop Oeq
                                                              (Etempvar _t'44 tuchar)
                                                              (Econst_int (Int.repr 0) tuint)
                                                              tint) tbool))))
                                                    (Sset _t'1
                                                      (Econst_int (Int.repr 0) tint))))))
                                            (Sifthenelse (Etempvar _t'1 tint)
                                              (Ssequence
                                                (Sset _t'38
                                                  (Efield
                                                    (Ederef
                                                      (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                                      (Tstruct _ccv_workspace noattr))
                                                    _forbidden (tptr tuchar)))
                                                (Ssequence
                                                  (Sset _t'39
                                                    (Ederef
                                                      (Ebinop Oadd
                                                        (Etempvar _t'38 (tptr tuchar))
                                                        (Etempvar _q tuint)
                                                        (tptr tuchar))
                                                      tuchar))
                                                  (Sset _t'2
                                                    (Ecast
                                                      (Ebinop Oeq
                                                        (Etempvar _t'39 tuchar)
                                                        (Econst_int (Int.repr 0) tuint)
                                                        tint) tbool))))
                                              (Sset _t'2
                                                (Econst_int (Int.repr 0) tint))))
                                          (Sifthenelse (Etempvar _t'2 tint)
                                            (Ssequence
                                              (Sset _count
                                                (Ebinop Oadd
                                                  (Etempvar _count tuint)
                                                  (Econst_int (Int.repr 1) tint)
                                                  tuint))
                                              (Ssequence
                                                (Sset _t'36
                                                  (Efield
                                                    (Ederef
                                                      (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                                      (Tstruct _ccv_workspace noattr))
                                                    _packed (tptr tuchar)))
                                                (Ssequence
                                                  (Sset _t'37
                                                    (Ederef
                                                      (Ebinop Oadd
                                                        (Etempvar _t'36 (tptr tuchar))
                                                        (Etempvar _q tuint)
                                                        (tptr tuchar))
                                                      tuchar))
                                                  (Sifthenelse (Ebinop One
                                                                 (Etempvar _t'37 tuchar)
                                                                 (Econst_int (Int.repr 0) tuint)
                                                                 tint)
                                                    (Sset _used
                                                      (Econst_int (Int.repr 1) tuint))
                                                    Sskip))))
                                            Sskip)))
                                      (Sset _q
                                        (Ebinop Oadd (Etempvar _q tuint)
                                          (Econst_int (Int.repr 1) tint)
                                          tuint))))
                                  (Ssequence
                                    (Sifthenelse (Ebinop Oeq
                                                   (Etempvar _count tuint)
                                                   (Econst_int (Int.repr 0) tuint)
                                                   tint)
                                      (Sreturn (Some (Econst_int (Int.repr 0) tint)))
                                      Sskip)
                                    (Ssequence
                                      (Ssequence
                                        (Ssequence
                                          (Sset _t'34
                                            (Ederef
                                              (Etempvar _row (tptr tuint))
                                              tuint))
                                          (Ssequence
                                            (Sset _t'35
                                              (Efield
                                                (Ederef
                                                  (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                  (Tstruct _ccv_problem noattr))
                                                _checks tuint))
                                            (Sifthenelse (Ebinop Oeq
                                                           (Etempvar _t'34 tuint)
                                                           (Etempvar _t'35 tuint)
                                                           tint)
                                              (Sset _t'3
                                                (Econst_int (Int.repr 1) tint))
                                              (Sifthenelse (Ebinop One
                                                             (Ebinop Oand
                                                               (Etempvar _rules tuint)
                                                               (Econst_int (Int.repr 32) tuint)
                                                               tuint)
                                                             (Econst_int (Int.repr 0) tuint)
                                                             tint)
                                                (Ssequence
                                                  (Sset _t'3
                                                    (Ecast
                                                      (Ebinop Olt
                                                        (Etempvar _count tuint)
                                                        (Etempvar _best tuint)
                                                        tint) tbool))
                                                  (Sset _t'3
                                                    (Ecast
                                                      (Etempvar _t'3 tint)
                                                      tbool)))
                                                (Sset _t'3
                                                  (Ecast
                                                    (Econst_int (Int.repr 0) tint)
                                                    tbool))))))
                                        (Sifthenelse (Etempvar _t'3 tint)
                                          (Ssequence
                                            (Sassign
                                              (Ederef
                                                (Etempvar _row (tptr tuint))
                                                tuint) (Etempvar _i tuint))
                                            (Sset _best
                                              (Etempvar _count tuint)))
                                          Sskip))
                                      (Ssequence
                                        (Sifthenelse (Ebinop One
                                                       (Ebinop Oand
                                                         (Etempvar _rules tuint)
                                                         (Econst_int (Int.repr 2) tuint)
                                                         tuint)
                                                       (Econst_int (Int.repr 0) tuint)
                                                       tint)
                                          (Sset _t'6
                                            (Ecast
                                              (Ebinop Oeq
                                                (Etempvar _used tuint)
                                                (Econst_int (Int.repr 0) tuint)
                                                tint) tbool))
                                          (Sset _t'6
                                            (Econst_int (Int.repr 0) tint)))
                                        (Sifthenelse (Etempvar _t'6 tint)
                                          (Ssequence
                                            (Sset _pack
                                              (Ebinop Oadd
                                                (Etempvar _pack tuint)
                                                (Econst_int (Int.repr 1) tint)
                                                tuint))
                                            (Ssequence
                                              (Ssequence
                                                (Sset _q
                                                  (Econst_int (Int.repr 0) tuint))
                                                (Sloop
                                                  (Ssequence
                                                    (Ssequence
                                                      (Sset _t'33
                                                        (Efield
                                                          (Ederef
                                                            (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                            (Tstruct _ccv_problem noattr))
                                                          _n tuint))
                                                      (Sifthenelse (Ebinop Olt
                                                                    (Etempvar _q tuint)
                                                                    (Etempvar _t'33 tuint)
                                                                    tint)
                                                        Sskip
                                                        Sbreak))
                                                    (Ssequence
                                                      (Ssequence
                                                        (Ssequence
                                                          (Sset _t'28
                                                            (Efield
                                                              (Ederef
                                                                (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                                (Tstruct _ccv_problem noattr))
                                                              _h
                                                              (tptr tuchar)))
                                                          (Ssequence
                                                            (Sset _t'29
                                                              (Efield
                                                                (Ederef
                                                                  (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                                  (Tstruct _ccv_problem noattr))
                                                                _n tuint))
                                                            (Ssequence
                                                              (Sset _t'30
                                                                (Ederef
                                                                  (Ebinop Oadd
                                                                    (Etempvar _t'28 (tptr tuchar))
                                                                    (Ebinop Oadd
                                                                    (Ebinop Omul
                                                                    (Etempvar _i tuint)
                                                                    (Etempvar _t'29 tuint)
                                                                    tuint)
                                                                    (Etempvar _q tuint)
                                                                    tuint)
                                                                    (tptr tuchar))
                                                                  tuchar))
                                                              (Sifthenelse 
                                                                (Ebinop One
                                                                  (Etempvar _t'30 tuchar)
                                                                  (Econst_int (Int.repr 0) tuint)
                                                                  tint)
                                                                (Ssequence
                                                                  (Sset _t'31
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                                                    (Tstruct _ccv_workspace noattr))
                                                                    _selected
                                                                    (tptr tuchar)))
                                                                  (Ssequence
                                                                    (Sset _t'32
                                                                    (Ederef
                                                                    (Ebinop Oadd
                                                                    (Etempvar _t'31 (tptr tuchar))
                                                                    (Etempvar _q tuint)
                                                                    (tptr tuchar))
                                                                    tuchar))
                                                                    (Sset _t'4
                                                                    (Ecast
                                                                    (Ebinop Oeq
                                                                    (Etempvar _t'32 tuchar)
                                                                    (Econst_int (Int.repr 0) tuint)
                                                                    tint)
                                                                    tbool))))
                                                                (Sset _t'4
                                                                  (Econst_int (Int.repr 0) tint))))))
                                                        (Sifthenelse (Etempvar _t'4 tint)
                                                          (Ssequence
                                                            (Sset _t'26
                                                              (Efield
                                                                (Ederef
                                                                  (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                                                  (Tstruct _ccv_workspace noattr))
                                                                _forbidden
                                                                (tptr tuchar)))
                                                            (Ssequence
                                                              (Sset _t'27
                                                                (Ederef
                                                                  (Ebinop Oadd
                                                                    (Etempvar _t'26 (tptr tuchar))
                                                                    (Etempvar _q tuint)
                                                                    (tptr tuchar))
                                                                  tuchar))
                                                              (Sset _t'5
                                                                (Ecast
                                                                  (Ebinop Oeq
                                                                    (Etempvar _t'27 tuchar)
                                                                    (Econst_int (Int.repr 0) tuint)
                                                                    tint)
                                                                  tbool))))
                                                          (Sset _t'5
                                                            (Econst_int (Int.repr 0) tint))))
                                                      (Sifthenelse (Etempvar _t'5 tint)
                                                        (Ssequence
                                                          (Sset _t'25
                                                            (Efield
                                                              (Ederef
                                                                (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                                                (Tstruct _ccv_workspace noattr))
                                                              _packed
                                                              (tptr tuchar)))
                                                          (Sassign
                                                            (Ederef
                                                              (Ebinop Oadd
                                                                (Etempvar _t'25 (tptr tuchar))
                                                                (Etempvar _q tuint)
                                                                (tptr tuchar))
                                                              tuchar)
                                                            (Econst_int (Int.repr 1) tuint)))
                                                        Sskip)))
                                                  (Sset _q
                                                    (Ebinop Oadd
                                                      (Etempvar _q tuint)
                                                      (Econst_int (Int.repr 1) tint)
                                                      tuint))))
                                              (Sifthenelse (Ebinop Ogt
                                                             (Etempvar _pack tuint)
                                                             (Etempvar _remaining tuint)
                                                             tint)
                                                (Ssequence
                                                  (Ssequence
                                                    (Sset _t'24
                                                      (Efield
                                                        (Ederef
                                                          (Etempvar _stats (tptr (Tstruct _ccv_stats noattr)))
                                                          (Tstruct _ccv_stats noattr))
                                                        _pack_prunes tuint))
                                                    (Sassign
                                                      (Efield
                                                        (Ederef
                                                          (Etempvar _stats (tptr (Tstruct _ccv_stats noattr)))
                                                          (Tstruct _ccv_stats noattr))
                                                        _pack_prunes tuint)
                                                      (Ebinop Oadd
                                                        (Etempvar _t'24 tuint)
                                                        (Econst_int (Int.repr 1) tint)
                                                        tuint)))
                                                  (Sreturn (Some (Econst_int (Int.repr 0) tint))))
                                                Sskip)))
                                          Sskip))))))))
                          Sskip))))
                  (Sset _i
                    (Ebinop Oadd (Etempvar _i tuint)
                      (Econst_int (Int.repr 1) tint) tuint))))
              (Ssequence
                (Ssequence
                  (Sifthenelse (Ebinop One
                                 (Ebinop Oand (Etempvar _rules tuint)
                                   (Econst_int (Int.repr 16) tuint) tuint)
                                 (Econst_int (Int.repr 0) tuint) tint)
                    (Sset _t'9
                      (Ecast
                        (Ebinop Ogt (Etempvar _odd tuint)
                          (Econst_int (Int.repr 0) tuint) tint) tbool))
                    (Sset _t'9 (Econst_int (Int.repr 0) tint)))
                  (Sifthenelse (Etempvar _t'9 tint)
                    (Ssequence
                      (Ssequence
                        (Sset _q (Econst_int (Int.repr 0) tuint))
                        (Sloop
                          (Ssequence
                            (Ssequence
                              (Sset _t'21
                                (Efield
                                  (Ederef
                                    (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                    (Tstruct _ccv_problem noattr)) _n tuint))
                              (Sifthenelse (Ebinop Olt (Etempvar _q tuint)
                                             (Etempvar _t'21 tuint) tint)
                                Sskip
                                Sbreak))
                            (Ssequence
                              (Ssequence
                                (Sset _t'17
                                  (Efield
                                    (Ederef
                                      (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                      (Tstruct _ccv_workspace noattr))
                                    _selected (tptr tuchar)))
                                (Ssequence
                                  (Sset _t'18
                                    (Ederef
                                      (Ebinop Oadd
                                        (Etempvar _t'17 (tptr tuchar))
                                        (Etempvar _q tuint) (tptr tuchar))
                                      tuchar))
                                  (Sifthenelse (Ebinop Oeq
                                                 (Etempvar _t'18 tuchar)
                                                 (Econst_int (Int.repr 0) tuint)
                                                 tint)
                                    (Ssequence
                                      (Sset _t'19
                                        (Efield
                                          (Ederef
                                            (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                            (Tstruct _ccv_workspace noattr))
                                          _forbidden (tptr tuchar)))
                                      (Ssequence
                                        (Sset _t'20
                                          (Ederef
                                            (Ebinop Oadd
                                              (Etempvar _t'19 (tptr tuchar))
                                              (Etempvar _q tuint)
                                              (tptr tuchar)) tuchar))
                                        (Sset _t'7
                                          (Ecast
                                            (Ebinop Oeq
                                              (Etempvar _t'20 tuchar)
                                              (Econst_int (Int.repr 0) tuint)
                                              tint) tbool))))
                                    (Sset _t'7
                                      (Econst_int (Int.repr 0) tint)))))
                              (Sifthenelse (Etempvar _t'7 tint)
                                (Ssequence
                                  (Sset _deg (Econst_int (Int.repr 0) tuint))
                                  (Ssequence
                                    (Ssequence
                                      (Sset _i
                                        (Econst_int (Int.repr 0) tuint))
                                      (Sloop
                                        (Ssequence
                                          (Ssequence
                                            (Sset _t'16
                                              (Efield
                                                (Ederef
                                                  (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                  (Tstruct _ccv_problem noattr))
                                                _checks tuint))
                                            (Sifthenelse (Ebinop Olt
                                                           (Etempvar _i tuint)
                                                           (Etempvar _t'16 tuint)
                                                           tint)
                                              Sskip
                                              Sbreak))
                                          (Ssequence
                                            (Sset _t'11
                                              (Efield
                                                (Ederef
                                                  (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                                  (Tstruct _ccv_workspace noattr))
                                                _syndrome (tptr tuchar)))
                                            (Ssequence
                                              (Sset _t'12
                                                (Ederef
                                                  (Ebinop Oadd
                                                    (Etempvar _t'11 (tptr tuchar))
                                                    (Etempvar _i tuint)
                                                    (tptr tuchar)) tuchar))
                                              (Sifthenelse (Ebinop One
                                                             (Etempvar _t'12 tuchar)
                                                             (Econst_int (Int.repr 0) tuint)
                                                             tint)
                                                (Ssequence
                                                  (Sset _t'13
                                                    (Efield
                                                      (Ederef
                                                        (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                        (Tstruct _ccv_problem noattr))
                                                      _h (tptr tuchar)))
                                                  (Ssequence
                                                    (Sset _t'14
                                                      (Efield
                                                        (Ederef
                                                          (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                          (Tstruct _ccv_problem noattr))
                                                        _n tuint))
                                                    (Ssequence
                                                      (Sset _t'15
                                                        (Ederef
                                                          (Ebinop Oadd
                                                            (Etempvar _t'13 (tptr tuchar))
                                                            (Ebinop Oadd
                                                              (Ebinop Omul
                                                                (Etempvar _i tuint)
                                                                (Etempvar _t'14 tuint)
                                                                tuint)
                                                              (Etempvar _q tuint)
                                                              tuint)
                                                            (tptr tuchar))
                                                          tuchar))
                                                      (Sset _deg
                                                        (Ebinop Oadd
                                                          (Etempvar _deg tuint)
                                                          (Etempvar _t'15 tuchar)
                                                          tuint)))))
                                                Sskip))))
                                        (Sset _i
                                          (Ebinop Oadd (Etempvar _i tuint)
                                            (Econst_int (Int.repr 1) tint)
                                            tuint))))
                                    (Sifthenelse (Ebinop Ogt
                                                   (Etempvar _deg tuint)
                                                   (Etempvar _maxdeg tuint)
                                                   tint)
                                      (Sset _maxdeg (Etempvar _deg tuint))
                                      Sskip)))
                                Sskip)))
                          (Sset _q
                            (Ebinop Oadd (Etempvar _q tuint)
                              (Econst_int (Int.repr 1) tint) tuint))))
                      (Ssequence
                        (Sifthenelse (Ebinop Oeq (Etempvar _maxdeg tuint)
                                       (Econst_int (Int.repr 0) tuint) tint)
                          (Sreturn (Some (Econst_int (Int.repr 0) tint)))
                          Sskip)
                        (Ssequence
                          (Ssequence
                            (Scall (Some _t'8)
                              (Evar _ccv_ceil_div (Tfunction
                                                    (Tcons tuint
                                                      (Tcons tuint Tnil))
                                                    tuint cc_default))
                              ((Etempvar _odd tuint) ::
                               (Etempvar _maxdeg tuint) :: nil))
                            (Sset _lb (Etempvar _t'8 tuint)))
                          (Sifthenelse (Ebinop Ogt (Etempvar _lb tuint)
                                         (Etempvar _remaining tuint) tint)
                            (Ssequence
                              (Ssequence
                                (Sset _t'10
                                  (Efield
                                    (Ederef
                                      (Etempvar _stats (tptr (Tstruct _ccv_stats noattr)))
                                      (Tstruct _ccv_stats noattr))
                                    _charge_prunes tuint))
                                (Sassign
                                  (Efield
                                    (Ederef
                                      (Etempvar _stats (tptr (Tstruct _ccv_stats noattr)))
                                      (Tstruct _ccv_stats noattr))
                                    _charge_prunes tuint)
                                  (Ebinop Oadd (Etempvar _t'10 tuint)
                                    (Econst_int (Int.repr 1) tint) tuint)))
                              (Sreturn (Some (Econst_int (Int.repr 0) tint))))
                            Sskip))))
                    Sskip))
                (Sreturn (Some (Econst_int (Int.repr 1) tint)))))))))))
|}.

Definition f_leaf := {|
  fn_return := tint;
  fn_callconv := cc_default;
  fn_params := ((_p, (tptr (Tstruct _ccv_problem noattr))) ::
                (_w, (tptr (Tstruct _ccv_workspace noattr))) :: nil);
  fn_vars := nil;
  fn_temps := ((_q, tuint) :: (_i, tuint) :: (_ok, tuint) ::
               (_logical, tuint) :: (_t'1, tint) :: (_t'18, tuint) ::
               (_t'17, tuchar) :: (_t'16, (tptr tuchar)) ::
               (_t'15, tuchar) :: (_t'14, (tptr tuchar)) :: (_t'13, tuint) ::
               (_t'12, tuchar) :: (_t'11, tuint) :: (_t'10, (tptr tuchar)) ::
               (_t'9, tuchar) :: (_t'8, (tptr tuchar)) :: (_t'7, tuint) ::
               (_t'6, tuchar) :: (_t'5, tuint) :: (_t'4, (tptr tuchar)) ::
               (_t'3, tuchar) :: (_t'2, (tptr tuchar)) :: nil);
  fn_body :=
(Ssequence
  (Ssequence
    (Sset _q (Econst_int (Int.repr 0) tuint))
    (Sloop
      (Ssequence
        (Ssequence
          (Sset _t'18
            (Efield
              (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                (Tstruct _ccv_problem noattr)) _n tuint))
          (Sifthenelse (Ebinop Olt (Etempvar _q tuint) (Etempvar _t'18 tuint)
                         tint)
            Sskip
            Sbreak))
        (Ssequence
          (Ssequence
            (Sset _t'14
              (Efield
                (Ederef (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                  (Tstruct _ccv_workspace noattr)) _selected (tptr tuchar)))
            (Ssequence
              (Sset _t'15
                (Ederef
                  (Ebinop Oadd (Etempvar _t'14 (tptr tuchar))
                    (Etempvar _q tuint) (tptr tuchar)) tuchar))
              (Sifthenelse (Ebinop Oeq (Etempvar _t'15 tuchar)
                             (Econst_int (Int.repr 0) tuint) tint)
                (Ssequence
                  (Sset _t'16
                    (Efield
                      (Ederef
                        (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                        (Tstruct _ccv_workspace noattr)) _forbidden
                      (tptr tuchar)))
                  (Ssequence
                    (Sset _t'17
                      (Ederef
                        (Ebinop Oadd (Etempvar _t'16 (tptr tuchar))
                          (Etempvar _q tuint) (tptr tuchar)) tuchar))
                    (Sset _t'1
                      (Ecast
                        (Ebinop Oeq (Etempvar _t'17 tuchar)
                          (Econst_int (Int.repr 0) tuint) tint) tbool))))
                (Sset _t'1 (Econst_int (Int.repr 0) tint)))))
          (Sifthenelse (Etempvar _t'1 tint)
            (Ssequence
              (Sset _ok (Econst_int (Int.repr 1) tuint))
              (Ssequence
                (Ssequence
                  (Sset _i (Econst_int (Int.repr 0) tuint))
                  (Sloop
                    (Ssequence
                      (Ssequence
                        (Sset _t'13
                          (Efield
                            (Ederef
                              (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                              (Tstruct _ccv_problem noattr)) _checks tuint))
                        (Sifthenelse (Ebinop Olt (Etempvar _i tuint)
                                       (Etempvar _t'13 tuint) tint)
                          Sskip
                          Sbreak))
                      (Ssequence
                        (Sset _t'8
                          (Efield
                            (Ederef
                              (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                              (Tstruct _ccv_workspace noattr)) _syndrome
                            (tptr tuchar)))
                        (Ssequence
                          (Sset _t'9
                            (Ederef
                              (Ebinop Oadd (Etempvar _t'8 (tptr tuchar))
                                (Etempvar _i tuint) (tptr tuchar)) tuchar))
                          (Ssequence
                            (Sset _t'10
                              (Efield
                                (Ederef
                                  (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                  (Tstruct _ccv_problem noattr)) _h
                                (tptr tuchar)))
                            (Ssequence
                              (Sset _t'11
                                (Efield
                                  (Ederef
                                    (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                    (Tstruct _ccv_problem noattr)) _n tuint))
                              (Ssequence
                                (Sset _t'12
                                  (Ederef
                                    (Ebinop Oadd
                                      (Etempvar _t'10 (tptr tuchar))
                                      (Ebinop Oadd
                                        (Ebinop Omul (Etempvar _i tuint)
                                          (Etempvar _t'11 tuint) tuint)
                                        (Etempvar _q tuint) tuint)
                                      (tptr tuchar)) tuchar))
                                (Sifthenelse (Ebinop One
                                               (Etempvar _t'9 tuchar)
                                               (Etempvar _t'12 tuchar) tint)
                                  (Sset _ok (Econst_int (Int.repr 0) tuint))
                                  Sskip)))))))
                    (Sset _i
                      (Ebinop Oadd (Etempvar _i tuint)
                        (Econst_int (Int.repr 1) tint) tuint))))
                (Sifthenelse (Ebinop One (Etempvar _ok tuint)
                               (Econst_int (Int.repr 0) tuint) tint)
                  (Ssequence
                    (Sset _logical (Econst_int (Int.repr 0) tuint))
                    (Ssequence
                      (Ssequence
                        (Sset _i (Econst_int (Int.repr 0) tuint))
                        (Sloop
                          (Ssequence
                            (Ssequence
                              (Sset _t'7
                                (Efield
                                  (Ederef
                                    (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                    (Tstruct _ccv_problem noattr))
                                  _logical_rows tuint))
                              (Sifthenelse (Ebinop Olt (Etempvar _i tuint)
                                             (Etempvar _t'7 tuint) tint)
                                Sskip
                                Sbreak))
                            (Ssequence
                              (Sset _t'2
                                (Efield
                                  (Ederef
                                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                    (Tstruct _ccv_workspace noattr))
                                  _logical_value (tptr tuchar)))
                              (Ssequence
                                (Sset _t'3
                                  (Ederef
                                    (Ebinop Oadd
                                      (Etempvar _t'2 (tptr tuchar))
                                      (Etempvar _i tuint) (tptr tuchar))
                                    tuchar))
                                (Ssequence
                                  (Sset _t'4
                                    (Efield
                                      (Ederef
                                        (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                        (Tstruct _ccv_problem noattr))
                                      _logical (tptr tuchar)))
                                  (Ssequence
                                    (Sset _t'5
                                      (Efield
                                        (Ederef
                                          (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                          (Tstruct _ccv_problem noattr)) _n
                                        tuint))
                                    (Ssequence
                                      (Sset _t'6
                                        (Ederef
                                          (Ebinop Oadd
                                            (Etempvar _t'4 (tptr tuchar))
                                            (Ebinop Oadd
                                              (Ebinop Omul
                                                (Etempvar _i tuint)
                                                (Etempvar _t'5 tuint) tuint)
                                              (Etempvar _q tuint) tuint)
                                            (tptr tuchar)) tuchar))
                                      (Sset _logical
                                        (Ebinop Oor (Etempvar _logical tuint)
                                          (Ebinop Oxor (Etempvar _t'3 tuchar)
                                            (Etempvar _t'6 tuchar) tint)
                                          tuint))))))))
                          (Sset _i
                            (Ebinop Oadd (Etempvar _i tuint)
                              (Econst_int (Int.repr 1) tint) tuint))))
                      (Sifthenelse (Ebinop One (Etempvar _logical tuint)
                                     (Econst_int (Int.repr 0) tuint) tint)
                        (Ssequence
                          (Scall None
                            (Evar _toggle (Tfunction
                                            (Tcons
                                              (tptr (Tstruct _ccv_problem noattr))
                                              (Tcons
                                                (tptr (Tstruct _ccv_workspace noattr))
                                                (Tcons tuint Tnil))) tvoid
                                            cc_default))
                            ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
                             (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                             (Etempvar _q tuint) :: nil))
                          (Sreturn (Some (Econst_int (Int.repr 1) tint))))
                        Sskip)))
                  Sskip)))
            Sskip)))
      (Sset _q
        (Ebinop Oadd (Etempvar _q tuint) (Econst_int (Int.repr 1) tint)
          tuint))))
  (Sreturn (Some (Econst_int (Int.repr 0) tint))))
|}.

Definition f_search := {|
  fn_return := tint;
  fn_callconv := cc_default;
  fn_params := ((_p, (tptr (Tstruct _ccv_problem noattr))) ::
                (_cap, tuint) :: (_budget, tuint) :: (_rules, tuint) ::
                (_w, (tptr (Tstruct _ccv_workspace noattr))) ::
                (_out, (tptr tuchar)) ::
                (_stats, (tptr (Tstruct _ccv_stats noattr))) :: nil);
  fn_vars := ((_top, tuint) :: (_row, tuint) :: nil);
  fn_temps := ((_seed, tuint) :: (_i, tuint) :: (_depth, tuint) ::
               (_q, tuint) :: (_remaining, tuint) :: (_finish, tint) ::
               (_ov, tint) :: (_f, (tptr (Tstruct _ccv_frame noattr))) ::
               (_t'12, tint) :: (_t'11, tint) :: (_t'10, tint) ::
               (_t'9, tint) :: (_t'8, tint) :: (_t'7, tint) ::
               (_t'6, tint) :: (_t'5, tint) :: (_t'4, tint) ::
               (_t'3, tint) :: (_t'2, tint) :: (_t'1, tint) ::
               (_t'51, tuint) :: (_t'50, tuint) :: (_t'49, (tptr tuchar)) ::
               (_t'48, (tptr (Tstruct _ccv_frame noattr))) ::
               (_t'47, tuint) :: (_t'46, tuint) ::
               (_t'45, (tptr (Tstruct _ccv_frame noattr))) ::
               (_t'44, tuint) :: (_t'43, tuint) :: (_t'42, tuint) ::
               (_t'41, tuchar) :: (_t'40, (tptr tuchar)) :: (_t'39, tuint) ::
               (_t'38, tuchar) :: (_t'37, (tptr tuchar)) :: (_t'36, tuint) ::
               (_t'35, tuint) :: (_t'34, tuint) :: (_t'33, tuint) ::
               (_t'32, tuchar) :: (_t'31, (tptr tuchar)) :: (_t'30, tuint) ::
               (_t'29, tuchar) :: (_t'28, (tptr tuchar)) ::
               (_t'27, tuchar) :: (_t'26, tuint) :: (_t'25, tuint) ::
               (_t'24, (tptr tuchar)) :: (_t'23, tuchar) ::
               (_t'22, (tptr tuchar)) :: (_t'21, tuint) :: (_t'20, tuint) ::
               (_t'19, (tptr (Tstruct _ccv_frame noattr))) ::
               (_t'18, (tptr (Tstruct _ccv_frame noattr))) ::
               (_t'17, tuint) :: (_t'16, tuint) :: (_t'15, tuint) ::
               (_t'14, tuint) :: (_t'13, tuint) :: nil);
  fn_body :=
(Ssequence
  (Sifthenelse (Ebinop Oeq (Etempvar _cap tuint)
                 (Econst_int (Int.repr 0) tuint) tint)
    (Sreturn (Some (Econst_int (Int.repr 0) tint)))
    Sskip)
  (Ssequence
    (Ssequence
      (Sset _t'51
        (Efield
          (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
            (Tstruct _ccv_problem noattr)) _n tuint))
      (Sifthenelse (Ebinop Ogt (Etempvar _cap tuint) (Etempvar _t'51 tuint)
                     tint)
        (Sset _cap
          (Efield
            (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
              (Tstruct _ccv_problem noattr)) _n tuint))
        Sskip))
    (Ssequence
      (Ssequence
        (Sset _seed (Econst_int (Int.repr 0) tuint))
        (Sloop
          (Ssequence
            (Ssequence
              (Sset _t'50
                (Efield
                  (Ederef (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                    (Tstruct _ccv_problem noattr)) _n tuint))
              (Sifthenelse (Ebinop Olt (Etempvar _seed tuint)
                             (Etempvar _t'50 tuint) tint)
                Sskip
                Sbreak))
            (Ssequence
              (Scall None
                (Evar _clear (Tfunction
                               (Tcons (tptr (Tstruct _ccv_problem noattr))
                                 (Tcons
                                   (tptr (Tstruct _ccv_workspace noattr))
                                   (Tcons (tptr tuchar) Tnil))) tvoid
                               cc_default))
                ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
                 (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                 (Etempvar _out (tptr tuchar)) :: nil))
              (Ssequence
                (Ssequence
                  (Sset _i (Econst_int (Int.repr 0) tuint))
                  (Sloop
                    (Ssequence
                      (Sifthenelse (Ebinop Olt (Etempvar _i tuint)
                                     (Etempvar _seed tuint) tint)
                        Sskip
                        Sbreak)
                      (Ssequence
                        (Sset _t'49
                          (Efield
                            (Ederef
                              (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                              (Tstruct _ccv_workspace noattr)) _forbidden
                            (tptr tuchar)))
                        (Sassign
                          (Ederef
                            (Ebinop Oadd (Etempvar _t'49 (tptr tuchar))
                              (Etempvar _i tuint) (tptr tuchar)) tuchar)
                          (Econst_int (Int.repr 1) tuint))))
                    (Sset _i
                      (Ebinop Oadd (Etempvar _i tuint)
                        (Econst_int (Int.repr 1) tint) tuint))))
                (Ssequence
                  (Scall None
                    (Evar _toggle (Tfunction
                                    (Tcons
                                      (tptr (Tstruct _ccv_problem noattr))
                                      (Tcons
                                        (tptr (Tstruct _ccv_workspace noattr))
                                        (Tcons tuint Tnil))) tvoid
                                    cc_default))
                    ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
                     (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                     (Etempvar _seed tuint) :: nil))
                  (Ssequence
                    (Sset _depth (Econst_int (Int.repr 1) tuint))
                    (Ssequence
                      (Sassign (Evar _top tuint)
                        (Econst_int (Int.repr 0) tuint))
                      (Ssequence
                        (Ssequence
                          (Sset _t'48
                            (Efield
                              (Ederef
                                (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                (Tstruct _ccv_workspace noattr)) _frames
                              (tptr (Tstruct _ccv_frame noattr))))
                          (Sset _f
                            (Ebinop Oadd
                              (Etempvar _t'48 (tptr (Tstruct _ccv_frame noattr)))
                              (Econst_int (Int.repr 0) tint)
                              (tptr (Tstruct _ccv_frame noattr)))))
                        (Ssequence
                          (Sassign
                            (Efield
                              (Ederef
                                (Etempvar _f (tptr (Tstruct _ccv_frame noattr)))
                                (Tstruct _ccv_frame noattr)) _phase tuint)
                            (Econst_int (Int.repr 0) tuint))
                          (Ssequence
                            (Sassign
                              (Efield
                                (Ederef
                                  (Etempvar _f (tptr (Tstruct _ccv_frame noattr)))
                                  (Tstruct _ccv_frame noattr)) _mark tuint)
                              (Econst_int (Int.repr 0) tuint))
                            (Swhile
                              (Ebinop Ogt (Etempvar _depth tuint)
                                (Econst_int (Int.repr 0) tuint) tint)
                              (Ssequence
                                (Ssequence
                                  (Sset _t'47
                                    (Efield
                                      (Ederef
                                        (Etempvar _stats (tptr (Tstruct _ccv_stats noattr)))
                                        (Tstruct _ccv_stats noattr)) _steps
                                      tuint))
                                  (Sifthenelse (Ebinop Oge
                                                 (Etempvar _t'47 tuint)
                                                 (Etempvar _budget tuint)
                                                 tint)
                                    (Ssequence
                                      (Scall None
                                        (Evar _clear (Tfunction
                                                       (Tcons
                                                         (tptr (Tstruct _ccv_problem noattr))
                                                         (Tcons
                                                           (tptr (Tstruct _ccv_workspace noattr))
                                                           (Tcons
                                                             (tptr tuchar)
                                                             Tnil))) tvoid
                                                       cc_default))
                                        ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
                                         (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                                         (Etempvar _out (tptr tuchar)) ::
                                         nil))
                                      (Sreturn (Some (Eunop Oneg
                                                       (Econst_int (Int.repr 1) tint)
                                                       tint))))
                                    Sskip))
                                (Ssequence
                                  (Ssequence
                                    (Sset _t'46
                                      (Efield
                                        (Ederef
                                          (Etempvar _stats (tptr (Tstruct _ccv_stats noattr)))
                                          (Tstruct _ccv_stats noattr)) _steps
                                        tuint))
                                    (Sassign
                                      (Efield
                                        (Ederef
                                          (Etempvar _stats (tptr (Tstruct _ccv_stats noattr)))
                                          (Tstruct _ccv_stats noattr)) _steps
                                        tuint)
                                      (Ebinop Oadd (Etempvar _t'46 tuint)
                                        (Econst_int (Int.repr 1) tint) tuint)))
                                  (Ssequence
                                    (Ssequence
                                      (Sset _t'45
                                        (Efield
                                          (Ederef
                                            (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                            (Tstruct _ccv_workspace noattr))
                                          _frames
                                          (tptr (Tstruct _ccv_frame noattr))))
                                      (Sset _f
                                        (Ebinop Oadd
                                          (Etempvar _t'45 (tptr (Tstruct _ccv_frame noattr)))
                                          (Ebinop Osub
                                            (Etempvar _depth tuint)
                                            (Econst_int (Int.repr 1) tuint)
                                            tuint)
                                          (tptr (Tstruct _ccv_frame noattr)))))
                                    (Ssequence
                                      (Sset _finish
                                        (Econst_int (Int.repr 0) tint))
                                      (Ssequence
                                        (Ssequence
                                          (Sset _t'14
                                            (Efield
                                              (Ederef
                                                (Etempvar _f (tptr (Tstruct _ccv_frame noattr)))
                                                (Tstruct _ccv_frame noattr))
                                              _phase tuint))
                                          (Sifthenelse (Ebinop Oeq
                                                         (Etempvar _t'14 tuint)
                                                         (Econst_int (Int.repr 0) tuint)
                                                         tint)
                                            (Ssequence
                                              (Ssequence
                                                (Sset _t'44
                                                  (Efield
                                                    (Ederef
                                                      (Etempvar _stats (tptr (Tstruct _ccv_stats noattr)))
                                                      (Tstruct _ccv_stats noattr))
                                                    _nodes tuint))
                                                (Sassign
                                                  (Efield
                                                    (Ederef
                                                      (Etempvar _stats (tptr (Tstruct _ccv_stats noattr)))
                                                      (Tstruct _ccv_stats noattr))
                                                    _nodes tuint)
                                                  (Ebinop Oadd
                                                    (Etempvar _t'44 tuint)
                                                    (Econst_int (Int.repr 1) tint)
                                                    tuint)))
                                              (Ssequence
                                                (Sset _remaining
                                                  (Ebinop Osub
                                                    (Etempvar _cap tuint)
                                                    (Etempvar _depth tuint)
                                                    tuint))
                                                (Ssequence
                                                  (Ssequence
                                                    (Sset _t'43
                                                      (Efield
                                                        (Ederef
                                                          (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                          (Tstruct _ccv_problem noattr))
                                                        _checks tuint))
                                                    (Sassign
                                                      (Evar _row tuint)
                                                      (Etempvar _t'43 tuint)))
                                                  (Ssequence
                                                    (Ssequence
                                                      (Sset _i
                                                        (Econst_int (Int.repr 0) tuint))
                                                      (Sloop
                                                        (Ssequence
                                                          (Ssequence
                                                            (Sset _t'42
                                                              (Efield
                                                                (Ederef
                                                                  (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                                  (Tstruct _ccv_problem noattr))
                                                                _checks
                                                                tuint))
                                                            (Sifthenelse 
                                                              (Ebinop Olt
                                                                (Etempvar _i tuint)
                                                                (Etempvar _t'42 tuint)
                                                                tint)
                                                              Sskip
                                                              Sbreak))
                                                          (Ssequence
                                                            (Sset _t'40
                                                              (Efield
                                                                (Ederef
                                                                  (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                                                  (Tstruct _ccv_workspace noattr))
                                                                _syndrome
                                                                (tptr tuchar)))
                                                            (Ssequence
                                                              (Sset _t'41
                                                                (Ederef
                                                                  (Ebinop Oadd
                                                                    (Etempvar _t'40 (tptr tuchar))
                                                                    (Etempvar _i tuint)
                                                                    (tptr tuchar))
                                                                  tuchar))
                                                              (Sifthenelse 
                                                                (Ebinop One
                                                                  (Etempvar _t'41 tuchar)
                                                                  (Econst_int (Int.repr 0) tuint)
                                                                  tint)
                                                                (Ssequence
                                                                  (Sassign
                                                                    (Evar _row tuint)
                                                                    (Etempvar _i tuint))
                                                                  Sbreak)
                                                                Sskip))))
                                                        (Sset _i
                                                          (Ebinop Oadd
                                                            (Etempvar _i tuint)
                                                            (Econst_int (Int.repr 1) tint)
                                                            tuint))))
                                                    (Ssequence
                                                      (Ssequence
                                                        (Sset _t'35
                                                          (Evar _row tuint))
                                                        (Ssequence
                                                          (Sset _t'36
                                                            (Efield
                                                              (Ederef
                                                                (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                                (Tstruct _ccv_problem noattr))
                                                              _checks tuint))
                                                          (Sifthenelse 
                                                            (Ebinop Oeq
                                                              (Etempvar _t'35 tuint)
                                                              (Etempvar _t'36 tuint)
                                                              tint)
                                                            (Ssequence
                                                              (Ssequence
                                                                (Scall (Some _t'1)
                                                                  (Evar _nontrivial 
                                                                  (Tfunction
                                                                    (Tcons
                                                                    (tptr (Tstruct _ccv_problem noattr))
                                                                    (Tcons
                                                                    (tptr (Tstruct _ccv_workspace noattr))
                                                                    Tnil))
                                                                    tint
                                                                    cc_default))
                                                                  ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
                                                                   (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                                                                   nil))
                                                                (Sifthenelse (Etempvar _t'1 tint)
                                                                  (Ssequence
                                                                    (Ssequence
                                                                    (Sset _i
                                                                    (Econst_int (Int.repr 0) tuint))
                                                                    (Sloop
                                                                    (Ssequence
                                                                    (Ssequence
                                                                    (Sset _t'39
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                                    (Tstruct _ccv_problem noattr))
                                                                    _n tuint))
                                                                    (Sifthenelse 
                                                                    (Ebinop Olt
                                                                    (Etempvar _i tuint)
                                                                    (Etempvar _t'39 tuint)
                                                                    tint)
                                                                    Sskip
                                                                    Sbreak))
                                                                    (Ssequence
                                                                    (Sset _t'37
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                                                    (Tstruct _ccv_workspace noattr))
                                                                    _selected
                                                                    (tptr tuchar)))
                                                                    (Ssequence
                                                                    (Sset _t'38
                                                                    (Ederef
                                                                    (Ebinop Oadd
                                                                    (Etempvar _t'37 (tptr tuchar))
                                                                    (Etempvar _i tuint)
                                                                    (tptr tuchar))
                                                                    tuchar))
                                                                    (Sassign
                                                                    (Ederef
                                                                    (Ebinop Oadd
                                                                    (Etempvar _out (tptr tuchar))
                                                                    (Etempvar _i tuint)
                                                                    (tptr tuchar))
                                                                    tuchar)
                                                                    (Etempvar _t'38 tuchar)))))
                                                                    (Sset _i
                                                                    (Ebinop Oadd
                                                                    (Etempvar _i tuint)
                                                                    (Econst_int (Int.repr 1) tint)
                                                                    tuint))))
                                                                    (Sreturn (Some (Econst_int (Int.repr 1) tint))))
                                                                  Sskip))
                                                              (Sset _finish
                                                                (Econst_int (Int.repr 1) tint)))
                                                            (Sifthenelse 
                                                              (Ebinop Oeq
                                                                (Etempvar _remaining tuint)
                                                                (Econst_int (Int.repr 0) tuint)
                                                                tint)
                                                              (Sset _finish
                                                                (Econst_int (Int.repr 1) tint))
                                                              Sskip))))
                                                      (Ssequence
                                                        (Ssequence
                                                          (Sifthenelse 
                                                            (Eunop Onotbool
                                                              (Etempvar _finish tint)
                                                              tint)
                                                            (Sset _t'3
                                                              (Ecast
                                                                (Ebinop One
                                                                  (Ebinop Oand
                                                                    (Etempvar _rules tuint)
                                                                    (Econst_int (Int.repr 8) tuint)
                                                                    tuint)
                                                                  (Econst_int (Int.repr 0) tuint)
                                                                  tint)
                                                                tbool))
                                                            (Sset _t'3
                                                              (Econst_int (Int.repr 0) tint)))
                                                          (Sifthenelse (Etempvar _t'3 tint)
                                                            (Ssequence
                                                              (Ssequence
                                                                (Scall (Some _t'2)
                                                                  (Evar _overlap 
                                                                  (Tfunction
                                                                    (Tcons
                                                                    (tptr (Tstruct _ccv_problem noattr))
                                                                    (Tcons
                                                                    (tptr (Tstruct _ccv_workspace noattr))
                                                                    (Tcons
                                                                    (tptr tuint)
                                                                    Tnil)))
                                                                    tint
                                                                    cc_default))
                                                                  ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
                                                                   (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                                                                   (Eaddrof
                                                                    (Evar _top tuint)
                                                                    (tptr tuint)) ::
                                                                   nil))
                                                                (Sset _ov
                                                                  (Etempvar _t'2 tint)))
                                                              (Ssequence
                                                                (Sifthenelse 
                                                                  (Ebinop Olt
                                                                    (Etempvar _ov tint)
                                                                    (Econst_int (Int.repr 0) tint)
                                                                    tint)
                                                                  (Ssequence
                                                                    (Scall None
                                                                    (Evar _clear 
                                                                    (Tfunction
                                                                    (Tcons
                                                                    (tptr (Tstruct _ccv_problem noattr))
                                                                    (Tcons
                                                                    (tptr (Tstruct _ccv_workspace noattr))
                                                                    (Tcons
                                                                    (tptr tuchar)
                                                                    Tnil)))
                                                                    tvoid
                                                                    cc_default))
                                                                    ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
                                                                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                                                                    (Etempvar _out (tptr tuchar)) ::
                                                                    nil))
                                                                    (Sreturn (Some 
                                                                    (Eunop Oneg
                                                                    (Econst_int (Int.repr 1) tint)
                                                                    tint))))
                                                                  Sskip)
                                                                (Sifthenelse 
                                                                  (Ebinop Oeq
                                                                    (Etempvar _ov tint)
                                                                    (Econst_int (Int.repr 0) tint)
                                                                    tint)
                                                                  (Ssequence
                                                                    (Ssequence
                                                                    (Sset _t'34
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _stats (tptr (Tstruct _ccv_stats noattr)))
                                                                    (Tstruct _ccv_stats noattr))
                                                                    _overlap_prunes
                                                                    tuint))
                                                                    (Sassign
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _stats (tptr (Tstruct _ccv_stats noattr)))
                                                                    (Tstruct _ccv_stats noattr))
                                                                    _overlap_prunes
                                                                    tuint)
                                                                    (Ebinop Oadd
                                                                    (Etempvar _t'34 tuint)
                                                                    (Econst_int (Int.repr 1) tint)
                                                                    tuint)))
                                                                    (Sset _finish
                                                                    (Econst_int (Int.repr 1) tint)))
                                                                  Sskip)))
                                                            Sskip))
                                                        (Ssequence
                                                          (Ssequence
                                                            (Sifthenelse 
                                                              (Eunop Onotbool
                                                                (Etempvar _finish tint)
                                                                tint)
                                                              (Ssequence
                                                                (Scall (Some _t'5)
                                                                  (Evar _bounds 
                                                                  (Tfunction
                                                                    (Tcons
                                                                    (tptr (Tstruct _ccv_problem noattr))
                                                                    (Tcons
                                                                    (tptr (Tstruct _ccv_workspace noattr))
                                                                    (Tcons
                                                                    tuint
                                                                    (Tcons
                                                                    tuint
                                                                    (Tcons
                                                                    (tptr tuint)
                                                                    (Tcons
                                                                    (tptr (Tstruct _ccv_stats noattr))
                                                                    Tnil))))))
                                                                    tint
                                                                    cc_default))
                                                                  ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
                                                                   (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                                                                   (Etempvar _remaining tuint) ::
                                                                   (Etempvar _rules tuint) ::
                                                                   (Eaddrof
                                                                    (Evar _row tuint)
                                                                    (tptr tuint)) ::
                                                                   (Etempvar _stats (tptr (Tstruct _ccv_stats noattr))) ::
                                                                   nil))
                                                                (Sset _t'4
                                                                  (Ecast
                                                                    (Eunop Onotbool
                                                                    (Etempvar _t'5 tint)
                                                                    tint)
                                                                    tbool)))
                                                              (Sset _t'4
                                                                (Econst_int (Int.repr 0) tint)))
                                                            (Sifthenelse (Etempvar _t'4 tint)
                                                              (Sset _finish
                                                                (Econst_int (Int.repr 1) tint))
                                                              Sskip))
                                                          (Ssequence
                                                            (Ssequence
                                                              (Ssequence
                                                                (Sifthenelse 
                                                                  (Eunop Onotbool
                                                                    (Etempvar _finish tint)
                                                                    tint)
                                                                  (Sset _t'7
                                                                    (Ecast
                                                                    (Ebinop Oeq
                                                                    (Etempvar _remaining tuint)
                                                                    (Econst_int (Int.repr 1) tuint)
                                                                    tint)
                                                                    tbool))
                                                                  (Sset _t'7
                                                                    (Econst_int (Int.repr 0) tint)))
                                                                (Sifthenelse (Etempvar _t'7 tint)
                                                                  (Sset _t'8
                                                                    (Ecast
                                                                    (Ebinop One
                                                                    (Ebinop Oand
                                                                    (Etempvar _rules tuint)
                                                                    (Econst_int (Int.repr 4) tuint)
                                                                    tuint)
                                                                    (Econst_int (Int.repr 0) tuint)
                                                                    tint)
                                                                    tbool))
                                                                  (Sset _t'8
                                                                    (Econst_int (Int.repr 0) tint))))
                                                              (Sifthenelse (Etempvar _t'8 tint)
                                                                (Ssequence
                                                                  (Ssequence
                                                                    (Scall (Some _t'6)
                                                                    (Evar _leaf 
                                                                    (Tfunction
                                                                    (Tcons
                                                                    (tptr (Tstruct _ccv_problem noattr))
                                                                    (Tcons
                                                                    (tptr (Tstruct _ccv_workspace noattr))
                                                                    Tnil))
                                                                    tint
                                                                    cc_default))
                                                                    ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
                                                                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                                                                    nil))
                                                                    (Sifthenelse (Etempvar _t'6 tint)
                                                                    (Ssequence
                                                                    (Ssequence
                                                                    (Sset _i
                                                                    (Econst_int (Int.repr 0) tuint))
                                                                    (Sloop
                                                                    (Ssequence
                                                                    (Ssequence
                                                                    (Sset _t'33
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                                    (Tstruct _ccv_problem noattr))
                                                                    _n tuint))
                                                                    (Sifthenelse 
                                                                    (Ebinop Olt
                                                                    (Etempvar _i tuint)
                                                                    (Etempvar _t'33 tuint)
                                                                    tint)
                                                                    Sskip
                                                                    Sbreak))
                                                                    (Ssequence
                                                                    (Sset _t'31
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                                                    (Tstruct _ccv_workspace noattr))
                                                                    _selected
                                                                    (tptr tuchar)))
                                                                    (Ssequence
                                                                    (Sset _t'32
                                                                    (Ederef
                                                                    (Ebinop Oadd
                                                                    (Etempvar _t'31 (tptr tuchar))
                                                                    (Etempvar _i tuint)
                                                                    (tptr tuchar))
                                                                    tuchar))
                                                                    (Sassign
                                                                    (Ederef
                                                                    (Ebinop Oadd
                                                                    (Etempvar _out (tptr tuchar))
                                                                    (Etempvar _i tuint)
                                                                    (tptr tuchar))
                                                                    tuchar)
                                                                    (Etempvar _t'32 tuchar)))))
                                                                    (Sset _i
                                                                    (Ebinop Oadd
                                                                    (Etempvar _i tuint)
                                                                    (Econst_int (Int.repr 1) tint)
                                                                    tuint))))
                                                                    (Sreturn (Some (Econst_int (Int.repr 1) tint))))
                                                                    Sskip))
                                                                  (Sset _finish
                                                                    (Econst_int (Int.repr 1) tint)))
                                                                Sskip))
                                                            (Sifthenelse 
                                                              (Eunop Onotbool
                                                                (Etempvar _finish tint)
                                                                tint)
                                                              (Ssequence
                                                                (Ssequence
                                                                  (Sset _t'30
                                                                    (Evar _row tuint))
                                                                  (Sassign
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _f (tptr (Tstruct _ccv_frame noattr)))
                                                                    (Tstruct _ccv_frame noattr))
                                                                    _row
                                                                    tuint)
                                                                    (Etempvar _t'30 tuint)))
                                                                (Ssequence
                                                                  (Sassign
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _f (tptr (Tstruct _ccv_frame noattr)))
                                                                    (Tstruct _ccv_frame noattr))
                                                                    _next
                                                                    tuint)
                                                                    (Econst_int (Int.repr 0) tuint))
                                                                  (Sassign
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _f (tptr (Tstruct _ccv_frame noattr)))
                                                                    (Tstruct _ccv_frame noattr))
                                                                    _phase
                                                                    tuint)
                                                                    (Econst_int (Int.repr 1) tuint))))
                                                              Sskip)))))))))
                                            (Ssequence
                                              (Sset _t'15
                                                (Efield
                                                  (Ederef
                                                    (Etempvar _f (tptr (Tstruct _ccv_frame noattr)))
                                                    (Tstruct _ccv_frame noattr))
                                                  _phase tuint))
                                              (Sifthenelse (Ebinop Oeq
                                                             (Etempvar _t'15 tuint)
                                                             (Econst_int (Int.repr 1) tuint)
                                                             tint)
                                                (Ssequence
                                                  (Sset _q
                                                    (Efield
                                                      (Ederef
                                                        (Etempvar _f (tptr (Tstruct _ccv_frame noattr)))
                                                        (Tstruct _ccv_frame noattr))
                                                      _next tuint))
                                                  (Ssequence
                                                    (Sloop
                                                      (Ssequence
                                                        (Ssequence
                                                          (Ssequence
                                                            (Sset _t'21
                                                              (Efield
                                                                (Ederef
                                                                  (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                                  (Tstruct _ccv_problem noattr))
                                                                _n tuint))
                                                            (Sifthenelse 
                                                              (Ebinop Olt
                                                                (Etempvar _q tuint)
                                                                (Etempvar _t'21 tuint)
                                                                tint)
                                                              (Ssequence
                                                                (Ssequence
                                                                  (Sset _t'24
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                                    (Tstruct _ccv_problem noattr))
                                                                    _h
                                                                    (tptr tuchar)))
                                                                  (Ssequence
                                                                    (Sset _t'25
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _f (tptr (Tstruct _ccv_frame noattr)))
                                                                    (Tstruct _ccv_frame noattr))
                                                                    _row
                                                                    tuint))
                                                                    (Ssequence
                                                                    (Sset _t'26
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                                    (Tstruct _ccv_problem noattr))
                                                                    _n tuint))
                                                                    (Ssequence
                                                                    (Sset _t'27
                                                                    (Ederef
                                                                    (Ebinop Oadd
                                                                    (Etempvar _t'24 (tptr tuchar))
                                                                    (Ebinop Oadd
                                                                    (Ebinop Omul
                                                                    (Etempvar _t'25 tuint)
                                                                    (Etempvar _t'26 tuint)
                                                                    tuint)
                                                                    (Etempvar _q tuint)
                                                                    tuint)
                                                                    (tptr tuchar))
                                                                    tuchar))
                                                                    (Sifthenelse 
                                                                    (Ebinop Oeq
                                                                    (Etempvar _t'27 tuchar)
                                                                    (Econst_int (Int.repr 0) tuint)
                                                                    tint)
                                                                    (Sset _t'10
                                                                    (Econst_int (Int.repr 1) tint))
                                                                    (Ssequence
                                                                    (Sset _t'28
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                                                    (Tstruct _ccv_workspace noattr))
                                                                    _selected
                                                                    (tptr tuchar)))
                                                                    (Ssequence
                                                                    (Sset _t'29
                                                                    (Ederef
                                                                    (Ebinop Oadd
                                                                    (Etempvar _t'28 (tptr tuchar))
                                                                    (Etempvar _q tuint)
                                                                    (tptr tuchar))
                                                                    tuchar))
                                                                    (Sset _t'10
                                                                    (Ecast
                                                                    (Ebinop One
                                                                    (Etempvar _t'29 tuchar)
                                                                    (Econst_int (Int.repr 0) tuint)
                                                                    tint)
                                                                    tbool)))))))))
                                                                (Sifthenelse (Etempvar _t'10 tint)
                                                                  (Sset _t'9
                                                                    (Ecast
                                                                    (Econst_int (Int.repr 1) tint)
                                                                    tbool))
                                                                  (Ssequence
                                                                    (Ssequence
                                                                    (Sset _t'22
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                                                    (Tstruct _ccv_workspace noattr))
                                                                    _forbidden
                                                                    (tptr tuchar)))
                                                                    (Ssequence
                                                                    (Sset _t'23
                                                                    (Ederef
                                                                    (Ebinop Oadd
                                                                    (Etempvar _t'22 (tptr tuchar))
                                                                    (Etempvar _q tuint)
                                                                    (tptr tuchar))
                                                                    tuchar))
                                                                    (Sset _t'9
                                                                    (Ecast
                                                                    (Ebinop One
                                                                    (Etempvar _t'23 tuchar)
                                                                    (Econst_int (Int.repr 0) tuint)
                                                                    tint)
                                                                    tbool))))
                                                                    (Sset _t'9
                                                                    (Ecast
                                                                    (Etempvar _t'9 tint)
                                                                    tbool)))))
                                                              (Sset _t'9
                                                                (Econst_int (Int.repr 0) tint))))
                                                          (Sifthenelse (Etempvar _t'9 tint)
                                                            Sskip
                                                            Sbreak))
                                                        (Sset _q
                                                          (Ebinop Oadd
                                                            (Etempvar _q tuint)
                                                            (Econst_int (Int.repr 1) tint)
                                                            tuint)))
                                                      Sskip)
                                                    (Ssequence
                                                      (Sset _t'17
                                                        (Efield
                                                          (Ederef
                                                            (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                            (Tstruct _ccv_problem noattr))
                                                          _n tuint))
                                                      (Sifthenelse (Ebinop Oeq
                                                                    (Etempvar _q tuint)
                                                                    (Etempvar _t'17 tuint)
                                                                    tint)
                                                        (Sset _finish
                                                          (Econst_int (Int.repr 1) tint))
                                                        (Ssequence
                                                          (Sassign
                                                            (Efield
                                                              (Ederef
                                                                (Etempvar _f (tptr (Tstruct _ccv_frame noattr)))
                                                                (Tstruct _ccv_frame noattr))
                                                              _next tuint)
                                                            (Ebinop Oadd
                                                              (Etempvar _q tuint)
                                                              (Econst_int (Int.repr 1) tuint)
                                                              tuint))
                                                          (Ssequence
                                                            (Sassign
                                                              (Efield
                                                                (Ederef
                                                                  (Etempvar _f (tptr (Tstruct _ccv_frame noattr)))
                                                                  (Tstruct _ccv_frame noattr))
                                                                _chosen
                                                                tuint)
                                                              (Etempvar _q tuint))
                                                            (Ssequence
                                                              (Sassign
                                                                (Efield
                                                                  (Ederef
                                                                    (Etempvar _f (tptr (Tstruct _ccv_frame noattr)))
                                                                    (Tstruct _ccv_frame noattr))
                                                                  _phase
                                                                  tuint)
                                                                (Econst_int (Int.repr 2) tuint))
                                                              (Ssequence
                                                                (Scall None
                                                                  (Evar _toggle 
                                                                  (Tfunction
                                                                    (Tcons
                                                                    (tptr (Tstruct _ccv_problem noattr))
                                                                    (Tcons
                                                                    (tptr (Tstruct _ccv_workspace noattr))
                                                                    (Tcons
                                                                    tuint
                                                                    Tnil)))
                                                                    tvoid
                                                                    cc_default))
                                                                  ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
                                                                   (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                                                                   (Etempvar _q tuint) ::
                                                                   nil))
                                                                (Ssequence
                                                                  (Ssequence
                                                                    (Sset _t'19
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                                                    (Tstruct _ccv_workspace noattr))
                                                                    _frames
                                                                    (tptr (Tstruct _ccv_frame noattr))))
                                                                    (Ssequence
                                                                    (Sset _t'20
                                                                    (Evar _top tuint))
                                                                    (Sassign
                                                                    (Efield
                                                                    (Ederef
                                                                    (Ebinop Oadd
                                                                    (Etempvar _t'19 (tptr (Tstruct _ccv_frame noattr)))
                                                                    (Etempvar _depth tuint)
                                                                    (tptr (Tstruct _ccv_frame noattr)))
                                                                    (Tstruct _ccv_frame noattr))
                                                                    _mark
                                                                    tuint)
                                                                    (Etempvar _t'20 tuint))))
                                                                  (Ssequence
                                                                    (Ssequence
                                                                    (Sset _t'18
                                                                    (Efield
                                                                    (Ederef
                                                                    (Etempvar _w (tptr (Tstruct _ccv_workspace noattr)))
                                                                    (Tstruct _ccv_workspace noattr))
                                                                    _frames
                                                                    (tptr (Tstruct _ccv_frame noattr))))
                                                                    (Sassign
                                                                    (Efield
                                                                    (Ederef
                                                                    (Ebinop Oadd
                                                                    (Etempvar _t'18 (tptr (Tstruct _ccv_frame noattr)))
                                                                    (Etempvar _depth tuint)
                                                                    (tptr (Tstruct _ccv_frame noattr)))
                                                                    (Tstruct _ccv_frame noattr))
                                                                    _phase
                                                                    tuint)
                                                                    (Econst_int (Int.repr 0) tuint)))
                                                                    (Sset _depth
                                                                    (Ebinop Oadd
                                                                    (Etempvar _depth tuint)
                                                                    (Econst_int (Int.repr 1) tint)
                                                                    tuint))))))))))))
                                                (Ssequence
                                                  (Sset _q
                                                    (Efield
                                                      (Ederef
                                                        (Etempvar _f (tptr (Tstruct _ccv_frame noattr)))
                                                        (Tstruct _ccv_frame noattr))
                                                      _chosen tuint))
                                                  (Ssequence
                                                    (Scall None
                                                      (Evar _toggle (Tfunction
                                                                    (Tcons
                                                                    (tptr (Tstruct _ccv_problem noattr))
                                                                    (Tcons
                                                                    (tptr (Tstruct _ccv_workspace noattr))
                                                                    (Tcons
                                                                    tuint
                                                                    Tnil)))
                                                                    tvoid
                                                                    cc_default))
                                                      ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
                                                       (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                                                       (Etempvar _q tuint) ::
                                                       nil))
                                                    (Ssequence
                                                      (Ssequence
                                                        (Sifthenelse 
                                                          (Ebinop One
                                                            (Ebinop Oand
                                                              (Etempvar _rules tuint)
                                                              (Econst_int (Int.repr 1) tuint)
                                                              tuint)
                                                            (Econst_int (Int.repr 0) tuint)
                                                            tint)
                                                          (Ssequence
                                                            (Ssequence
                                                              (Sset _t'16
                                                                (Efield
                                                                  (Ederef
                                                                    (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                                                    (Tstruct _ccv_problem noattr))
                                                                  _n tuint))
                                                              (Scall (Some _t'12)
                                                                (Evar _forbid 
                                                                (Tfunction
                                                                  (Tcons
                                                                    (tptr (Tstruct _ccv_workspace noattr))
                                                                    (Tcons
                                                                    tuint
                                                                    (Tcons
                                                                    (tptr tuint)
                                                                    (Tcons
                                                                    tuint
                                                                    Tnil))))
                                                                  tint
                                                                  cc_default))
                                                                ((Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                                                                 (Etempvar _q tuint) ::
                                                                 (Eaddrof
                                                                   (Evar _top tuint)
                                                                   (tptr tuint)) ::
                                                                 (Etempvar _t'16 tuint) ::
                                                                 nil)))
                                                            (Sset _t'11
                                                              (Ecast
                                                                (Eunop Onotbool
                                                                  (Etempvar _t'12 tint)
                                                                  tint)
                                                                tbool)))
                                                          (Sset _t'11
                                                            (Econst_int (Int.repr 0) tint)))
                                                        (Sifthenelse (Etempvar _t'11 tint)
                                                          (Ssequence
                                                            (Scall None
                                                              (Evar _clear 
                                                              (Tfunction
                                                                (Tcons
                                                                  (tptr (Tstruct _ccv_problem noattr))
                                                                  (Tcons
                                                                    (tptr (Tstruct _ccv_workspace noattr))
                                                                    (Tcons
                                                                    (tptr tuchar)
                                                                    Tnil)))
                                                                tvoid
                                                                cc_default))
                                                              ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
                                                               (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                                                               (Etempvar _out (tptr tuchar)) ::
                                                               nil))
                                                            (Sreturn (Some 
                                                              (Eunop Oneg
                                                                (Econst_int (Int.repr 1) tint)
                                                                tint))))
                                                          Sskip))
                                                      (Sassign
                                                        (Efield
                                                          (Ederef
                                                            (Etempvar _f (tptr (Tstruct _ccv_frame noattr)))
                                                            (Tstruct _ccv_frame noattr))
                                                          _phase tuint)
                                                        (Econst_int (Int.repr 1) tuint)))))))))
                                        (Sifthenelse (Etempvar _finish tint)
                                          (Ssequence
                                            (Ssequence
                                              (Sset _t'13
                                                (Efield
                                                  (Ederef
                                                    (Etempvar _f (tptr (Tstruct _ccv_frame noattr)))
                                                    (Tstruct _ccv_frame noattr))
                                                  _mark tuint))
                                              (Scall None
                                                (Evar _restore (Tfunction
                                                                 (Tcons
                                                                   (tptr (Tstruct _ccv_workspace noattr))
                                                                   (Tcons
                                                                    (tptr tuint)
                                                                    (Tcons
                                                                    tuint
                                                                    Tnil)))
                                                                 tvoid
                                                                 cc_default))
                                                ((Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                                                 (Eaddrof (Evar _top tuint)
                                                   (tptr tuint)) ::
                                                 (Etempvar _t'13 tuint) ::
                                                 nil)))
                                            (Sset _depth
                                              (Ebinop Osub
                                                (Etempvar _depth tuint)
                                                (Econst_int (Int.repr 1) tint)
                                                tuint)))
                                          Sskip))))))))))))))))
          (Sset _seed
            (Ebinop Oadd (Etempvar _seed tuint)
              (Econst_int (Int.repr 1) tint) tuint))))
      (Ssequence
        (Scall None
          (Evar _clear (Tfunction
                         (Tcons (tptr (Tstruct _ccv_problem noattr))
                           (Tcons (tptr (Tstruct _ccv_workspace noattr))
                             (Tcons (tptr tuchar) Tnil))) tvoid cc_default))
          ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
           (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
           (Etempvar _out (tptr tuchar)) :: nil))
        (Sreturn (Some (Econst_int (Int.repr 0) tint)))))))
|}.

Definition f_stats_init := {|
  fn_return := tvoid;
  fn_callconv := cc_default;
  fn_params := ((_s, (tptr (Tstruct _ccv_stats noattr))) :: nil);
  fn_vars := nil;
  fn_temps := nil;
  fn_body :=
(Ssequence
  (Sassign
    (Efield
      (Ederef (Etempvar _s (tptr (Tstruct _ccv_stats noattr)))
        (Tstruct _ccv_stats noattr)) _steps tuint)
    (Econst_int (Int.repr 0) tuint))
  (Ssequence
    (Sassign
      (Efield
        (Ederef (Etempvar _s (tptr (Tstruct _ccv_stats noattr)))
          (Tstruct _ccv_stats noattr)) _nodes tuint)
      (Econst_int (Int.repr 0) tuint))
    (Ssequence
      (Sassign
        (Efield
          (Ederef (Etempvar _s (tptr (Tstruct _ccv_stats noattr)))
            (Tstruct _ccv_stats noattr)) _pack_prunes tuint)
        (Econst_int (Int.repr 0) tuint))
      (Ssequence
        (Sassign
          (Efield
            (Ederef (Etempvar _s (tptr (Tstruct _ccv_stats noattr)))
              (Tstruct _ccv_stats noattr)) _charge_prunes tuint)
          (Econst_int (Int.repr 0) tuint))
        (Sassign
          (Efield
            (Ederef (Etempvar _s (tptr (Tstruct _ccv_stats noattr)))
              (Tstruct _ccv_stats noattr)) _overlap_prunes tuint)
          (Econst_int (Int.repr 0) tuint))))))
|}.

Definition f_ccv_decide := {|
  fn_return := tint;
  fn_callconv := cc_default;
  fn_params := ((_p, (tptr (Tstruct _ccv_problem noattr))) ::
                (_cap, tuint) :: (_budget, tuint) :: (_rules, tuint) ::
                (_w, (tptr (Tstruct _ccv_workspace noattr))) ::
                (_out, (tptr tuchar)) ::
                (_s, (tptr (Tstruct _ccv_stats noattr))) :: nil);
  fn_vars := nil;
  fn_temps := ((_t'4, tint) :: (_t'3, tint) :: (_t'2, tint) ::
               (_t'1, tint) :: nil);
  fn_body :=
(Ssequence
  (Scall None
    (Evar _stats_init (Tfunction
                        (Tcons (tptr (Tstruct _ccv_stats noattr)) Tnil) tvoid
                        cc_default))
    ((Etempvar _s (tptr (Tstruct _ccv_stats noattr))) :: nil))
  (Ssequence
    (Ssequence
      (Ssequence
        (Scall (Some _t'1)
          (Evar _shape (Tfunction
                         (Tcons (tptr (Tstruct _ccv_problem noattr))
                           (Tcons (tptr (Tstruct _ccv_workspace noattr))
                             (Tcons tuint Tnil))) tint cc_default))
          ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
           (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
           (Etempvar _rules tuint) :: nil))
        (Sifthenelse (Eunop Onotbool (Etempvar _t'1 tint) tint)
          (Sset _t'2 (Econst_int (Int.repr 1) tint))
          (Ssequence
            (Scall (Some _t'3)
              (Evar _validate (Tfunction
                                (Tcons (tptr (Tstruct _ccv_problem noattr))
                                  Tnil) tint cc_default))
              ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) :: nil))
            (Sset _t'2
              (Ecast (Eunop Onotbool (Etempvar _t'3 tint) tint) tbool)))))
      (Sifthenelse (Etempvar _t'2 tint)
        (Sreturn (Some (Eunop Oneg (Econst_int (Int.repr 2) tint) tint)))
        Sskip))
    (Ssequence
      (Scall None
        (Evar _clear (Tfunction
                       (Tcons (tptr (Tstruct _ccv_problem noattr))
                         (Tcons (tptr (Tstruct _ccv_workspace noattr))
                           (Tcons (tptr tuchar) Tnil))) tvoid cc_default))
        ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
         (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
         (Etempvar _out (tptr tuchar)) :: nil))
      (Ssequence
        (Scall (Some _t'4)
          (Evar _search (Tfunction
                          (Tcons (tptr (Tstruct _ccv_problem noattr))
                            (Tcons tuint
                              (Tcons tuint
                                (Tcons tuint
                                  (Tcons
                                    (tptr (Tstruct _ccv_workspace noattr))
                                    (Tcons (tptr tuchar)
                                      (Tcons
                                        (tptr (Tstruct _ccv_stats noattr))
                                        Tnil))))))) tint cc_default))
          ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
           (Etempvar _cap tuint) :: (Etempvar _budget tuint) ::
           (Etempvar _rules tuint) ::
           (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
           (Etempvar _out (tptr tuchar)) ::
           (Etempvar _s (tptr (Tstruct _ccv_stats noattr))) :: nil))
        (Sreturn (Some (Etempvar _t'4 tint)))))))
|}.

Definition f_ccv_distance := {|
  fn_return := tint;
  fn_callconv := cc_default;
  fn_params := ((_p, (tptr (Tstruct _ccv_problem noattr))) ::
                (_budget, tuint) :: (_rules, tuint) ::
                (_w, (tptr (Tstruct _ccv_workspace noattr))) ::
                (_out, (tptr tuchar)) :: (_distance, (tptr tuint)) ::
                (_s, (tptr (Tstruct _ccv_stats noattr))) :: nil);
  fn_vars := nil;
  fn_temps := ((_cap, tuint) :: (_result, tint) :: (_t'5, tuint) ::
               (_t'4, tint) :: (_t'3, tint) :: (_t'2, tint) ::
               (_t'1, tint) :: (_t'7, tuint) :: (_t'6, tuint) :: nil);
  fn_body :=
(Ssequence
  (Scall None
    (Evar _stats_init (Tfunction
                        (Tcons (tptr (Tstruct _ccv_stats noattr)) Tnil) tvoid
                        cc_default))
    ((Etempvar _s (tptr (Tstruct _ccv_stats noattr))) :: nil))
  (Ssequence
    (Ssequence
      (Ssequence
        (Scall (Some _t'1)
          (Evar _shape (Tfunction
                         (Tcons (tptr (Tstruct _ccv_problem noattr))
                           (Tcons (tptr (Tstruct _ccv_workspace noattr))
                             (Tcons tuint Tnil))) tint cc_default))
          ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
           (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
           (Etempvar _rules tuint) :: nil))
        (Sifthenelse (Eunop Onotbool (Etempvar _t'1 tint) tint)
          (Sset _t'2 (Econst_int (Int.repr 1) tint))
          (Ssequence
            (Scall (Some _t'3)
              (Evar _validate (Tfunction
                                (Tcons (tptr (Tstruct _ccv_problem noattr))
                                  Tnil) tint cc_default))
              ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) :: nil))
            (Sset _t'2
              (Ecast (Eunop Onotbool (Etempvar _t'3 tint) tint) tbool)))))
      (Sifthenelse (Etempvar _t'2 tint)
        (Sreturn (Some (Eunop Oneg (Econst_int (Int.repr 2) tint) tint)))
        Sskip))
    (Ssequence
      (Scall None
        (Evar _clear (Tfunction
                       (Tcons (tptr (Tstruct _ccv_problem noattr))
                         (Tcons (tptr (Tstruct _ccv_workspace noattr))
                           (Tcons (tptr tuchar) Tnil))) tvoid cc_default))
        ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
         (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
         (Etempvar _out (tptr tuchar)) :: nil))
      (Ssequence
        (Sassign (Ederef (Etempvar _distance (tptr tuint)) tuint)
          (Econst_int (Int.repr 0) tuint))
        (Ssequence
          (Ssequence
            (Sset _cap (Econst_int (Int.repr 1) tuint))
            (Sloop
              (Ssequence
                (Ssequence
                  (Sset _t'7
                    (Efield
                      (Ederef
                        (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                        (Tstruct _ccv_problem noattr)) _n tuint))
                  (Sifthenelse (Ebinop Ole (Etempvar _cap tuint)
                                 (Etempvar _t'7 tuint) tint)
                    Sskip
                    Sbreak))
                (Ssequence
                  (Ssequence
                    (Scall (Some _t'4)
                      (Evar _search (Tfunction
                                      (Tcons
                                        (tptr (Tstruct _ccv_problem noattr))
                                        (Tcons tuint
                                          (Tcons tuint
                                            (Tcons tuint
                                              (Tcons
                                                (tptr (Tstruct _ccv_workspace noattr))
                                                (Tcons (tptr tuchar)
                                                  (Tcons
                                                    (tptr (Tstruct _ccv_stats noattr))
                                                    Tnil))))))) tint
                                      cc_default))
                      ((Etempvar _p (tptr (Tstruct _ccv_problem noattr))) ::
                       (Etempvar _cap tuint) :: (Etempvar _budget tuint) ::
                       (Etempvar _rules tuint) ::
                       (Etempvar _w (tptr (Tstruct _ccv_workspace noattr))) ::
                       (Etempvar _out (tptr tuchar)) ::
                       (Etempvar _s (tptr (Tstruct _ccv_stats noattr))) ::
                       nil))
                    (Sset _result (Etempvar _t'4 tint)))
                  (Ssequence
                    (Sifthenelse (Ebinop Oeq (Etempvar _result tint)
                                   (Econst_int (Int.repr 1) tint) tint)
                      (Ssequence
                        (Ssequence
                          (Ssequence
                            (Sset _t'6
                              (Efield
                                (Ederef
                                  (Etempvar _p (tptr (Tstruct _ccv_problem noattr)))
                                  (Tstruct _ccv_problem noattr)) _n tuint))
                            (Scall (Some _t'5)
                              (Evar _ccv_weight (Tfunction
                                                  (Tcons tuint
                                                    (Tcons (tptr tuchar)
                                                      Tnil)) tuint
                                                  cc_default))
                              ((Etempvar _t'6 tuint) ::
                               (Etempvar _out (tptr tuchar)) :: nil)))
                          (Sassign
                            (Ederef (Etempvar _distance (tptr tuint)) tuint)
                            (Etempvar _t'5 tuint)))
                        (Sreturn (Some (Etempvar _result tint))))
                      Sskip)
                    (Sifthenelse (Ebinop One (Etempvar _result tint)
                                   (Econst_int (Int.repr 0) tint) tint)
                      (Sreturn (Some (Etempvar _result tint)))
                      Sskip))))
              (Sset _cap
                (Ebinop Oadd (Etempvar _cap tuint)
                  (Econst_int (Int.repr 1) tint) tuint))))
          (Sreturn (Some (Econst_int (Int.repr 0) tint))))))))
|}.

Definition composites : list composite_definition :=
(Composite _ccv_problem Struct
   (Member_plain _n tuint :: Member_plain _checks tuint ::
    Member_plain _logical_rows tuint :: Member_plain _stabilizers tuint ::
    Member_plain _h (tptr tuchar) :: Member_plain _logical (tptr tuchar) ::
    Member_plain _stabilizer (tptr tuchar) :: nil)
   noattr ::
 Composite _ccv_frame Struct
   (Member_plain _row tuint :: Member_plain _next tuint ::
    Member_plain _chosen tuint :: Member_plain _mark tuint ::
    Member_plain _phase tuint :: nil)
   noattr ::
 Composite _ccv_workspace Struct
   (Member_plain _capacity tuint :: Member_plain _frame_capacity tuint ::
    Member_plain _selected (tptr tuchar) ::
    Member_plain _forbidden (tptr tuchar) ::
    Member_plain _syndrome (tptr tuchar) ::
    Member_plain _logical_value (tptr tuchar) ::
    Member_plain _packed (tptr tuchar) :: Member_plain _undo (tptr tuint) ::
    Member_plain _frames (tptr (Tstruct _ccv_frame noattr)) :: nil)
   noattr ::
 Composite _ccv_stats Struct
   (Member_plain _steps tuint :: Member_plain _nodes tuint ::
    Member_plain _pack_prunes tuint :: Member_plain _charge_prunes tuint ::
    Member_plain _overlap_prunes tuint :: nil)
   noattr :: nil).

Definition global_definitions : list (ident * globdef fundef type) :=
((___compcert_va_int32,
   Gfun(External (EF_runtime "__compcert_va_int32"
                   (mksignature (AST.Tlong :: nil) AST.Tint cc_default))
     (Tcons (tptr tvoid) Tnil) tuint cc_default)) ::
 (___compcert_va_int64,
   Gfun(External (EF_runtime "__compcert_va_int64"
                   (mksignature (AST.Tlong :: nil) AST.Tlong cc_default))
     (Tcons (tptr tvoid) Tnil) tulong cc_default)) ::
 (___compcert_va_float64,
   Gfun(External (EF_runtime "__compcert_va_float64"
                   (mksignature (AST.Tlong :: nil) AST.Tfloat cc_default))
     (Tcons (tptr tvoid) Tnil) tdouble cc_default)) ::
 (___compcert_va_composite,
   Gfun(External (EF_runtime "__compcert_va_composite"
                   (mksignature (AST.Tlong :: AST.Tlong :: nil) AST.Tlong
                     cc_default)) (Tcons (tptr tvoid) (Tcons tulong Tnil))
     (tptr tvoid) cc_default)) ::
 (___compcert_i64_dtos,
   Gfun(External (EF_runtime "__compcert_i64_dtos"
                   (mksignature (AST.Tfloat :: nil) AST.Tlong cc_default))
     (Tcons tdouble Tnil) tlong cc_default)) ::
 (___compcert_i64_dtou,
   Gfun(External (EF_runtime "__compcert_i64_dtou"
                   (mksignature (AST.Tfloat :: nil) AST.Tlong cc_default))
     (Tcons tdouble Tnil) tulong cc_default)) ::
 (___compcert_i64_stod,
   Gfun(External (EF_runtime "__compcert_i64_stod"
                   (mksignature (AST.Tlong :: nil) AST.Tfloat cc_default))
     (Tcons tlong Tnil) tdouble cc_default)) ::
 (___compcert_i64_utod,
   Gfun(External (EF_runtime "__compcert_i64_utod"
                   (mksignature (AST.Tlong :: nil) AST.Tfloat cc_default))
     (Tcons tulong Tnil) tdouble cc_default)) ::
 (___compcert_i64_stof,
   Gfun(External (EF_runtime "__compcert_i64_stof"
                   (mksignature (AST.Tlong :: nil) AST.Tsingle cc_default))
     (Tcons tlong Tnil) tfloat cc_default)) ::
 (___compcert_i64_utof,
   Gfun(External (EF_runtime "__compcert_i64_utof"
                   (mksignature (AST.Tlong :: nil) AST.Tsingle cc_default))
     (Tcons tulong Tnil) tfloat cc_default)) ::
 (___compcert_i64_sdiv,
   Gfun(External (EF_runtime "__compcert_i64_sdiv"
                   (mksignature (AST.Tlong :: AST.Tlong :: nil) AST.Tlong
                     cc_default)) (Tcons tlong (Tcons tlong Tnil)) tlong
     cc_default)) ::
 (___compcert_i64_udiv,
   Gfun(External (EF_runtime "__compcert_i64_udiv"
                   (mksignature (AST.Tlong :: AST.Tlong :: nil) AST.Tlong
                     cc_default)) (Tcons tulong (Tcons tulong Tnil)) tulong
     cc_default)) ::
 (___compcert_i64_smod,
   Gfun(External (EF_runtime "__compcert_i64_smod"
                   (mksignature (AST.Tlong :: AST.Tlong :: nil) AST.Tlong
                     cc_default)) (Tcons tlong (Tcons tlong Tnil)) tlong
     cc_default)) ::
 (___compcert_i64_umod,
   Gfun(External (EF_runtime "__compcert_i64_umod"
                   (mksignature (AST.Tlong :: AST.Tlong :: nil) AST.Tlong
                     cc_default)) (Tcons tulong (Tcons tulong Tnil)) tulong
     cc_default)) ::
 (___compcert_i64_shl,
   Gfun(External (EF_runtime "__compcert_i64_shl"
                   (mksignature (AST.Tlong :: AST.Tint :: nil) AST.Tlong
                     cc_default)) (Tcons tlong (Tcons tint Tnil)) tlong
     cc_default)) ::
 (___compcert_i64_shr,
   Gfun(External (EF_runtime "__compcert_i64_shr"
                   (mksignature (AST.Tlong :: AST.Tint :: nil) AST.Tlong
                     cc_default)) (Tcons tulong (Tcons tint Tnil)) tulong
     cc_default)) ::
 (___compcert_i64_sar,
   Gfun(External (EF_runtime "__compcert_i64_sar"
                   (mksignature (AST.Tlong :: AST.Tint :: nil) AST.Tlong
                     cc_default)) (Tcons tlong (Tcons tint Tnil)) tlong
     cc_default)) ::
 (___compcert_i64_smulh,
   Gfun(External (EF_runtime "__compcert_i64_smulh"
                   (mksignature (AST.Tlong :: AST.Tlong :: nil) AST.Tlong
                     cc_default)) (Tcons tlong (Tcons tlong Tnil)) tlong
     cc_default)) ::
 (___compcert_i64_umulh,
   Gfun(External (EF_runtime "__compcert_i64_umulh"
                   (mksignature (AST.Tlong :: AST.Tlong :: nil) AST.Tlong
                     cc_default)) (Tcons tulong (Tcons tulong Tnil)) tulong
     cc_default)) ::
 (___builtin_ais_annot,
   Gfun(External (EF_builtin "__builtin_ais_annot"
                   (mksignature (AST.Tlong :: nil) AST.Tvoid
                     {|cc_vararg:=(Some 1); cc_unproto:=false; cc_structret:=false|}))
     (Tcons (tptr tschar) Tnil) tvoid
     {|cc_vararg:=(Some 1); cc_unproto:=false; cc_structret:=false|})) ::
 (___builtin_bswap64,
   Gfun(External (EF_builtin "__builtin_bswap64"
                   (mksignature (AST.Tlong :: nil) AST.Tlong cc_default))
     (Tcons tulong Tnil) tulong cc_default)) ::
 (___builtin_bswap,
   Gfun(External (EF_builtin "__builtin_bswap"
                   (mksignature (AST.Tint :: nil) AST.Tint cc_default))
     (Tcons tuint Tnil) tuint cc_default)) ::
 (___builtin_bswap32,
   Gfun(External (EF_builtin "__builtin_bswap32"
                   (mksignature (AST.Tint :: nil) AST.Tint cc_default))
     (Tcons tuint Tnil) tuint cc_default)) ::
 (___builtin_bswap16,
   Gfun(External (EF_builtin "__builtin_bswap16"
                   (mksignature (AST.Tint :: nil) AST.Tint16unsigned
                     cc_default)) (Tcons tushort Tnil) tushort cc_default)) ::
 (___builtin_clz,
   Gfun(External (EF_builtin "__builtin_clz"
                   (mksignature (AST.Tint :: nil) AST.Tint cc_default))
     (Tcons tuint Tnil) tint cc_default)) ::
 (___builtin_clzl,
   Gfun(External (EF_builtin "__builtin_clzl"
                   (mksignature (AST.Tlong :: nil) AST.Tint cc_default))
     (Tcons tulong Tnil) tint cc_default)) ::
 (___builtin_clzll,
   Gfun(External (EF_builtin "__builtin_clzll"
                   (mksignature (AST.Tlong :: nil) AST.Tint cc_default))
     (Tcons tulong Tnil) tint cc_default)) ::
 (___builtin_ctz,
   Gfun(External (EF_builtin "__builtin_ctz"
                   (mksignature (AST.Tint :: nil) AST.Tint cc_default))
     (Tcons tuint Tnil) tint cc_default)) ::
 (___builtin_ctzl,
   Gfun(External (EF_builtin "__builtin_ctzl"
                   (mksignature (AST.Tlong :: nil) AST.Tint cc_default))
     (Tcons tulong Tnil) tint cc_default)) ::
 (___builtin_ctzll,
   Gfun(External (EF_builtin "__builtin_ctzll"
                   (mksignature (AST.Tlong :: nil) AST.Tint cc_default))
     (Tcons tulong Tnil) tint cc_default)) ::
 (___builtin_fabs,
   Gfun(External (EF_builtin "__builtin_fabs"
                   (mksignature (AST.Tfloat :: nil) AST.Tfloat cc_default))
     (Tcons tdouble Tnil) tdouble cc_default)) ::
 (___builtin_fabsf,
   Gfun(External (EF_builtin "__builtin_fabsf"
                   (mksignature (AST.Tsingle :: nil) AST.Tsingle cc_default))
     (Tcons tfloat Tnil) tfloat cc_default)) ::
 (___builtin_fsqrt,
   Gfun(External (EF_builtin "__builtin_fsqrt"
                   (mksignature (AST.Tfloat :: nil) AST.Tfloat cc_default))
     (Tcons tdouble Tnil) tdouble cc_default)) ::
 (___builtin_sqrt,
   Gfun(External (EF_builtin "__builtin_sqrt"
                   (mksignature (AST.Tfloat :: nil) AST.Tfloat cc_default))
     (Tcons tdouble Tnil) tdouble cc_default)) ::
 (___builtin_memcpy_aligned,
   Gfun(External (EF_builtin "__builtin_memcpy_aligned"
                   (mksignature
                     (AST.Tlong :: AST.Tlong :: AST.Tlong :: AST.Tlong ::
                      nil) AST.Tvoid cc_default))
     (Tcons (tptr tvoid)
       (Tcons (tptr tvoid) (Tcons tulong (Tcons tulong Tnil)))) tvoid
     cc_default)) ::
 (___builtin_sel,
   Gfun(External (EF_builtin "__builtin_sel"
                   (mksignature (AST.Tint :: nil) AST.Tvoid
                     {|cc_vararg:=(Some 1); cc_unproto:=false; cc_structret:=false|}))
     (Tcons tbool Tnil) tvoid
     {|cc_vararg:=(Some 1); cc_unproto:=false; cc_structret:=false|})) ::
 (___builtin_annot,
   Gfun(External (EF_builtin "__builtin_annot"
                   (mksignature (AST.Tlong :: nil) AST.Tvoid
                     {|cc_vararg:=(Some 1); cc_unproto:=false; cc_structret:=false|}))
     (Tcons (tptr tschar) Tnil) tvoid
     {|cc_vararg:=(Some 1); cc_unproto:=false; cc_structret:=false|})) ::
 (___builtin_annot_intval,
   Gfun(External (EF_builtin "__builtin_annot_intval"
                   (mksignature (AST.Tlong :: AST.Tint :: nil) AST.Tint
                     cc_default)) (Tcons (tptr tschar) (Tcons tint Tnil))
     tint cc_default)) ::
 (___builtin_membar,
   Gfun(External (EF_builtin "__builtin_membar"
                   (mksignature nil AST.Tvoid cc_default)) Tnil tvoid
     cc_default)) ::
 (___builtin_va_start,
   Gfun(External (EF_builtin "__builtin_va_start"
                   (mksignature (AST.Tlong :: nil) AST.Tvoid cc_default))
     (Tcons (tptr tvoid) Tnil) tvoid cc_default)) ::
 (___builtin_va_arg,
   Gfun(External (EF_builtin "__builtin_va_arg"
                   (mksignature (AST.Tlong :: AST.Tint :: nil) AST.Tvoid
                     cc_default)) (Tcons (tptr tvoid) (Tcons tuint Tnil))
     tvoid cc_default)) ::
 (___builtin_va_copy,
   Gfun(External (EF_builtin "__builtin_va_copy"
                   (mksignature (AST.Tlong :: AST.Tlong :: nil) AST.Tvoid
                     cc_default))
     (Tcons (tptr tvoid) (Tcons (tptr tvoid) Tnil)) tvoid cc_default)) ::
 (___builtin_va_end,
   Gfun(External (EF_builtin "__builtin_va_end"
                   (mksignature (AST.Tlong :: nil) AST.Tvoid cc_default))
     (Tcons (tptr tvoid) Tnil) tvoid cc_default)) ::
 (___builtin_unreachable,
   Gfun(External (EF_builtin "__builtin_unreachable"
                   (mksignature nil AST.Tvoid cc_default)) Tnil tvoid
     cc_default)) ::
 (___builtin_expect,
   Gfun(External (EF_builtin "__builtin_expect"
                   (mksignature (AST.Tlong :: AST.Tlong :: nil) AST.Tlong
                     cc_default)) (Tcons tlong (Tcons tlong Tnil)) tlong
     cc_default)) ::
 (___builtin_fmax,
   Gfun(External (EF_builtin "__builtin_fmax"
                   (mksignature (AST.Tfloat :: AST.Tfloat :: nil) AST.Tfloat
                     cc_default)) (Tcons tdouble (Tcons tdouble Tnil))
     tdouble cc_default)) ::
 (___builtin_fmin,
   Gfun(External (EF_builtin "__builtin_fmin"
                   (mksignature (AST.Tfloat :: AST.Tfloat :: nil) AST.Tfloat
                     cc_default)) (Tcons tdouble (Tcons tdouble Tnil))
     tdouble cc_default)) ::
 (___builtin_fmadd,
   Gfun(External (EF_builtin "__builtin_fmadd"
                   (mksignature
                     (AST.Tfloat :: AST.Tfloat :: AST.Tfloat :: nil)
                     AST.Tfloat cc_default))
     (Tcons tdouble (Tcons tdouble (Tcons tdouble Tnil))) tdouble
     cc_default)) ::
 (___builtin_fmsub,
   Gfun(External (EF_builtin "__builtin_fmsub"
                   (mksignature
                     (AST.Tfloat :: AST.Tfloat :: AST.Tfloat :: nil)
                     AST.Tfloat cc_default))
     (Tcons tdouble (Tcons tdouble (Tcons tdouble Tnil))) tdouble
     cc_default)) ::
 (___builtin_fnmadd,
   Gfun(External (EF_builtin "__builtin_fnmadd"
                   (mksignature
                     (AST.Tfloat :: AST.Tfloat :: AST.Tfloat :: nil)
                     AST.Tfloat cc_default))
     (Tcons tdouble (Tcons tdouble (Tcons tdouble Tnil))) tdouble
     cc_default)) ::
 (___builtin_fnmsub,
   Gfun(External (EF_builtin "__builtin_fnmsub"
                   (mksignature
                     (AST.Tfloat :: AST.Tfloat :: AST.Tfloat :: nil)
                     AST.Tfloat cc_default))
     (Tcons tdouble (Tcons tdouble (Tcons tdouble Tnil))) tdouble
     cc_default)) ::
 (___builtin_read16_reversed,
   Gfun(External (EF_builtin "__builtin_read16_reversed"
                   (mksignature (AST.Tlong :: nil) AST.Tint16unsigned
                     cc_default)) (Tcons (tptr tushort) Tnil) tushort
     cc_default)) ::
 (___builtin_read32_reversed,
   Gfun(External (EF_builtin "__builtin_read32_reversed"
                   (mksignature (AST.Tlong :: nil) AST.Tint cc_default))
     (Tcons (tptr tuint) Tnil) tuint cc_default)) ::
 (___builtin_write16_reversed,
   Gfun(External (EF_builtin "__builtin_write16_reversed"
                   (mksignature (AST.Tlong :: AST.Tint :: nil) AST.Tvoid
                     cc_default)) (Tcons (tptr tushort) (Tcons tushort Tnil))
     tvoid cc_default)) ::
 (___builtin_write32_reversed,
   Gfun(External (EF_builtin "__builtin_write32_reversed"
                   (mksignature (AST.Tlong :: AST.Tint :: nil) AST.Tvoid
                     cc_default)) (Tcons (tptr tuint) (Tcons tuint Tnil))
     tvoid cc_default)) ::
 (___builtin_debug,
   Gfun(External (EF_external "__builtin_debug"
                   (mksignature (AST.Tint :: nil) AST.Tvoid
                     {|cc_vararg:=(Some 1); cc_unproto:=false; cc_structret:=false|}))
     (Tcons tint Tnil) tvoid
     {|cc_vararg:=(Some 1); cc_unproto:=false; cc_structret:=false|})) ::
 (_ccv_ceil_div,
   Gfun(External (EF_external "ccv_ceil_div"
                   (mksignature (AST.Tint :: AST.Tint :: nil) AST.Tint
                     cc_default)) (Tcons tuint (Tcons tuint Tnil)) tuint
     cc_default)) ::
 (_ccv_weight,
   Gfun(External (EF_external "ccv_weight"
                   (mksignature (AST.Tint :: AST.Tlong :: nil) AST.Tint
                     cc_default)) (Tcons tuint (Tcons (tptr tuchar) Tnil))
     tuint cc_default)) :: (_shape, Gfun(Internal f_shape)) ::
 (_validate, Gfun(Internal f_validate)) ::
 (_clear, Gfun(Internal f_clear)) :: (_toggle, Gfun(Internal f_toggle)) ::
 (_nontrivial, Gfun(Internal f_nontrivial)) ::
 (_restore, Gfun(Internal f_restore)) ::
 (_forbid, Gfun(Internal f_forbid)) ::
 (_overlap, Gfun(Internal f_overlap)) ::
 (_bounds, Gfun(Internal f_bounds)) :: (_leaf, Gfun(Internal f_leaf)) ::
 (_search, Gfun(Internal f_search)) ::
 (_stats_init, Gfun(Internal f_stats_init)) ::
 (_ccv_decide, Gfun(Internal f_ccv_decide)) ::
 (_ccv_distance, Gfun(Internal f_ccv_distance)) :: nil).

Definition public_idents : list ident :=
(_ccv_distance :: _ccv_decide :: _ccv_weight :: _ccv_ceil_div ::
 ___builtin_debug :: ___builtin_write32_reversed ::
 ___builtin_write16_reversed :: ___builtin_read32_reversed ::
 ___builtin_read16_reversed :: ___builtin_fnmsub :: ___builtin_fnmadd ::
 ___builtin_fmsub :: ___builtin_fmadd :: ___builtin_fmin ::
 ___builtin_fmax :: ___builtin_expect :: ___builtin_unreachable ::
 ___builtin_va_end :: ___builtin_va_copy :: ___builtin_va_arg ::
 ___builtin_va_start :: ___builtin_membar :: ___builtin_annot_intval ::
 ___builtin_annot :: ___builtin_sel :: ___builtin_memcpy_aligned ::
 ___builtin_sqrt :: ___builtin_fsqrt :: ___builtin_fabsf ::
 ___builtin_fabs :: ___builtin_ctzll :: ___builtin_ctzl :: ___builtin_ctz ::
 ___builtin_clzll :: ___builtin_clzl :: ___builtin_clz ::
 ___builtin_bswap16 :: ___builtin_bswap32 :: ___builtin_bswap ::
 ___builtin_bswap64 :: ___builtin_ais_annot :: ___compcert_i64_umulh ::
 ___compcert_i64_smulh :: ___compcert_i64_sar :: ___compcert_i64_shr ::
 ___compcert_i64_shl :: ___compcert_i64_umod :: ___compcert_i64_smod ::
 ___compcert_i64_udiv :: ___compcert_i64_sdiv :: ___compcert_i64_utof ::
 ___compcert_i64_stof :: ___compcert_i64_utod :: ___compcert_i64_stod ::
 ___compcert_i64_dtou :: ___compcert_i64_dtos :: ___compcert_va_composite ::
 ___compcert_va_float64 :: ___compcert_va_int64 :: ___compcert_va_int32 ::
 nil).

Definition prog : Clight.program := 
  mkprogram composites global_definitions public_idents _main Logic.I.


