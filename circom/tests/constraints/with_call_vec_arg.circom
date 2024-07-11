pragma circom 2.0.0;

// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

// NOTE: Tests Call case inside of ConstraintBucket::Substitution during LLVM IR generation.

// %0 = [ a[0], a[1], i ]
function feeShiftTable(a, i) {
    return a[i];
}

// %0 (i.e. signal arena) = [ feeOut[0], feeOut[1] ]
// %lvars =  [ temp[0][0], temp[0][1], temp[1][0], temp[1][1], 3, 9, 6, 7, i ]
// %subcmps = []
template ComputeFee() {
    signal output feeOut[2];
    var temp[2][2] = [[3,9],[6,7]];

    for (var i = 0; i < 2; i++) {
        feeOut[i] <== feeShiftTable(temp[i], i);
    }
}

component main = ComputeFee();

//CHECK-LABEL: define{{.*}} void @..generated..loop.body.
//CHECK-SAME: [[$F_ID_1:[0-9]+]]([0 x i256]* %lvars, [0 x i256]* %signals, i256* %sig_0){{.*}} {
//CHECK-NEXT: ..generated..loop.body.[[$F_ID_1]]:
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY: 
//CHECK-NEXT: call1:
//CHECK-NEXT:   %[[FUN_NAME:[0-9a-zA-Z_\.]+]]_arena = alloca [3 x i256], align 8
//CHECK-NEXT:   %[[T00:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %[[FUN_NAME]]_arena, i32 0, i32 0
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 8
//CHECK-NEXT:   %[[T12:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T13:[0-9a-zA-Z_\.]+]] = call i32 @fr_cast_to_addr(i256 %[[T12]])
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = mul i32 2, %[[T13]]
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = add i32 %[[T14]], 0
//CHECK-NEXT:   %[[T16:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 %[[T15]]
//CHECK-NEXT:   %[[COPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T16]], i32 0
//CHECK-NEXT:   %[[COPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_0]], i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[COPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T16]], i32 1
//CHECK-NEXT:   %[[COPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T00]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_1]], i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [3 x i256], [3 x i256]* %[[FUN_NAME]]_arena, i32 0, i32 2
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 8
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T03]], align 4
//CHECK-NEXT:   store i256 %[[T04]], i256* %[[T02]], align 4
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = bitcast [3 x i256]* %[[FUN_NAME]]_arena to i256*
//CHECK-NEXT:   %call.[[FUN_NAME]] = call i256 @[[FUN_NAME]](i256* %[[T05]])
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %sig_0, i32 0
//CHECK-NEXT:   store i256 %call.[[FUN_NAME]], i256* %[[T06]], align 4
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   %constraint = alloca i1, align 1
//CHECK-NEXT:   call void @__constraint_values(i256 %call.[[FUN_NAME]], i256 %[[T07]], i1* %constraint)
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 8
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %lvars, i32 0, i32 8
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T09]], align 4
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = call i256 @fr_add(i256 %[[T10]], i256 1)
//CHECK-NEXT:   store i256 %[[T11]], i256* %[[T08]], align 4
//CHECK-NEXT:   br label %return3
//CHECK-EMPTY: 
//CHECK-NEXT: return3:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} i256 @feeShiftTable_{{[0-9]+}}(i256* %0){{.*}} {
//CHECK-NEXT: feeShiftTable_0:
//CHECK-NEXT:   br label %return1
//CHECK-EMPTY: 
//CHECK-NEXT: return1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 2
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T01]], align 4
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = call i32 @fr_cast_to_addr(i256 %[[T02]])
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = mul i32 1, %[[T03]]
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = add i32 %[[T04]], 0
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %0, i32 %[[T05]]
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[T06]], align 4
//CHECK-NEXT:   ret i256 %[[T07]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @ComputeFee_{{[0-9]+}}_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [9 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY: 
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_\.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   store i256 3, i256* %[[T01]], align 4
//CHECK-NEXT:   br label %store2
//CHECK-EMPTY: 
//CHECK-NEXT: store2:
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_\.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 5
//CHECK-NEXT:   store i256 9, i256* %[[T02]], align 4
//CHECK-NEXT:   br label %store3
//CHECK-EMPTY: 
//CHECK-NEXT: store3:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_\.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   store i256 6, i256* %[[T03]], align 4
//CHECK-NEXT:   br label %store4
//CHECK-EMPTY: 
//CHECK-NEXT: store4:
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_\.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 7
//CHECK-NEXT:   store i256 7, i256* %[[T04]], align 4
//CHECK-NEXT:   br label %store5
//CHECK-EMPTY: 
//CHECK-NEXT: store5:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_\.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 0
//CHECK-NEXT:   %[[T06:[0-9a-zA-Z_\.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 4
//CHECK-NEXT:   %[[COPY_SRC_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T06]], i32 0
//CHECK-NEXT:   %[[COPY_DST_0:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T05]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_0:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_0]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_0]], i256* %[[COPY_DST_0]], align 4
//CHECK-NEXT:   %[[COPY_SRC_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T06]], i32 1
//CHECK-NEXT:   %[[COPY_DST_1:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T05]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_1:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_1]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_1]], i256* %[[COPY_DST_1]], align 4
//CHECK-NEXT:   br label %store6
//CHECK-EMPTY: 
//CHECK-NEXT: store6:
//CHECK-NEXT:   %[[T07:[0-9a-zA-Z_\.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 2
//CHECK-NEXT:   %[[T08:[0-9a-zA-Z_\.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 6
//CHECK-NEXT:   %[[COPY_SRC_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T08]], i32 0
//CHECK-NEXT:   %[[COPY_DST_2:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 0
//CHECK-NEXT:   %[[COPY_VAL_2:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_2]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_2]], i256* %[[COPY_DST_2]], align 4
//CHECK-NEXT:   %[[COPY_SRC_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T08]], i32 1
//CHECK-NEXT:   %[[COPY_DST_3:[0-9a-zA-Z_\.]+]] = getelementptr i256, i256* %[[T07]], i32 1
//CHECK-NEXT:   %[[COPY_VAL_3:[0-9a-zA-Z_\.]+]] = load i256, i256* %[[COPY_SRC_3]], align 4
//CHECK-NEXT:   store i256 %[[COPY_VAL_3]], i256* %[[COPY_DST_3]], align 4
//CHECK-NEXT:   br label %store7
//CHECK-EMPTY: 
//CHECK-NEXT: store7:
//CHECK-NEXT:   %[[T09:[0-9a-zA-Z_\.]+]] = getelementptr [9 x i256], [9 x i256]* %lvars, i32 0, i32 8
//CHECK-NEXT:   store i256 0, i256* %[[T09]], align 4
//CHECK-NEXT:   br label %unrolled_loop8
//CHECK-EMPTY: 
//CHECK-NEXT: unrolled_loop8:
//CHECK-NEXT:   %[[T10:[0-9a-zA-Z_\.]+]] = bitcast [9 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T11:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 0
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T10]], [0 x i256]* %0, i256* %[[T11]])
//CHECK-NEXT:   %[[T14:[0-9a-zA-Z_\.]+]] = bitcast [9 x i256]* %lvars to [0 x i256]*
//CHECK-NEXT:   %[[T15:[0-9a-zA-Z_\.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i256 1
//CHECK-NEXT:   call void @..generated..loop.body.[[$F_ID_1]]([0 x i256]* %[[T14]], [0 x i256]* %0, i256* %[[T15]])
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY: 
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
