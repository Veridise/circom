pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template EmptyTemplate() {
}
component main = EmptyTemplate();

//CHECK-LABEL:  module attributes {veridise.lang = "llzk"} {
//CHECK-NEXT:   }
