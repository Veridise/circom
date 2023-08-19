open Ast
open Dsl
open Nice_dsl
open Expr
open Qual
open Typ
open TypRef

let body_AbstractCircuit prefix (z, x) output =
  elet z (call "AbstractCircuit" [(var x)]) @@
  output


let body_XXX prefix (zzz, xxx) output =
  elet (prefix ^ "yyy") (var xxx) @@
  elet zzz (var (prefix ^ "yyy")) @@
  output

let circuit_XXX =
  Circuit
    { name= "XXX"
    ; inputs= [("xxx", field)]
    ; outputs= [("zzz", field)]
    ; dep=None
    ; body= let prefix = "main_" in body_XXX prefix ("zzz", "xxx") (Expr.tuple [(var (prefix ^ "zzz"))]) }


let body_Main prefix (b, a) output =
  elet "ac_0_x" (var a) @@
  body_AbstractCircuit (prefix ^ "sc0_") ("ac_0_z", "ac_0_x") @@
  elet "xxx_0_xxx" (var "ac_0_z") @@
  body_XXX (prefix ^ "sc0_") ("xxx_0_zzz", "xxx_0_xxx") @@
  elet b (var "xxx_0_zzz") @@
  output

let circuit_Main =
  Circuit
    { name= "Main"
    ; inputs= [("a", field)]
    ; outputs= [("b", field)]
    ; dep=None
    ; body= let prefix = "main_" in body_Main prefix ("b", "a") (Expr.tuple [(var (prefix ^ "b"))]) }


