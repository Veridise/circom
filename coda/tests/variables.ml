let body_Main (y, x) body = elet "var_0" (F.const 1) @@ elet "var_1" (F.const 2) @@ elet "var_2" (F.const 3) @@ elet "var_3" (F.const 4) @@ elet "var_4" (F.const 5) @@ elet "var_5" (F.const 6) @@ elet "var_6" (F.const 7) @@ elet "var_7" (F.const 8) @@ elet y (var x) @@ body

let circuit_Main = Hoare_circuit {name= "Main", inputs= [Presignal "x"], outputs= [Presignal "y"], preconditions= [], postconditions= [], dep= None, body= body_Main ("y", "x")}


