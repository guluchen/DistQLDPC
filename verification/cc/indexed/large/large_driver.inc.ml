let () =
  try
    if Array.length Sys.argv < 4 || Array.length Sys.argv > 11 then invalid_arg "usage: pcm-large WIDTH HX HZ";
    let n=checked_width Sys.argv.(1) in
    if n > 756 then exit (print_report OutOfBudget);
    let hx=read_matrix Sys.argv.(2) and hz=read_matrix Sys.argv.(3) in
    let side=match read_line() with "X"->true |"Z"->false |_->invalid_arg "invalid side" in
    let bits=read_line() in if String.length bits<>n then invalid_arg "incorrect witness width";
    let w=List.init n(fun i->match bits.[i] with '0'->false|'1'->true|_->invalid_arg "nonbinary witness") in
    let options=List.filteri (fun i _ -> i>=4) (Array.to_list Sys.argv) in
    if List.exists (fun opt -> not (List.mem opt ["reverse-bfs";"pair-pack";"sparse-checks";"double-erasure";"erasure-pack";"class-parity";"quick-probe"])) options then
      invalid_arg "optional settings: reverse-bfs, pair-pack, sparse-checks, erasure-pack, double-erasure, class-parity";
    let use_class_parity=List.mem "class-parity" options in
    let choice_budget=if List.mem "quick-probe" options then 32768 else 40000000 in
    let double_erasure=List.mem "double-erasure" options in
    let erasure=double_erasure || List.mem "erasure-pack" options in
    let bfs=List.mem "reverse-bfs" options and pairs=erasure || List.mem "pair-pack" options in
    let sparse=List.mem "sparse-checks" options in
    let checks,stabs=if side then hz,hx else hx,hz in
    let a=prepare_half n checks stabs in
    if a.model_m>756 || a.model_l>756 then exit(print_report OutOfBudget);
    let order,sums=Row_advice.plan ~bfs ~sparse 756 n checks in
    let d=List.fold_left (fun sum bit->if bit then sum+1 else sum) 0 w in
    let groups=lazy (Row_advice.line_groups n d hx hz) in
    let logical_lines target=if target=d then Lazy.force groups else [] in
    let facts=Row_advice.raw_dual n hx hz in
    match facts with
    | Some (p,forward,backward)->
      let f,b=if side then forward,backward else backward,forward in
      let _,m,h=checks and _,k,g=stabs in
      let q={width=n;check_count=m;same_count=k;checks=h;same_bytes=g} in
      (match raw_packed_report q a side w (Large_advice.make_advice ~use_class_parity ~double_erasure ~erasure ~logical_lines choice_budget pairs) order sums p f b with
      | Some ans->exit(print_report ans) | None->exit(print_report OutOfBudget))
    | None->
      let other=prepare_half n stabs checks in
      if other.model_m>756 || other.model_l>756 then exit(print_report OutOfBudget);
      let os,ss=Row_advice.plan ~bfs ~sparse 756 n stabs in
      let ax,az,rx,rz,px,pz=if side then a,other,order,os,sums,ss else other,a,os,order,ss,sums in
      let p,inv=Row_advice.span_dual n hx hz in
      (match packed_report n ax az side w (Large_advice.make_advice ~use_class_parity ~double_erasure ~erasure ~logical_lines choice_budget pairs) p inv rx rz px pz with
      | Some ans->exit(print_report ans)|None->exit(print_report OutOfBudget))
  with Large_advice.Exhausted->exit(print_report OutOfBudget)
     | Invalid_argument msg | Sys_error msg | Failure msg ->prerr_endline msg;exit 2
