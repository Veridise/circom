let body_A (x2, x1) body = elet x2 (var x1) @@ body

let circuit_A = Hoare_circuit {name= "A", inputs= [Presignal "x1"], outputs= [Presignal "x2"], preconditions= [], postconditions= [], dep= None, body= body_A ("x2", "x1")}


let body_B (y2, y1) body = elet a_x1 (var y1) @@ elet y2 (var a_x2) @@ body

let circuit_B = Hoare_circuit {name= "B", inputs= [Presignal "y1"], outputs= [Presignal "y2"], preconditions= [], postconditions= [], dep= None, body= body_B ("y2", "y1")}


let body_C (z3, z1, z2) body = elet a_x1 (var z1) @@ elet b1_y1 (var z2) @@ elet b2_y1 (var z2) @@ elet z3 (((var a_x2) + (var b1_y2)) + (var b2_y2)) @@ body

let circuit_C = Hoare_circuit {name= "C", inputs= [Presignal "z1"; Presignal "z2"], outputs= [Presignal "z3"], preconditions= [], postconditions= [], dep= None, body= body_C ("z3", "z1", "z2")}


