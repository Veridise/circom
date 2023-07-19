let template___Example1 = Hoare_circuit { name= "Example1"; inputs= [("x1", field); ("x2", field)]; outputs= [("y", field)]; preconditions= []; postcondition= []; body= let tmp = ((var "x1")) in (let y = (((var "tmp") * (var "x2"))) in ((y))) }

let generator___Example1 x1 x2 = let tmp = (x1) in (let y = ((tmp * x2)) in ((y)))

