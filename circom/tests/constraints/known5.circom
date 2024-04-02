pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template A() {
    signal output valA;
    signal output valB;

    valA <-- 0;
    valB <== valA * 1;
}

component main = A();

//CHECK-LABEL: define{{.*}} void @A_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK: store{{[0-9]+}}:{{.*}}
//CHECK: store{{[0-9]+}}:{{.*}}
//CHECK:   %[[T4:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK:   %[[T1:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK:   %[[T2:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T1]], align 4
//CHECK:   %[[T3:[0-9a-zA-Z_.]+]] = call i256 @fr_mul(i256 %[[T2]], i256 1)
//CHECK:   store i256 %[[T3]], i256* %[[T4]], align 4
//CHECK:   %[[T5:[0-9a-zA-Z_.]+]] = load i256, i256* %[[T4]], align 4
//CHECK:   %constraint = alloca i1, align 1
//CHECK:   call void @__constraint_values(i256 %[[T3]], i256 %[[T5]], i1* %constraint)
//CHECK:   br label %prologue
