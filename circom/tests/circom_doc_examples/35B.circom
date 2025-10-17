// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.0.0;

template A(n) {
  signal input in;
  assert(n>0);
  in * in === n;
}

component main = A(1);
//CHECK-LABEL:  module attributes {veridise.lang = "llzk"} {
