let body_A (a2, a1) body = elet a2 (var a1) @@ body

let circuit_A = Hoare_circuit {name= "A", inputs= [Presignal "a1"], outputs= [Presignal "a2"], preconditions= [], postconditions= [], dep= None, body= body_A ("a2", "a1")}


let body_B (b2, b1) body = elet b2 (var b1) @@ body

let circuit_B = Hoare_circuit {name= "B", inputs= [Presignal "b1"], outputs= [Presignal "b2"], preconditions= [], postconditions= [], dep= None, body= body_B ("b2", "b1")}


let body_C (c2, c1) body = elet "a_a1" (var c1) @@ body_A ("a_a2", "a_a1") @@ elet "b_b1" (var "a_a2") @@ body_B ("b_b2", "b_b1") @@ elet c2 (var "b_b2") @@ body

let circuit_C = Hoare_circuit {name= "C", inputs= [Presignal "c1"], outputs= [Presignal "c2"], preconditions= [], postconditions= [], dep= None, body= body_C ("c2", "c1")}


