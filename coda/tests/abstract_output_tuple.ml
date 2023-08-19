open Ast
open Dsl
open Nice_dsl
open Expr
open Qual
open Typ
open TypRef

let body_AbstractCircuit prefix (b, c, a) output =
  elet (prefix ^ "__tuple__AbstractCircuit") (call "AbstractCircuit" [a]) @@
  elet b (project (var (prefix ^ "__tuple__AbstractCircuit")) 0) @@
  elet c (project (var (prefix ^ "__tuple__AbstractCircuit")) 1) @@
  output


let body_Main prefix (y, z, x) output = elet "a_0_a" (var x) @@
  body_AbstractCircuit (prefix ^ "sc0_") ("a_0_b", "a_0_c", "a_0_a") @@
  elet y (var "a_0_b") @@
  elet z (var "a_0_c") @@
  output

let circuit_Main = Circuit { name= "Main"; inputs= [("x", field)]; outputs= [("y", field); ("z", field)]; dep=None; body= let prefix = "main_" in body_Main prefix ("y", "z", "x") (Expr.tuple ["y"; "z"]) }


