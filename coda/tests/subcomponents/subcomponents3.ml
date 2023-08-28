let circuit_A_0 = Circuit{

  name =
  "A_0";

  inputs =
  [("xs_i0", field); ("xs_i1", field)];

  outputs =
  [("y", field)];

  dep =
  None;

  body =
  elet "var0_v1" (F.const_of_string "2") @@
  elet "var1_v1" (F.const_of_string "0") @@
  elet "var2_v1" (F.const_of_string "0") @@
  elet "var1_v2" F.((var "var1_v1") + (var "xs_i0")) @@
  elet "var2_v2" (F.const_of_string "666") @@
  elet "var1_v3" F.((var "var1_v2") + (var "xs_i1")) @@
  elet "var2_v3" (F.const_of_string "666") @@
  elet "y" (var "var1_v3") @@
  (var "y");}

let circuit_A_1 = Circuit{

  name =
  "A_1";

  inputs =
  [("xs_i0", field); ("xs_i1", field); ("xs_i2", field)];

  outputs =
  [("y", field)];

  dep =
  None;

  body =
  elet "var0_v1" (F.const_of_string "3") @@
  elet "var1_v1" (F.const_of_string "0") @@
  elet "var2_v1" (F.const_of_string "0") @@
  elet "var1_v2" F.((var "var1_v1") + (var "xs_i0")) @@
  elet "var2_v2" (F.const_of_string "666") @@
  elet "var1_v3" F.((var "var1_v2") + (var "xs_i1")) @@
  elet "var2_v3" (F.const_of_string "666") @@
  elet "var1_v4" F.((var "var1_v3") + (var "xs_i2")) @@
  elet "var2_v4" (F.const_of_string "666") @@
  elet "y" (var "var1_v4") @@
  (var "y");}

let circuit_Main_2 = Circuit{

  name =
  "Main_2";

  inputs =
  [];

  outputs =
  [("y", field)];

  dep =
  None;

  body =
  elet "var0_v1" (F.const_of_string "0") @@
  elet "a2_dot_xs_i0" (F.const_of_string "2") @@
  elet "var0_v2" (F.const_of_string "666") @@
  elet "a2_dot_xs_i1" (F.const_of_string "2") @@
  elet "a2_result" (call "A_0" [(var "a2_dot_xs_i0"); (var "a2_dot_xs_i1")]) @@
  elet "a2_dot_y" (var "a2_result") @@
  elet "var0_v3" (F.const_of_string "666") @@
  elet "var0_v4" (F.const_of_string "0") @@
  elet "a3_dot_xs_i0" (F.const_of_string "3") @@
  elet "var0_v5" (F.const_of_string "666") @@
  elet "a3_dot_xs_i1" (F.const_of_string "3") @@
  elet "var0_v6" (F.const_of_string "666") @@
  elet "a3_dot_xs_i2" (F.const_of_string "3") @@
  elet "a3_result" (call "A_1" [(var "a3_dot_xs_i0"); (var "a3_dot_xs_i1"); (var "a3_dot_xs_i2")]) @@
  elet "a3_dot_y" (var "a3_result") @@
  elet "var0_v7" (F.const_of_string "666") @@
  elet "y" F.((var "a2_dot_y") + (var "a3_dot_y")) @@
  (var "y");}

