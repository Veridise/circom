pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s

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

//CHECK-LABEL: define void @Caller_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %0)
//CHECK: store{{[0-9]+}}: ; preds = %create_cmp{{[0-9]+}}
//CHECK: %[[SUBCMP_PTR:[0-9]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK: %[[SUBCMP_INP_ARR:[0-9]+]] = load [0 x i256]*, [0 x i256]** %[[SUBCMP_PTR]]
//CHECK: %[[SUBCMP_INP_PTR:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP_INP_ARR]], i32 0, i32 1
//CHECK: %[[INP_PTR:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK: call void @fr_copy_n(i256* %[[INP_PTR]], i256* %[[SUBCMP_INP_PTR]], i32 5)
//CHECK: %decrement.counter = sub i32 %load.subcmp.counter, 5
//CHECK: call void @Sum_{{[0-9]+}}_run([0 x i256]* %{{[0-9]+}})

//CHECK: %[[INP_PTR_0:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK: %[[SUBCMP_INP_PTR_0:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP_INP_ARR]], i32 0, i32 1
//CHECK: %[[INP_0:[0-9]+]] = load i256, i256* %[[INP_PTR_0]]
//CHECK: %[[SUBCMP_INP_0:[0-9]+]] = load i256, i256* %[[SUBCMP_INP_PTR_0]]
//CHECK: %constraint_0 = alloca i1
//CHECK: call void @__constraint_values(i256 %[[INP_0]], i256 %[[SUBCMP_INP_0]], i1* %constraint_0)

//CHECK: %[[INP_PTR_1:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 1
//CHECK: %[[SUBCMP_INP_PTR_1:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP_INP_ARR]], i32 0, i32 2
//CHECK: %[[INP_1:[0-9]+]] = load i256, i256* %[[INP_PTR_1]]
//CHECK: %[[SUBCMP_INP_1:[0-9]+]] = load i256, i256* %[[SUBCMP_INP_PTR_1]]
//CHECK: %constraint_1 = alloca i1
//CHECK: call void @__constraint_values(i256 %[[INP_1]], i256 %[[SUBCMP_INP_1]], i1* %constraint_1)

//CHECK: %[[INP_PTR_2:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 2
//CHECK: %[[SUBCMP_INP_PTR_2:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP_INP_ARR]], i32 0, i32 3
//CHECK: %[[INP_2:[0-9]+]] = load i256, i256* %[[INP_PTR_2]]
//CHECK: %[[SUBCMP_INP_2:[0-9]+]] = load i256, i256* %[[SUBCMP_INP_PTR_2]]
//CHECK: %constraint_2 = alloca i1
//CHECK: call void @__constraint_values(i256 %[[INP_2]], i256 %[[SUBCMP_INP_2]], i1* %constraint_2)

//CHECK: %[[INP_PTR_3:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 3
//CHECK: %[[SUBCMP_INP_PTR_3:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP_INP_ARR]], i32 0, i32 4
//CHECK: %[[INP_3:[0-9]+]] = load i256, i256* %[[INP_PTR_3]]
//CHECK: %[[SUBCMP_INP_3:[0-9]+]] = load i256, i256* %[[SUBCMP_INP_PTR_3]]
//CHECK: %constraint_3 = alloca i1
//CHECK: call void @__constraint_values(i256 %[[INP_3]], i256 %[[SUBCMP_INP_3]], i1* %constraint_3)

//CHECK: %[[INP_PTR_4:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 4
//CHECK: %[[SUBCMP_INP_PTR_4:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP_INP_ARR]], i32 0, i32 5
//CHECK: %[[INP_4:[0-9]+]] = load i256, i256* %[[INP_PTR_4]]
//CHECK: %[[SUBCMP_INP_4:[0-9]+]] = load i256, i256* %[[SUBCMP_INP_PTR_4]]
//CHECK: %constraint_4 = alloca i1
//CHECK: call void @__constraint_values(i256 %[[INP_4]], i256 %[[SUBCMP_INP_4]], i1* %constraint_4)
