let body___AND  a b = 
  let out = (a * b) in (out)

let template___AND = Hoare_circuit { name= "AND"; inputs= [("a", field); ("b", field)]; outputs= [("out", field)]; preconditions= []; postcondition= []; body= body___AND (var "a") (var "b") }



