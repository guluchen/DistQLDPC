(* Exhaustive finite execution of actual forbid: present/full/insertion cases.
   Concrete initialized loads, permissions and nonaliasing are explicit PREs. *)
Require Import VST.floyd.proofauto.
Require Import compcert.lib.Maps compcert.common.Events compcert.common.Smallstep compcert.cfrontend.Clight.
Require Import CCV.CCRestoreMemory CCV.CCForbidPaths CCV.CCForbidInsertion CCV.ccv_core.
Import ListNotations. Open Scope Z_scope.
Definition forbid_insertion_access m bu ou top bt ot bf ofl q bw ow df:Prop:=
 Mem.valid_access m Mint32 bu(Ptrofs.unsigned(Ptrofs.add ou(Ptrofs.repr(4*top))))Writable /\
 Mem.valid_access m Mint32 bt(Ptrofs.unsigned ot)Writable /\
 Mem.valid_access m Mint8unsigned bf(Ptrofs.unsigned(Ptrofs.add ofl(Ptrofs.repr q)))Writable /\
 cell_apart Mint32 bu(Ptrofs.add ou(Ptrofs.repr(4*top)))Mint32 bt ot /\
 cell_apart Mint32 bu(Ptrofs.add ou(Ptrofs.repr(4*top)))Mptr bw(Ptrofs.add ow(Ptrofs.repr df)) /\
 cell_apart Mint32 bt ot Mptr bw(Ptrofs.add ow(Ptrofs.repr df)).
Theorem actual_forbid_terminates ge bw ow q bt ot n bf ofl bu ou top value m k co df du:
 PTree.get _ccv_workspace(Clight.genv_cenv ge)=Some co ->
 Ctypes.field_offset ge _forbidden(co_members co)=Errors.OK(df,Full) ->
 Ctypes.field_offset ge _undo(co_members co)=Errors.OK(du,Full) ->
 Mem.loadv Mptr m(Vptr bw(Ptrofs.add ow(Ptrofs.repr df)))=Some(Vptr bf ofl) ->
 Mem.loadv Mptr m(Vptr bw(Ptrofs.add ow(Ptrofs.repr du)))=Some(Vptr bu ou) ->
 0<=q<=Int.max_unsigned ->0<=n<=Int.max_unsigned ->0<=top<=n ->
 Mem.loadv Mint8unsigned m(Vptr bf(Ptrofs.add ofl(Ptrofs.repr q)))=Some(Vint value) ->
 Mem.loadv Mint32 m(Vptr bt ot)=Some(Vint(Int.repr top)) ->
 (top<n ->forbid_insertion_access m bu ou top bt ot bf ofl q bw ow df) ->
 exists result m',(result=Int.zero \/result=Int.one) /\
 star Clight.step2 ge
 (Clight.Callstate(Internal f_forbid)[Vptr bw ow;Vint(Int.repr q);Vptr bt ot;Vint(Int.repr n)]k m)E0
 (Clight.Returnstate(Vint result)(Clight.call_cont k)m').
Proof.
 intros Composite FlagOffset UndoOffset Flags Undo QR NR TR Read Top Access.
 destruct(Int.eq_dec value Int.zero)as[Zero|Present].
 - subst value;destruct(Z_le_dec n top)as[Full|Room].
   + exists Int.zero,m;split;[left;reflexivity|].
     apply(actual_forbid_full_path ge bw ow q bt ot n bf ofl top m k co df);try assumption;lia.
   + destruct(Access ltac:(lia))as[UW[TW[FW[UT[UF TF]]]]].
     destruct(actual_forbid_insert_path ge bw ow q bt ot n bf ofl bu ou top m k co df du
     Composite FlagOffset UndoOffset Flags Undo QR NR ltac:(lia)Read Top UW TW FW UT UF TF)as[m' Path].
     exists Int.one,m';split;[right;reflexivity|exact Path].
 - exists Int.one,m;split;[right;reflexivity|].
   apply(actual_forbid_existing_path ge bw ow q bt ot n bf ofl value m k co df);try assumption.
   apply Int.eq_false;exact Present.
Qed.
Print Assumptions actual_forbid_terminates.
