pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s

template A(n) {
    signal input inp[n];
    signal output out[n];

    out <== inp;
}

component main = A(5);

//CHECK-LABEL: define void @A_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %0)
//CHECK: %[[INP_PTR:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK: %[[INP_PTR_DST:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 5
//CHECK: call void @fr_copy_n(i256* %[[INP_PTR_DST]], i256* %[[INP_PTR]], i32 5)

//CHECK: %[[INP_PTR_0:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 5
//CHECK: %[[INP_PTR_DST_0:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK: %[[INP_0:[0-9]+]] = load i256, i256* %[[INP_PTR_0]]
//CHECK: %[[INP_DST_0:[0-9]+]] = load i256, i256* %[[INP_PTR_DST_0]]
//CHECK: %constraint_0 = alloca i1
//CHECK: call void @__constraint_values(i256 %[[INP_0]], i256 %[[INP_DST_0]], i1* %constraint_0)

//CHECK: %[[INP_PTR_1:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 6
//CHECK: %[[INP_PTR_DST_1:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK: %[[INP_1:[0-9]+]] = load i256, i256* %[[INP_PTR_1]]
//CHECK: %[[INP_DST_1:[0-9]+]] = load i256, i256* %[[INP_PTR_DST_1]]
//CHECK: %constraint_1 = alloca i1
//CHECK: call void @__constraint_values(i256 %[[INP_1]], i256 %[[INP_DST_1]], i1* %constraint_1)

//CHECK: %[[INP_PTR_2:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 7
//CHECK: %[[INP_PTR_DST_2:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK: %[[INP_2:[0-9]+]] = load i256, i256* %[[INP_PTR_2]]
//CHECK: %[[INP_DST_2:[0-9]+]] = load i256, i256* %[[INP_PTR_DST_2]]
//CHECK: %constraint_2 = alloca i1
//CHECK: call void @__constraint_values(i256 %[[INP_2]], i256 %[[INP_DST_2]], i1* %constraint_2)

//CHECK: %[[INP_PTR_3:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 8
//CHECK: %[[INP_PTR_DST_3:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK: %[[INP_3:[0-9]+]] = load i256, i256* %[[INP_PTR_3]]
//CHECK: %[[INP_DST_3:[0-9]+]] = load i256, i256* %[[INP_PTR_DST_3]]
//CHECK: %constraint_3 = alloca i1
//CHECK: call void @__constraint_values(i256 %[[INP_3]], i256 %[[INP_DST_3]], i1* %constraint_3)

//CHECK: %[[INP_PTR_4:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 9
//CHECK: %[[INP_PTR_DST_4:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 4
//CHECK: %[[INP_4:[0-9]+]] = load i256, i256* %[[INP_PTR_4]]
//CHECK: %[[INP_DST_4:[0-9]+]] = load i256, i256* %[[INP_PTR_DST_4]]
//CHECK: %constraint_4 = alloca i1
//CHECK: call void @__constraint_values(i256 %[[INP_4]], i256 %[[INP_DST_4]], i1* %constraint_4)
