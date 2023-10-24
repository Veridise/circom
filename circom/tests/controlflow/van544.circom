pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s

template Conditional() {
    signal input inp;
    var q;
    if (inp) {
        q = 0;
    } else {
        q = 1;
    }
}

component main = Conditional();

//CHECK-LABEL: define{{.*}} void @Conditional_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %0)
//CHECK: %[[INP_PTR:.*]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK: %[[INP:.*]] = load i256, i256* %2
//CHECK: %[[COND:.*]] = icmp ne i256 %[[INP]], 0
//CHECK: br i1 %[[COND]], label %if.then, label %if.else
