let body___Id1  x = 
  let y = x in (y)

let template___Id1 = Hoare_circuit { name= "Id1"; inputs= [("x", field)]; outputs= [("y", field)]; preconditions= []; postcondition= []; body= body___Id1 (var "x") }



let body___Id2  x = 
  let y = x in (y)

let template___Id2 = Hoare_circuit { name= "Id2"; inputs= [("x", field)]; outputs= [("y", field)]; preconditions= []; postcondition= []; body= body___Id2 (var "x") }



let body___Main  a = 
  let subcomponent___id1___x = a in 
  let (* component *) (subcomponent___id1___y) = body___Id1 subcomponent___id1___x in 
  let subcomponent___id2___x = a in 
  let (* component *) (subcomponent___id2___y) = body___Id2 subcomponent___id2___x in 
  let b = subcomponent___id1___y in (b)

let template___Main = Hoare_circuit { name= "Main"; inputs= [("a", field)]; outputs= [("b", field)]; preconditions= []; postcondition= []; body= body___Main (var "a") }



