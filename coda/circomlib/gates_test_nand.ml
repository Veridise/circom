let body___NAND  a b = 
  let out = (1 - (a * b)) in (out)

let template___NAND = Hoare_circuit { name= "NAND"; inputs= [("a", field); ("b", field)]; outputs= [("out", field)]; preconditions= []; postcondition= []; body= body___NAND (var "a") (var "b") }



