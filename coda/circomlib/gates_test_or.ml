let body___OR  a b = 
  let out = ((a + b) - (a * b)) in (out)

let template___OR = Hoare_circuit { name= "OR"; inputs= [("a", field); ("b", field)]; outputs= [("out", field)]; preconditions= []; postcondition= []; body= body___OR (var "a") (var "b") }



