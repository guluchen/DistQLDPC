let test n lines expected =
  let flat = List.concat_map (fun s ->
    List.init (String.length s) (fun i -> if s.[i]='1' then 1 else 0)) lines in
  let actual = Row_advice.order true n (n,List.length lines,flat) in
  assert (actual = expected);
  assert (List.sort Int.compare actual = List.init (List.length lines) Fun.id);
  assert (Row_advice.order false n (n,List.length lines,flat) = [])

let () =
  test 4 ["1100";"0010";"1000";"0110";"0000";"0001"] [5;4;1;3;2;0];
  test 3 ["010";"000";"001"] [2;1;0];
  test 2 ["11";"11"] [1;0];
  test 1 [] [];
  assert (Row_advice.reverse_bfs 0 (Bytes.of_string "x") = [||]);
  assert (Row_advice.reverse_bfs 3 (Bytes.create 2) = [||]);
  assert (Row_advice.reverse_bfs 1 (Bytes.create 757) = [||]);
  print_endline "7 row-order controls passed"

let () =
  let flat = [1;1;0;1;1;1;1;0;0;1;1;0] in
  let order,pairs = Row_advice.plan ~bfs:true ~sparse:true 12 4 (4,3,flat) in
  assert (pairs=[1,0;2,0;2,1]);
  assert (List.sort Int.compare order=List.init 6 Fun.id);
  let _,limited=Row_advice.plan ~bfs:false ~sparse:true 4 4 (4,3,flat) in
  assert (limited=[1,0]);
  let o,p = Row_advice.plan ~bfs:false ~sparse:false 12 4 (4,3,flat) in
  assert (o=[] && p=[]);
  print_endline "4 redundant-row advice controls passed"

let () =
  (* A twisted two-by-three grid: invert the two coordinates, shear the
     second when the first wraps, and exchange the two six-column blocks. *)
  let n=12 in
  let pi q = let x=q mod 6 / 3 and y=q mod 3 in
    (1-q/6)*6+(2-x) mod 2*3+(3-y+(if x=0 then 0 else 1)) mod 3 in
  let x=[[0;1;6];[1;3;8];[0;4;7;11];[2;6;8;9]] in
  let z=List.rev (List.map (List.map pi) x) in
  let raw a=(n,List.length a,
    List.concat_map (fun row -> List.init n (fun i->if List.mem i row then 1 else 0)) a) in
  let _,_,flat=raw x in
  (match Row_advice.raw_dual n (raw x) (raw z) with
   | None->assert false
   | Some(p,f,b)->
     assert (List.length p=n && List.for_all2 (=) (List.map (List.nth p) p) (List.init n Fun.id));
     let cover src dst idx=List.for_all2 (fun row j->
       List.sort Int.compare (List.map (List.nth p) row)=List.sort Int.compare (List.nth dst j)) src idx in
     assert (cover z x f && cover x z b));
  assert (Row_advice.raw_dual n (raw x) (raw ([]::List.tl z))=None);
  assert (Row_advice.raw_dual n (n,2,flat) (raw z)=None);
  assert (Row_advice.dual_hint 0 Bytes.empty Bytes.empty=[||]);
  assert (Row_advice.dual_hint 4 (Bytes.make 3 '0') (Bytes.make 3 '0')=[||]);
  print_endline "5 raw symmetry advice controls passed"
