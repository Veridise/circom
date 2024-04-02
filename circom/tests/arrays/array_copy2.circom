pragma circom 2.0.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// Vector copy version of `array2.circom` test. Output is identical except for basic blocks.
template Array2(n) {
    signal input inp[n];
    signal output out[n];

    out <== inp;
}

component main = Array2(5);

//CHECK-LABEL: define{{.*}} void @Array2_{{[0-9]+}}_run
//CHECK-SAME: ([0 x i256]* %[[ARG:[0-9a-zA-Z_.]+]]){{.*}} {
//CHECK:      store2:
//CHECK-NEXT:   %[[PTR_DST:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   %[[PTR_SRC:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 5
//CHECK-NEXT:   %[[COPY_SRC_0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_SRC]], i32 0
//CHECK-NEXT:   %[[COPY_DST_0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_DST]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_0:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_0]], i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[COPY_VAL_0]]1 = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   %4 = load i256, i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[CONSTRAINT_1:[0-9a-zA-Z_.]+]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[COPY_VAL_0]]1, i256 %4, i1* %[[CONSTRAINT_1]])
//CHECK-NEXT:   %[[COPY_SRC_1:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_SRC]], i32 1
//CHECK-NEXT:   %[[COPY_DST_1:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_DST]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_1:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_1]], i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[COPY_VAL_1]]2 = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   %5 = load i256, i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[CONSTRAINT_3:[0-9a-zA-Z_.]+]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[COPY_VAL_1]]2, i256 %5, i1* %[[CONSTRAINT_3]])
//CHECK-NEXT:   %[[COPY_SRC_2:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_SRC]], i32 2
//CHECK-NEXT:   %[[COPY_DST_2:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_DST]], i32 2
//CHECK-NEXT:   %[[COPY_VAL_2:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_2]], i256* %[[COPY_DST_2]], align 4
//CHECK-NEXT:   %[[COPY_VAL_2]]4 = load i256, i256* %[[COPY_SRC_2]], align 4
//CHECK-NEXT:   %6 = load i256, i256* %[[COPY_DST_2]], align 4
//CHECK-NEXT:   %[[CONSTRAINT_5:[0-9a-zA-Z_.]+]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[COPY_VAL_2]]4, i256 %6, i1* %[[CONSTRAINT_5]])
//CHECK-NEXT:   %[[COPY_SRC_3:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_SRC]], i32 3
//CHECK-NEXT:   %[[COPY_DST_3:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_DST]], i32 3
//CHECK-NEXT:   %[[COPY_VAL_3:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_3]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_3]], i256* %[[COPY_DST_3]], align 4
//CHECK-NEXT:   %[[COPY_VAL_3]]6 = load i256, i256* %[[COPY_SRC_3]], align 4
//CHECK-NEXT:   %7 = load i256, i256* %[[COPY_DST_3]], align 4
//CHECK-NEXT:   %[[CONSTRAINT_7:[0-9a-zA-Z_.]+]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[COPY_VAL_3]]6, i256 %7, i1* %[[CONSTRAINT_7]])
//CHECK-NEXT:   %[[COPY_SRC_4:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_SRC]], i32 4
//CHECK-NEXT:   %[[COPY_DST_4:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[PTR_DST]], i32 4
//CHECK-NEXT:   %[[COPY_VAL_4:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_4]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_4]], i256* %[[COPY_DST_4]], align 4
//CHECK-NEXT:   %[[COPY_VAL_4]]8 = load i256, i256* %[[COPY_SRC_4]], align 4
//CHECK-NEXT:   %8 = load i256, i256* %[[COPY_DST_4]], align 4
//CHECK-NEXT:   %[[CONSTRAINT_9:[0-9a-zA-Z_.]+]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[COPY_VAL_4]]8, i256 %8, i1* %[[CONSTRAINT_9]])
//CHECK-NEXT:   br label %prologue
