pragma circom 2.1.0;
// REQUIRES: circom
// RUN: rm -rf %t && mkdir %t && %circom --llvm -o %t %s | sed -n 's/.*Written successfully:.* \(.*\)/\1/p' | xargs cat | FileCheck %s --enable-var-scope

function sum(a) {
    var b[4] = a;
    return b;
}

template CallRetTest() {
    signal input x[4];
    signal output y[4];

    y <-- sum(x);
}

component main = CallRetTest();

//CHECK-LABEL: define{{.*}} i256* @sum_0(i256* %0){{.*}} {
//CHECK-NEXT: sum_0:
//CHECK-NEXT:   br label %store1
//CHECK-EMPTY:
//CHECK-NEXT: store1:
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 0
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T04]], i256* %[[T03]], i32 4)
//CHECK-NEXT:   br label %return2
//CHECK-EMPTY:
//CHECK-NEXT: return2:
//CHECK-NEXT:   %[[T05:[0-9a-zA-Z_.]+]] = getelementptr i256, i256* %0, i32 4
//CHECK-NEXT:   ret i256* %[[T05]]
//CHECK-NEXT: }
//
//CHECK-LABEL: define{{.*}} void @CallRetTest_0_run([0 x i256]* %0){{.*}} {
//CHECK-NEXT: prelude:
//CHECK-NEXT:   %lvars = alloca [0 x i256], align 8
//CHECK-NEXT:   %subcmps = alloca [0 x { [0 x i256]*, i32 }], align 8
//CHECK-NEXT:   br label %call1
//CHECK-EMPTY:
//CHECK-NEXT: call1:
//CHECK-NEXT:   %sum_0_arena = alloca [8 x i256], align 8
//CHECK-NEXT:   %[[T01:[0-9a-zA-Z_.]+]] = getelementptr [8 x i256], [8 x i256]* %sum_0_arena, i32 0, i32 0
//CHECK-NEXT:   %[[T02:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 4
//CHECK-NEXT:   call void @fr_copy_n(i256* %[[T02]], i256* %[[T01]], i32 4)
//CHECK-NEXT:   %[[T03:[0-9a-zA-Z_.]+]] = bitcast [8 x i256]* %sum_0_arena to i256*
//CHECK-NEXT:   %call.sum_0 = call i256* @sum_0(i256* %[[T03]])
//CHECK-NEXT:   %[[T04:[0-9a-zA-Z_.]+]] = getelementptr [0 x i256], [0 x i256]* %0, i32 0, i32 0
//CHECK-NEXT:   call void @fr_copy_n(i256* %call.sum_0, i256* %[[T04]], i32 4)
//CHECK-NEXT:   br label %prologue
//CHECK-EMPTY:
//CHECK-NEXT: prologue:
//CHECK-NEXT:   ret void
//CHECK-NEXT: }
