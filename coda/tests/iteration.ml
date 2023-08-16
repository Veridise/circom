open Ast
open Dsl
open Nice_dsl
open Expr
open Qual
open Typ
open TypRef

let body_Test2 prefix (x) output =
  elet (prefix ^ "var_0_1") (F.const (* literal *) 0) @@
  elet (prefix ^ "var_1_1") (F.const (* literal *) 1) @@
  elet (prefix ^ "var_2_1") (F.const (* literal *) 1) @@
  elet (prefix ^ "var_1_2") (F.const (* literal *) 4) @@
  elet (prefix ^ "var_2_2") (F.const (* literal *) 5) @@
  elet (prefix ^ "var_1_3") (F.const (* literal *) 6) @@
  elet (prefix ^ "var_2_3") (F.const (* literal *) 7) @@
  elet (prefix ^ "var_1_4") (F.const (* literal *) 8) @@
  elet (prefix ^ "var_2_4") (F.const (* literal *) 9) @@
  elet (prefix ^ "var_1_5") (F.const (* literal *) 10) @@
  elet (prefix ^ "var_2_5") (F.const (* literal *) 11) @@
  elet x (F.const (* literal *) 3) @@
  output

let circuit_Test2 = Circuit { name= "Test2"; inputs= []; outputs= [("x", field)]; dep=None; body= let prefix = "main_" in body_Test2 prefix ("x") (Expr.tuple ["x"]) }


