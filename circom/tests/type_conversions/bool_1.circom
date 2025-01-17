pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function binop_comp(a, b) {
  return a > b;
}

template A(x) {
  signal input in;
  signal output out;

  out <-- binop_comp(in, x);
}

component main = A(5);

//CHECK-LABEL: define{{.*}} i256 @binop_comp_
//CHECK-SAME: [[$F_ID:[0-9a-zA-Z_\.]+]](i256* %0){{.*}} {
//CHECK: %call.fr_gt = call i1 @fr_gt(i256 %{{[0-9]+}}, i256 %{{[0-9]+}})
//CHECK: %[[RET:[0-9a-zA-Z_\.]+]] = zext i1 %call.fr_gt to i256
//CHECK: ret i256 %[[RET]]
