let circuit_A = Circuit{

  name =
  "circuit_A";

  inputs =
  [("x", field)];

  outputs =
  [("y", field)];

  dep =
  None;

  body =
  elet "y" (var "x") @@
  (Expr.tuple [(var "y")]);}

let circuit_Main = Circuit{

  name =
  "circuit_Main";

  inputs =
  [("x_i0", field); ("x_i1", field); ("x_i2", field); ("x_i3", field)];

  outputs =
  [("y_i0", field); ("y_i1", field); ("y_i2", field); ("y_i3", field)];

  dep =
  None;

  body =
  elet "var0_f_1" (F.const 4) @@
  elet "var1_f_1" (F.const 0) @@
  elet "a_0__x" (var "x_i0") @@
  elet "a_0__result" (call "circuit_A" [(var "a_0__x")]) @@
  elet "a_0__y" (project (var "a_0__result") 0) @@
  elet "y_i0" (var "a_0__y") @@
  elet "var1_f_2" (F.const 666) @@
  elet "a_1__x" (var "x_i1") @@
  elet "a_1__result" (call "circuit_A" [(var "a_1__x")]) @@
  elet "a_1__y" (project (var "a_1__result") 0) @@
  elet "y_i1" (var "a_1__y") @@
  elet "var1_f_3" (F.const 666) @@
  elet "a_2__x" (var "x_i2") @@
  elet "a_2__result" (call "circuit_A" [(var "a_2__x")]) @@
  elet "a_2__y" (project (var "a_2__result") 0) @@
  elet "y_i2" (var "a_2__y") @@
  elet "var1_f_4" (F.const 666) @@
  elet "a_3__x" (var "x_i3") @@
  elet "a_3__result" (call "circuit_A" [(var "a_3__x")]) @@
  elet "a_3__y" (project (var "a_3__result") 0) @@
  elet "y_i3" (var "a_3__y") @@
  elet "var1_f_5" (F.const 666) @@
  (Expr.tuple [(var "y_i0"); (var "y_i1"); (var "y_i2"); (var "y_i3")]);}

