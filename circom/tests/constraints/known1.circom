pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template A() {
    signal output val;

    val <-- 0;
    val * (val - 1) === 0;
}

component main = A();

//CHECK-LABEL: define{{.*}} void @A_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK: assert{{[0-9]+}}:{{.*}}
//CHECK:   %[[T1:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK:   %[[T2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T1]], align 4
//CHECK:   %[[T3:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK:   %[[T4:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T3]], align 4
//CHECK:   %[[T5:[0-9a-zA-Z_\.]+]] = call i256 @fr_sub(i256 %[[T4]], i256 1)
//CHECK:   %[[T6:[0-9a-zA-Z_\.]+]] = call i256 @fr_mul(i256 %[[T2]], i256 %[[T5]])
//CHECK:   %[[T7:[0-9a-zA-Z_\.]+]] = call i1 @fr_eq(i256 %[[T6]], i256 0)
//CHECK:   %[[T8:[0-9a-zA-Z_\.]+]] = alloca i1, align 1
//CHECK:   call void @__constraint_value(i1 %[[T7]], i1* %[[T8]])
//CHECK:   br label %prologue
