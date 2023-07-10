let body___A  b_in = 
  let b_out = b_in in (b_out)

let template___A = Hoare_circuit { name= "A"; inputs= [("b_in", field)]; outputs= [("b_out", field)]; preconditions= []; postcondition= []; body= body___A  (var "b_in") }



let body___B  a_in = 
  let subcomponent___a___b_in = a_in in 
  let (* component *) (subcomponent___a___b_out) = body___B  subcomponent___a___b_in in 
  let a_out = subcomponent___a___b_out in (a_out)

let template___B = Hoare_circuit { name= "B"; inputs= [("a_in", field)]; outputs= [("a_out", field)]; preconditions= []; postcondition= []; body= body___B  (var "a_in") }



