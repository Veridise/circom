let body_MultiMux1 (out_0, c_0_0, c_0_1, s) body =
    elet "var_0" (F.const 1) @@
    elet "var_1" (F.const 0) @@
    elet "out_0" ((((var c_0_1) - (var c_0_0)) * (var s)) + (var c_0_0)) @@
    elet "var_1" (F.const 1) @@
    body

let circuit_MultiMux1 =
    Hoare_circuit {name= "MultiMux1", inputs= [Presignal "c_0_0"; Presignal "c_0_1"; Presignal "s"], outputs= [Presignal "out_0"], preconditions= [], postconditions= [], dep= None, body= body_MultiMux1 ("out_0", "c_0_0", "c_0_1", "s")}


let body_Mux1 (out, c_0, c_1, s) body =
    body_mux (out_0, c_0_0, c_0_1, s) @@
    elet "var_0" (F.const 0) @@
    elet "var_0" (F.const 0) @@
    elet "mux_c_0_0" (var c_0) @@
    elet "var_0" (F.const (bad constant index: 4)) @@
    elet "mux_c_0_1" (var c_1) @@
    elet "var_0" (F.const (bad constant index: 5)) @@
    elet "mux_s" (var s) @@
    elet "out" (var mux_out_0) @@
    body

let circuit_Mux1 =
    Hoare_circuit {name= "Mux1", inputs= [Presignal "c_0"; Presignal "c_1"; Presignal "s"], outputs= [Presignal "out"], preconditions= [], postconditions= [], dep= None, body= body_Mux1 ("out", "c_0", "c_1", "s")}


let body_Main (out) body =
    body_mux1 (out, c_0, c_1, s) @@
    elet "mux1_c_0" (F.const 1) @@
    elet "mux1_c_1" (F.const 2) @@
    elet "mux1_s" (F.const 3) @@
    elet "out" (var mux1_out) @@
    body

let circuit_Main =
    Hoare_circuit {name= "Main", inputs= [], outputs= [Presignal "out"], preconditions= [], postconditions= [], dep= None, body= body_Main ("out")}
