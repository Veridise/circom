let body___Id1  x = 
  let y = x in (y)

let template___Id1 = Hoare_circuit { name= "Id1"; inputs= [("x", field)]; outputs= [("y", field)]; preconditions= []; postcondition= []; body= body___Id1  (var "x") }



let body___Id2  a = 
  let b = a in (b)

let template___Id2 = Hoare_circuit { name= "Id2"; inputs= [("a", field)]; outputs= [("b", field)]; preconditions= []; postcondition= []; body= body___Id2  (var "a") }



let body___Main  x = 
  let (subcomponent___id1___y) = body___Id2  subcomponent___id1___x in 
  let (subcomponent___id2___b) = body___Main  subcomponent___id2___a in 
  let subcomponent___id1___x = x in 
  let subcomponent___id2___a = x in 
  let y = subcomponent___id1___y in (y)

let template___Main = Hoare_circuit { name= "Main"; inputs= [("x", field)]; outputs= [("y", field)]; preconditions= []; postcondition= []; body= body___Main  (var "x") }



