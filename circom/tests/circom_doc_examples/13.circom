// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.0.0;

template right(N){
    signal input in;
    var x = 2;
    var t = 5;
    if(in > N){
      t = 2;
    }
}

component main = right(10);
// CHECK: TODO
