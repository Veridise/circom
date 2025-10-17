// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.0.0;

template right(N1,N2){
    signal input in;
    var x = 2;
    var t = 5;
    if(N1 > N2){
      t = 2;
    }
    x === t;
}

component main = right(10, 5);
// CHECK: TODO
