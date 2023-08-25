let circuit_A = Circuit{

  name =
  "circuit_A";

  inputs =
  [("a1", field)];

  outputs =
  [("a2", field)];

  dep =
  None;

  body =
  elet "a2" (var "a1") @@
  (Expr.tuple [(var "a2")]);}

let circuit_B = Circuit{

  name =
  "circuit_B";

  inputs =
  [("b1", field)];

  outputs =
  [("b2", field)];

  dep =
  None;

  body =
  elet "a__a1" (var "b1") @@
  elet "a__result" (call "circuit_A" [(var "a2"); (var "a1")]) @@
  elet "a__a2" (project (var "a__result") 0) @@
  elet "b2" (var "a__a2") @@
  (Expr.tuple [(var "b2")]);}

let circuit_C = Circuit{

  name =
  "circuit_C";

  inputs =
  [("c1", field)];

  outputs =
  [("c2", field)];

  dep =
  None;

  body =
  elet "a__a1" (var "c1") @@
  elet "a__result" (call "circuit_A" [(var "a2"); (var "a1")]) @@
  elet "a__a2" (project (var "a__result") 0) @@
  elet "b__b1" (var "a__a2") @@
  elet "b__result" (call "circuit_B" [(var "b2"); (var "b1")]) @@
  elet "b__b2" (project (var "b__result") 0) @@
  elet "c2" (var "b__b2") @@
  (Expr.tuple [(var "c2")]);}

