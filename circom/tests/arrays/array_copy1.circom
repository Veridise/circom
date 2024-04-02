pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Vector copy version of `array1.circom` test. Output is identical except for basic blocks.
template Array1(n, S) {
    signal output out[n];

    out <== S;
}

component main = Array1(5, [11,22,33,44,55]);

//CHECK-LABEL: define{{.*}} void @..generated..array.param.{{[0-9]+}}([0 x i256]* %lvars){{.*}} {
//CHECK-NEXT: ..generated..array.param.[[$F_ID_1:[0-9a-zA-Z_.]+]]:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   store i256 11, i256* %[[T00]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY:
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 1
//CHECK-NEXT:   store i256 22, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY:
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   store i256 33, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY:
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 3
//CHECK-NEXT:   store i256 44, i256* %[[T03]], align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY:
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 55, i256* %[[T04]], align 4
//CHECK-NEXT:   br label %return6
//CHECK-EMPTY:
//CHECK-NEXT: return6:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }

//CHECK-LABEL: define{{.*}} void @Array1_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9a-zA-Z_.]+]]){{.*}} {
//CHECK:      store3:
//CHECK-NEXT:   %[[PTR_DST:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[PTR_SRC:[0-9a-zA-Z_.]+]] = getelementptr [6 x i256], [6 x i256]* %lvars, i32 0, i32 0
//
//CHECK-NEXT:   %[[COPY_SRC_0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_SRC]], i32 0
//CHECK-NEXT:   %[[COPY_DST_0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_DST]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_0:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_0]], i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[INP_0:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_0]]
//CHECK-NEXT:   %[[INP_DST_0:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_DST_0]]
//CHECK-NEXT:   %[[CONSTRAINT_0:[0-9a-zA-Z_.]+]] = alloca i1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[INP_0]], i256 %[[INP_DST_0]], i1* %[[CONSTRAINT_0]])
//
//CHECK-NEXT:   %[[COPY_SRC_1:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_SRC]], i32 1
//CHECK-NEXT:   %[[COPY_DST_1:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_DST]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_1:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_1]], i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[INP_1:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_1]]
//CHECK-NEXT:   %[[INP_DST_1:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_DST_1]]
//CHECK-NEXT:   %[[CONSTRAINT_1:[0-9a-zA-Z_.]+]] = alloca i1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[INP_1]], i256 %[[INP_DST_1]], i1* %[[CONSTRAINT_1]])
//
//CHECK-NEXT:   %[[COPY_SRC_2:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_SRC]], i32 2
//CHECK-NEXT:   %[[COPY_DST_2:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_DST]], i32 2
//CHECK-NEXT:   %[[COPY_VAL_2:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_2]], i256* %[[COPY_DST_2]], align 4
//CHECK-NEXT:   %[[INP_2:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_2]]
//CHECK-NEXT:   %[[INP_DST_2:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_DST_2]]
//CHECK-NEXT:   %[[CONSTRAINT_2:[0-9a-zA-Z_.]+]] = alloca i1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[INP_2]], i256 %[[INP_DST_2]], i1* %[[CONSTRAINT_2]])
//
//CHECK-NEXT:   %[[COPY_SRC_3:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_SRC]], i32 3
//CHECK-NEXT:   %[[COPY_DST_3:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_DST]], i32 3
//CHECK-NEXT:   %[[COPY_VAL_3:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_3]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_3]], i256* %[[COPY_DST_3]], align 4
//CHECK-NEXT:   %[[INP_3:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_3]]
//CHECK-NEXT:   %[[INP_DST_3:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_DST_3]]
//CHECK-NEXT:   %[[CONSTRAINT_3:[0-9a-zA-Z_.]+]] = alloca i1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[INP_3]], i256 %[[INP_DST_3]], i1* %[[CONSTRAINT_3]])
//
//CHECK-NEXT:   %[[COPY_SRC_4:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_SRC]], i32 4
//CHECK-NEXT:   %[[COPY_DST_4:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_DST]], i32 4
//CHECK-NEXT:   %[[COPY_VAL_4:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_4]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_4]], i256* %[[COPY_DST_4]], align 4
//CHECK-NEXT:   %[[INP_4:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_4]]
//CHECK-NEXT:   %[[INP_DST_4:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_DST_4]]
//CHECK-NEXT:   %[[CONSTRAINT_4:[0-9a-zA-Z_.]+]] = alloca i1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[INP_4]], i256 %[[INP_DST_4]], i1* %[[CONSTRAINT_4]])
//
//CHECK-NEXT:   br label %prologue