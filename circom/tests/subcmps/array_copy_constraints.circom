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
//CHECK:      store3:
//CHECK-NEXT:   %[[SUBCMP_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[SUBCMP_INP_ARR:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[SUBCMP_PTR]]
//CHECK-NEXT:   %[[SUBCMP_INP_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %[[SUBCMP_INP_ARR]], i32 0, i32 1
//CHECK-NEXT:   %[[INP_PTR:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//
//CHECK-NEXT:   %[[COPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[INP_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SUBCMP_INP_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_0]], i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[INP_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_0]]
//CHECK-NEXT:   %[[SUBCMP_INP_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_DST_0]]
//CHECK-NEXT:   %[[CONSTRAINT_0:[0-9a-zA-Z_\.]+]] = alloca i1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[INP_0]], i256 %[[SUBCMP_INP_0]], i1* %[[CONSTRAINT_0]])
//
//CHECK-NEXT:   %[[COPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[INP_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SUBCMP_INP_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_1]], i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[INP_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_1]]
//CHECK-NEXT:   %[[SUBCMP_INP_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_DST_1]]
//CHECK-NEXT:   %[[CONSTRAINT_1:[0-9a-zA-Z_\.]+]] = alloca i1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[INP_1]], i256 %[[SUBCMP_INP_1]], i1* %[[CONSTRAINT_1]])
//
//CHECK-NEXT:   %[[COPY_SRC_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[INP_PTR]], i32 2
//CHECK-NEXT:   %[[COPY_DST_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SUBCMP_INP_PTR]], i32 2
//CHECK-NEXT:   %[[COPY_VAL_2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_2]], i256* %[[COPY_DST_2]], align 4
//CHECK-NEXT:   %[[INP_2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_2]]
//CHECK-NEXT:   %[[SUBCMP_INP_2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_DST_2]]
//CHECK-NEXT:   %[[CONSTRAINT_2:[0-9a-zA-Z_\.]+]] = alloca i1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[INP_2]], i256 %[[SUBCMP_INP_2]], i1* %[[CONSTRAINT_2]])
//
//CHECK-NEXT:   %[[COPY_SRC_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[INP_PTR]], i32 3
//CHECK-NEXT:   %[[COPY_DST_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SUBCMP_INP_PTR]], i32 3
//CHECK-NEXT:   %[[COPY_VAL_3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_3]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_3]], i256* %[[COPY_DST_3]], align 4
//CHECK-NEXT:   %[[INP_3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_3]]
//CHECK-NEXT:   %[[SUBCMP_INP_3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_DST_3]]
//CHECK-NEXT:   %[[CONSTRAINT_3:[0-9a-zA-Z_\.]+]] = alloca i1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[INP_3]], i256 %[[SUBCMP_INP_3]], i1* %[[CONSTRAINT_3]])
//
//CHECK-NEXT:   %[[COPY_SRC_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[INP_PTR]], i32 4
//CHECK-NEXT:   %[[COPY_DST_4:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[SUBCMP_INP_PTR]], i32 4
//CHECK-NEXT:   %[[COPY_VAL_4:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_4]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_4]], i256* %[[COPY_DST_4]], align 4
//CHECK-NEXT:   %[[INP_4:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_4]]
//CHECK-NEXT:   %[[SUBCMP_INP_4:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_DST_4]]
//CHECK-NEXT:   %[[CONSTRAINT_4:[0-9a-zA-Z_\.]+]] = alloca i1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[INP_4]], i256 %[[SUBCMP_INP_4]], i1* %[[CONSTRAINT_4]])
//
//CHECK:        %[[SUBCMP_PTR_B:[0-9a-zA-Z_\.]+]] = getelementptr [1 x { [0 x i256]*, i32 }], [1 x { [0 x i256]*, i32 }]* %subcmps, i32 0, i32 0, i32 0
//CHECK-NEXT:   %[[RUN_INP_ARR:[0-9a-zA-Z_\.]+]] = load [0 x i256]*, [0 x i256]** %[[SUBCMP_PTR_B]]
//CHECK-NEXT:   call void @Sum_{{[0-9]+}}_run([0 x i256]* %[[RUN_INP_ARR]])
