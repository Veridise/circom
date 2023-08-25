let circuit_Test2 = Circuit{

  name =
  "circuit_Test2";

  inputs =
  [];

  outputs =
  [("x", field)];

  dep =
  None;

  body =
  elet "var0_v1" (F.const 4) @@
  elet "var1_v1" (F.const 0) @@
  elet "var2_v1" (F.const 0) @@
  elet "var1_v2" (F.const 666) @@
  elet "var2_v2" (F.const 666) @@
  elet "var1_v3" (F.const 666) @@
  elet "var2_v3" (F.const 666) @@
  elet "var1_v4" (F.const 666) @@
  elet "var2_v4" (F.const 666) @@
  elet "var1_v5" (F.const 666) @@
  elet "var2_v5" (F.const 666) @@
  elet "x" (F.const 6) @@
  (Expr.tuple [(var "x")]);}

