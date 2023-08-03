let body_AND (out, a, b) body = elet out ((var a) * (var b)) @@ body

let circuit_AND = Hoare_circuit {name= "AND", inputs= [Presignal "a"; Presignal "b"], outputs= [Presignal "out"], preconditions= [], postconditions= [], dep= None, body= body_AND ("out", "a", "b")}


let body_MultiAND (out, in_0, in_1) body = elet "var_0" (F.const 2) @@ elet "and1_a" (var in_0) @@ elet "and1_b" (var in_1) @@ body_AND ("and1_out", "and1_a", "and1_b") @@ elet out (var "and1_out") @@ body

let circuit_MultiAND = Hoare_circuit {name= "MultiAND", inputs= [Presignal "in_0"; Presignal "in_1"], outputs= [Presignal "out"], preconditions= [], postconditions= [], dep= None, body= body_MultiAND ("out", "in_0", "in_1")}


let body_MultiAND (out, in_0, in_1, in_2, in_3) body = elet "var_0" (F.const 4) @@ elet "var_1" (F.const 2) @@ elet "var_2" (F.const 2) @@ elet "var_3" (F.const 0) @@ elet "var_3" (F.const 0) @@ elet "ands_in_0" (var in_0) @@ elet "var_3" (F.const (* ERROR: bad constant index: 4 in ["2", "0", "1", "4"] *) 0) @@ elet "ands_in_1" (var in_1) @@ body_MultiAND ("ands_out", "ands_in_0", "ands_in_1") @@ elet "var_3" (F.const (* ERROR: bad constant index: 5 in ["2", "0", "1", "4"] *) 0) @@ elet "var_3" (F.const 0) @@ elet "ands_in_0" (var in_2) @@ elet "var_3" (F.const (* ERROR: bad constant index: 6 in ["2", "0", "1", "4"] *) 0) @@ elet "ands_in_1" (var in_3) @@ body_MultiAND ("ands_out", "ands_in_0", "ands_in_1") @@ elet "var_3" (F.const (* ERROR: bad constant index: 7 in ["2", "0", "1", "4"] *) 0) @@ elet "and2_a" (var "ands_out") @@ elet "and2_b" (var "ands_out") @@ body_AND ("and2_out", "and2_a", "and2_b") @@ elet out (var "and2_out") @@ body

let circuit_MultiAND = Hoare_circuit {name= "MultiAND", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"; Presignal "in_3"], outputs= [Presignal "out"], preconditions= [], postconditions= [], dep= None, body= body_MultiAND ("out", "in_0", "in_1", "in_2", "in_3")}


