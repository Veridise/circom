open Ast
open Dsl
open Nice_dsl
open Expr
open Qual
open Typ
open TypRef

let body_Main (y, x) body =
    elet "var_0_1" (F.const 0) @@
    elet "var_0_2" (var x) @@
    elet "var_0_3" F.((var "var_0_2") + (F.const 1)) @@
    elet "var_0_4" F.((var "var_0_3") + (F.const 1)) @@
    elet "var_0_5" F.((var "var_0_4") + (F.const 1)) @@
    elet "var_0_6" F.((var "var_0_5") + (F.const 1)) @@
    elet y (var "var_0_6") @@
    body

let circuit_Main = Circuit { name= "Main"; inputs= [("x", field)]; outputs= [("y", field)]; dep=None; body= body_Main ("y", "x") (Expr.tuple [(var "y")]) }
