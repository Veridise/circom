let body_Main (b, a) body = elet b (((F.const 4) * (var a)) + (F.const 2)) @@ body

let circuit_Main = Hoare_circuit {name= "Main", inputs= [Presignal "a"], outputs= [Presignal "b"], preconditions= [], postconditions= [], dep= None, body= body_Main ("b", "a")}


