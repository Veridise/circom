

let body_XOR input_signal_0 input_signal_1 output_signal_0 = let input_signal_0 = ((input_signal_1 + input_signal_2) - ((value_0 * input_signal_1) * input_signal_2)) in (output_signal_0)

let circuit_XOR = body_XOR (var "input_signal_0") (var "input_signal_1") (var "output_signal_0")



