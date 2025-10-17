// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.0.0;

template fun(N){
  signal output out;
  out <== N;
}

template all(N){
  component c[N];
  for(var i = 0; i < N; i++){
     c[i] = fun(i);
  }
}

component main = all(5);
// CHECK: TODO
