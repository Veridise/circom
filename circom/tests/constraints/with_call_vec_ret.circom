pragma circom 2.0.0;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

//NOTE: Tests Call case inside of ConstraintBucket::Substitution during LLVM IR generation.
function feeShiftTable() {
    var out[2] = [3,9];
    return out;
}

template ComputeFee() {
    signal output feeOut[3][2];

    for (var i = 0; i < 3; i++) {
        feeOut[i] <== feeShiftTable();
    }
}

component main = ComputeFee();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[FUN_NAME:[0-9a-zA-Z_.]+]]_arena = alloca [2 x i256], align 8
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_.]+]] = bitcast [2 x i256]* %[[FUN_NAME]]_arena to i256*
//CHECK-NEXT:   %[[SRC_PTR:[0-9a-zA-Z_.]+]] = call i256* @[[FUN_NAME]](i256* %[[T00]])
//CHECK-NEXT:   %[[DST_PTR:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %sig_0, i32 0
//
//CHECK-NEXT:   %[[COPY_SRC_0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_DST_0:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_0:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_0]], i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[CONSTRAINT_0:[0-9a-zA-Z_.]+]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T04]], i256 %[[T06]], i1* %[[CONSTRAINT_0]])
//
//CHECK-NEXT:   %[[COPY_SRC_1:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[SRC_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_DST_1:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %[[DST_PTR]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_1:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_1]], i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_.]+]] = load i256, i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[CONSTRAINT_1:[0-9a-zA-Z_.]+]] = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T08]], i256 %[[T10]], i1* %[[CONSTRAINT_1]])
//
//CHECK-NEXT:   br label %store2
