let body___Main  xs[0] xs[1] xs[2] xs[3] = 
  let var___0 = 4 in 
  let out = xs[0] in (out)

let template___Main = Hoare_circuit { name= "Main"; inputs= [("xs[0]", field); ("xs[1]", field); ("xs[2]", field); ("xs[3]", field)]; outputs= [("out", field)]; preconditions= []; postcondition= []; body= body___Main (var "xs[0]") (var "xs[1]") (var "xs[2]") (var "xs[3]") }



