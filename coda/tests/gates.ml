let body_XOR signal_a signal_b = let signal_out = ((signal_a + signal_b) - ((2 * signal_a) * signal_b)) in (signal_out)

let circuit_XOR = Hoare_circuit { name= "XOR"; inputs= [Presignal "signal_a" Presignal "signal_b"]; outputs= [Presignal "signal_out"]; preconditions= []; postconditions= []; body= body_XOR (var "signal_a") (var "signal_b") }


