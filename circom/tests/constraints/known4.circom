pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template A() {
    signal output val;

    val <-- 0;
    0 === val;
}

component main = A();

//CHECK-LABEL: define{{.*}} void @A_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK: assert{{[0-9]+}}:{{.*}}
//CHECK:   %[[T1:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK:   %[[T2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T1]], align 4
//CHECK:   %[[T3:[0-9a-zA-Z_\.]+]] = call i1 @fr_eq(i256 0, i256 %[[T2]])
//CHECK:   %[[T4:[0-9a-zA-Z_\.]+]] = alloca i1, align 1
//CHECK:   call void @__constraint_value(i1 %[[T3]], i1* %[[T4]])
//CHECK:   br label %prologue
