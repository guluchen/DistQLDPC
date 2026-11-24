(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto VST.floyd.reassoc_seq.
Require Import ClightSelect level_ast VerifDetected VerifChildVisit OverlapColumnState
 OverlapView OverlapChildState OverlapSharedBlocks VerifOverlapDispatch.
Local Open Scope Z_scope.
#[local] Existing Instance VerifDetected.CompSpecs.

Record policy_state := {
 nested:nested_calls; callback_owner:val; callback_addr:val; conn:addresses; geometry:layout
}.
Definition cols (c:policy_state) st:=view_mem (callback_owner c) (conn c) (geometry c) st.
Definition pointers c:=
 (callback_fields (nested_policy (nested c)) (callback_owner c) (callback_addr c) *
  func_ptr' (callback_contract (callback_owner c) (geometry c) (cols c)) (callback_addr c))%logic.
Definition enabled_memory c s cp w path st :=
 (level_links s cp (blockp (conn c)) w path * cols c st * pointers c)%logic.

(* A child receives the live overlap view and its callback fields. Traversal
   can increment the statistics; its caller needs just the two search arrays
   restored and the prefix of the witness trace kept. *)
Definition enabled_child_spec c:ident*funspec :=
 DECLARE _dfs WITH s:val,cp:val,w:Z,depth:Z,q:Z,st:snapshot,path:list int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint]
 PROP(1<=depth<w-2;w<=Int.max_signed;w<=Zlength path;0<=q<Zlength (blocked st);
      Znth depth path=Int.repr q)
 PARAMS(s;nested_policy (nested c);Vint (Int.repr (depth+1)))
 SEP(enabled_memory c s cp w path st;active_support (nested c) s (Some q))
 POST [tint] EX final:snapshot, EX tail:list int,
 PROP(same_search final st;0<=child_outcome (nested c) (blocked st) q<=3;
      Zlength tail=Zlength path;sublist 0 (depth+1) tail=sublist 0 (depth+1) path;
      child_outcome (nested c) (blocked st) q<>0 -> returned_trace (nested c) (blocked st) q tail)
 RETURN(Vint (Int.repr (child_outcome (nested c) (blocked st) q)))
 SEP(enabled_memory c s cp w tail final;active_support (nested c) s (Some q)).
Definition EGprog c:funspecs := ltac:(let fs:=constr:([enter_child (nested c);enabled_child_spec c]) in with_library prog fs).

Definition recurse_and_assign (s:statement):bool :=
 match s with
 | Ssequence (Scall (Some tmp) (Evar id _) _) (Sset dst (Etempvar tmp2 _)) =>
   andb (Pos.eqb id _dfs) (andb (Pos.eqb dst _result) (Pos.eqb tmp tmp2))
 | _=>false end.
Definition native_recurse:statement:=ltac:(native_fragment recurse_and_assign f_dfs).
Definition before_call c s depth:=
 [temp _s s;temp _policy (nested_policy (nested c));temp _size (Vint (Int.repr depth))].
Theorem semax_recursion_with_active_overlap {Espec:OracleKind} c s cp w depth q st path :
 1<=depth<w-2 -> w<=Int.max_signed -> w<=Zlength path -> 0<=q<Zlength (blocked st) ->
 Znth depth path=Int.repr q ->
 semax (func_tycontext f_dfs Vprog (EGprog c) [])
   (PROPx nil (LOCALx (before_call c s depth)
     (SEPx [enabled_memory c s cp w path st;active_support (nested c) s (Some q)])))
   native_recurse
   (normal_ret_assert (EX final:snapshot,EX tail:list int,
    PROPx [same_search final st;0<=child_outcome (nested c) (blocked st) q<=3;
     Zlength tail=Zlength path;sublist 0 (depth+1) tail=sublist 0 (depth+1) path;
     child_outcome (nested c) (blocked st) q<>0 -> returned_trace (nested c) (blocked st) q tail]
     (LOCALx (temp _result (Vint (Int.repr (child_outcome (nested c) (blocked st) q)))::before_call c s depth)
      (SEPx [enabled_memory c s cp w tail final;active_support (nested c) s (Some q)])))).
Proof.
 intros deep cap len inside here;pose proof (nested_policy_valid (nested c)) as ptr.
 unfold before_call,native_recurse;abbreviate_semax.
 assert_PROP (isptr s) as valid_s by (unfold enabled_memory,level_links;entailer!).
 forward_call (s,cp,w,depth,q,st,path);
  try solve [entailer!;rep_lia | entailer!;f_equal;unfold Int.add;rewrite Int.unsigned_repr by rep_lia;reflexivity].
 Intros vret;destruct vret as [final tail];cbn [fst snd] in *;forward;Exists final tail;entailer!;try apply derives_refl.
Qed.
