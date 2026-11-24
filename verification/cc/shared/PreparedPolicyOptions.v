(* SPDX-License-Identifier: GPL-3.0-or-later *)
From Coq Require Import List Bool.
From compcert Require Import Clightdefs.
Require flag_level_ast level_ast.
Import Clight Ctypes Cop.
Local Open Scope bool_scope.
Definition pointer_type (t:type):bool:=match t with Tpointer _ _=>true|_=>false end.
Definition integer_condition e:=negb (pointer_type (typeof e)).
Fixpoint checked_expression (e:expr):bool:=
 match e with
 | Ecast a (Tint IBool _ _) | Eunop Onotbool a _ => integer_condition a && checked_expression a
 | Ebinop Oeq a b _ | Ebinop One a b _ =>
   integer_condition a && integer_condition b && checked_expression a && checked_expression b
 | Ebinop _ a b _ =>checked_expression a && checked_expression b
 | Ecast a _ | Eunop _ a _ | Eaddrof a _ | Ederef a _ | Efield a _ _ =>checked_expression a
 | _=>true end.
(* Unknown statement forms fail closed. Function pointers may still be loaded,
   stored and called. Only their use as branch predicates is forbidden. *)
Fixpoint numeric_guards (s:statement):bool:=
 match s with
 | Ssequence a b | Sloop a b=>numeric_guards a && numeric_guards b
 | Sifthenelse e a b=>integer_condition e && checked_expression e && numeric_guards a && numeric_guards b
 | Sset _ e=>checked_expression e
 | Sassign a b=>checked_expression a && checked_expression b
 | Scall _ e args=>checked_expression e && forallb checked_expression args
 | Sreturn (Some e)=>checked_expression e
 | Sreturn None | Sskip | Sbreak | Scontinue=>true
 | _=>false end.
Example prepared_source_has_numeric_guards :
 numeric_guards (fn_body flag_level_ast.f_cc_run_prepared_level)=true /\
 numeric_guards (fn_body flag_level_ast.f_dfs)=true /\ numeric_guards (fn_body flag_level_ast.f_flip)=true.
Proof. vm_compute;auto. Qed.
Example nullable_api_uses_pointer_guards :
 numeric_guards (fn_body flag_level_ast.f_cc_run_level)=false /\
 numeric_guards (fn_body level_ast.f_cc_run_level)=false /\ numeric_guards (fn_body level_ast.f_dfs)=false.
Proof. vm_compute;auto. Qed.
