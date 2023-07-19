let body___NOT  in = 
  let out = ((1 + in) - (2 * in)) in (out)

let template___NOT = Hoare_circuit { name= "NOT"; inputs= [("in", field)]; outputs= [("out", field)]; preconditions= []; postcondition= []; body= body___NOT (var "in") }



