let () =
  try
    if Array.length Sys.argv < 4 || Array.length Sys.argv > 7 then invalid_arg "usage: pcm-large WIDTH HX HZ";
    let n=checked_width Sys.argv.(1) in
    if n > 756 then exit (print_report OutOfBudget);
    let hx=read_matrix Sys.argv.(2) and hz=read_matrix Sys.argv.(3) in
    let side=match read_line() with "X"->true |"Z"->false |_->invalid_arg "invalid side" in
    let bits=read_line() in if String.length bits<>n then invalid_arg "incorrect witness width";
    let w=List.init n(fun i->match bits.[i] with '0'->false|'1'->true|_->invalid_arg "nonbinary witness") in
    let options=List.filteri (fun i _ -> i>=4) (Array.to_list Sys.argv) in
    if List.exists (fun opt -> not (List.mem opt ["reverse-bfs";"pair-pack";"sparse-checks"])) options then
      invalid_arg "optional settings: reverse-bfs, pair-pack, sparse-checks";
    let bfs=List.mem "reverse-bfs" options and pairs=List.mem "pair-pack" options in
    let sparse=List.mem "sparse-checks" options in
    let checks,stabs=if side then hz,hx else hx,hz in
    let a=prepare_half n checks stabs in
    if a.model_m>756 || a.model_l>756 then exit(print_report OutOfBudget);
    let order,sums=Row_advice.plan ~bfs ~sparse 756 n checks in
    let facts=Row_advice.raw_dual n hx hz in
    match facts with
    | Some (p,forward,backward)->
      let f,b=if side then forward,backward else backward,forward in
      let _,m,h=checks and _,k,g=stabs in
      let q={width=n;check_count=m;same_count=k;checks=h;same_bytes=g} in
      (match raw_packed_report q a side w (Large_advice.make_advice 40000000 pairs) order sums p f b with
      | Some ans->exit(print_report ans) | None->exit(print_report OutOfBudget))
    | None->
      let other=prepare_half n stabs checks in
      if other.model_m>756 || other.model_l>756 then exit(print_report OutOfBudget);
      let os,ss=Row_advice.plan ~bfs ~sparse 756 n stabs in
      let ax,az,rx,rz,px,pz=if side then a,other,order,os,sums,ss else other,a,os,order,ss,sums in
      (match packed_report n ax az side w (Large_advice.make_advice 40000000 pairs) [] [] rx rz px pz with
      | Some ans->exit(print_report ans)|None->exit(print_report OutOfBudget))
  with Large_advice.Exhausted->exit(print_report OutOfBudget)
     | Invalid_argument msg | Sys_error msg | Failure msg ->prerr_endline msg;exit 2
