let body_Ark (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body


let body_Sigma (out, in, in2, in4) body = elet out star @@ elet in star @@ elet in2 star @@ elet in4 star @@ body


let body_Mix (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body


let body_MixLast (out, in_0, in_1, in_2) body = elet out star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body


let body_PoseidonEx (out_0, inputs_0, inputs_1, initialState) body = elet out_0 star @@ elet inputs_0 star @@ elet inputs_1 star @@ elet initialState star @@ body


let body_Poseidon (out, inputs_0, inputs_1) body = elet out star @@ elet inputs_0 star @@ elet inputs_1 star @@ body


let body_MultiMux1 (out_0, out_1, c_0_0, c_0_1, c_1_0, c_1_1, s) body = elet "var_0" (F.const 2) @@ elet "var_1" (F.const 0) @@ elet out_0 ((((var c_0_1) - (var c_0_0)) * (var s)) + (var c_0_0)) @@ elet "var_1" (F.const 0) @@ elet out_1 ((((var c_1_1) - (var c_1_0)) * (var s)) + (var c_1_0)) @@ elet "var_1" (F.const 0) @@ body

let circuit_MultiMux1 = Hoare_circuit {name= "MultiMux1", inputs= [Presignal "c_0_0"; Presignal "c_0_1"; Presignal "c_1_0"; Presignal "c_1_1"; Presignal "s"], outputs= [Presignal "out_0"; Presignal "out_1"], preconditions= [], postconditions= [], dep= None, body= body_MultiMux1 ("out_0", "out_1", "c_0_0", "c_0_1", "c_1_0", "c_1_1", "s")}


let body_MerkleTreeInclusionProof (root, leaf, pathIndices_0, pathIndices_1, siblings_0, siblings_1, hashes_0, hashes_1, hashes_2) body = elet "var_0" (F.const 2) @@ elet hashes_0 (var leaf) @@ elet "var_1" (F.const 0) @@ assert_in "_1" (((var pathIndices_0) * ((F.const 1) - (var pathIndices_0))) =. (F.const 0)) @@ elet "mux_c_0_0" (var hashes_0) @@ elet "mux_c_0_1" (var siblings_0) @@ elet "mux_c_1_0" (var siblings_0) @@ elet "mux_c_1_1" (var hashes_0) @@ elet "mux_s" (var pathIndices_0) @@ body_MultiMux1 ("mux_out_0", "mux_out_1", "mux_c_0_0", "mux_c_0_1", "mux_c_1_0", "mux_c_1_1", "mux_s") @@ elet "poseidons_inputs_0" (var "mux_out_0") @@ elet "poseidons_inputs_1" (var "mux_out_1") @@ body_Poseidon ("poseidons_out", "poseidons_inputs_0", "poseidons_inputs_1") @@ elet hashes_1 (var "poseidons_out") @@ elet "var_1" (F.const 0) @@ assert_in "_2" (((var pathIndices_1) * ((F.const 1) - (var pathIndices_1))) =. (F.const 0)) @@ elet "mux_c_0_0" (var hashes_1) @@ elet "mux_c_0_1" (var siblings_1) @@ elet "mux_c_1_0" (var siblings_1) @@ elet "mux_c_1_1" (var hashes_1) @@ elet "mux_s" (var pathIndices_1) @@ body_MultiMux1 ("mux_out_0", "mux_out_1", "mux_c_0_0", "mux_c_0_1", "mux_c_1_0", "mux_c_1_1", "mux_s") @@ elet "poseidons_inputs_0" (var "mux_out_0") @@ elet "poseidons_inputs_1" (var "mux_out_1") @@ body_Poseidon ("poseidons_out", "poseidons_inputs_0", "poseidons_inputs_1") @@ elet hashes_2 (var "poseidons_out") @@ elet "var_1" (F.const 0) @@ elet root (var hashes_2) @@ body

let circuit_MerkleTreeInclusionProof = Hoare_circuit {name= "MerkleTreeInclusionProof", inputs= [Presignal "leaf"; Presignal "pathIndices_0"; Presignal "pathIndices_1"; Presignal "siblings_0"; Presignal "siblings_1"], outputs= [Presignal "root"], preconditions= [], postconditions= [], dep= None, body= body_MerkleTreeInclusionProof ("root", "leaf", "pathIndices_0", "pathIndices_1", "siblings_0", "siblings_1", "hashes_0", "hashes_1", "hashes_2")}


