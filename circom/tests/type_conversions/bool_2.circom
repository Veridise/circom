pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function binop_bool(a, b) {
  return a || b;
}

template A(x) {
  signal input in;
  signal output out;

  var temp;
  if (binop_bool(in, x)) {
    temp = 1;
  } else {
    temp = 0;
  }
  out <-- temp;

  //Essentially equivalent code:
  // out <-- binop_bool(in, x);
}

component main = A(555);

//CHECK-LABEL: define{{.*}} i256 @binop_bool_
//CHECK-SAME: [[$F_ID:[0-9a-zA-Z_\.]+]](i256* %0){{.*}} {
//CHECK: %call.fr_logic_or = call i1 @fr_logic_or(i1 %{{[0-9]+}}, i1 %{{[0-9]+}})
//CHECK: %[[RET:[0-9a-zA-Z_\.]+]] = zext i1 %call.fr_logic_or to i256
//CHECK: ret i256 %[[RET]]
