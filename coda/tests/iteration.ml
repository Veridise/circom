open Ast
open Dsl
open Nice_dsl
open Expr
open Qual
open Typ
open TypRef

let body_Test2 prefix (x) output =
  elet (prefix ^ "var_0_1") (F.const (* index *) 4) @@
  elet (prefix ^ "var_1_1") (F.const (* index *) 0) @@
  elet (prefix ^ "var_2_1") (F.const (* index *) 0) @@
  elet (prefix ^ "var_1_2") (F.const (* index *) 666) @@
  elet (prefix ^ "var_2_2") (F.const (* index *) 666) @@
  elet (prefix ^ "var_1_3") (F.const (* index *) 666) @@
  elet (prefix ^ "var_2_3") (F.const (* index *) 666) @@
  elet (prefix ^ "var_1_4") (F.const (* index *) 666) @@
  elet (prefix ^ "var_2_4") (F.const (* index *) 666) @@
  elet (prefix ^ "var_1_5") (F.const (* index *) 666) @@
  elet (prefix ^ "var_2_5") (F.const (* index *) 666) @@
  elet x (F.const (* index *) 6) @@
  output

let circuit_Test2 = Circuit { name= "Test2"; inputs= []; outputs= [("x", field)]; dep=None; body= let prefix = "main_" in body_Test2 prefix ("x") (Expr.tuple ["x"]) }


