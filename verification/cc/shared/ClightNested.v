(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto ClightSelect.
(* Swhile is a CompCert abbreviation. Unfolding it while selecting the
   branch keeps the term small for statements inside nested loops. *)
Ltac native_while_fragment accept f :=
 let path:=eval vm_compute in (branch_path accept (fn_body f)) in
 lazymatch path with
 | Some ?route=>let s:=eval cbv beta iota zeta delta [at_branch fn_body f Swhile] in
                            (at_branch route (fn_body f)) in exact s
 end.
