let circuit_AND = Circuit{ name = "circuit_AND"; inputs = [("a", field); ("b", field)]; outputs = [("out", field)]; dep = None; body = (elet "out" F.((var "a") * (var "b")) (Expr.tuple [(var "out")]));}

