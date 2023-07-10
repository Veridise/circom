let body___A  in = 
  let out = in in (out)

let template___A = Hoare_circuit { name= "A"; inputs= [("in", field)]; outputs= [("out", field)]; preconditions= []; postcondition= []; body= body___A  (var "in") }



let body___B  in = 
  let out = in in (out)

let template___B = Hoare_circuit { name= "B"; inputs= [("in", field)]; outputs= [("out", field)]; preconditions= []; postcondition= []; body= body___B  (var "in") }



let body___C  in = 
  let out = in in (out)

let template___C = Hoare_circuit { name= "C"; inputs= [("in", field)]; outputs= [("out", field)]; preconditions= []; postcondition= []; body= body___C  (var "in") }



let body___D  in = 
  let subcomponent___a___in = in in 
  let (* component *) (subcomponent___a___out) = body___A  subcomponent___a___in in 
  let subcomponent___b___in = in in 
  let (* component *) (subcomponent___b___out) = body___B  subcomponent___b___in in 
  let subcomponent___c___in = in in 
  let (* component *) (subcomponent___c___out) = body___C  subcomponent___c___in in 
  let out = subcomponent___c___out in (out)

let template___D = Hoare_circuit { name= "D"; inputs= [("in", field)]; outputs= [("out", field)]; preconditions= []; postcondition= []; body= body___D  (var "in") }



