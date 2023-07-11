let body___Main  xs___0 xs___1 xs___2 xs___3 = 
  let var___0 = 4 in 
  let out = xs___0 in (out)

let template___Main = Hoare_circuit { name= "Main"; inputs= [("xs___0", field); ("xs___1", field); ("xs___2", field); ("xs___3", field)]; outputs= [("out", field)]; preconditions= []; postcondition= []; body= body___Main (var "xs___0") (var "xs___1") (var "xs___2") (var "xs___3") }



