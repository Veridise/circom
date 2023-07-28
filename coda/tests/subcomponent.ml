let body_A signal_x1 = let signal_x2 = signal_x1 in (signal_x2)

let circuit_A = Hoare_circuit { name= "A"; inputs= [Presignal "signal_x1"]; outputs= [Presignal "signal_x2"]; preconditions= []; postconditions= []; body= body_A (var "signal_x1") }


let body_B signal_y1 = let (signal_y2) = body_A signal_y1 in let signal_A_x1 = signal_y1 in let signal_y2 = signal_A_x2 in (signal_y2)

let circuit_B = Hoare_circuit { name= "B"; inputs= [Presignal "signal_y1"]; outputs= [Presignal "signal_y2"]; preconditions= []; postconditions= []; body= body_B (var "signal_y1") }


let body_C signal_z1 signal_z2 = let (signal_z3) = body_A signal_z1 signal_z2 in let (signal_z3) = body_B signal_z1 signal_z2 in let (signal_z3) = body_A signal_z1 signal_z2 in let signal_A_x1 = signal_z1 in let signal_B_y1 = signal_z1 in let signal_C_z1 = signal_z2 in let signal_z3 = ((signal_A_x1 + signal_B_y2) + signal_C_z1) in (signal_z3)

let circuit_C = Hoare_circuit { name= "C"; inputs= [Presignal "signal_z1" Presignal "signal_z2"]; outputs= [Presignal "signal_z3"]; preconditions= []; postconditions= []; body= body_C (var "signal_z1") (var "signal_z2") }


