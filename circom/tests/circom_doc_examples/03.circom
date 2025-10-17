// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.0.0;

template A(N){
   signal input in;
   signal output out;
   out <== in;
}
template C(N){
   signal output out;
   out <== N;
}
template B(N){
  signal output out;
  component a;
  if(N > 0){
     a = A(N);
  }
  else{
     a = A(0);
  }
  a.in <== 1;
  a.out ==> out;
}

component main = B(1);
// CHECK: TODO
