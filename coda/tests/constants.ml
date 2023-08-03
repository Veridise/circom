let body_Foo (y, x1, x2) body = elet "var_0" (F.const 1) @@ elet y (F.const 1) @@ body

let circuit_Foo = Hoare_circuit {name= "Foo", inputs= [Presignal "x1"; Presignal "x2"], outputs= [Presignal "y"], preconditions= [], postconditions= [], dep= None, body= body_Foo ("y", "x1", "x2")}


let body_Foo (y, x1, x2) body = elet "var_0" (F.const 2) @@ elet "var_1" (F.const 1) @@ elet "foo1_x1" (var x1) @@ elet "foo1_x2" (var x2) @@ body_Foo ("foo1_y", "foo1_x1", "foo1_x2") @@ elet "foo2_x1" (var x1) @@ elet "foo2_x2" (var x2) @@ body_Foo ("foo2_y", "foo2_x1", "foo2_x2") @@ elet y ((var "foo1_y") + (var "foo2_y")) @@ body

let circuit_Foo = Hoare_circuit {name= "Foo", inputs= [Presignal "x1"; Presignal "x2"], outputs= [Presignal "y"], preconditions= [], postconditions= [], dep= None, body= body_Foo ("y", "x1", "x2")}


let body_Foo (y, x1, x2) body = elet "var_0" (F.const 4) @@ elet "var_1" (F.const 2) @@ elet "foo1_x1" (var x1) @@ elet "foo1_x2" (var x2) @@ body_Foo ("foo1_y", "foo1_x1", "foo1_x2") @@ elet "foo2_x1" (var x1) @@ elet "foo2_x2" (var x2) @@ body_Foo ("foo2_y", "foo2_x1", "foo2_x2") @@ elet y ((var "foo1_y") + (var "foo2_y")) @@ body

let circuit_Foo = Hoare_circuit {name= "Foo", inputs= [Presignal "x1"; Presignal "x2"], outputs= [Presignal "y"], preconditions= [], postconditions= [], dep= None, body= body_Foo ("y", "x1", "x2")}


