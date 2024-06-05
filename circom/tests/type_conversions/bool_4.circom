pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

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

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %var_0, i256* %var_1, i256* %var_2){{.*}} {
//CHECK: %call.fr_logic_or = call i1 @fr_logic_or(i1 %{{[0-9]+}}, i1 %{{[0-9]+}})
//CHECK: %[[VAL:[0-9]+]] = zext i1 %call.fr_logic_or to i256
//CHECK: store i256 %[[VAL]], i256* %{{[0-9]+}}

//CHECK-LABEL: define{{.*}} i256* @binop_bool_array_
//CHECK-SAME: [[$F_ID_2:[0-9]+]](i256* %0){{.*}} {
//CHECK-COUNT-10: call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %{{[0-9]+}}, [0 x i256]* null, i256* %{{[0-9]+}}, i256* %{{[0-9]+}}, i256* %{{[0-9]+}})

//CHECK-LABEL: define{{.*}} void @A_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK: %[[CV_1:[0-9a-zA-Z_.]+]] = call i256* @binop_bool_array_[[$F_ID_2]](i256* %{{[0-9]+}})
