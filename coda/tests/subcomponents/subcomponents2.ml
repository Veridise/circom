open Ast
open Dsl
open Nice_dsl
open Expr
open Qual
open Typ
open TypRef

let body_A prefix (y, x) output =
    elet y (var x) @@
    output

let circuit_A = Circuit { name= "A"; inputs= [("x", field)]; outputs= [("y", field)]; dep=None; body= let prefix = "main" in body_A prefix ("y", "x") (Expr.tuple [(var (prefix ^ "y"))]) }


let body_Main prefix (y_0, y_1, y_2, y_3, x_0, x_1, x_2, x_3) output =
    elet (prefix ^ "var_0_1") (F.const 4) @@
    elet (prefix ^ "var_1_1") (F.const 0) @@
    elet "a_0_x" (var x_0) @@
    body_A (prefix ^ "sc0_") ("a_0_y", "a_0_x") @@
    elet y_0 (var "a_0_y") @@
    elet (prefix ^ "var_1_2") (F.const 0) @@
    elet "a_1_x" (var x_1) @@
    body_A (prefix ^ "sc1_") ("a_1_y", "a_1_x") @@
    elet y_1 (var "a_1_y") @@
    elet (prefix ^ "var_1_3") (F.const 0) @@
    elet "a_2_x" (var x_2) @@
    body_A (prefix ^ "sc2_") ("a_2_y", "a_2_x") @@
    elet y_2 (var "a_2_y") @@
    elet (prefix ^ "var_1_4") (F.const 0) @@
    elet "a_3_x" (var x_3) @@
    body_A (prefix ^ "sc3_") ("a_3_y", "a_3_x") @@
    elet y_3 (var "a_3_y") @@
    elet (prefix ^ "var_1_5") (F.const 0) @@
    output

let circuit_Main = Circuit {
    name= "Main";
    inputs= [("x_0", field); ("x_1", field); ("x_2", field); ("x_3", field)];
    outputs= [("y_0", field); ("y_1", field); ("y_2", field); ("y_3", field)];
    dep=None;
    body=
        let prefix = "main" in
        body_Main
            prefix
            ("y_0", "y_1", "y_2", "y_3", "x_0", "x_1", "x_2", "x_3") (Expr.tuple [(var (prefix ^ "y_0")); (var (prefix ^ "y_1")); (var (prefix ^ "y_2")); (var (prefix ^ "y_3"))])
}
