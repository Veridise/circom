let template___Id1 = Hoare_circuit { name= "Id1"; inputs= [("x", field)]; outputs= [("y", field)]; preconditions= []; postcondition= []; body= let y = var "x" in (y) }

let generator___Id1 x = let y = x in (y)

let template___Id2 = Hoare_circuit { name= "Id2"; inputs= [("a", field)]; outputs= [("b", field)]; preconditions= []; postcondition= []; body= let b = var "a" in (b) }

let generator___Id2 a = let b = a in (b)

let template___Main = Hoare_circuit { name= "Main"; inputs= [("x", field)]; outputs= [("y", field)]; preconditions= []; postcondition= []; body= let (subcomponent___id1___y) = generator___Id2  subcomponent___id1___x in let (subcomponent___id2___b) = generator___Main  subcomponent___id2___a in let (subcomponent___id1___y) = generator___Id2  subcomponent___id1___x in let subcomponent___id1___x = var "x" in let (subcomponent___id2___b) = generator___Main  subcomponent___id2___a in let subcomponent___id2___a = var "x" in let y = subcomponent___id1___y in (y) }

let generator___Main x = let (subcomponent___id1___y) = generator___Id2  subcomponent___id1___x in let (subcomponent___id2___b) = generator___Main  subcomponent___id2___a in let (subcomponent___id1___y) = generator___Id2  subcomponent___id1___x in let subcomponent___id1___x = x in let (subcomponent___id2___b) = generator___Main  subcomponent___id2___a in let subcomponent___id2___a = x in let y = subcomponent___id1___y in (y)

