let body___Id  a = 
  let b = a in (b)

let template___Id = Hoare_circuit { name= "Id"; inputs= [("a", field)]; outputs= [("b", field)]; preconditions= []; postcondition= []; body= body___Id (var "a") }



let body___Main  x = 
  let subcomponent___id1___x = x in 
  let (* component *) (subcomponent___id1___y) = body___Id subcomponent___id1___x in 
  let subcomponent___id2___x = x in 
  let (* component *) (subcomponent___id2___y) = body___Id subcomponent___id2___x in 
  let y = subcomponent___id1___y in (y)

let template___Main = Hoare_circuit { name= "Main"; inputs= [("x", field)]; outputs= [("y", field)]; preconditions= []; postcondition= []; body= body___Main (var "x") }



