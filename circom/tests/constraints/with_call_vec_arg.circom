pragma circom 2.0.0;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

//NOTE: Tests Call case inside of ConstraintBucket::Substitution during LLVM IR generation.
function feeShiftTable(out, i) {
    return out[i];
}

template ComputeFee() {
    signal output feeOut[2];
    var temp[2][2] = [[3,9],[6,7]];

    for (var i = 0; i < 2; i++) {
        feeOut[i] <== feeShiftTable(temp[i], i);
    }
}

component main = ComputeFee();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0, i256* %var_1){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[FUN_NAME:[0-9a-zA-Z_]+]]_arena = alloca [3 x i256], align 8
//CHECK-NEXT:   %[[T0:[0-9]+]] = getelementptr [3 x i256], [3 x i256]* %[[FUN_NAME]]_arena, i32 0, i32 0
//CHECK-NEXT:   %[[T1:[0-9]+]] = getelementptr i256, i256* %var_1, i32 0
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T1]], i256* %[[T0]], i32 2)
//CHECK-NEXT:   %[[T2:[0-9]+]] = getelementptr [3 x i256], [3 x i256]* %[[FUN_NAME]]_arena, i32 0, i32 2
//CHECK-NEXT:   %[[T3:[0-9]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 8
//CHECK-NEXT:   %[[T4:[0-9]+]] = load i256, i256* %[[T3]], align 4
//CHECK-NEXT:   store i256 %[[T4]], i256* %[[T2]], align 4
//CHECK-NEXT:   %[[T5:[0-9]+]] = bitcast [3 x i256]* %[[FUN_NAME]]_arena to i256*
//CHECK-NEXT:   %call.[[FUN_NAME]] = call i256 @[[FUN_NAME]](i256* %[[T5]])
//CHECK-NEXT:   %[[T6:[0-9]+]] = getelementptr i256, i256* %sig_0, i32 0
//CHECK-NEXT:   store i256 %call.[[FUN_NAME]], i256* %[[T6]], align 4
//CHECK-NEXT:   %[[T7:[0-9]+]] = load i256, i256* %[[T6]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %call.[[FUN_NAME]], i256 %[[T7]], i1* %constraint)
//CHECK-NEXT:   br label %store2
