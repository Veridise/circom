// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.0.0;

template Translate(n) {
  signal input in;  
  assert(in<=254);
}

component main = Translate(1);
//CHECK-LABEL:  module attributes {veridise.lang = "llzk"} {
