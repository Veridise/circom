pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck --enable-var-scope %s

function binop_bool_array(a, b) {
  var arr[10];
  for (var i = 0; i < 10; i++) {
    arr[i] = a[i] || b[i];
  }
  return arr;
}

template A() {
  signal input in1[10];
  signal input in2[10];
  signal output out[10];

  out <-- binop_bool_array(in1, in2);
}

component main = A();

//CHECK-LABEL: define{{.*}} void @binop_bool_array_{{[0-9]+}}
//CHECK-SAME: (i256* %0)
//CHECK: %call.fr_logic_or = call i1 @fr_logic_or(i1 %{{[0-9]+}}, i1 %{{[0-9]+}})
//CHECK: %[[VAL:[0-9]+]] = zext i1 %call.fr_logic_or to i256
//CHECK: store i256 %[[VAL]], i256* %{{[0-9]+}}