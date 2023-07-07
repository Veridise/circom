let open Hoare_circuit in to_circuit @@ Hoare_circuit { name= "Id1"; inputs= BaseTyp.[("a", field)]; outputs= BaseTyp.[("b", field)]; preconditions= []; postconditions= []; body= a }

let open Hoare_circuit in to_circuit @@ Hoare_circuit { name= "Id2"; inputs= BaseTyp.[("x", field)]; outputs= BaseTyp.[("y", field)]; preconditions= []; postconditions= []; body= x }

let open Hoare_circuit in to_circuit @@ Hoare_circuit { name= "Main"; inputs= BaseTyp.[("x", field)]; outputs= BaseTyp.[("y", field)]; preconditions= []; postconditions= []; body= Main__b }

