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
