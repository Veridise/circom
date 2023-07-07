let open Hoare_circuit in to_circuit @@ Hoare_circuit { name= "Example"; inputs= BaseTyp.[("a1", field)("a2", field)]; outputs= BaseTyp.[("b", field)]; preconditions= []; postconditions= []; body= let x = a1 in x }

