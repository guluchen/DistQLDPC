(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
(* Compute only the path. Reducing the returned statement by vm_compute
   would also unfold temporary identifiers and all integer literal casts. *)
Fixpoint branch_path (accept:statement->bool) (s:statement) : option (list bool) :=
  if accept s then Some [] else
  match s with
  | Ssequence l r | Sloop l r | Sifthenelse _ l r =>
    match branch_path accept l with
    | Some path => Some (false::path)
    | None => option_map (cons true) (branch_path accept r)
    end
  | _ => None end.
Fixpoint at_branch (path:list bool) (s:statement) : statement :=
 match path with
 | []=>s
 | side::tail =>
   match s with
   | Ssequence l r | Sloop l r | Sifthenelse _ l r =>
     at_branch tail (if side then r else l)
   | _ => Sskip end
 end.
Definition counts_on id (s:statement) :=
 match s with Ssequence (Sset i _) (Sloop _ _) => Pos.eqb i id | _=>false end.
Ltac native_fragment accept f :=
 let path := eval vm_compute in (branch_path accept (fn_body f)) in
 lazymatch path with
 | Some ?route => let t:= eval cbv beta iota zeta delta [at_branch fn_body f] in
                            (at_branch route (fn_body f)) in exact t
 end.
