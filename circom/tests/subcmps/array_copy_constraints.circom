pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

template Sum(n) {
    signal input inp[n];
    signal output outp;

    var acc = 0;
    for (var i = 0; i < n; i++) {
        acc += inp[i];
    }

    outp <== acc;
}

template Caller(n) {
    signal input inp[n];
    signal outp;

    component op = Sum(n);
    op.inp <== inp;

    outp <== op.outp;
}

component main = Caller(5);

//CHECK-LABEL: define{{.*}} void @Caller_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {

//CHECK: %[[SUBCMP_PTR_A:[0-9]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT: %[[SUBCMP_INP_ARR:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[SUBCMP_PTR_A]]
//CHECK-NEXT: %[[SUBCMP_INP_PTR:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP_INP_ARR]], i32 0, i32 1
//CHECK-NEXT: %[[INP_PTR:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT: call void @fr_copy_n(i256* %[[INP_PTR]], i256* %[[SUBCMP_INP_PTR]], i32 5)

//CHECK: %[[SUBCMP_PTR_B:[0-9]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT: %[[RUN_INP_ARR:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[SUBCMP_PTR_B]]
//CHECK-NEXT: call void @Sum_{{[0-9]+}}_run([0 x i256]* %[[RUN_INP_ARR]])

//CHECK-NEXT: %[[INP_PTR_0:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT: %[[INP_0:[0-9]+]] = load i256, i256* %[[INP_PTR_0]]
//CHECK-NEXT: %[[SUBCMP_INP_PTR_0:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP_INP_ARR]], i32 0, i32 1
//CHECK-NEXT: %[[SUBCMP_INP_0:[0-9]+]] = load i256, i256* %[[SUBCMP_INP_PTR_0]]
//CHECK-NEXT: %constraint_0 = alloca i1
//CHECK-NEXT: call void @__constraint_values(i256 %[[INP_0]], i256 %[[SUBCMP_INP_0]], i1* %constraint_0)

//CHECK-NEXT: %[[INP_PTR_1:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK-NEXT: %[[INP_1:[0-9]+]] = load i256, i256* %[[INP_PTR_1]]
//CHECK-NEXT: %[[SUBCMP_INP_PTR_1:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP_INP_ARR]], i32 0, i32 2
//CHECK-NEXT: %[[SUBCMP_INP_1:[0-9]+]] = load i256, i256* %[[SUBCMP_INP_PTR_1]]
//CHECK-NEXT: %constraint_1 = alloca i1
//CHECK-NEXT: call void @__constraint_values(i256 %[[INP_1]], i256 %[[SUBCMP_INP_1]], i1* %constraint_1)

//CHECK-NEXT: %[[INP_PTR_2:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK-NEXT: %[[INP_2:[0-9]+]] = load i256, i256* %[[INP_PTR_2]]
//CHECK-NEXT: %[[SUBCMP_INP_PTR_2:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP_INP_ARR]], i32 0, i32 3
//CHECK-NEXT: %[[SUBCMP_INP_2:[0-9]+]] = load i256, i256* %[[SUBCMP_INP_PTR_2]]
//CHECK-NEXT: %constraint_2 = alloca i1
//CHECK-NEXT: call void @__constraint_values(i256 %[[INP_2]], i256 %[[SUBCMP_INP_2]], i1* %constraint_2)

//CHECK-NEXT: %[[INP_PTR_3:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK-NEXT: %[[INP_3:[0-9]+]] = load i256, i256* %[[INP_PTR_3]]
//CHECK-NEXT: %[[SUBCMP_INP_PTR_3:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP_INP_ARR]], i32 0, i32 4
//CHECK-NEXT: %[[SUBCMP_INP_3:[0-9]+]] = load i256, i256* %[[SUBCMP_INP_PTR_3]]
//CHECK-NEXT: %constraint_3 = alloca i1
//CHECK-NEXT: call void @__constraint_values(i256 %[[INP_3]], i256 %[[SUBCMP_INP_3]], i1* %constraint_3)

//CHECK-NEXT: %[[INP_PTR_4:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 4
//CHECK-NEXT: %[[INP_4:[0-9]+]] = load i256, i256* %[[INP_PTR_4]]
//CHECK-NEXT: %[[SUBCMP_INP_PTR_4:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP_INP_ARR]], i32 0, i32 5
//CHECK-NEXT: %[[SUBCMP_INP_4:[0-9]+]] = load i256, i256* %[[SUBCMP_INP_PTR_4]]
//CHECK-NEXT: %constraint_4 = alloca i1
//CHECK-NEXT: call void @__constraint_values(i256 %[[INP_4]], i256 %[[SUBCMP_INP_4]], i1* %constraint_4)
