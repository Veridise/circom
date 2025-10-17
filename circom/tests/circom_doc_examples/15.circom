// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.0.0;

template mult(){
  signal input in[2];
  signal output out;
  out <== in[0] * in[1];
}

template mult4(){
  signal input in[4];
  component comp1 = mult();
  component comp2 = mult();
  comp1.in[0] <== in[0];
  comp2.in[0] <== in[1];
  comp2.in[1] <== in[2];
  comp1.in[1] <== in[3];
}

component main = mult4();
//CHECK-LABEL:  module attributes {veridise.lang = "llzk"} {
