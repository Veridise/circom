let body___XOR  a b = 
  let out = ((a + b) - ((2 * a) * b)) in (out)

let template___XOR = Hoare_circuit { name= "XOR"; inputs= [("a", field); ("b", field)]; outputs= [("out", field)]; preconditions= []; postcondition= []; body= body___XOR (var "a") (var "b") }



