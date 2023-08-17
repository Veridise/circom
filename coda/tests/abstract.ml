open Ast
open Dsl
open Nice_dsl
open Expr
open Qual
open Typ
open TypRef

let body_AbstractCircuit _prefix (y, x) output =
  elet y (call "AbstractCircuit" [x]) @@
  output


let body_Main prefix (b, a) output = elet "ac_0_x" (var a) @@
  body_AbstractCircuit (prefix ^ "sc0_") ("ac_0_y", "ac_0_x") @@
  elet b (var "ac_0_y") @@
  output

let circuit_Main = Circuit { name= "Main"; inputs= [("a", field)]; outputs= [("b", field)]; dep=None; body= let prefix = "main_" in body_Main prefix ("b", "a") (Expr.tuple ["b"]) }


