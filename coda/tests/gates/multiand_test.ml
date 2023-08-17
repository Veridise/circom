open Ast
open Dsl
open Nice_dsl
open Expr
open Qual
open Typ
open TypRef

let body_AND prefix (out, a, b) output = elet out F.((var a) * (var b)) @@
     output

let circuit_AND = Circuit { name= "AND"; inputs= [("a", field); ("b", field)]; outputs= [("out", field)]; dep=None; body= let prefix = "main_" in body_AND prefix ("out", "a", "b") (Expr.tuple [(var (prefix ^ "out"))]) }


let body_MultiAND prefix (out, in_0, in_1) output = elet (prefix ^ "var_0_1") (F.const 2) @@
     elet "and1_0_a" (var in_0) @@
     elet "and1_0_b" (var in_1) @@
     body_AND (prefix ^ "sc0_") ("and1_0_out", "and1_0_a", "and1_0_b") @@
     elet out (var "and1_0_out") @@
     output

let circuit_MultiAND = Circuit { name= "MultiAND"; inputs= [("in_0", field); ("in_1", field)]; outputs= [("out", field)]; dep=None; body= let prefix = "main_" in body_MultiAND prefix ("out", "in_0", "in_1") (Expr.tuple [(var (prefix ^ "out"))]) }
