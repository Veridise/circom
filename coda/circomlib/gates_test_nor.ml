let body___NOR  a b = 
  let out = ((((a * b) + 1) - a) - b) in (out)

let template___NOR = Hoare_circuit { name= "NOR"; inputs= [("a", field); ("b", field)]; outputs= [("out", field)]; preconditions= []; postcondition= []; body= body___NOR (var "a") (var "b") }



