let () =
  try
    if Array.length Sys.argv < 4 || Array.length Sys.argv > 7 then invalid_arg "usage: pcm-large WIDTH HX HZ";
    let n=checked_width Sys.argv.(1) in
    if n > 756 then exit (print_report OutOfBudget);
    let hx=read_matrix Sys.argv.(2) and hz=read_matrix Sys.argv.(3) in
    let ax=prepare_half n hz hx and az=prepare_half n hx hz in
    if List.exists (fun a->a.model_m>756 || a.model_l>756) [ax;az] then exit(print_report OutOfBudget);
    let side=match read_line() with "X"->true |"Z"->false |_->invalid_arg "invalid side" in
    let bits=read_line() in if String.length bits<>n then invalid_arg "incorrect witness width";
    let w=List.init n(fun i->match bits.[i] with '0'->false|'1'->true|_->invalid_arg "nonbinary witness") in
    let p,inv=match Dual_advice.propose n hx hz with Some(v,_,_)->v,v |None->[],[] in
    let options=List.filteri (fun i _ -> i>=4) (Array.to_list Sys.argv) in
    if List.exists (fun opt -> not (List.mem opt ["reverse-bfs";"pair-pack";"sparse-checks"])) options then
      invalid_arg "optional settings: reverse-bfs, pair-pack, sparse-checks";
    let bfs=List.mem "reverse-bfs" options and pairs=List.mem "pair-pack" options in
    let sparse=List.mem "sparse-checks" options in
    let rx,px=Row_advice.plan ~bfs ~sparse 756 n hz and rz,pz=Row_advice.plan ~bfs ~sparse 756 n hx in
    match packed_report n ax az side w (Large_advice.make_advice 40000000 pairs) p inv rx rz px pz with
    | Some ans->exit(print_report ans)|None->exit(print_report OutOfBudget)
  with Large_advice.Exhausted->exit(print_report OutOfBudget)
     | Invalid_argument msg | Sys_error msg | Failure msg ->prerr_endline msg;exit 2
