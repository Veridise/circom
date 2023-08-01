let body_Main (b, a) body = elet b (((CInt 0) * (var a)) + (CInt 1)) @@ body

let circuit_Main = Hoare_circuit {name= "Main", inputs= [Presignal "a"], outputs= [Presignal "b"], preconditions= [], postconditions= [], dep= None, body= body_Main ("b", "a")}


