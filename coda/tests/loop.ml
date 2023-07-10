let body___Loop  a = 
  let var___0 = a in 
  let var___1 = 0 in 
  let var___0 = (var___0 + 1) in 
  let var___1 = 1 in 
  let var___0 = (var___0 + 1) in 
  let var___1 = 2 in 
  let var___0 = (var___0 + 1) in 
  let var___1 = 3 in 
  let var___0 = (var___0 + 1) in 
  let var___1 = 4 in 
  let var___0 = (var___0 + 1) in 
  let var___1 = 5 in 
  let var___0 = (var___0 + 1) in 
  let var___1 = 6 in 
  let var___0 = (var___0 + 1) in 
  let var___1 = 7 in 
  let var___0 = (var___0 + 1) in 
  let var___1 = 8 in 
  let var___0 = (var___0 + 1) in 
  let var___1 = 9 in 
  let var___0 = (var___0 + 1) in 
  let var___1 = 10 in 
  let b = var___0 in (b)

let template___Loop = Hoare_circuit { name= "Loop"; inputs= [("a", field)]; outputs= [("b", field)]; preconditions= []; postcondition= []; body= body___Loop  (var "a") }



