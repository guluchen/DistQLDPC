external reverse_bfs : int -> bytes -> int array = "caml_ccv_reverse_bfs"

let order enabled n (_, rows, flat) =
  if not enabled || rows = 0 then [] else
  let cells = Bytes.create (n*rows) in
  List.iteri (fun i bit -> Bytes.set cells i (Char.chr bit)) flat;
  Array.to_list (reverse_bfs n cells)

external sparse_pairs : int -> bytes -> int -> int array = "caml_ccv_sparse_pairs"

let plan ~bfs ~sparse capacity n ((_,rows,flat) as raw) =
  if not sparse || rows >= capacity || rows < 2 then order bfs n raw,[] else
  let cells=Bytes.create (n*rows) in
  List.iteri (fun i b->Bytes.set cells i (Char.chr b)) flat;
  let ids=sparse_pairs n cells capacity in
  let pairs=List.init (Array.length ids/2) (fun i->ids.(2*i),ids.(2*i+1)) in
  if not bfs then [],pairs else if pairs=[] then Array.to_list (reverse_bfs n cells),[] else
  let full=Bytes.create (n*(rows+List.length pairs)) in
  Bytes.blit cells 0 full 0 (Bytes.length cells);
  List.iteri (fun i (a,b)->
    for q=0 to n-1 do
      let x=Char.code (Bytes.get cells (a*n+q)) and y=Char.code (Bytes.get cells (b*n+q)) in
      Bytes.set full ((rows+i)*n+q) (Char.chr (x lxor y))
    done) pairs;
  Array.to_list (reverse_bfs n full),pairs

external dual_hint : int -> bytes -> bytes -> int array = "caml_ccv_dual_hint"

let raw_dual n ((_,xc,xf) as hx) ((_,zc,zf) as hz) =
  if n<1 || n>756 || xc<>zc || xc<1 || xc>756 ||
     List.length xf<>xc*n || List.length zf<>zc*n then None else
  match Dual_advice.propose n hx hz with
  | Some cert -> Some cert
  | None ->
    let bytes flat = Bytes.of_seq (Seq.map Char.chr (List.to_seq flat)) in
    let perm=dual_hint n (bytes xf) (bytes zf) in
    if Array.length perm<>n then None else
    let x,xt=Dual_advice.index_rows n xc xf and z,zt=Dual_advice.index_rows n zc zf in
    let images rows target=Array.to_list(Array.map (fun row ->
      Hashtbl.find target (String.init n (fun i->row.[perm.(i)]))) rows) in
    try Some(Array.to_list perm,images z xt,images x zt) with Not_found->None
