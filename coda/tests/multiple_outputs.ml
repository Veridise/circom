let body___Main  a = 
  let b = a in 
  let c = a in (b, c)

let template___Main = Hoare_circuit { name= "Main"; inputs= [("a", field)]; outputs= [("b", field); ("c", field)]; preconditions= []; postcondition= []; body= body___Main  (var "a") }



