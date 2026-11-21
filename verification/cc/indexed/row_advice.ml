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

external grid_shift : int -> bytes -> bytes -> int array = "caml_ccv_grid_shift"

let grid_roots n (_,_,flat) previous =
  let covered=Bytes.make n (Char.chr 0) in
  List.iter (fun (_,inv)->List.iteri (fun i j->
    if j<i then Bytes.set covered i (Char.chr 1)) inv) previous;
  let matrix=Bytes.of_seq (Seq.map Char.chr (List.to_seq flat)) in
  let map=grid_shift n matrix covered in
  if Array.length map<>n then previous else
  let inv=Array.make n 0 in
  Array.iteri (fun i j->inv.(j)<-i) map;
  previous@[Array.to_list map,Array.to_list inv]

external line_hint : int -> int -> bytes -> bytes -> int array = "caml_ccv_disjoint_lines"

let line_groups n d (_,xcount,xf) (_,zcount,zf) =
  if d<2 || n<2 || n>756 || d>n || xcount+zcount<n-1 then [] else
  let bytes flat=Bytes.of_seq (Seq.map Char.chr (List.to_seq flat)) in
  let x=bytes xf and z=bytes zf in
  let lines h g=
    let data=line_hint n d h g in
    if Array.length data<>2*d then [] else
    List.init d (fun i->data.(2*i),data.(2*i+1)) in
  let a=lines z x and b=lines x z in
  List.sort_uniq Stdlib.compare (List.filter ((<>) []) [a;b])
