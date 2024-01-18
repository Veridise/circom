pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template A(x) {
  signal input in;
  signal output out;

  var z = 0;
  if (in || x) {
    z = 1;
  }
  out <-- z;
}

component main = A(99);

//CHECK-LABEL: define{{.*}} void @A_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %0)
//CHECK: branch{{[0-9]+}}:
//CHECK: %[[VAL_PTR:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK: %[[VAL:[0-9]+]] = load i256, i256* %[[VAL_PTR]]
//CHECK: %[[BOOL:[0-9]+]] = icmp ne i256 %[[VAL]], 0
//CHECK: %call.fr_logic_or = call i1 @fr_logic_or(i1 %[[BOOL]], i1 true)
//CHECK: br i1 %call.fr_logic_or, label %if.then, label %if.else
