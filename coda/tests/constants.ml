let body_Main signal_a = let signal_b = ((4 * signal_a) + 2) in (signal_b)

let circuit_Main = Hoare_circuit { name= "Main"; inputs= [Presignal "signal_a"]; outputs= [Presignal "signal_b"]; preconditions= []; postconditions= []; body= body_Main (var "signal_a") }


