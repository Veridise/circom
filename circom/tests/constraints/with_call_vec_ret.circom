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
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %fix_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[FUN_NAME:[0-9a-zA-Z_]+]]_arena = alloca [2 x i256], align 8
//CHECK-NEXT:   %[[T00:[0-9]+]] = bitcast [2 x i256]* %[[FUN_NAME]]_arena to i256*
//CHECK-NEXT:   call void @[[FUN_NAME]](i256* %[[T00]])
//CHECK-NEXT:   %[[T01:[0-9]+]] = getelementptr i256, i256* %[[T00]], i32 0
//CHECK-NEXT:   %[[T02:[0-9]+]] = getelementptr i256, i256* %fix_0, i32 0
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T01]], i256* %[[T02]], i32 2)
//CHECK-NEXT:   %[[T03:[0-9]+]] = getelementptr i256, i256* %[[T00]], i32 0
//CHECK-NEXT:   %[[T04:[0-9]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   %[[T05:[0-9]+]] = getelementptr i256, i256* %fix_0, i32 0
//CHECK-NEXT:   %[[T06:[0-9]+]] = load i256, i256* %[[T05]], align 4
//CHECK-NEXT:   %constraint_0 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T04]], i256 %[[T06]], i1* %constraint_0)
//CHECK-NEXT:   %[[T07:[0-9]+]] = getelementptr i256, i256* %[[T00]], i32 1
//CHECK-NEXT:   %[[T08:[0-9]+]] = load i256, i256* %[[T07]], align 4
//CHECK-NEXT:   %[[T09:[0-9]+]] = getelementptr i256, i256* %fix_0, i32 1
//CHECK-NEXT:   %[[T10:[0-9]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   %constraint_1 = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %[[T08]], i256 %[[T10]], i1* %constraint_1)
//CHECK-NEXT:   br label %store2
