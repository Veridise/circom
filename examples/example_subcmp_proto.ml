(* let open Hoare_circuit in to_circuit @@ Hoare_circuit 
    { name= "Not"
    ; inputs= BaseTyp.[("a", field)]
    ; outputs= BaseTyp.[("b", field)]
    ; preconditions= []
    ; postconditions= []
    ; body= ((a + 1) - (2 * a)) 
    } *)

(* template Id1 *)

let template_Id1 = to_circuit @@ Hoare_circuit
  { name= "Id1"
  ; inputs= [("x", field)]
  ; outputs= [("y", field)]
  ; body= var "x"
  }

let run_Id1 x = x

let template_Id2 = to_circuit @@ Hoare_circuit
  { name= "Id2"
  ; inputs= [("x", field)]
  ; outputs= [("y", field)]
  ; body= var "x"
  }

let run_Id2 x = x

let template_Main = to_circuit @@ Hoare_circuit
  { name= "Main"
  ; inputs= [("a", field)]
  ; outputs= [("b", field)]
  ; body=
      let out_Id1_y = 
          let in_Id1_x = var "a" in 
          run_Id1 in_Id1_x 
      in
      let out_Id2_y = 
          let in_Id2_x = var "a" in
          run_Id2 in_Id2_xin
      in
      let b = out_Id1_y in
      b
  }