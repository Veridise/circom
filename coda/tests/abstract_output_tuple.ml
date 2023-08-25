(* The circuit "circuit_AbstractCircuit" is uninterpreted *)

let circuit_Main = Circuit{

  name =
  "circuit_Main";

  inputs =
  [("x", field)];

  outputs =
  [("y", field); ("z", field)];

  dep =
  None;

  body =
  elet "a_dot_a" (var "x") @@
  elet "a_result" (call "circuit_AbstractCircuit" [(var "a_dot_a")]) @@
  elet "a_dot_b" (project (var "a_result") 1) @@
  elet "a_dot_c" (project (var "a_result") 0) @@
  elet "y" (var "a_dot_b") @@
  elet "z" (var "a_dot_c") @@
  (Expr.tuple [(var "y"); (var "z")]);}

