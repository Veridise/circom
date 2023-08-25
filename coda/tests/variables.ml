let circuit_Main = Circuit{

  name =
  "circuit_Main";

  inputs =
  [("x", field)];

  outputs =
  [("y", field)];

  dep =
  None;

  body =
  elet "var0" (var 1) @@
  elet "var1" (var 2) @@
  elet "var2" (var 3) @@
  elet "var3" (var 4) @@
  elet "var4" (var 5) @@
  elet "var5" (var 6) @@
  elet "var6" (var 7) @@
  elet "var7" (var 8) @@
  elet "y" (var "x") @@
  (Expr.tuple [(var "y")]);}

