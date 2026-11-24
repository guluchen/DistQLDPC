(* SPDX-License-Identifier: GPL-3.0-or-later *)
Require Import VST.floyd.proofauto.
From mathcomp Require Import all_ssreflect all_algebra.
Require Import LeafMatrix MinimumPrefix LevelSearch CSSLevelDistance DetectorRank DetectorMatrix VerifDetected
 VerifClosesBody NativeFlipPayload PreparedSeedDispatch PreparedDFSTerminal PreparedTerminalPoll
 PreparedMatrixResponse PreparedMatrixPath PreparedWitnessWeight PreparedDepthSpec PreparedCSSTerminal.
Require flag_level_ast.
Import flag_level_ast.
#[local] Existing Instance VerifDetected.CompSpecs.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Local Open Scope ring_scope.
Local Delimit Scope Z_scope with coqZ.

Definition terminal_trace s cp (cells:list Integers.int):mpred:=
 (field_at Tsh level_type [StructField _cur] cp s *
  data_at Tsh (tarray tint (Zlength cells)) (List.map Vint cells) cp)%logic.

Section PhysicalTrace.
Variables m r k n:nat.
Variables (H:'M['F_2]_(m,n)) (S:'M['F_2]_(r,n)) (G:'M['F_2]_(k,n)) (rowkey:'I_m->int64).
Variables (path:seq 'I_n) (payload:packed_support).
Variables (before:Values.val->mpred) (after:bool->Values.val->mpred).
Let v:=vector_on (0:'cV['F_2]_n) path.
Let size_z:=Z.of_nat (size path).
Let odd:=odd_count payload.
Let words:=parities (words_at payload).
Let code:=@result_word m r n H S path.
Let witness:=@saved_witness m r n H S path.
Definition traced_terminal:ident*funspec:= DECLARE _dfs
 WITH s:Values.val,policy:Values.val,b:Values.val,par:Values.val,nodes:int64,budget:int64,saved:Integers.int,
  bits:Integers.int,site:poll_site,cp:Values.val,cells:list Integers.int
 PRE [tptr level_type,tptr (Tstruct _cc_level_policy noattr),tint,tuint]
 PROP(site_matches bits (Int64.add nodes Int64.one) site;is_pointer_or_null policy;
 (1<=size_z<=Int.max_signed)%coqZ;(0<=odd<=Int.max_signed)%coqZ;(Zlength words<=Int.max_signed)%coqZ;
 active_prefix size_z cells=literal_path path)
 PARAMS(s;policy;Vint (Int.repr size_z);Vint bits)
 SEP(terminal_fields s b par size_z odd words nodes budget (Vint saved);poll_frame s site before after None;
 terminal_trace s cp cells)
 POST [tint] EX event:option bool,
 PROP(observed site event;code event=Int.one ->
 [ /\ active_prefix size_z cells=literal_path path, H*m v=0, ~~(v^T<=S)%MS,
 #|support v|=size path & (distance_index H (detectors S)<=size path)%N ])
 RETURN(Vint (code event))
 SEP(terminal_fields s b par size_z odd words (Int64.add nodes Int64.one) (Int64.add budget Int64.one)
  (Vint (witness event saved));poll_frame s site before after event;terminal_trace s cp cells).

Theorem native_found_returns_stored_trace:
 H*m S^T=0 -> G*m S^T=0 -> (\rank (col_mx H G)+\rank S=n)%N ->
 uniq path -> pcm_response H G rowkey v payload ->
 semax_body prepared_vars (TimedLeafG before after) f_dfs traced_terminal.
Proof.
 move=> orthH orthG shape distinct physical.
 have checked:=@native_terminal_returns_css_value m r k n H S G rowkey path payload before after orthH orthG shape distinct physical.
 eapply semax_body_funspec_sub;[exact checked| |].
 - do_funspec_sub;destruct w as [[[[[[[[[[s policy] b] par] nodes] budget] saved] bits] site] cp] cells];cbn [fst snd];normalize.
   Exists (s,policy,b,par,nodes,budget,saved,bits,site) (terminal_trace s cp cells);apply andp_right.
   + unfold size_z,odd,words;entailer!;cancel.
   + apply prop_right;intro rho;normalize;Exists x.
     have logical:code x=Int.one -> H*m v=0 /\ ~~(v^T<=S)%MS.
     { unfold code,result_word;case:(abort_answer x);first discriminate.
       case E:((H*m v==0) && ~~(v^T<=S)%MS);last discriminate.
       move=>_;by move/andP:E=>[/eqP zero outside]. }
     unfold code,witness,size_z,odd,words in *;entailer!;try cancel;try apply derives_refl;
       intuition;constructor;intuition.
 - vm_compute;repeat (apply list_norepet_cons;[simpl;intuition congruence|]);apply list_norepet_nil.
Qed.
End PhysicalTrace.
