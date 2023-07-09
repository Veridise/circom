let template___Id1 = Hoare_circuit { name= "Id1"; inputs= [("a", field)]; outputs= [("b", field)]; preconditions= []; postcondition= []; body= let b = ((var "a")) in ((b)) }

let generator___Id1 a = let b = (a) in ((b))

let template___Id2 = Hoare_circuit { name= "Id2"; inputs= [("x", field)]; outputs= [("y", field)]; preconditions= []; postcondition= []; body= let y = ((var "x")) in ((y)) }

let generator___Id2 x = let y = (x) in ((y))

let template___Main = Hoare_circuit { name= "Main"; inputs= [("x", field)]; outputs= [("y", field)]; preconditions= []; postcondition= []; body= let (subcomponent___id1___b) = template___Main  in let (subcomponent___id2___y) = template___Id2  in let subcomponent___id1___a = ((var "x")) in ((y)) }

let generator___Main x = let (subcomponent___id1___b) = template___Main  in let (subcomponent___id2___y) = template___Id2  in let subcomponent___id1___a = (x) in ((y))

