// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llzk -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope
// XFAIL:.*

pragma circom 2.1.0;

template Ex(n, m){ 
   signal input in[n];
   signal output out[m];
   var i = 0;
   while(i < n) { 
      out[i] <== in[i];
      i += 1;
   }
}

template A{
   signal input inp[4];
   signal output out[4];
   component anon = Ex(4,4);
   var i = 0;
   while(i < 4){ 
      anon.in[i] <== inp[i];
      i += 1;
   }
   i = 0;
   while(i < 4){
      out[i] <== anon.out[i];
      i += 1;
   }
}
component main = A();
// CHECK: TODO
