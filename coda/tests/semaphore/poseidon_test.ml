let body_Ark (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_Ark = Hoare_circuit {name= "Ark", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_Ark ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_Sigma (out, in, in2, in4) body = elet out star @@ elet in star @@ elet in2 star @@ elet in4 star @@ body

let circuit_Sigma = Hoare_circuit {name= "Sigma", inputs= [Presignal "in"], outputs= [Presignal "out"], preconditions= [], postconditions= [], dep= None, body= body_Sigma ("out", "in", "in2", "in4")}


let body_Ark (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_Ark = Hoare_circuit {name= "Ark", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_Ark ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_Mix (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_Mix = Hoare_circuit {name= "Mix", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_Mix ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_Ark (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_Ark = Hoare_circuit {name= "Ark", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_Ark ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_Ark (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_Ark = Hoare_circuit {name= "Ark", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_Ark ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_Ark (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_Ark = Hoare_circuit {name= "Ark", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_Ark ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_Mix (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_Mix = Hoare_circuit {name= "Mix", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_Mix ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixS (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixS = Hoare_circuit {name= "MixS", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_MixS ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_Ark (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_Ark = Hoare_circuit {name= "Ark", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_Ark ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_Ark (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_Ark = Hoare_circuit {name= "Ark", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_Ark ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_Ark (out_0, out_1, out_2, in_0, in_1, in_2) body = elet out_0 star @@ elet out_1 star @@ elet out_2 star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_Ark = Hoare_circuit {name= "Ark", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out_0"; Presignal "out_1"; Presignal "out_2"], preconditions= [], postconditions= [], dep= None, body= body_Ark ("out_0", "out_1", "out_2", "in_0", "in_1", "in_2")}


let body_MixLast (out, in_0, in_1, in_2) body = elet out star @@ elet in_0 star @@ elet in_1 star @@ elet in_2 star @@ body

let circuit_MixLast = Hoare_circuit {name= "MixLast", inputs= [Presignal "in_0"; Presignal "in_1"; Presignal "in_2"], outputs= [Presignal "out"], preconditions= [], postconditions= [], dep= None, body= body_MixLast ("out", "in_0", "in_1", "in_2")}


let body_PoseidonEx (out_0, inputs_0, inputs_1, initialState) body = elet out_0 star @@ elet inputs_0 star @@ elet inputs_1 star @@ elet initialState star @@ body

let circuit_PoseidonEx = Hoare_circuit {name= "PoseidonEx", inputs= [Presignal "inputs_0"; Presignal "inputs_1"; Presignal "initialState"], outputs= [Presignal "out_0"], preconditions= [], postconditions= [], dep= None, body= body_PoseidonEx ("out_0", "inputs_0", "inputs_1", "initialState")}


let body_Poseidon (out, inputs_0, inputs_1) body = elet out star @@ elet inputs_0 star @@ elet inputs_1 star @@ body

let circuit_Poseidon = Hoare_circuit {name= "Poseidon", inputs= [Presignal "inputs_0"; Presignal "inputs_1"], outputs= [Presignal "out"], preconditions= [], postconditions= [], dep= None, body= body_Poseidon ("out", "inputs_0", "inputs_1")}


