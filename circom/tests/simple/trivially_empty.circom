// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

pragma circom 2.0.0;

template EmptyTemplate() {
}
component main = EmptyTemplate();
//CHECK-LABEL:  module attributes {veridise.lang = "llzk"} {
//CHECK-NEXT:     struct.def @EmptyTemplate<[]> {
//CHECK-NEXT:       function.def @compute() -> !struct.type<@EmptyTemplate<[]>> attributes {function.allow_witness} {
//CHECK-NEXT:         %[[SELF:[0-9a-zA-Z_\.]+]] = struct.new : <@EmptyTemplate<[]>>
//CHECK-NEXT:         function.return %[[SELF]] : !struct.type<@EmptyTemplate<[]>>
//CHECK-NEXT:       }
//CHECK-NEXT:       function.def @constrain(%arg0: !struct.type<@EmptyTemplate<[]>>) attributes {function.allow_constraint} {
//CHECK-NEXT:         function.return
//CHECK-NEXT:       }
//CHECK-NEXT:     }
//CHECK-NEXT:   }
